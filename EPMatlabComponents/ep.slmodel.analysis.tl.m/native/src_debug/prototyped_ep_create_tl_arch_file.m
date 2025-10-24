function ep_create_tl_arch_file(stEnv, stModel, stArgs, sMaFile)
% Exports the model analysis structure to TL-XML file.
% TL Use Case: Generates XML-File for the Targetlink-Architecture (see targetlink_architecture.xsd),
%
% function ep_create_tl_arch_file(stEnv, stModel, stArgs, sMaFile)
%
%   INPUT               DESCRIPTION
%    - stEnv                (object)  Environment
%    - stModel              (struct)  Model analysis struct produced by "atgcv_m01_model_analyse".
%    - stArgs               (struct)  stArgs holds information about the output files which have to be generated.
%                                            Also information about involved models is given.
%       .sTlResultFile      (String)  Path to the TargetLink output file.
%       .sMappingResultFile (String)  Path to the Mapping output file.
%       .sSlResultFile      (String)  Path to the Simulink output file.
%       .astTlModules       (array)   Information about involved TargetLink modeles
%       .astSlModules       (array)   Information about involved Simulink modeles
%   - sMaFile               (String)  Path to the ModelAnalysis.xml
%
%   OUTPUT              DESCRIPTION
%    -                      -
%

%% internal
%
%   AUTHOR(S):
%     Steffen Kollmann
% $$$COPYRIGHT$$$
%%

%% Legacy way
if true
    ep_legacy_ma_model_arch_convert(stArgs.xEnv, sMaFile, stArgs.sTlResultFile, stArgs, false);
    return;
end

%TODO: New way must be implemented
%      - Only a prototype implementation !!!!!!!!
%      - Must be cleaned up

%% prepare data
try
    %% Prepare
    % reset persistent counters (used globally)
    i_reset_internal_counters();
    % Cleanup counters when function is completed
    xOnCleanupClearCounters = onCleanup(@() i_clear_internal_counters());
    % Set TL or SL context
    i_is_sl(strcmpi(stModel.sModelMode, 'SL'));
    i_is_opt_sl(~isempty(stModel.sSlModel));

    % Get information about involved Simulink/TargetLink models. Important for model references.
    stModel.astTlModels = stArgs.astTlModels;
    stModel.astSlModels = stArgs.astSlModels;

    %% Collect information about the optional Simulnk model.
    astSlModelInfo = [];
    if i_is_opt_sl
        casSubPaths = {stModel.astSubsystems(:).sSlPath};
        casDispBlocks = []; % TODO: Must be implemented
        astSlModelInfo = atgcv_m01_compiled_info_get(stEnv, [casSubPaths, casDispBlocks]);
    end

    %% Init struct holding references to the Architecture XML-Nodes
    stArchXmlNodes = struct('hTlArchNode', [], 'hCArchNode', [], 'hSlArchNode', [], 'hMapArchNode', []);

    %% Create header information and prepare xml files for export
    stArchXmlNodes.hTlArchNode= i_create_headers_for_xml_outputs(stEnv, 'TL', stModel);
    stArchXmlNodes.hCArchNode = i_create_headers_for_xml_outputs(stEnv, 'C', stModel);
    if  i_is_opt_sl
        stArchXmlNodes.hSlArchNode = i_create_headers_for_xml_outputs(stEnv, 'SL', stModel);
    end
    stArchXmlNodes.hMapArchNode = i_create_headers_for_xml_outputs(stEnv, 'MAP', stModel);

    %% Callback to clear Xml files.
    xOnCleanupClearTlDoc = onCleanup(@() mxx_xmltree('clear', stArchXmlNodes.hTlArchNode));
    xOnCleanupClearCCodeDoc = onCleanup(@() mxx_xmltree('clear', stArchXmlNodes.hCArchNode));
    if i_is_opt_sl
        xOnCleanupClearSlDoc = onCleanup(@() mxx_xmltree('clear', stArchXmlNodes.hSlArchNode));
    end
    xOnCleanupClearMappingDoc = onCleanup(@() mxx_xmltree('clear', stArchXmlNodes.hMapArchNode));


    %% Export model analysis information
    i_convert_input_data_to_xml_outputs(stEnv, stModel, astSlModelInfo, stArchXmlNodes);

    %% Save and clear outputs
    mxx_xmltree('save', stArchXmlNodes.hTlArchNode, stArgs.sTlResultFile);
    mxx_xmltree('save', stArchXmlNodes.hCArchNode, stArgs.sCResultFile);
    mxx_xmltree('save', stArchXmlNodes.hMapArchNode, stArgs.sMappingResultFile);
    if  i_is_opt_sl
        mxx_xmltree('save', stArchXmlNodes.hSlArchNode, stArgs.sSlResultFile);
    end
catch exception
    rethrow(exception);
end
end

%***********************************************************************************************************************
% INTERNAL FUNCTION DEFINITION(S)
%***********************************************************************************************************************

%***********************************************************************************************************************
% Converts the input data to the output XMLs
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv          (struct)  Environment
%    - stModel        (struct)  Information about the analyzed model
%    - astSlModelInfo (struct)  Information about the optional Simulink model
%    - stArchNodes    (struct)  Handles of the Architecture XML-nodes
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_convert_input_data_to_xml_outputs(stEnv, stModel, astSlModelInfo, stArchNodes)
%% Prepare
% Struct of XML subsystem nodes
% oCPathMap, needed to extend easily the scope path of the C-Code architeture
stSubystemNodes = struct('hTlSubsystemNode', [], 'hCSubsystemNode', [], 'hSlSubsystemNode', [], ...
    'hMapSubsystemNode', [], 'oCPathMap', containers.Map);

% Collect all subsystem IDs
casSubIDs = {stModel.astSubsystems(:).sId};

%% Iterate over subsystems
for i = 1:length(stModel.astSubsystems);
    stSub = stModel.astSubsystems(i);
    % Add information to subsystem
    stSubystemNodes = i_add_subsystem_information(stEnv, stModel, stSub, stArchNodes, stSubystemNodes);
    % Find corresponding subsystem of Simulink Subsystem
    stSlModel = [];
    if i_is_opt_sl
        for j=1:length(astSlModelInfo)
            % Assumption sPath and sSlPath must be equal
            if strcmp(astSlModelInfo(j).sPath, stSub.sSlPath)
                stSlModel = astSlModelInfo(j);
                break;
            end
        end
    end

    % Add interface to subsystems
    i_add_interface_information(stEnv, stSub, stModel, stSlModel, stSubystemNodes);

    % Add parent/child relations
    i_add_child_information_to_subsystems(stSub, casSubIDs, stSubystemNodes);
end

%% Mark root subsystem for TargetLink-Architecture
hRootSystemNode = mxx_xmltree('add_node', stArchNodes.hTlArchNode, 'rootSystem');
mxx_xmltree('set_attribute', hRootSystemNode, 'refSubsysID', 'ss1');

%% Mark root subsystem for Simulink-Architecture
if ~isempty(stArchNodes.hSlArchNode)
    hRootSystemNode = mxx_xmltree('add_node', stArchNodes.hSlArchNode, 'rootSystem');
    mxx_xmltree('set_attribute', hRootSystemNode, 'refSubsysID', 'ss1');
end

%% TODO: NEEDED ????
%     if (isfield(stModel, 'stSystemTimeVar') && ~isempty(stModel.stSystemTimeVar))
%         i_addSystemTimeVar(stEnv, hRootNode, stModel.stSystemTimeVar);
%     end

end

%***********************************************************************************************************************
% Adds child relations to the XML-files. Only needed for TL/SL
%
%   PARAMETER(S)          DESCRIPTION
%    - stSub                (struct)   Subsystem information
%    - casSubIDs            (array)    Available subsystem IDs in the system
%    - stSubsystemNodes     (struct)   Subsystem XML-Nodes
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_child_information_to_subsystems(stSub, casSubIDs, stSubsystemNodes)
aiChildIdx = stSub.aiChildIdx;
if ~isempty(aiChildIdx)
    for nj = 1:length(aiChildIdx)
        sChildId = casSubIDs{aiChildIdx(nj)};
        hRefNode = mxx_xmltree('add_node', stSubsystemNodes.hTlSubsystemNode, 'subsystem');
        mxx_xmltree('set_attribute', hRefNode, 'refSubsysID', sChildId);
        if i_is_opt_sl
            hRefNode = mxx_xmltree('add_node', stSubsystemNodes.hSlSubsystemNode, 'subsystem');
            mxx_xmltree('set_attribute', hRefNode, 'refSubsysID', sChildId);
        end
    end
end

%% TODO check if needed? Maybe env subsystems for closed-loop models
% if (isfield(stSub, 'astBlocks') && ~isempty(stSub.astBlocks))
%     if isempty(hChildrenNode)
%         hChildrenNode = mxx_xmltree('add_node', hSubNode, 'Children');
%     end
%     for j = 1:length(stSub.astBlocks)
%         stBlock = stSub.astBlocks(j);
%         hBlockNode = mxx_xmltree('add_node', hChildrenNode, 'Block');
%
%         mxx_xmltree('set_attribute', hBlockNode, 'name', stBlock.sName);
%         mxx_xmltree('set_attribute', hBlockNode, 'path', stBlock.sPath);
%         mxx_xmltree('set_attribute', hBlockNode, 'type', stBlock.sType);
%     end
% end
end

%***********************************************************************************************************************
% Creates header information for the different XML output files.
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv         (struct) Environment
%    - sKind         (String) (TL|SL|C|MAP)
%    - stModel       (struct) Model information
%   OUTPUT
%    - hArch         (handle) architecture node
%    - hRoot         (handle) doc handle
%***********************************************************************************************************************
function [hArch, hRoot] = i_create_headers_for_xml_outputs(~, sKind, stModel)
hArch = [];
hRoot = [];
% Create header information for TL architecture.
if strcmp(sKind, 'TL')
    hRoot = mxx_xmltree('create', 'tl:TargetLinkArchitecture');
    mxx_xmltree('set_attribute', hRoot, 'xmlns:tl', 'http://btc-es.de/ep/targetlink/2014/12/09');
    mxx_xmltree('set_attribute', hRoot, 'initScript', '');
    mxx_xmltree('set_attribute', hRoot, 'modelVersion', '');
    mxx_xmltree('set_attribute', hRoot, 'modelPath', stModel.sModelFile);
    mxx_xmltree('set_attribute', hRoot, 'modelCreationDate', '');
    i_add_tool_info(hRoot, 'Matlab');
    i_add_tool_info(hRoot, 'Simulink');
    i_add_tool_info(hRoot, 'TargetLink');

    for ni=1:length(stModel.astTlModels)
        hArchTmp =  mxx_xmltree('add_node', hRoot, 'model');
        if ni == 1
            hArch = hArchTmp;
        end
        mxx_xmltree('set_attribute', hArchTmp, 'modelID', ['model00',num2str(ni)]);
        mxx_xmltree('set_attribute', hArchTmp, 'modelVersion', stModel.astTlModels(ni).sVersion);
        mxx_xmltree('set_attribute', hArchTmp, 'modelPath', stModel.astTlModels(ni).sFile);
        mxx_xmltree('set_attribute', hArchTmp, 'creationDate', stModel.astTlModels(ni).sCreated);
        mxx_xmltree('set_attribute', hArchTmp, 'initScript', '');
    end
    hModelRoot =  mxx_xmltree('add_node', hRoot, 'root');
    mxx_xmltree('set_attribute', hModelRoot, 'refModelID', 'model001');
end

% Create header information for C architecture.
if strcmp(sKind, 'C')
    hRoot = mxx_xmltree('create', 'CodeModel');
    hArch = mxx_xmltree('add_node', hRoot, 'Functions');
    mxx_xmltree('add_node', hRoot, 'Scalings');
end

% Create header information for SL architecture.
% TODO: Handle model references
if strcmp(sKind, 'SL')
    hRoot = mxx_xmltree('create', 'sl:SimulinkArchitecture');
    mxx_xmltree('set_attribute', hRoot, 'xmlns:sl', 'http://btc-es.de/ep/simulink/2014/12/09');
    mxx_xmltree('set_attribute', hRoot, 'modelPath', stModel.sModelFile);
    mxx_xmltree('set_attribute', hRoot, 'initScript', '');
    mxx_xmltree('set_attribute', hRoot, 'modelCreationDate', '');
    mxx_xmltree('set_attribute', hRoot, 'modelVersion', '');
    i_add_tool_info(hRoot, 'Matlab');
    i_add_tool_info(hRoot, 'Simulink');
    i_add_tool_info(hRoot, 'TargetLink');
    hArch = mxx_xmltree('add_node', hRoot, 'model');
    mxx_xmltree('set_attribute', hArch, 'modelID', 'model001');
    mxx_xmltree('set_attribute', hArch, 'modelVersion', '');
    mxx_xmltree('set_attribute', hArch, 'modelPath', stModel.sModelFile);
    mxx_xmltree('set_attribute', hArch, 'creationDate', '');
    mxx_xmltree('set_attribute', hArch, 'initScript', '');
    hModelRoot =  mxx_xmltree('add_node', hRoot, 'root');
    mxx_xmltree('set_attribute', hModelRoot, 'refModelID', 'model001');
end

% Create header information for Mapping architecture.
if strcmp(sKind, 'MAP')
    hRoot = mxx_xmltree('create', 'Mappings');
    hArch = mxx_xmltree('add_node', hRoot, 'ArchitectureMapping');

    hMapTLArchNode = mxx_xmltree('add_node', hArch, 'Architecture');
    mxx_xmltree('set_attribute', hMapTLArchNode, 'id', 'id0');
    mxx_xmltree('set_attribute', hMapTLArchNode, 'name', stModel.sName);

    hMapCArchNode = mxx_xmltree('add_node', hArch, 'Architecture');
    mxx_xmltree('set_attribute', hMapCArchNode, 'id', 'id1');
    mxx_xmltree('set_attribute', hMapCArchNode, 'name', [stModel.astSubsystems(1).sStepFunc, ' [C-Code]']);

    if i_is_opt_sl()
        hMapSlArchNode = mxx_xmltree('add_node', hArch, 'Architecture');
        mxx_xmltree('set_attribute', hMapSlArchNode, 'id', 'id2');
        mxx_xmltree('set_attribute', hMapSlArchNode, 'name', stModel.sSlModel);
    end
end
end

%***********************************************************************************************************************
% Adds subsystem information
%
%   PARAMETER(S)                         DESCRIPTION
%    - xEnv                               (object) Environment object
%    - stModel                            (struct) model information
%    - stSub                              (struct) information about the subsystem
%    - stArchNodes                        (struct) XML handles for adding the subsystem information
%    - stCollectedSubsystemInformation    (struct) Information about already analyzed subsystems.
%   OUTPUT
%    - stSubsystemNodes                   (struct) XML-Nodes (TL/C-Code/(SL)/Mapping
%                                                  of the subsystem in order to add more information
%***********************************************************************************************************************
function stSubsystemNodes = i_add_subsystem_information(~, stModel, stSub, stArchNodes, stCollectedSubsystemInformation)

%% init return value struct
stSubsystemNodes = struct('hTlSubsystemNode', [], 'hCSubsystemNode', [], 'hSlSubsystemNode', [], ...
    'hMapSubsystemNode', [], 'oCPathMap', stCollectedSubsystemInformation.oCPathMap);

%% Add TargetLink subsystem information
stSubsystemNodes.hTlSubsystemNode =  mxx_xmltree('add_node', stArchNodes.hTlArchNode, 'subsystem');
mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'subsysID', stSub.sId);
mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'path', stSub.sTlPath);
mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'sampleTime', sprintf('%g', stSub.dSampleTime));
mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'name', i_get_name_from_path(stSub.sTlPath));
mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'scopeKind', 'SUT');
mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'kind', stSub.sKind);
% Handle model references
if ~strcmp(stSub.sModelPath, stSub.sTlPath)
    mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'physicalPath', stSub.sModelPath);
    sModelName = strtok(stSub.sModelPath, '/');
    for ni=1:length(stModel.astTlModels)
        [~,sName] = fileparts(stModel.astTlModules(ni).sFile);
        if strcmp(sModelName, sName)
            mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'modelRef', ['model00', num2str(ni)]);
            break;
        end
    end
end

%Check SUT kind
if isfield(stSub, 'bHasMilSupport')
    bHasMilSupport = stSub.bHasMilSupport;
else
    bHasMilSupport = ~isempty(stSub.stInterface);
end
if stSub.bIsDummy && bHasMilSupport
    mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'scopeKind', 'VIRTUAL');
end
if stSub.bIsDummy && ~bHasMilSupport
    mxx_xmltree('set_attribute', stSubsystemNodes.hTlSubsystemNode, 'scopeKind', 'DUMMY');
end

% TODO: Check if possible for EP2.x
% if ~isempty(stSub.sDescription)
%     mxx_xmltree('set_attribute', hSubNode, 'description', stSub.sDescription);
% end


%% Add C-Code subsystem information
stSubsystemNodes.hCSubsystemNode = mxx_xmltree('add_node', stArchNodes.hCArchNode, 'Function');
mxx_xmltree('set_attribute', stSubsystemNodes.hCSubsystemNode, 'name', stSub.sStepFunc);

%% TODO: POST INIT FUNCTION / PROXY FUNCTIONS
% Special handling for init functions.
sGlobalInitFunc = '';
if ~i_is_sl()
    if stModel.bSetGlobalInitFuncForAutosar
        sGlobalInitFunc = 'Rte_Start';
    end
end
if isempty(sGlobalInitFunc)
    if ~isempty(stSub.hInitFunc)
        sInitFunc = stSub.sInitFunc;
        mxx_xmltree('set_attribute', stSubsystemNodes.hCSubsystemNode, 'initFunc', sInitFunc);
    end
    %     if ~isempty(stSub.hPostInitFunc)
    %         sPostInitFunc = stSub.sPostInitFunc;
    %         mxx_xmltree('set_attribute', hSubNode, 'postInitFct', sPostInitFunc);
    %     end
else
    % if we have a global InitFunction, -->
    %    1) use it as init function of the Subsystem
    %    2) use the original init functiono of the Subsystem as postInitFct
    mxx_xmltree('set_attribute', stSubsystemNodes.hCSubsystemNode, 'initFct', sGlobalInitFunc);
    %     if ~isempty(stSub.hInitFunc)
    %         sInitFunc = stSub.sInitFunc;
    %         mxx_xmltree('set_attribute', hSubNode, 'postInitFct', sInitFunc);
    %     end
    % just ignore the real postInitFunc for now; probably not relevant in
    % AUTOSAR UseCase
end

%% Add Simulink subsystem information
% TODO: Handle model references
if i_is_opt_sl
    stSubsystemNodes.hSlSubsystemNode =  mxx_xmltree('add_node', stArchNodes.hSlArchNode, 'subsystem');
    mxx_xmltree('set_attribute', stSubsystemNodes.hSlSubsystemNode , 'subsysID', stSub.sId);
    mxx_xmltree('set_attribute', stSubsystemNodes.hSlSubsystemNode , 'path', stSub.sSlPath);
    mxx_xmltree('set_attribute', stSubsystemNodes.hSlSubsystemNode , 'sampleTime', sprintf('%g', stSub.dSampleTime));
    mxx_xmltree('set_attribute', stSubsystemNodes.hSlSubsystemNode , 'name', i_get_name_from_path(stSub.sSlPath));
    mxx_xmltree('set_attribute', stSubsystemNodes.hSlSubsystemNode , 'scopeKind', 'SUT'); % TODO: Virtual/Dummy, etc
    mxx_xmltree('set_attribute', stSubsystemNodes.hSlSubsystemNode , 'kind', stSub.sKind);
    if ~strcmp(stSub.sSlPath, stSub.sSlPath)
        mxx_xmltree('set_attribute', stSubsystemNodes.hSlSubsystemNode, 'physicalPath', stSub.sSlPath);
        mxx_xmltree('set_attribute', stSubsystemNodes.hSlSubsystemNode, 'modelRef', 'model001'); % TODO: Clean up
    end
end

%% Add Mapping subsystem information
% TODO: Handle mapping for DUMMY/VIRTURAL subsystems
stSubsystemNodes.hMapSubsystemNode = mxx_xmltree('add_node', stArchNodes.hMapArchNode, 'ScopeMapping');
hTlPath = mxx_xmltree('add_node', stSubsystemNodes.hMapSubsystemNode, 'Path');
mxx_xmltree('set_attribute', hTlPath, 'refId', 'id0');
mxx_xmltree('set_attribute', hTlPath, 'path', stSub.sTlPath);

hCPath = mxx_xmltree('add_node', stSubsystemNodes.hMapSubsystemNode, 'Path');
mxx_xmltree('set_attribute', hCPath, 'refId', 'id1');
sPath = sprintf('%s:1:%s', stSub.sModuleName, stSub.sStepFunc);
if ~isempty(stSub.iParentIdx)
    sPath = [stSubsystemNodes.oCPathMap(['ss',num2str(stSub.iParentIdx)]),'/', sPath];
end
stSubsystemNodes.oCPathMap(stSub.sId) = sPath;
mxx_xmltree('set_attribute', hCPath, 'path', sPath);

if ~isempty(stArchNodes.hSlArchNode)
    hSlPath = mxx_xmltree('add_node', stSubsystemNodes.hMapSubsystemNode, 'Path');
    mxx_xmltree('set_attribute', hSlPath, 'refId', 'id2');
    mxx_xmltree('set_attribute', hSlPath, 'path', stSub.sSlPath);
end
end

%***********************************************************************************************************************
% Adds interface information
%
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_interface_information(stEnv, stSubsystem, stModel, astSlModel, stSubsystemNodes)
% simplify struct-access a little by using local copies
stInterface = stSubsystem.stInterface;

%% Add inputs
hCInterfaceNode = mxx_xmltree('add_node', stSubsystemNodes.hCSubsystemNode, 'Interface');
nInports = length(stInterface.astInports);
for i = 1:(nInports)
    % Data type struct
    stSlPort = [];
    stInport = stInterface.astInports(i);
    if i_is_opt_sl
        stSlPort = astSlModel.astInports(i);
    end
    i_add_tl_port(stEnv, stSubsystemNodes.hTlSubsystemNode, 'inport', stInport);
    i_add_ccode_port(stEnv, hCInterfaceNode,'in', stInport);
    i_add_mapping_port(stEnv, stSubsystemNodes.hMapSubsystemNode,'Input',stInport )
    i_add_sl_port(stEnv, stSubsystemNodes.hSlSubsystemNode, 'inport', stInport, stSlPort);
    % TODO: Have a look what is to do here
    %i_modifyMuxPort(stEnv, hPortNode, stInport);
end

%% Add outputs
% TODO: This is just for debugging so that the Mapping.xml fits to the XML produced by the previous release.
%       Clean up after stabalization. See bellow
nOutports = length(stInterface.astOutports);
for i = 1:(nOutports)
    stOutport = stInterface.astOutports(i);
    i_add_mapping_port(stEnv, stSubsystemNodes.hMapSubsystemNode,'Output',stOutport)
end

%% Add parameters
nCalVars = length(stSubsystem.astCalRefs);
for i = 1:nCalVars
    iVarIdx = stSubsystem.astCalRefs(i).iVarIdx;
    stParameter   = stModel.astCalVars(iVarIdx);
    aiBlockIdx = stSubsystem.astCalRefs(i).aiBlockIdx;
    stParameter.stBlockInfo = stParameter.astBlockInfo(aiBlockIdx(1));
    stParameter.aiBlockIdx = aiBlockIdx;
    stSlParameter = [];

    iFirstIdx = 1; % TODO: Check 1.x code again where the index is important. Seems to be for Stateflow start index
    nModelRefs = length(aiBlockIdx);
    for j = 1:nModelRefs
        stBlockInfo = stParameter.astBlockInfo(aiBlockIdx(j));
        if strcmpi(stBlockInfo.sBlockKind, 'Stateflow')
            if ~isempty(stBlockInfo.stSfInfo)
                iFirstIdx = stBlockInfo.stSfInfo.iSfFirstIndex;
            else
                iFirstIdx = 1;
            end
        end
    end

    i_add_tl_parameter(stEnv, stSubsystemNodes.hTlSubsystemNode, stParameter)
    i_add_ccode_parameter(stEnv, hCInterfaceNode, stParameter);
    i_add_mapping_parameter(stEnv, stSubsystemNodes.hMapSubsystemNode, stParameter);
    i_add_sl_parameter(stEnv, stSubsystemNodes.hSlSubsystemNode, stParameter, stSlParameter);
end

%% Add outputs
nOutports = length(stInterface.astOutports);
for i = 1:(nOutports)
    stSlOutport = [];
    stOutport = stInterface.astOutports(i);
    if i_is_opt_sl
        stSlOutport = astSlModel.astOutports(i);
    end
    i_add_tl_port(stEnv, stSubsystemNodes.hTlSubsystemNode, 'outport', stOutport);
    i_add_ccode_port(stEnv, hCInterfaceNode,'out', stOutport);
    %i_add_mapping_port(stEnv, stSubsystemNodes.hMapSubsystemNode,'Output',stOutport ) % TODO: See above and clean up
    i_add_sl_port(stEnv, stSubsystemNodes.hSlSubsystemNode, 'outport', stOutport, stSlOutport);
    % TODO: Have a look what is to do here
    %i_modifyMuxPort(stEnv, hPortNode, stInport);
end


%% Add Locals
% add different C-vars to same Display node if they have a common TL-block
nDispVars = length(stSubsystem.astDispRefs);
stSlLocal = [];
casLocalPath = [];
for i = 1:nDispVars
    % for now use the first reference! assuming _no_ multiple refs in model
    iVarIdx = stSubsystem.astDispRefs(i).iVarIdx;
    stLocal = stModel.astDispVars(iVarIdx);
    stLocal.stBlockInfo = stLocal.astBlockInfo(1);
    % TODO: Handle optional Simulink information
    if i_is_opt_sl
        stSlLocal = struct('sSlPath',stSubsystem.sSlPath);
    end

    iFirstIdx = 1; % TODO: Check 1.x code again where the index is important. Seems to be for Stateflow start index

    % Assumption: Collect all Blocks with the same sTLPath and handle this struct only once.
    if any(strcmp(stLocal.stBlockInfo.sTlPath, casLocalPath))
        continue;
    else
        casLocalPath = [casLocalPath, stLocal.stBlockInfo.sTlPath];
        for nj = 1:nDispVars
            iVarIdxTmp = stSubsystem.astDispRefs(nj).iVarIdx;
            stLocalTmp = stModel.astDispVars(iVarIdxTmp);
            if strcmp(stLocalTmp.astBlockInfo(1).sTlPath, stLocal.stBlockInfo(1).sTlPath)
                stLocal.astSomeSubSigs = [stLocal.astSomeSubSigs, stLocalTmp.astSomeSubSigs];
            end
        end

    end

    i_add_tl_local(stEnv, stSubsystemNodes.hTlSubsystemNode, stLocal);
    i_add_ccode_local(stEnv, hCInterfaceNode, stLocal);
    i_add_mapping_local(stEnv, stSubsystemNodes.hMapSubsystemNode,stLocal )
    i_add_sl_local(stEnv, stSubsystemNodes.hSlSubsystemNode, stSubsystem, stLocal, stSlLocal);
end

% TODO: Have a look what is to do here.
% % add DSM Input ports
% i_addDsmPorts(stEnv, ...
%     hInterfaceNode, 'in', stModel.sTlRoot, stModel.sSlRoot, astDsmVars);

%
% % add DSM Ouput ports
% i_addDsmPorts(stEnv, ...
%     hInterfaceNode, 'out', stModel.sTlRoot, stModel.sSlRoot, astDsmVars);
end

%***********************************************************************************************************************
% Adds a Local to the C-Code architecture
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv            (struct) Environment
%    - hCInterfaceNode  (handle) Interface handle
%    - stLocal          (struct) Local information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_ccode_local(stEnv, hCInterfaceNode, stLocal)
%% Iterate over the signals
astSignals = stLocal.astSignals;
stInfo = stLocal.stInfo;
casSomeSubSigs = [];
if ~isempty(stLocal.astSomeSubSigs)
    casSomeSubSigs = stLocal.astSomeSubSigs(:).sName;
end
% Assumption: If casSomeSubSigs is not empty, only these signals must be considered
for ni=1:length(astSignals)
    if ~isempty(casSomeSubSigs) && ~any(strcmp(astSignals(ni).sName, casSomeSubSigs))
        continue;
    end
    hCType = mxx_xmltree('add_node', hCInterfaceNode, 'InterfaceObj');
    mxx_xmltree('set_attribute', hCType, 'kind', 'disp');
    mxx_xmltree('set_attribute', hCType,  'var', stInfo.sRootName);
    mxx_xmltree('set_attribute', hCType,  'access', stInfo.sAccessPath);
    % TODO: handle arrays
    i_add_ccode_meta_type_info(stEnv, hCType, stInfo.astProp(1));
end
end

%***********************************************************************************************************************
% Adds a Local interface to the Targetlink architecture
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv            (struct) Environment
%    - hTlSubsystemNode (handle) Subsystem handle
%    - stLocal          (struct) Local information
%   OUTPUT
%    -
%*********************************************************************************************************************
function i_add_tl_local(stEnv, hTlSubsystemNode, stLocal)
stBlockInfo = stLocal.stBlockInfo;
hTlLocal = mxx_xmltree('add_node', hTlSubsystemNode, 'display');
mxx_xmltree('set_attribute', hTlLocal, 'path', sprintf('%s', stBlockInfo.sTlPath));
mxx_xmltree('set_attribute', hTlLocal, 'name', sprintf('%s', i_get_name_from_path(stBlockInfo.sTlPath)));
mxx_xmltree('set_attribute', hTlLocal, 'portNumber', sprintf('%s', num2str(stLocal.iPortNumber)));
i_add_tl_mil_sil_type_for_local(stEnv, hTlLocal, stLocal);
end

%***********************************************************************************************************************
% Adds a Local interface to the Simulink architecture
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv            (struct) Environment
%    - hSlSubsystemNode (handle) Subsystem handle
%    - stSubsystem      (struct) Subsystem information
%    - stLocal          (struct) Local information
%    - stSlLocal        (struct) Simulink Local information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_sl_local(stEnv, hSlSubsystemNode, stSubsystem, stLocal, stSlLocal)
if i_is_opt_sl
    stBlockInfo = stLocal.stBlockInfo;
    hSlLocal = mxx_xmltree('add_node', hSlSubsystemNode, 'display');
    mxx_xmltree('set_attribute', hSlLocal, 'path', sprintf('%s', strrep(stBlockInfo.sTlPath, ...
        stSubsystem.sModelPath, stSubsystem.sModelPathSl)));
    mxx_xmltree('set_attribute', hSlLocal, 'name', sprintf('%s', i_get_name_from_path(stBlockInfo.sTlPath)));
    mxx_xmltree('set_attribute', hSlLocal, 'portNumber', sprintf('%s', num2str(stLocal.iPortNumber)));
    i_add_sl_mil_type_for_local(stEnv, hSlLocal, stLocal, stSlLocal);
end
end

%***********************************************************************************************************************
% Adds the mapping for Local interfaces
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv             (struct) Environment
%    - hMapSubsystemNode (handle) Subsystem handle for mapping
%    - stLocal           (struct) Local information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_mapping_local(~, hMapSubsystemNode, stLocal)
astSignals = stLocal.astSignals;
nNumberOfSignals = length(astSignals);
stBlockInfo = stLocal.stBlockInfo;
stInfo = stLocal.stInfo;
bIsBus = 0;
% Is complex type
if strcmp(stLocal.sSigKind, 'bus')
    bIsBus = 1;
end

% Assumption: If casSomeSubSigs is not empty, only these signals must be considered
casSomeSubSigs = [];
if ~isempty(stLocal.astSomeSubSigs)
    casSomeSubSigs = stLocal.astSomeSubSigs(:).sName;
end

for ni=1:nNumberOfSignals
    if ~isempty(casSomeSubSigs) && ~any(strcmp(astSignals(ni).sName, casSomeSubSigs))
        continue;
    end
    %% Iterate over the sub signals
    astSubSigs = astSignals(ni).astSubSigs;
    for nj=1:length(astSubSigs)
        if (nj > 1)
            continue;
        end
        % Add Mapping node
        hMapSignals = mxx_xmltree('add_node', hMapSubsystemNode,'InterfaceObjectMapping');
        mxx_xmltree('set_attribute', hMapSignals, 'kind', 'Local');

        %% TL IO Mapping
        hPathTL = mxx_xmltree('add_node',hMapSignals, 'Path');
        mxx_xmltree('set_attribute',hPathTL, 'refId' , 'id0');
        mxx_xmltree('set_attribute',hPathTL, 'path' , stBlockInfo.sTlPath);

        %% SL IO Mapping
        if i_is_opt_sl
            hPathSl = mxx_xmltree('add_node',hMapSignals, 'Path');
            mxx_xmltree('set_attribute',hPathSl, 'refId' , 'id2');
            mxx_xmltree('set_attribute',hPathSl, 'path' , stBlockInfo.sTlPath);
        end

        %% C IO Mapping
        hPathC = mxx_xmltree('add_node', hMapSignals, 'Path');
        mxx_xmltree('set_attribute',hPathC, 'refId' , 'id1');
        sAccessPath =  [stLocal.stInfo.sRootName, stInfo.sAccessPath];
        mxx_xmltree('set_attribute',hPathC, 'path' , sAccessPath);

        %% TL Signal Mapping
        hSignalPath = mxx_xmltree('add_node',hMapSignals, 'SignalMapping');
        hPathTL = mxx_xmltree('add_node',hSignalPath, 'Path');
        mxx_xmltree('set_attribute',hPathTL, 'refId' , 'id0');

        sTLAccessPath = '';
        if ~isempty(astSubSigs(nj).sName) && nNumberOfSignals > 1
            sTLAccessPath = astSubSigs(nj).sName;
            if (astSubSigs(nj).sName(1) == '.')
                sTLAccessPath = ['<signal1>', astSubSigs(nj).sName];
            end
            if (bIsBus)
                sTLAccessPath = ['.', sTLAccessPath];
            end
        end
        mxx_xmltree('set_attribute',hPathTL, 'path' , sTLAccessPath);

        %% SL Signal Mapping
        if i_is_opt_sl
            hPathSl = mxx_xmltree('add_node',hSignalPath, 'Path');
            mxx_xmltree('set_attribute',hPathSl, 'refId' , 'id2');
            mxx_xmltree('set_attribute',hPathSl, 'path' , sTLAccessPath); % TODO: Fill Simulink information
        end

        %% C Signal Mapping
        hPathC = mxx_xmltree('add_node', hSignalPath, 'Path');
        mxx_xmltree('set_attribute',hPathC, 'refId' , 'id1');
        mxx_xmltree('set_attribute',hPathC, 'path' , '');
    end
end
end

%***********************************************************************************************************************
% Adds the MIL/SIL type to the Targetlink architecture
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv          (struct)  Environment
%    - hTlLocal       (handle)  XML-Node Handle
%    - stLocal        (struct)  Local information
%   OUTPUT
%    -
%***********************************************************************************************************************
function [hTlMilType] = i_add_tl_mil_sil_type_for_local(stEnv, hTlLocal, stLocal)

hTlMilType = mxx_xmltree('add_node', hTlLocal, 'miltype');
hTlSilType = mxx_xmltree('add_node', hTlLocal, 'siltype');

hDataTypeNode = hTlMilType;
hSilDataTypeNode = hTlSilType;

% Is complex type
if strcmp(stLocal.sSigKind, 'bus')
    hDataTypeNode = mxx_xmltree('add_node', hDataTypeNode, 'bus');
    hSilDataTypeNode = mxx_xmltree('add_node', hSilDataTypeNode, 'bus');
end


astSignals = stLocal.astSignals;
nNumberOfSignals = length(astSignals);
hDataTypeNodeTmp = hDataTypeNode;
hSilDataTypeNodeTmp = hSilDataTypeNode;

% Assumption: If casSomeSubSigs is not empty, only these signals must be considered
casSignals = [];
if ~isempty(stLocal.astSomeSubSigs)
    casSignals = stLocal.astSomeSubSigs(:).sName;
end

%% Iterate over the signals
for ni=1:nNumberOfSignals
    if ~isempty(casSignals) && ~any(strcmp(astSignals(ni).sName, casSignals))
        continue;
    end
    hDataTypeNode = hDataTypeNodeTmp;
    hSilDataTypeNode = hSilDataTypeNodeTmp;
    if (nNumberOfSignals > 1)
        hSignal =  mxx_xmltree('add_node', hDataTypeNode, 'signal');
        hSilSignal =  mxx_xmltree('add_node', hSilDataTypeNode, 'signal');
    else
        hSignal = hDataTypeNode;
        hSilSignal = hSilDataTypeNode;
    end

    hSignal2 = hSignal;
    hSilSignal2 = hSilSignal;
    % non-uniform array
    astSubSigs = astSignals(ni).astSubSigs;
    if length(astSubSigs) > 1
        hArrayNode = mxx_xmltree('add_node', hSignal, 'nonUniformArray');
        mxx_xmltree('set_attribute', hArrayNode, 'size', num2str(astSignals(ni).iWidth));
        hSignal2 = hArrayNode;
        hSilArrayNode = mxx_xmltree('add_node', hSilSignal, 'nonUniformArray');
        mxx_xmltree('set_attribute', hSilArrayNode, 'size', num2str(astSignals(ni).iWidth));
        hSilSignal2 = hSilArrayNode;
    end
    %% Iterate over the sub signals
    for nj=1:length(astSubSigs)
        % single element
        if length(stLocal.stInfo.astProp) == 1
            mxx_xmltree('add_node', hSignal2, astSubSigs(nj).sType);
            if nj <= length(stLocal.stInfo.astProp)
                i_add_tl_concrete_sil_type(stEnv,hSilSignal2, stLocal.stInfo.stVarType.sBase, ...
                    stLocal.stInfo.astProp(nj), any(strcmp(astSubSigs(nj).sType, {'double', 'single'})));
                if ~isempty(stLocal.stInfo.astProp(nj).dInitValue)
                    i_set_attribute_double(hSignal2, 'initValue', stLocal.stInfo.astProp(nj).dInitValue);
                    i_set_attribute_double(hSilSignal2, 'initValue',stLocal.stInfo.astProp(nj).dInitValue);
                end
                if ~isempty(stLocal.stInfo.astProp(nj).sUnit)
                    mxx_xmltree('set_attribute', hSilSignal2, 'unitName', stLocal.stInfo.astProp(nj).sUnit);
                end
            else
                mxx_xmltree('set_attribute', hSilSignal2, 'missingTypeSinceNoCVar', 'true');
                mxx_xmltree('add_node', hSilSignal2, 'unsupportedTypeInformation');
            end
        else
            % Mil Type
            hSubSignal = mxx_xmltree('add_node', hSignal2, 'signal');
            mxx_xmltree('add_node', hSubSignal, astSubSigs(nj).sType);
            %Sil Type
            hSilSubSignal = mxx_xmltree('add_node', hSilSignal2, 'signal');
            if  nj <= length(stLocal.stInfo.astProp)
                i_add_tl_concrete_sil_type(stEnv, hSilSubSignal, stLocal.stInfo.stVarType.sBase, ...
                    stLocal.stInfo.astProp(nj), any(strcmp(astSubSigs(nj).sType, {'double', 'single'})));
                if ~isempty(stLocal.stInfo.astProp(nj).dInitValue)
                    i_set_attribute_double(hSubSignal, 'initValue', stLocal.stInfo.astProp(nj).dInitValue);
                    i_set_attribute_double(hSilSubSignal, 'initValue',stLocal.stInfo.astProp(nj).dInitValue);
                end
                if ~isempty(stLocal.stInfo.astProp(nj).sUnit)
                    mxx_xmltree('set_attribute', hSilSubSignal, 'unitName',stLocal.stInfo.astProp(nj).sUnit);
                end
            else
                mxx_xmltree('add_node', hSilSubSignal, 'unsupportedTypeInformation');
            end
            mxx_xmltree('set_attribute', hSilSubSignal, 'index', num2str(astSubSigs(nj).iSubSigIdx));
            mxx_xmltree('set_attribute', hSubSignal, 'index', num2str(astSubSigs(nj).iSubSigIdx));
        end
        % TODO: Sometimes the signalName is not needed. Unclear what the pattern is.
        if ~isempty(astSubSigs(nj).sName)
            sName = astSubSigs(nj).sName;
            if (astSubSigs(nj).sName(1) == '.')
                sName = ['<signal1>', astSubSigs(nj).sName];
            end
            mxx_xmltree('set_attribute', hSignal, 'signalName', sName);
            mxx_xmltree('set_attribute', hSilSignal, 'signalName', sName);
        end
    end
end
end

%***********************************************************************************************************************
% Adds the type to the Simulink architecture
%
% TODO: This function must be revised and checked again
%       Simulink not handled correctly!!!
%
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_sl_mil_type_for_local(~, hSlInport, stLocal, stSlLocal)
%TODO: This function must be revised and checked again
%      Simulink not handled correctly!!!

hDataTypeNode = hSlInport;
% Is complex type
if strcmp(stLocal.sSigKind, 'bus')
    hDataTypeNode = mxx_xmltree('add_node', hDataTypeNode, 'bus');
end

%% Iterate over the signals
astSignals = stLocal.astSignals;
nNumberOfSignals = length(astSignals);
hDataTypeNodeTmp = hDataTypeNode;
for ni=1:nNumberOfSignals
    hDataTypeNode = hDataTypeNodeTmp;
    if (nNumberOfSignals > 1)
        hSignal =  mxx_xmltree('add_node', hDataTypeNode, 'signal');
    else
        hSignal = hDataTypeNode;
    end

    hSignal2 = hSignal;
    % non-uniform array
    astSubSigs = astSignals(ni).astSubSigs;
    if length(astSubSigs) > 1
        hArrayNode = mxx_xmltree('add_node', hSignal, 'nonUniformArray');
        mxx_xmltree('set_attribute', hArrayNode, 'size', num2str(astSignals(ni).iWidth));
        hSignal2 = hArrayNode;
    end
    %% Iterate over the sub signals
    for nj=1:length(astSubSigs)
        % single element
        if length(stLocal.stInfo.astProp) == 1
            mxx_xmltree('add_node', hSignal2, astSubSigs(nj).sType);
        else
            % Mil Type
            hSubSignal = mxx_xmltree('add_node', hSignal2, 'signal');
            mxx_xmltree('set_attribute', hSubSignal, 'index', num2str(astSubSigs(nj).iSubSigIdx));
            mxx_xmltree('add_node', hSubSignal, astSubSigs(nj).sType);
        end
        if ~isempty(astSubSigs(nj).sName)
            sName = astSubSigs(nj).sName;
            if (astSubSigs(nj).sName(1) == '.')
                sName = ['<signal1>', astSubSigs(nj).sName];
            end
            mxx_xmltree('set_attribute', hSignal, 'signalName', sName);
        end
    end
end
end

%***********************************************************************************************************************
% Adds a parameter to the C-Code architecure
%
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_ccode_parameter(stEnv, hCInterfaceNode, stParameter)
stInfo = stParameter.stInfo;
% Add C type information
hCType = mxx_xmltree('add_node', hCInterfaceNode, 'InterfaceObj');
mxx_xmltree('set_attribute', hCType, 'kind', 'cal');
mxx_xmltree('set_attribute', hCType,  'var', stInfo.sRootName);
mxx_xmltree('set_attribute', hCType,  'access', stInfo.sAccessPath);
% TODO: Handle arrays
i_add_ccode_meta_type_info(stEnv, hCType, stInfo.astProp(1))
end

%***********************************************************************************************************************
% Adds a parameter to the TargetLink architecure
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv             (struct) Environment
%    - hTlSubsystemNode  (handle) Subsystem handle
%    - stParameter       (struct) Parameter information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_tl_parameter(stEnv, hTlSubsystemNode, stParameter)
stBlockInfo = stParameter.stBlockInfo;
stCal = stParameter.stCal;

% Add TargetLink type information
hTlParameter = mxx_xmltree('add_node', hTlSubsystemNode, 'calibration');

if ~isempty(stBlockInfo.stSfInfo)
    sName = sprintf('%s', stParameter.stBlockInfo.stSfInfo.sSfName);

elseif ~isempty(stCal.sWorkspaceVar)
    sName =  sprintf('%s', stCal.sWorkspaceVar);
elseif ~isempty(stCal.sPoolVarPath)
    % if there is no WorkspaceVar, the Parameter is shown with C-Name
    sName = stParameter.stInfo.sRootName;
    if ~isempty(stCal.sPoolVarPath)
        % replace /Components/ with DotNotation for structs
        sName = regexprep(stCal.sPoolVarPath, '/Components/', '.');

        % get rid of DdPrefix //DD0/Pool/Variables/<VariableGroup1>/...
        % <==> everything before and including the last slash
        casTmpName = regexp(sName, '.*/(.*)', 'tokens', 'once');
        sName = casTmpName{1};
    end
else
    sName = sprintf('%s', i_get_name_from_path(stBlockInfo.sTlPath));
end

mxx_xmltree('set_attribute', hTlParameter, 'name',sName);
mxx_xmltree('set_attribute', hTlParameter, 'path', sprintf('%s', stBlockInfo.sTlPath));


sUsage = 'explicit_param';
if strcmpi(stParameter.stCal.sKind, 'limited')
    sUsage = i_get_limited_cal_usage(stEnv, stParameter.stBlockInfo);
end
if ~isempty(sUsage)
    mxx_xmltree('set_attribute', hTlParameter, 'origin', sUsage);
else
    mxx_xmltree('set_attribute', hTlParameter, 'origin', 'explicit_param');
end

if ~isempty(stParameter.stBlockInfo.sRestriction)
    mxx_xmltree('set_attribute', hTlParameter, 'restricted', 'true');
else
    mxx_xmltree('set_attribute', hTlParameter, 'restricted', 'false');
end

if ~isempty(stParameter.stBlockInfo.stSfInfo)
    mxx_xmltree('set_attribute', hTlParameter, 'stateflowVariable', stParameter.stBlockInfo.stSfInfo.sSfName);
end

if ~isempty(stParameter.stCal.sPoolVarPath)
    mxx_xmltree('set_attribute', hTlParameter, 'ddPath', sprintf('%s', stCal.sPoolVarPath));
end

if ~isempty(stCal.sWorkspaceVar)
    mxx_xmltree('set_attribute', hTlParameter, 'workspace', sprintf('%s', stCal.sWorkspaceVar));
end

[hTlMilType, hTlSilType] = i_add_tl_mil_sil_type_for_parameter(stEnv, hTlParameter, stParameter);

% Add Usage context
for nk=1:length(stParameter.aiBlockIdx)
    stBlockInfoIterate = stParameter.astBlockInfo(stParameter.aiBlockIdx(nk));
    hUsageBlock = mxx_xmltree('add_node', hTlParameter,'usageContext');
    mxx_xmltree('set_attribute', hUsageBlock, 'path',stBlockInfoIterate.sTlPath);
    mxx_xmltree('set_attribute', hUsageBlock, 'targetLinkBlockKind', stBlockInfoIterate.sBlockKind);
    mxx_xmltree('set_attribute', hUsageBlock, 'simulinkBlockType', stBlockInfoIterate.sBlockType);
    mxx_xmltree('set_attribute', hUsageBlock, 'blockAttribute', stBlockInfoIterate.sBlockUsage);
    if ~isempty(stBlockInfoIterate.stSfInfo)
        mxx_xmltree('set_attribute', hUsageBlock, 'stateflowVariable', stBlockInfoIterate.stSfInfo.sSfName);
    end
    if ~isempty(stBlockInfoIterate.sRestriction)
        mxx_xmltree('set_attribute', hUsageBlock, 'restriction', sprintf('%s', stBlockInfoIterate.sRestriction));
    end
end
end

%***********************************************************************************************************************
% Adds a Parameter to the Simulink architecture.
%
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_sl_parameter(stEnv, hTlSubsystemNode, stParameter, stSlParameter)
% TODO to be done
end

%***********************************************************************************************************************
% Adds the mapping for Parameter interfaces
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv             (struct) Environment
%    - hMapSubsystemNode (handle) Subsystem handle
%    - stParameter       (struct) Parameter information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_mapping_parameter(stEnv, hMapSubsystemNode, stParameter)
stBlockInfo = stParameter.stBlockInfo;
stInfo = stParameter.stInfo;
% Add Mapping
stDataTypes.hMapSignals = mxx_xmltree('add_node', hMapSubsystemNode,'InterfaceObjectMapping');
mxx_xmltree('set_attribute', stDataTypes.hMapSignals, 'kind', 'Parameter');

hPathTL = mxx_xmltree('add_node',stDataTypes.hMapSignals, 'Path');
mxx_xmltree('set_attribute',hPathTL, 'refId' , 'id0');
if ~isempty(stParameter.stBlockInfo.stSfInfo)
    sName = stParameter.stBlockInfo.stSfInfo.sSfName;
    mxx_xmltree('set_attribute',hPathTL, 'path' , [stBlockInfo.sTlPath, '/', sName]);
elseif ~isempty(stParameter.stCal.sWorkspaceVar)
    sName =  stParameter.stCal.sWorkspaceVar;
    mxx_xmltree('set_attribute',hPathTL, 'path' , [stBlockInfo.sTlPath, '/', sName]);
else
    mxx_xmltree('set_attribute',hPathTL, 'path' , stBlockInfo.sTlPath);
end

if i_is_opt_sl
    hPathSl = mxx_xmltree('add_node',stDataTypes.hMapSignals, 'Path');
    mxx_xmltree('set_attribute',hPathSl, 'refId' , 'id2');
    mxx_xmltree('set_attribute',hPathSl, 'path' , i_get_name_from_path(stBlockInfo.sTlPath)); %TODO: Replace with SL path
end

hPathC = mxx_xmltree('add_node', stDataTypes.hMapSignals, 'Path');
mxx_xmltree('set_attribute',hPathC, 'refId' , 'id1');
if isempty(stInfo.sAccessPath)
    mxx_xmltree('set_attribute',hPathC, 'path' , stInfo.sRootName);
else
    mxx_xmltree('set_attribute',hPathC, 'path' , [stInfo.sRootName, stInfo.sAccessPath]);
end


hSignalPath = mxx_xmltree('add_node',stDataTypes.hMapSignals, 'SignalMapping');
hPathTL = mxx_xmltree('add_node',hSignalPath, 'Path');
mxx_xmltree('set_attribute',hPathTL, 'refId' , 'id0');
mxx_xmltree('set_attribute',hPathTL, 'path' , '');

if i_is_opt_sl
    hPathSl = mxx_xmltree('add_node',hSignalPath, 'Path');
    mxx_xmltree('set_attribute',hPathSl, 'refId' , 'id2');
    mxx_xmltree('set_attribute',hPathSl, 'path' , '');
end

hPathC = mxx_xmltree('add_node', hSignalPath, 'Path');
mxx_xmltree('set_attribute',hPathC, 'refId' , 'id1');
mxx_xmltree('set_attribute',hPathC, 'path' , '');
end

%***********************************************************************************************************************
% Adds the MIL/SIL type for a Parameter to the TargetLink architecture.
%
%   PARAMETER(S)    DESCRIPTION
%     - stEnv           (struct) Environment
%     - hTlParameter    (handle) Interface handle
%     - stParameter     (struct) Parameter information
%   OUTPUT
%    -
%***********************************************************************************************************************
function [hTlMilType, hTlSilType] = i_add_tl_mil_sil_type_for_parameter(stEnv, hTlParameter, stParameter)

hTlMilType = mxx_xmltree('add_node', hTlParameter, 'miltype');
hTlSilType = mxx_xmltree('add_node', hTlParameter, 'siltype');

hMilDataTypeNode = hTlMilType;
hSilDataTypeNode = hTlSilType;

stCal = stParameter.stCal;
stInfo = stParameter.stInfo;

nWidth1 = 1;
if ~isempty(stInfo.aiWidth)
    nWidth1 = stInfo.aiWidth(1);
end
nWidth2 = 1;
if (length(stInfo.aiWidth) > 1)
    nWidth2 = stInfo.aiWidth(2);
end

if (nWidth1 > 1)
    % MIL
    hMilDataTypeNode = mxx_xmltree('add_node',hMilDataTypeNode, 'nonUniformArray');
    mxx_xmltree('set_attribute', hMilDataTypeNode, 'size', num2str(nWidth1));
    % SIL
    hSilDataTypeNode = mxx_xmltree('add_node',hSilDataTypeNode, 'nonUniformArray');
    mxx_xmltree('set_attribute', hSilDataTypeNode, 'size', num2str(nWidth1));
end

% TODO: Clean up ugly naming and iteration
signalMilNode = hMilDataTypeNode;
signalSilNode = hSilDataTypeNode;
signalMilNodeTmp = signalMilNode;
signalSilNodeTmp = signalSilNode;

for ni=1:nWidth1
    signalMilNode = signalMilNodeTmp;
    signalSilNode = signalSilNodeTmp;

    if (nWidth2 > 1)
        signalMilNode = mxx_xmltree('add_node', signalMilNode, 'signal');
        signalSilNode = mxx_xmltree('add_node', signalSilNode, 'signal');
        mxx_xmltree('set_attribute', signalMilNode, 'index', num2str(ni));
        mxx_xmltree('set_attribute', signalSilNode, 'index', num2str(ni));

        % MIL
        signalMilNode = mxx_xmltree('add_node',signalMilNode, 'nonUniformArray');
        % SIL
        signalSilNode = mxx_xmltree('add_node',signalSilNode, 'nonUniformArray');

        mxx_xmltree('set_attribute', signalMilNode, 'size', num2str(nWidth2));
        mxx_xmltree('set_attribute', signalSilNode, 'size', num2str(nWidth2));
    end


    signalMilNode2 = signalMilNode;
    signalSilNode2 = signalSilNode;
    signalMilNodeTmp2 = signalMilNode2;
    signalSilNodeTmp2 = signalSilNode2;
    for nj=1:nWidth2
        signalMilNode2 = signalMilNodeTmp2;
        signalSilNode2 = signalSilNodeTmp2;
        bSignal = false;
        if (nWidth2 > 1 || nWidth1 > 1)
            signalMilNode2 = mxx_xmltree('add_node', signalMilNode2, 'signal');
            signalSilNode2 = mxx_xmltree('add_node', signalSilNode2, 'signal');
            bSignal = true;
        end
        i_set_attribute_double(signalMilNode2, 'initValue', stInfo.astProp(((nj-1)*nWidth1) + ni).dInitValue);
        i_set_attribute_double(signalSilNode2, 'initValue',stInfo.astProp(((nj-1)*nWidth1) + ni).dInitValue);
        if ~isempty(stInfo.astProp(((nj-1)*nWidth1) + ni).sUnit)
            mxx_xmltree('set_attribute', signalSilNode2, 'unitName',stInfo.astProp(((nj-1)*nWidth1) + ni).sUnit);
        end
        if bSignal
            if (nWidth2 == 1)
                mxx_xmltree('set_attribute', signalMilNode2, 'index', num2str(ni));
                mxx_xmltree('set_attribute', signalSilNode2, 'index', num2str(ni));
            else
                mxx_xmltree('set_attribute', signalMilNode2, 'index', num2str(nj));
                mxx_xmltree('set_attribute', signalSilNode2, 'index', num2str(nj));
            end
        end
        if ~isempty(stCal.sType)
            mxx_xmltree('add_node', signalMilNode2, stCal.sType);
        else
            mxx_xmltree('add_node', signalMilNode2, 'double'); % Default value. It can happen that sType is empty.
        end
        i_add_tl_concrete_sil_type(stEnv, signalSilNode2, stInfo.stVarType.sBase, ...
            stInfo.astProp(((nj-1)*nWidth1) + ni), true);
    end
end
end

%***********************************************************************************************************************
% Adds a Inport/Outport it the C-Code architecture
%
%   PARAMETER(S)    DESCRIPTION
%     - stEnv           (struct) Environment
%     - hCInterfaceNode (handle) Interface handle
%     - sKind           (String) ('IN' |'OUT')
%     - stPort          (struct) Port information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_ccode_port(stEnv, hCInterfaceNode, sKind, stPort)

%% Iterate over the signals
astSignals = stPort.astSignals;
nNumberOfSignals = length(astSignals);
for ni=1:nNumberOfSignals
    if ~isempty(astSignals(ni).stVarInfo)
        hCType = mxx_xmltree('add_node', hCInterfaceNode, 'InterfaceObj');
        mxx_xmltree('set_attribute', hCType, 'kind', sKind);
        % mxx_xmltree('set_attribute', hCType,  'var', astSignals(ni).stVarInfo.sRootName);
        if isfield(astSignals(ni).stVarInfo, 'stInterface')
            if strcmp(astSignals(ni).stVarInfo.stInterface.sKind, 'RETURN_VALUE')
                sName = '';
            else
                sName = astSignals(ni).stVarInfo.stInterface.sOrigRootName;
            end
        else
            sName = astSignals(ni).stVarInfo.sRootName;
        end
        mxx_xmltree('set_attribute', hCType,  'var', sName);
        sAccessPath = astSignals(ni).stVarInfo.sAccessPath;
        mxx_xmltree('set_attribute', hCType,  'access', sAccessPath);
        %% TODO: Handle arrays
        i_add_ccode_meta_type_info(stEnv, hCType, astSignals(ni).stVarInfo.astProp(1));
    end
end
end

%***********************************************************************************************************************
% Adds a Inport/Outport it the TargetLink architecture
%
%   PARAMETER(S)        DESCRIPTION
%     - stEnv            (struct) Environment
%     - hTlSubsystemNode (handle) Subsystem handle
%     - sKind            (String) ('Inport' |'Outport')
%     - stPort           (struct) Port information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_tl_port(stEnv, hTlSubsystemNode, sKind, stPort)
hTlInport = mxx_xmltree('add_node', hTlSubsystemNode, sKind);
mxx_xmltree('set_attribute', hTlInport, 'portNumber', sprintf('%i', stPort.iPortNumber))
mxx_xmltree('set_attribute', hTlInport, 'name', sprintf('%s', i_get_name_from_path(stPort.sModelPortPath)));
mxx_xmltree('set_attribute', hTlInport, 'path', sprintf('%s', stPort.sSlPortPath));
i_add_tl_mil_sil_type_for_port(stEnv, hTlInport, stPort);
end

%***********************************************************************************************************************
% Adds a Inport/Outport it the Simulink architecture
%
%   PARAMETER(S)    DESCRIPTION
%     - stEnv            (struct) Environment
%     - hTlSubsystemNode (handle) Subsystem handle
%     - sKind            (String) ('Inport' |'Outport')
%     - stPort           (struct) Port information
%     - stSlPort         (struct) Simulink port information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_sl_port(stEnv, hSlSubsystemNode, sKind, stPort, stSlPort)
% Add Simulink type information
if i_is_opt_sl
    hSlPort = mxx_xmltree('add_node', hSlSubsystemNode, sKind);
    mxx_xmltree('set_attribute', hSlPort, 'portNumber', sprintf('%i', stSlPort.iNumber))
    mxx_xmltree('set_attribute', hSlPort, 'name', sprintf('%s', i_get_name_from_path(stSlPort.sPath)));
    mxx_xmltree('set_attribute', hSlPort, 'path', sprintf('%s', stSlPort.sPath));
    i_add_sl_mil_type(stEnv, hSlPort, stPort, stSlPort);
end
end

%***********************************************************************************************************************
% Adds the mapping for Inports/Outports
%
%   PARAMETER(S)    DESCRIPTION
%     - stEnv            (struct) Environment
%     - hTlSubsystemNode (handle) Subsystem handle
%     - sKind            (String) ('Input' |'Output')
%     - stPort           (struct) Port information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_mapping_port(~, hMapSubsystemNode, sKind, stPort)
% TODO: Clean up and find shared functionality with other functions.
%       Clean up variable naming and loop interations to be more efficient
%       Extract sub-functions

bIsBus = 0;
% Is complex type
if strcmp(stPort.stCompInfo.sSigKind, 'bus')
    bIsBus = 1;
    %% Iterate over the signals
    nNumberOfSignals = length(stPort.stCompInfo.astSignals);
    astSignals = [];
    if (nNumberOfSignals ~= length(stPort.astSignals))
        for ni=1:nNumberOfSignals
            sName = stPort.stCompInfo.astSignals(ni).sName;
            for nj=1:length(stPort.astSignals)
                if strcmp(stPort.astSignals(nj).sSignalName, sName) || isempty(stPort.astSignals(nj).sSignalName)
                    if length(astSignals) < ni
                        astSignals = [astSignals, stPort.astSignals(nj)];
                    else
                        astSignals(ni).astSubSigs = [astSignals(ni).astSubSigs ,stPort.astSignals(nj).astSubSigs];
                    end
                end
            end
        end
        nNumberOfSignals = length(astSignals);
    else
        nNumberOfSignals = length(stPort.astSignals);
        astSignals = stPort.astSignals;
    end
else
    nNumberOfSignals = length(stPort.astSignals);
    astSignals = stPort.astSignals;
end

%% Iterate over the sub signals
for ni=1:nNumberOfSignals
    astSubSigs = astSignals(ni).astSubSigs;
    for nj=1:length(astSubSigs)
        if (nj > 1) || isempty(astSignals(ni).stVarInfo)
            continue;
        end
        % Add Mapping node
        hMapSignals = mxx_xmltree('add_node', hMapSubsystemNode,'InterfaceObjectMapping');
        mxx_xmltree('set_attribute', hMapSignals, 'kind', sKind);

        %% TL IO Mapping
        hPathTL = mxx_xmltree('add_node',hMapSignals, 'Path');
        mxx_xmltree('set_attribute',hPathTL, 'refId' , 'id0');
        mxx_xmltree('set_attribute',hPathTL, 'path' , i_get_name_from_path(stPort.sModelPortPath));

        %% SL IO Mapping
        if i_is_opt_sl
            hPathSl = mxx_xmltree('add_node',hMapSignals, 'Path');
            mxx_xmltree('set_attribute',hPathSl, 'refId' , 'id2');
            mxx_xmltree('set_attribute',hPathSl, 'path' , i_get_name_from_path(stPort.sSlPortPath));
        end

        %% C IO Mapping
        hPathC = mxx_xmltree('add_node', hMapSignals, 'Path');
        mxx_xmltree('set_attribute',hPathC, 'refId' , 'id1');
        sAccessPath =  [astSignals(ni).stVarInfo.sRootName, astSignals(ni).stVarInfo.sAccessPath];
        mxx_xmltree('set_attribute',hPathC, 'path' , sAccessPath);

        %% TL Signal Mapping
        hSignalPath = mxx_xmltree('add_node',hMapSignals, 'SignalMapping');
        hPathTL = mxx_xmltree('add_node',hSignalPath, 'Path');
        mxx_xmltree('set_attribute',hPathTL, 'refId' , 'id0');

        sTLAccessPath = '';
        if ~isempty(astSubSigs(nj).sName) && nNumberOfSignals > 1
            sTLAccessPath = astSubSigs(nj).sName;
            if (astSubSigs(nj).sName(1) == '.')
                sTLAccessPath = ['<signal1>', astSubSigs(nj).sName];
            end
            if (bIsBus)
                sTLAccessPath = ['.', sTLAccessPath];
            end
        end
        mxx_xmltree('set_attribute',hPathTL, 'path' , sTLAccessPath);

        %% SL Signal Mapping
        if i_is_opt_sl
            hPathSl = mxx_xmltree('add_node',hSignalPath, 'Path');
            mxx_xmltree('set_attribute',hPathSl, 'refId' , 'id2');
            mxx_xmltree('set_attribute',hPathSl, 'path' , sTLAccessPath); % TODO: Fill Simulink information
        end

        %% C Signal Mapping
        hPathC = mxx_xmltree('add_node', hSignalPath, 'Path');
        mxx_xmltree('set_attribute',hPathC, 'refId' , 'id1');
        mxx_xmltree('set_attribute',hPathC, 'path' , ''); % TODO: Handle acess paths correctly
    end
end
end

%***********************************************************************************************************************
% Adds the MIL/SIL type for a port to the TargetLink architecture
%
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function [hTlMilType] = i_add_tl_mil_sil_type_for_port(stEnv, hTlInport, stPort)
% TODO: Clean up and find shared functionality with other functions.
%       Clean up variable naming and loop interations to be more efficient
%       Extract sub-functions
hTlMilType = mxx_xmltree('add_node', hTlInport, 'miltype');
hTlSilType = mxx_xmltree('add_node', hTlInport, 'siltype');

hDataTypeNode = hTlMilType;
hSilDataTypeNode = hTlSilType;

% Is complex type
if strcmp(stPort.stCompInfo.sSigKind, 'bus')
    hDataTypeNode = mxx_xmltree('add_node', hDataTypeNode, 'bus');
    hSilDataTypeNode = mxx_xmltree('add_node', hSilDataTypeNode, 'bus');
    %% Iterate over the signals
    nNumberOfSignals = length(stPort.stCompInfo.astSignals);
    astSignals = [];
    if (nNumberOfSignals ~= length(stPort.astSignals))
        for ni=1:nNumberOfSignals
            sName = stPort.stCompInfo.astSignals(ni).sName;
            for nj=1:length(stPort.astSignals)
                if strcmp(stPort.astSignals(nj).sSignalName, sName)
                    if length(astSignals) < ni
                        astSignals = [astSignals, stPort.astSignals(nj)];
                    else
                        astSignals(ni).astSubSigs = [astSignals(ni).astSubSigs ,stPort.astSignals(nj).astSubSigs];
                    end
                end
            end
        end
        nNumberOfSignals = length(astSignals);
    else
        nNumberOfSignals = length(stPort.astSignals);
        astSignals = stPort.astSignals;
    end

else
    nNumberOfSignals = length(stPort.astSignals);
    astSignals = stPort.astSignals;
end


hDataTypeNodeTmp = hDataTypeNode;
hSilDataTypeNodeTmp = hSilDataTypeNode;
for ni=1:nNumberOfSignals
    hDataTypeNode = hDataTypeNodeTmp;
    hSilDataTypeNode = hSilDataTypeNodeTmp;
    if (nNumberOfSignals > 1)
        hSignal =  mxx_xmltree('add_node', hDataTypeNode, 'signal');
        hSilSignal =  mxx_xmltree('add_node', hSilDataTypeNode, 'signal');
    else
        hSignal = hDataTypeNode;
        hSilSignal = hSilDataTypeNode;
    end

    hSignal2 = hSignal;
    hSilSignal2 = hSilSignal;

    astSubSigs = astSignals(ni).astSubSigs;

    % non-uniform array
    if length(astSubSigs) > 1
        hArrayNode = mxx_xmltree('add_node', hSignal, 'nonUniformArray');
        mxx_xmltree('set_attribute', hArrayNode, 'size', num2str(astSignals(ni).iWidth));
        hSignal2 = hArrayNode;
        hSilArrayNode = mxx_xmltree('add_node', hSilSignal, 'nonUniformArray');
        mxx_xmltree('set_attribute', hSilArrayNode, 'size', num2str(astSignals(ni).iWidth));
        hSilSignal2 = hSilArrayNode;
    end
    %% Iterate over the sub signals
    for nj=1:length(astSubSigs)
        % single element
        if length(astSubSigs) == 1
            mxx_xmltree('add_node', hSignal2, astSubSigs(nj).sType);
            if  ~isempty(astSignals(ni).stVarInfo) &&  nj <= length(astSignals(ni).stVarInfo.astProp)
                if ~isempty(astSignals(ni).stVarInfo.stVarType.sBaseDest)
                    sTypeName = astSignals(ni).stVarInfo.stVarType.sBaseDest;
                else
                    sTypeName = astSignals(ni).stVarInfo.stVarType.sBase;
                end
                i_add_tl_concrete_sil_type(stEnv,hSilSignal2, sTypeName, ...
                    astSignals(ni).stVarInfo.astProp(nj), any(strcmp(astSubSigs(nj).sType, {'double', 'single'})));
                if ~isempty(astSignals(ni).stVarInfo.astProp.dInitValue)
                    i_set_attribute_double(hSignal2, 'initValue', astSignals(ni).stVarInfo.astProp.dInitValue);
                    i_set_attribute_double(hSilSignal2, 'initValue',astSignals(ni).stVarInfo.astProp.dInitValue);
                end
                if ~isempty(astSignals(ni).stVarInfo.astProp.sUnit)
                    mxx_xmltree('set_attribute', hSilSignal2, 'unitName',astSignals(ni).stVarInfo.astProp.sUnit);
                end
            else
                mxx_xmltree('set_attribute', hSilSignal2, 'missingTypeSinceNoCVar', 'true');
                mxx_xmltree('add_node', hSilSignal2, 'unsupportedTypeInformation');
            end

        else
            % Mil Type
            hSubSignal = mxx_xmltree('add_node', hSignal2, 'signal');
            mxx_xmltree('add_node', hSubSignal, astSubSigs(nj).sType);

            %Sil Type
            hSilSubSignal = mxx_xmltree('add_node', hSilSignal2, 'signal');
            if ~isempty(astSignals(ni).stVarInfo) && nj <= length(astSignals(ni).stVarInfo.astProp)
                if ~isempty(astSignals(ni).stVarInfo.stVarType.sBaseDest)
                    sTypeName = astSignals(ni).stVarInfo.stVarType.sBaseDest;
                else
                    sTypeName = astSignals(ni).stVarInfo.stVarType.sBase;
                end
                i_add_tl_concrete_sil_type(stEnv, hSilSubSignal, sTypeName, ...
                    astSignals(ni).stVarInfo.astProp(nj), any(strcmp(astSubSigs(nj).sType, {'double', 'single'})));
                if ~isempty( astSignals(ni).stVarInfo.astProp(nj).dInitValue)
                    i_set_attribute_double(hSubSignal, 'initValue', astSignals(ni).stVarInfo.astProp(nj).dInitValue);
                    i_set_attribute_double(hSilSubSignal, 'initValue',astSignals(ni).stVarInfo.astProp(nj).dInitValue);
                end
                if ~isempty(astSignals(ni).stVarInfo.astProp(nj).sUnit)
                    mxx_xmltree('set_attribute', hSilSubSignal, 'unitName',astSignals(ni).stVarInfo.astProp(nj).sUnit);
                end
            else
                mxx_xmltree('set_attribute', hSilSubSignal, 'missingTypeSinceNoCVar', 'true');
                mxx_xmltree('add_node', hSilSubSignal, 'unsupportedTypeInformation');
            end
            mxx_xmltree('set_attribute', hSubSignal, 'index', num2str(astSubSigs(nj).iSubSigIdx));
            mxx_xmltree('set_attribute', hSilSubSignal, 'index', num2str(astSubSigs(nj).iSubSigIdx));
        end

        if ~isempty(astSubSigs(nj).sName)
            sName = astSubSigs(nj).sName;
            if (astSubSigs(nj).sName(1) == '.')
                sName = ['<signal1>', astSubSigs(nj).sName];
            end
            mxx_xmltree('set_attribute', hSignal, 'signalName', sName);
            mxx_xmltree('set_attribute', hSilSignal, 'signalName', sName);
        end
    end
end
end

%***********************************************************************************************************************
% Adds the concrete SIL type to the TargetLink architecture
%
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function [hConcreteDataType] = i_add_tl_concrete_sil_type(stEnv, hTlSilType, sBaseType, stProp, bKeepFixedPoint)
% TODO: Handle decision correctly, if lsb and offset must be added or not
if (stProp.dLsb ~= 1.0 || stProp.dOffset ~= 0.0 || bKeepFixedPoint) && ...
        (~any(strcmp(sBaseType, {'Bitfield', 'Float64', 'Float32'})))
    hConcreteDataType = mxx_xmltree('add_node', hTlSilType, 'fixedPoint');
    mxx_xmltree('set_attribute', hConcreteDataType, 'baseType', sprintf('%s', sBaseType));
    i_set_attribute_double(hConcreteDataType, 'lsb', stProp.dLsb);
    i_set_attribute_double(hConcreteDataType, 'offset', stProp.dOffset);
    i_set_attribute_double(hConcreteDataType, 'min', stProp.dMin);
    i_set_attribute_double(hConcreteDataType, 'max', stProp.dMax);
else
    hConcreteDataType =mxx_xmltree('add_node', hTlSilType, sBaseType);
    % Bitfield handling
    if strcmp(sBaseType, 'Bitfield')
        mxx_xmltree('set_attribute', hConcreteDataType, 'min', '0');
        mxx_xmltree('set_attribute', hConcreteDataType, 'max', '1');
    end
end
end

%***********************************************************************************************************************
% Adds the Mil type to the Simulink architecture
% TODO: Must be implemented correctly.
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_sl_mil_type(~, hSlPort, stPort, stSlPort)
% TODO: Must be implemented correctly.
% TODO: Clean up and find shared functionality with other functions.
%       Clean up variable naming and loop interations to be more efficient
%       Extract sub-functions
hTlMilType = hSlPort;

hDataTypeNode = hTlMilType;

% Is complex type
if strcmp(stSlPort.sSigKind, 'bus')
    hDataTypeNode = mxx_xmltree('add_node', hDataTypeNode, 'bus');
end

%% Iterate over the signals
astSignals = stPort.astSignals;
nNumberOfSignals = length(astSignals);
hDataTypeNodeTmp = hDataTypeNode;
for ni=1:nNumberOfSignals
    hDataTypeNode = hDataTypeNodeTmp;
    if (nNumberOfSignals > 1)
        hSignal =  mxx_xmltree('add_node', hDataTypeNode, 'signal');
    else
        hSignal = hDataTypeNode;
    end

    hSignal2 = hSignal;
    % non-uniform array
    astSubSigs = astSignals(ni).astSubSigs;
    if length(astSubSigs) > 1
        hArrayNode = mxx_xmltree('add_node', hSignal, 'nonUniformArray');
        mxx_xmltree('set_attribute', hArrayNode, 'size', num2str(astSignals(ni).iWidth));
        hSignal2 = hArrayNode;
    end
    %% Iterate over the sub signals
    for nj=1:length(astSubSigs)
        % single element
        if length(astSubSigs) == 1
            mxx_xmltree('add_node', hSignal2, astSubSigs(nj).sType);
        else
            % Mil Type
            hSubSignal = mxx_xmltree('add_node', hSignal2, 'signal');
            mxx_xmltree('set_attribute', hSubSignal, 'index', num2str(astSubSigs(nj).iSubSigIdx));
            mxx_xmltree('add_node', hSubSignal, astSubSigs(nj).sType);
        end
        if ~isempty(astSubSigs(nj).sName)
            sName = astSubSigs(nj).sName;
            if (astSubSigs(nj).sName(1) == '.')
                sName = ['<signal1>', astSubSigs(nj).sName];
            end
            mxx_xmltree('set_attribute', hSignal, 'signalName', sName);
        end
    end
end
end

%***********************************************************************************************************************
% Adds meta information to a C-Code interface (e.g LSB, Offset, Min, Max)
%
%   PARAMETER(S)    DESCRIPTION
%    - xEnv          (object) Environment object
%    - hCInterface   (handle) XML-node
%    - stProp        (struct) Holding the meta-information
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_add_ccode_meta_type_info(~, hCInterface, stProp)
i_set_attribute_double(hCInterface, 'min', stProp.dMin);
i_set_attribute_double(hCInterface, 'max', stProp.dMax);
% TODO: Correct to exclude the scaling?
if stProp.dLsb ~= 1.0 || stProp.dOffset ~= 0.0


    %%%% HACK !!!!!!!!!!!!!!!!! %%%%%
    %%%%% TODO: Must be solved on a higher level. %%%%%%
    sGlobalScalingId = ['ID',num2str(1000000 + atgcv_m01_counter('get', 'nGlobalIdForC'))];
    %%%% HACK !!!!!!!!!!!!!!!!! %%%%%

    mxx_xmltree('set_attribute', hCInterface,  'scaling' , sGlobalScalingId);
    hScalings = mxx_xmltree('get_nodes', hCInterface, '//Scalings'); % TODO: Maybe the handle can be stored to reduce XML-access
    hScaling = mxx_xmltree('add_node', hScalings, 'Scaling');

    % Add Scaling information
    mxx_xmltree('set_attribute', hScaling,  'id' , sGlobalScalingId);
    i_set_attribute_double(hScaling, 'lsb', stProp.dLsb);
    i_set_attribute_double(hScaling, 'offset', stProp.dOffset);
end
end

%***********************************************************************************************************************
% Sets a double as String to an XML-Node
%
%   PARAMETER(S)    DESCRIPTION
%    - hNode         (handle)  Handle where the attribute should be added.
%    - sAttName      (String)  Name of the attribute
%    - dValue        (double)  Value to be set
%   OUTPUT
%    -
%*********************************************************************************************************************
function i_set_attribute_double(hNode, sAttName, dValue)
mxx_xmltree('set_attribute', hNode, sAttName, sprintf('%.16e', dValue));
end

%***********************************************************************************************************************
% Function representing a global state for pure SL
%
%   PARAMETER(S)    DESCRIPTION
%    - bIsSL         (logical)  True, globale state is set to true. Otherwise to false.
%   OUTPUT
%    - bIsSL         (logical)  True, pure SL model is available, False, not.
%***********************************************************************************************************************
function bIsSL = i_is_sl(bIsSL)
persistent p_bIsSL;

if (nargin < 1)
    bIsSL = p_bIsSL;
else
    p_bIsSL =bIsSL;
end
end

%***********************************************************************************************************************
% Function representing a global state for optional SL
%
%   PARAMETER(S)    DESCRIPTION
%    - bIsSL         (logical)  True, globale state is set to true. Otherwise to false.
%   OUTPUT
%    - bIsOptionalSL (logical)  True, optional SL model is available, False, not.
%***********************************************************************************************************************
% function respresenting a global state
function bIsOptionalSL = i_is_opt_sl(bIsSL)
persistent p_bIsOptionalSL;
if (nargin < 1)
    bIsOptionalSL = p_bIsOptionalSL;
else
    p_bIsOptionalSL =bIsSL;
end
end

%***********************************************************************************************************************
% Reset Counters
%
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_reset_internal_counters()
i_clear_internal_counters();
atgcv_m01_counter('add', 'nGlobalIdForC');
end

%***********************************************************************************************************************
% Clear Counters
%
%   PARAMETER(S)    DESCRIPTION
%    -
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_clear_internal_counters()
clear atgcv_m01_counter;
end

%***********************************************************************************************************************
% Adds tool information to a given XML-Node
%
%   PARAMETER(S)    DESCRIPTION
%    - hArchRoot     (handle)    XML-handle where the information is added to
%    - sToolName     (String)    'ML' Add Matlab information
%                                'SL' Add Simulink information
%                                'TL' Add TargetLink information
%   OUTPUT
%    -
%***********************************************************************************************************************                       -
function i_add_tool_info(hArchRoot, sToolName)

sRelase = '';
sVersion = '';
sPatch = '';

if strcmp('Matlab', sToolName)
    stVersion = ver('Matlab');
    sRelase = stVersion.Release;
    [sVersion, sPatch] = ep_core_version_get('ML');
end

if strcmp('Simulink', sToolName)
    stVersion = ver('Simulink');
    sRelase = stVersion.Release;
    [sVersion, sPatch] = ep_core_version_get('SL');
end

if strcmp('TargetLink', sToolName)
    stVersion = ver('TL');
    sRelase = stVersion.Release;
    [sVersion, sPatch] = ep_core_version_get('TL');
end

hToolInfo = mxx_xmltree('add_node', hArchRoot, 'toolInfo');
mxx_xmltree('set_attribute', hToolInfo, 'name', sToolName);
mxx_xmltree('set_attribute', hToolInfo, 'release', sRelase);
mxx_xmltree('set_attribute', hToolInfo, 'version', sVersion);
mxx_xmltree('set_attribute', hToolInfo, 'patchLevel', sPatch);
end

%***********************************************************************************************************************
% Extracts naming from path
%
%   PARAMETER(S)    DESCRIPTION
%    - sPath         (String) Path used to extract the name
%   OUTPUT
%    - sName         (String) The extracted name
%***********************************************************************************************************************
function sName = i_get_name_from_path(sPath)
% Slashes in names are escaped by "//".
sName = regexprep(sPath, '(.)*[^/]/([^/])', '$2');
% Replacing escaped slashes in output.
sName = regexprep(sName, '//', '/');
end

%***********************************************************************************************************************
% Get limited cal usage
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv           (struct) Environment
%    - stBlockInfo     (struct) BlockInfo
%   OUTPUT
%    -
%***********************************************************************************************************************
function sUsage = i_get_limited_cal_usage(stEnv, stBlockInfo)
sMaskType  = stBlockInfo.sBlockKind;
if isempty(sMaskType)
    if atgcv_sl_block_isa(sBlockPath, 'Stateflow')
        sMaskType = 'stateflow';
    else
        sMaskType = '<empty>';
    end
end
switch lower(sMaskType)
    case 'tl_gain'
        sUsage = 'gain';

    case 'tl_constant'
        sUsage = 'const';

    case 'tl_saturate'
        switch lower(stBlockInfo.sBlockUsage)
            case 'upperlimit'
                sUsage = 'sat_upper';

            case 'lowerlimit'
                sUsage = 'sat_lower';

            otherwise
                i_throw_wrong_param_val(stEnv, ...
                    stBlockInfo.sTlPath, stBlockInfo.sBlockUsage);
        end

    case 'tl_switch'
        sUsage = 'switch_threshold';

    case 'tl_relay'
        switch lower(stBlockInfo.sBlockUsage)
            case 'offoutput'
                sUsage = 'relay_out_off';

            case 'onoutput'
                sUsage = 'relay_out_on';

            case 'offswitch'
                sUsage = 'relay_switch_off';

            case 'onswitch'
                sUsage = 'relay_switch_on';

            otherwise
                i_throw_wrong_param_val(stEnv, ...
                    stBlockInfo.sTlPath, stBlockInfo.sBlockUsage);
        end
    case 'stateflow'
        sUsage = 'sf_const';

    otherwise
        i_throw_wrong_param_val(stEnv, ...
            stBlockInfo.sTlPath, sMaskType);
end
end

%***********************************************************************************************************************
% Throw exception for wrong param val usage
%
%   PARAMETER(S)    DESCRIPTION
%    - stEnv           (struct) Environmen
%    - sBlockPath      (string) block path
%    - sBlockUsage     (string) block usage
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_throw_wrong_param_val(stEnv, sBlockPath, sBlockUsage)
stErr = osc_messenger_add(stEnv, 'ATGCV:STD:WRONG_PARAM_VAL', ...
    'param_name',  sBlockPath, ...
    'wrong_value', sBlockUsage);
osc_throw(stErr);
end


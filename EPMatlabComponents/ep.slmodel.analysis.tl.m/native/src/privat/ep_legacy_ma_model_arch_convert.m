function ep_legacy_ma_model_arch_convert(xEnv, sMaFile, sArchFile, stArchInfo, bUseSimulinkInfo, oTypeInfoMap)
% Export the SL or TL architecture XML.
%
% function ep_legacy_ma_model_arch_convert(xEnv, sMaFile, sArchFile, stArchInfo, bUseSimulinkInfo)
%
%   INPUT               DESCRIPTION
%     xEnv                (object)  EPEnvironment object
%     sMaFile             (string)  full path to the ModelAnalysis.xml
%     sArchFile           (string)  full path to the output XML file, where the result shall be stored
%     stArchInfo          (struct)  additional info for the architecture
%       .astTlModules     (string)    TL: additional info for the TL model components
%          .xxx           (...)           ...
%       .sTlInitScript    (string)    TL: full path to the TL init script (might be empty)
%       .sAddModelInfo    (string)    SL: full path to the additional info XML for the SL model
%          .xxx           (...)           ...
%       .astSlModules     (string)    SL: additional info for the SL model components
%       .sSlInitScript    (string)    SL: full path to the SL init script (might be empty)
%     bUseSimulinkInfo    (boolean) optional flag if the output shall be the SL or TL architecture
%                                   (default = false)
%
%   OUTPUT              DESCRIPTION
%       -                      -
%

%% inputs
if (nargin < 5)
    bUseSimulinkInfo = false;
end
if (nargin < 6)
    oTypeInfoMap = containers.Map;
end
i_typeInfo('init', oTypeInfoMap);

%% main
if bUseSimulinkInfo
    [hOutRoot, ahModels, hModelRoot] = i_createRootSL(stArchInfo);
    sPathAttrib = 'slPath';
    sBlockPathAttrib = 'slBlockPath';
else
    [hOutRoot, ahModels, hModelRoot] = i_createRootTL(stArchInfo);
    sPathAttrib = 'tlPath';
    sBlockPathAttrib = 'tlBlockPath';
end

hMaDoc = mxx_xmltree('load', sMaFile);
ahSubsystemNodes = mxx_xmltree('get_nodes', hMaDoc, './ma:Subsystem');
i_silTypeInfo('init', hMaDoc);

for ni = 1:length(ahSubsystemNodes)
    hSubSource = ahSubsystemNodes(ni);
    
    hSubTarget = mxx_xmltree('add_node', hModelRoot, 'subsystem');
    i_copyAttribute(hSubSource, 'id', hSubTarget, 'subsysID');
    
    sPath = mxx_xmltree('get_attribute', hSubSource, sPathAttrib);
    mxx_xmltree('set_attribute', hSubTarget, 'physicalPath', sPath);
    mxx_xmltree('set_attribute', hSubTarget, 'path', i_delete_model_name_from_path(sPath));
    i_copyAttribute(hSubSource, 'sampleTime', hSubTarget, 'sampleTime');
    i_copyPathNameAttribute(hSubSource, sPathAttrib, hSubTarget, 'name');
    
    % Set the 'scopeKind' attribute (in this case only if milSupport and isDummy are set, the subsystem is virtual.
    bIsVirtual = false;
    if bUseSimulinkInfo
        sIsDummy = mxx_xmltree('get_attribute', hSubSource, 'isDummy');
        if (~isempty(sIsDummy) && strcmp(sIsDummy, 'yes'))
            mxx_xmltree('set_attribute', hSubTarget, 'scopeKind', 'DUMMY');
            i_addDummyNode(hSubSource, hSubTarget, hModelRoot);
        else
            mxx_xmltree('set_attribute', hSubTarget, 'scopeKind', 'SUT');
        end
    else
        sIsDummy = mxx_xmltree('get_attribute', hSubSource, 'isDummy');
        sMilSupport = mxx_xmltree('get_attribute', hSubSource, 'milSupport');
        if (~isempty(sIsDummy) && ~isempty(sMilSupport) && strcmp(sIsDummy, 'yes'))
            if strcmp(sMilSupport, 'yes')
                mxx_xmltree('set_attribute', hSubTarget, 'scopeKind', 'VIRTUAL');
                i_addEnvNode(hSubSource, hSubTarget, hModelRoot);
                bIsVirtual = true;
            else
                mxx_xmltree('set_attribute', hSubTarget, 'scopeKind', 'DUMMY');
                i_addDummyNode(hSubSource, hSubTarget, hModelRoot);
            end
        else
            mxx_xmltree('set_attribute', hSubTarget, 'scopeKind', 'SUT');
        end
    end
    
    sSubsystemKind = mxx_xmltree('get_attribute', hSubSource, 'kind');
    switch sSubsystemKind
        case 'SUBSYSTEM'
            mxx_xmltree('set_attribute', hSubTarget, 'kind', 'subsystem');
        case 'STATEFLOW'
            mxx_xmltree('set_attribute', hSubTarget, 'kind', 'stateflow');
        otherwise
            warning('MA_CONVERT:UNSUPPORTED_KIND', 'Unsupported subsystem kind %s', sSubsystemKind);
    end
    
    % Create model reference information
    i_addModelReferenceInformation(hSubSource, hSubTarget, ahModels, bUseSimulinkInfo)
    
    % Create interface elements for this node.
    
    % We only need the Input(Port, Calibration) and Output(Port, Display) nodes, but can safely ignore the Parameter() nodes
    % below Interface since they only describe C-Function (dummy) parameters.
    ahIfaceNodes = mxx_xmltree('get_nodes', hSubSource, './ma:Interface/ma:Input|./ma:Interface/ma:Output');
    for nj = 1:length(ahIfaceNodes)
        hIfaceNode = ahIfaceNodes(nj);
        
        % Note: Below each ma:Input or ma:Output, there is exactly 1 Port or 1 Calibration or 1 Display
        
        % --- Port --------
        ahPorts = mxx_xmltree('get_nodes', hIfaceNode, './ma:Port');
        if (length(ahPorts) >= 1)
            hPort = ahPorts(1);
            
            if strcmp(mxx_xmltree('get_name', hIfaceNode), 'Input')
                sPortType = 'inport';
            else
                sPortType = 'outport';
            end
            hPortTarget = mxx_xmltree('add_node', hSubTarget, sPortType);
            
            i_copyAttribute(hPort, 'portNumber', hPortTarget, 'portNumber');
            i_copyPathNameAttribute(hPort, sPathAttrib, hPortTarget, 'name');
            
            sPath = mxx_xmltree('get_attribute', hPort, sPathAttrib);
            mxx_xmltree('set_attribute', hPortTarget, 'physicalPath', sPath);
            mxx_xmltree('set_attribute', hPortTarget, 'path', i_delete_model_name_from_path(sPath));
            
            i_addModelReferenceInformation(hPort,hPortTarget , ahModels, bUseSimulinkInfo);
            i_copyDataTypeInfo(xEnv, hPort, hPortTarget, true, bUseSimulinkInfo, bIsVirtual);
            
            % add a node into the XML file to inidcate that the Port is a DataStoreMemory
            sPortNumber = mxx_xmltree('get_attribute', hPort, 'portNumber');
            if strcmp(sPortNumber, '0')
                hDSM = mxx_xmltree('add_node', hPortTarget, 'dataStoreMemory');
                sSignalName = mxx_xmltree('get_attribute', hPort, 'signal');
                mxx_xmltree('set_attribute', hDSM, 'signalName', sSignalName);
                sMemBlock = mxx_xmltree('get_attribute', hPort, 'memoryBlock');
                if ~isempty(sMemBlock)
                    mxx_xmltree('set_attribute', hDSM, 'physicalPath', sMemBlock);
                end
            end
            continue; % continue with the next interface
        end
        
        % --- Calibration --------
        ahCalibrationParam = mxx_xmltree('get_nodes', hIfaceNode, './ma:Calibration');
        if (length(ahCalibrationParam) >= 1)
            hCalibParam = ahCalibrationParam(1);
            
            if bUseSimulinkInfo
                hCalibTarget = mxx_xmltree('add_node', hSubTarget, 'parameter');
            else
                hCalibTarget = mxx_xmltree('add_node', hSubTarget, 'calibration');
            end
            
            % Potentially empty names for the setting limited blockset
            
            if ~isempty(mxx_xmltree('get_attribute', hCalibParam, 'sfVariable'))
                i_copyAttribute(hCalibParam, 'sfVariable', hCalibTarget, 'name');
            elseif ~isempty(mxx_xmltree('get_attribute', hCalibParam, 'name'))
                i_copyAttribute(hCalibParam, 'name', hCalibTarget, 'name');
            else
                sNamePrefix = i_extractNameFromPath(mxx_xmltree('get_attribute', hCalibParam, sBlockPathAttrib));
                sNameSuffix = mxx_xmltree('get_attribute', hCalibParam, 'usage');
                mxx_xmltree('set_attribute', hCalibTarget, 'name', [sNamePrefix, '[', sNameSuffix, ']']);
            end
            i_copyAttribute(hCalibParam, sBlockPathAttrib, hCalibTarget, 'path');
            
            sPath = mxx_xmltree('get_attribute', hCalibParam, sBlockPathAttrib);
            mxx_xmltree('set_attribute', hCalibTarget, 'physicalPath', sPath);
            mxx_xmltree('set_attribute', hCalibTarget, 'path', i_delete_model_name_from_path(sPath));
            
            i_addModelReferenceInformation(hCalibParam, hCalibTarget, ahModels, bUseSimulinkInfo);
            
            i_copyDataTypeInfo(xEnv, hCalibParam, hCalibTarget, false, bUseSimulinkInfo);
            i_addCalibUsage(hCalibParam, hCalibTarget, bUseSimulinkInfo, ahModels);
            continue; % continue with the next interface
        end
        
        % --- Display --------
        % Note: Displays might be missing for SL-model
        %       --> slBlockPath is missing then --> select only the Displays with existing path
        ahDisplay = mxx_xmltree('get_nodes', hIfaceNode, sprintf('./ma:Display[@%s]', sBlockPathAttrib));
        if (length(ahDisplay) >= 1)
            hDisp = ahDisplay(1);
            
            hDispTarget = mxx_xmltree('add_node', hSubTarget, 'display');
            
            sPath = mxx_xmltree('get_attribute', hDisp, sBlockPathAttrib);
            mxx_xmltree('set_attribute', hDispTarget, 'physicalPath', sPath);
            mxx_xmltree('set_attribute', hDispTarget, 'path', i_delete_model_name_from_path(sPath));
            
            if ~isempty(mxx_xmltree('get_attribute', hDisp, 'sfVariable'))
                i_copyAttribute(hDisp, 'sfVariable', hDispTarget, 'name');
                i_copyAttribute(hDisp, 'sfVariable', hDispTarget, 'stateflowVariable');
            else
                i_copyPathNameAttribute(hDisp, sBlockPathAttrib, hDispTarget, 'name')
            end
            i_copyAttribute(hDisp, 'portNumber', hDispTarget, 'portNumber');
            i_copyDataTypeInfo(xEnv, hDisp, hDispTarget, false, bUseSimulinkInfo);
            i_addModelReferenceInformation(hDisp, hDispTarget, ahModels, bUseSimulinkInfo);
        end
    end
    
    % Create subsystem references for children of this node.
    ahChildrenNodes = mxx_xmltree('get_nodes', hSubSource, './ma:Children/ma:SubsystemRef');
    for nj = 1:length(ahChildrenNodes)
        hChildRef = mxx_xmltree('add_node', hSubTarget, 'subsystem');
        i_copyAttribute(ahChildrenNodes(nj), 'refID', hChildRef, 'refSubsysID');
    end
end

ahRootSubsystems = mxx_xmltree('get_nodes', hMaDoc, './ma:Subsystem[count(ma:Parents)=0]');
for ni = 1:length(ahRootSubsystems)
    hRootNode = mxx_xmltree('add_node', hModelRoot, 'rootSystem');
    sRootSubsysId = mxx_xmltree('get_attribute', ahRootSubsystems(ni), 'id');
    mxx_xmltree('set_attribute', hRootNode, 'refSubsysID', sRootSubsysId);
end

% Mark the only model element as root -- TODO: generalize to multiple models in one file.
hTlRootRef = mxx_xmltree('add_node', hOutRoot, 'root');
mxx_xmltree('set_attribute', hTlRootRef, 'refModelID', 'model001');

% Save TargetLinkArchitecture XML file.
mxx_xmltree('save', hOutRoot, sArchFile);

% Clean up mxx_xmltree.
mxx_xmltree('clear', hOutRoot);
mxx_xmltree('clear', hMaDoc);
end


%%
function [hOutRoot, ahModels, hModelRoot] = i_createRootTL(stArchInfo)
hOutRoot = mxx_xmltree('create', 'tl:TargetLinkArchitecture');
mxx_xmltree('set_attribute', hOutRoot, 'xmlns:tl', 'http://btc-es.de/ep/targetlink/2014/12/09');

sInitScript = [];
if (isfield(stArchInfo, 'sTlInitScript') && ~isempty(stArchInfo.sTlInitScript))
    mxx_xmltree('set_attribute', hOutRoot, 'initScript', stArchInfo.sTlInitScript);
    sInitScript = stArchInfo.sTlInitScript;
end
i_setMainToolsInfo(hOutRoot, false);

% An empty model node is generated, if no meta data is available.
if ~isfield(stArchInfo, 'astTlModules') || isempty(stArchInfo.astTlModules)
    hModelRoot = mxx_xmltree('add_node', hOutRoot, 'model');
    mxx_xmltree('set_attribute', hModelRoot, 'modelID', 'model001');
    ahModels = hModelRoot;
else
    % It is assumed that astTlModules holds all available models.
    % Needed to resolve the model references.
    nModels = length(stArchInfo.astTlModules);
    ahModels = repmat(hOutRoot, 1, nModels);
    for nk = 1:nModels
        stModule = stArchInfo.astTlModules(nk);
        sCreated = i_convertDate(stModule.sCreated);
        sModified = i_convertDate(stModule.sModified);
        
        hModelNode = mxx_xmltree('add_node', hOutRoot, 'model');
        ahModels(nk) = hModelNode;
        
        mxx_xmltree('set_attribute', hModelNode, 'modelID', ['model00', num2str(nk)]);
        mxx_xmltree('set_attribute', hModelNode, 'modelKind', stModule.sKind);
        mxx_xmltree('set_attribute', hModelNode, 'modelVersion', stModule.sVersion);
        mxx_xmltree('set_attribute', hModelNode, 'modelPath', stModule.sFile);
        mxx_xmltree('set_attribute', hModelNode, 'creationDate', sCreated);
        mxx_xmltree('set_attribute', hModelNode, 'modificationDate', sModified);
        if ~isempty(sInitScript)
            mxx_xmltree('set_attribute', hModelNode, 'initScript', sInitScript);
        end
        
        % Add meta info to architecture. It is asssumed that the kind="model" occurs only once.
        % Hence it must be the top level model.
        if strcmp(stModule.sKind, 'model')
            hModelRoot = hModelNode;
            mxx_xmltree('set_attribute', hOutRoot, 'modelVersion', stModule.sVersion);
            mxx_xmltree('set_attribute', hOutRoot, 'modelPath', stModule.sFile);
            mxx_xmltree('set_attribute', hOutRoot, 'modelCreationDate', sCreated);
            mxx_xmltree('set_attribute', hOutRoot, 'creator', stModule.sCreator);
        end
    end
end
end


%%
function [hOutRoot, ahModels, hModelRoot] = i_createRootSL(stArchInfo)
hOutRoot = mxx_xmltree('create', 'sl:SimulinkArchitecture');
mxx_xmltree('set_attribute', hOutRoot, 'xmlns:sl', 'http://btc-es.de/ep/simulink/2014/12/09');

if isfield(stArchInfo, 'sAddModelInfo') && ~isempty(stArchInfo.sAddModelInfo)
    mxx_xmltree('set_attribute', hOutRoot, 'infoXML', stArchInfo.sAddModelInfo);
end
sInitScript = '';
if (isfield(stArchInfo, 'sSlInitScript') && ~isempty(stArchInfo.sSlInitScript))
    mxx_xmltree('set_attribute', hOutRoot, 'initScript', stArchInfo.sSlInitScript);
    sInitScript = stArchInfo.sSlInitScript;
end
i_setMainToolsInfo(hOutRoot, true);

% An empty model node is generated, if no meta data is available.
if ~isfield(stArchInfo, 'astSlModules') || isempty(stArchInfo.astSlModules)
    hModelRoot = mxx_xmltree('add_node', hOutRoot, 'model');
    mxx_xmltree('set_attribute', hModelRoot, 'modelID', 'model001');
    ahModels = hModelRoot;
else
    % It is assumed that astTlModules holds all available models.
    % Needed to resolve the model references.
    nModels = length(stArchInfo.astSlModules);
    ahModels = repmat(hOutRoot, 1, nModels);
    for nk = 1:nModels
        stModule = stArchInfo.astSlModules(nk);
        sCreated = i_convertDate(stModule.sCreated);
        sModified = i_convertDate(stModule.sModified);
        
        hModelNode = mxx_xmltree('add_node', hOutRoot, 'model');
        ahModels(nk) = hModelNode;
        
        mxx_xmltree('set_attribute', hModelNode, 'modelID', ['model00', num2str(nk)]);
        mxx_xmltree('set_attribute', hModelNode, 'modelKind', stModule.sKind);
        mxx_xmltree('set_attribute', hModelNode, 'modelVersion', stModule.sVersion);
        mxx_xmltree('set_attribute', hModelNode, 'modelPath', stModule.sFile);
        mxx_xmltree('set_attribute', hModelNode, 'creationDate', sCreated);
        mxx_xmltree('set_attribute', hModelNode, 'modificationDate', sModified);
        if ~isempty(sInitScript)
            mxx_xmltree('set_attribute', hModelNode, 'initScript', sInitScript);
        end
        
        % Add meta info to architecture. It is asssumed that the kind="model" occurs only once.
        % Hence it must be the top level model.
        if strcmp(stModule.sKind, 'model')
            hModelRoot = hModelNode;
            mxx_xmltree('set_attribute', hOutRoot, 'modelVersion', stModule.sVersion);
            mxx_xmltree('set_attribute', hOutRoot, 'modelPath', stModule.sFile);
            mxx_xmltree('set_attribute', hOutRoot, 'modelCreationDate', sCreated);
            mxx_xmltree('set_attribute', hOutRoot, 'creator', stModule.sCreator);
        end
    end
end
end


%%
function i_copyDataTypeInfo(stEnv, hSourceNode, hTargetNode, bIsPort, bUseSimulinkInfo, bIsVirtual)
if (nargin < 6)
    bIsVirtual = false; % does interface belong to a VIRTUAL scope? default --> no
end
sPathAttrib = 'tlPath';
sBlockPathAttrib = 'tlBlockPath';
if bUseSimulinkInfo
    sPathAttrib(1) = 's';
    sBlockPathAttrib(1) = 's';
end
if bIsPort
    sPath = mxx_xmltree('get_attribute', hSourceNode, sPathAttrib);
else
    sPath = mxx_xmltree('get_attribute', hSourceNode, sBlockPathAttrib);
end
if isempty(sPath)
    sPath = '<unknown path>';
end

% Create a <miltype> node and copy the Simulink type information into it.
if bUseSimulinkInfo
    bIsSLModel = true;
    i_copyDataTypeMIL(stEnv, hSourceNode, hTargetNode, sPath, bIsSLModel);
else
    bIsSLModel = false;
    hMiltypeNode = mxx_xmltree('add_node', hTargetNode, 'miltype');
    i_copyDataTypeMIL(stEnv, hSourceNode, hMiltypeNode, sPath, bIsSLModel);
    
    % Create a <siltype> node and copy the TargetLink / C-code type information into it.
    hSiltypeNode = mxx_xmltree('add_node', hTargetNode, 'siltype');
    i_copyDataTypeSIL(stEnv, hSourceNode, hSiltypeNode, sPath, bIsVirtual);
end
end


%%
function i_copyDataTypeMIL(xEnv, hSourceNode, hTargetNode, sPath, bIsSLModel)
stSimulinkCallbacks = struct(...
    'hCopyScalarType', @i_setTypeSL, ...
    'hSetTypeMissingSinceNoCVariable', []);
i_copyGenericDataTypeInfo(xEnv, stSimulinkCallbacks, hSourceNode, hTargetNode, sPath, bIsSLModel);
end


%%
function i_copyDataTypeSIL(xEnv, hSourceNode, hTargetNode, sPath, bIsVirtual)
hSetTypeMissingSinceNoCVariable = ...
    @(hTargetNode) mxx_xmltree('set_attribute', hTargetNode, 'missingTypeSinceNoCVar', 'true');

stTargetLinkCallbacks = struct(...
    'hCopyScalarType', @i_setTypeTL, ...
    'hSetTypeMissingSinceNoCVariable', hSetTypeMissingSinceNoCVariable);
i_copyGenericDataTypeInfo(xEnv, stTargetLinkCallbacks, hSourceNode, hTargetNode, sPath, bIsVirtual);
end


%%
function i_copyGenericDataTypeInfo(xEnv, stCallbacks, hSourceNode, hTargetNode, sPath, bIsSLModel)
ahSignals = mxx_xmltree('get_nodes', hSourceNode, 'ma:Variable/ma:ifName');

sComposite = mxx_xmltree('get_attribute', hSourceNode, 'compositeSig');
if  (isempty(sComposite) || any(strcmp(sComposite, {'none', 'pseudo_bus'}))) && (length(ahSignals) == 1)
    i_copyVariableType(xEnv, stCallbacks, ahSignals(1), hTargetNode, sPath, bIsSLModel);
    
else
    % The value of sComposite can be 'bus', 'mux', 'pseudo_bus', or 'none' according to the DTD.
    bHaveComposNode = false;
    % For busses, we expect each element to NOT have an index, except if it is a signal that itself is an array signal.
    % In that case, we need to add an array (potentially nested) into the bus. For muxes and arrays, on the other hand,
    % we expect EACH element to have an index, i.e. if a signal within a mux or array has no index, this is unexpected.
    bExpectEachSignalToHaveAnIndex = true;
    
    if (~bHaveComposNode && strcmp(sComposite, 'mux'))
        hComposNode = mxx_xmltree('add_node', hTargetNode, 'mux');
        bHaveComposNode = true;
        bExpectEachSignalToHaveAnIndex = true;
    end
    if (~bHaveComposNode && strcmp(sComposite, 'bus'))
        % Create a bus node for this input.
        hComposNode = mxx_xmltree('add_node', hTargetNode, 'bus');
        bHaveComposNode = true;
        bExpectEachSignalToHaveAnIndex = false;
        
        stRes = mxx_xmltree('get_attributes', hSourceNode, '.', 'busType', 'busObj');
        if (~isempty(stRes.busType) && strcmpi(stRes.busType, 'NON_VIRTUAL_BUS'))
            if ~isempty(stRes.busObj)
                mxx_xmltree('set_attribute', hComposNode, 'busType', 'non_virtual');
                mxx_xmltree('set_attribute', hComposNode, 'busObjectName', stRes.busObj);
            end
        end
        
    end
    sSourceNodeName = mxx_xmltree('get_name', hSourceNode);
    if (~bHaveComposNode && strcmp(sSourceNodeName, 'Display'))
        % The loss of structural information caused by not having the composition type available is quite severe.
        % We can not directly distinguish mux from bus displays, except by some observations, which may not always
        % hold, e.g. if we encounter a display mux in which "accidentally" all signals carry signalName attributes.
        %
        % We base the behavior on the following assumptions, but complete recovery of the lost information is not
        % possible.
        %
        % If the display originally was a bus, and if this bus contains an array, we need to make sure that we can still
        % detect this array. We assume in this case, that all elements carry signalName attributes. To handle this
        % like a bus, we set bExpectEachSignalToHaveAnIndex to false and therefore introduce explicit arrays for all
        % groups of elements that share the same signalName.
        %
        % If not all elements have signalName attributes, we do not consider this to have been a bus originally. If in
        % this case all elements have an index, we set bExpectEachSignalToHaveAnIndex to true. Therefore, no explicit
        % arrays are introduced at all, but we may end up with a display in which multiple signals have the same
        % signalName attribute.
        %
        % In case that no signalName is given at all and all have an index, we detect the Display
        % as array or matrix.
        %
        % Else, there is a mix of signals with signalName and signals with an index, but some signals have no signalName
        % and some have no index. For this chaotic case, we also need to set bExpectEachSignalToHaveAnIndex to false,
        % since not all signals have an index, and try to handle this like a bus, i.e. introduce arrays for subsequent
        % signals with the same name an index values.
        
        % Maybe setting bExpectEachSignalToHaveAnIndex to true in all cases, in which all elements have an index1
        % attribute might help to avoid wrongly introducing arrays for a mux with only named signals, but then we would
        % not be able to detect a bus that carries only array signals. This either requires more heuristics or the
        % input format needs to be adapted to always provide composition information.
        
        bAllHaveSignalName = true;
        bNoneHasASignalName = true;
        for nk = 1:length(ahSignals)
            sSignalName = mxx_xmltree('get_attribute', ahSignals(nk), 'signalName');
            if isempty(sSignalName)
                bAllHaveSignalName = false;
            else
                bNoneHasASignalName = false;
            end
        end
        
        bAllHaveIndex1 = true;
        for nk = 1:length(ahSignals)
            sIndex1 = mxx_xmltree('get_attribute', ahSignals(nk), 'index1');
            if isempty(sIndex1)
                bAllHaveIndex1 = false;
                break;
            end
        end
        
        if bAllHaveSignalName
            % For display nodes, we have a flat collection of variables, since the model analysis does not preserve more
            % detailed structure information.
            %             bExpectEachSignalToHaveAnIndex = false;
            %             hComposNode = mxx_xmltree('add_node', hTargetNode, 'flattenedDisplayVariables');
            %             bHaveComposNode = true;
        else
            if bAllHaveIndex1 && bNoneHasASignalName
                bExpectEachSignalToHaveAnIndex = true;
            else
                % For display nodes, we have a flat collection of variables, since the model analysis does not preserve more
                % detailed structure information.
                hComposNode = mxx_xmltree('add_node', hTargetNode, 'flattenedDisplayVariables');
                bHaveComposNode = true;
                if bAllHaveIndex1
                    bExpectEachSignalToHaveAnIndex = true;
                else
                    bExpectEachSignalToHaveAnIndex = false;
                end
            end
        end
    end
    
    if bHaveComposNode
        %% Now copy all the type information below this node into signals below the newly added composite parent.
        nk = 1;
        while nk <= length(ahSignals)
            sSignalIndex1 = mxx_xmltree('get_attribute', ahSignals(nk), 'index1');
            
            if (bExpectEachSignalToHaveAnIndex && isempty(sSignalIndex1))
                % This signal should have an index, but does not provide one. This is unexpected and points to an
                % error in the ModelAnalysis or our interpretation of it.
                warning(['Encountered a signal in a ', sSourceNodeName, ' which did not provide expected ', ...
                    'index information. (Composite type: "', sComposite, '"), ', ...
                    mxx_xmltree('get_attribute', hSourceNode, 'tlBlockPath')]);
                xEnv.addMessage('EP:EPSLIMP:UNEXPECTED_NO_INDEX_INFORMATION', 'path', sPath);
            end
            
            if (bExpectEachSignalToHaveAnIndex && ~isempty(sSignalIndex1)) ...
                    || (~bExpectEachSignalToHaveAnIndex && isempty(sSignalIndex1)) ...
                    || (bExpectEachSignalToHaveAnIndex && isempty(sSignalIndex1))
                % This signal has an expected index or does not have one where none is expected. In both cases, it can
                % simply be added to its parent composite. Or it has lacks an expected index -- in which case it is
                % best to add it as a scalar to the composite, too.
                hSignalNode = mxx_xmltree('add_node', hComposNode, 'signal');
                i_copyVariableType(xEnv, stCallbacks, ahSignals(nk), hSignalNode, sPath, ...
                    bIsSLModel);
                i_copyAttribute(ahSignals(nk), 'index1', hSignalNode, 'index');
            else
                % We do not expect to see an index at every element, but there is one. So this marks the beginning
                % of an array, which we assume to continue as long as signals carry the same signalName.
                
                % Collect all signals until the signalName attribute changes.
                ahArraySignals = [];
                sCurrentSignalName = mxx_xmltree('get_attribute', ahSignals(nk), 'signalName');
                sArraySignalName = sCurrentSignalName;
                while strcmp(sCurrentSignalName, sArraySignalName)
                    % This signal carries the same name as the first signal of this array.
                    if isempty(ahArraySignals)
                        ahArraySignals = ahSignals(nk);
                    else
                        ahArraySignals(end + 1) = ahSignals(nk);
                    end
                    % Look ahead to next signal and retrieve its name.
                    nk = nk + 1;
                    if (length(ahSignals) >= nk)
                        sCurrentSignalName = mxx_xmltree('get_attribute', ahSignals(nk), 'signalName');
                    else
                        % Reached end of signals.
                        break;
                    end
                end
                
                % Create a signal which carries an array for the collected ahArraySignals.
                hSignalNode = mxx_xmltree('add_node', hComposNode, 'signal');
                i_copyArrayType(xEnv, stCallbacks, ahArraySignals, hSignalNode, sPath, bIsSLModel);
                
                % Continue with the first signal after the array, i.e. the one curently pointed to by index nk --
                % which therefore needs to be reduced by one again.
                nk = nk - 1;
            end
            nk = nk + 1;
        end
    else
        %% This is neither a bus nor a mux on its top-level, but it still contains more than one ifName node.
        
        % This could be a pseudo_bus according to DTD. According to AlHo, a "pseudo bus" is a signal which looks like a
        % bus (the term itself is introduced by AlHo, not by SL/TL) and can occur e.g. for a signal, which is an
        % element of a mux may look like a bus itself, but it should be handled as an array, not as a bus. In old
        % Simulink versions this could have been handled as a mix of array / bus, but in TL this seems to be an array.
        
        % We handle it as an array here, by falling through the above if cases whenever a port is neither display, bus,
        % nor mux.
        
        % We do not issue a warning about this -- but there has been a warning prepared for this:
        % xEnv.addMessage('EP:EPSLIMP:UNEXPECTED_PORT_STRUCTURE', 'path', sPath);
        
        % Create an array as the type of the hTargetNode which will contain the ahSignals as its elements.
        i_copyArrayType(xEnv, stCallbacks, ahSignals, hTargetNode, sPath, bIsSLModel);
    end
end
end


%%
function i_copyVariableType(xEnv, stCallbacks, hSourceIfNameNode, hTargetNode, sPath, bIsSLModel)
% Find out if this ifName's parent variable has been marked as a dummy variable. This information is relevant in the
% SIL data type case, where it causes variables to lose their TL-SIL type information during MA.
if ~isempty(stCallbacks.hSetTypeMissingSinceNoCVariable)
    ahParentVarNode = mxx_xmltree('get_nodes', hSourceIfNameNode, '..');
    sIsDummy = mxx_xmltree('get_attribute', ahParentVarNode(1), 'isDummy');
    if ~isempty(sIsDummy) && strcmp(sIsDummy, 'yes')
        stCallbacks.hSetTypeMissingSinceNoCVariable(hTargetNode);
    end
end

stCallbacks.hCopyScalarType(xEnv, hSourceIfNameNode, hTargetNode, sPath, bIsSLModel);
sSignalName = mxx_xmltree('get_attribute', hSourceIfNameNode, 'signalName');
if ~isempty(sSignalName)
    mxx_xmltree('set_attribute', hTargetNode, 'signalName', sSignalName);
end
end


%%
function bIsPortSignal = i_isSignalFromPort(hIfNode)
hInterface = mxx_xmltree('get_nodes', hIfNode, './../..'); % need the "grandparent" node
bIsPortSignal = strcmp(mxx_xmltree('get_name', hInterface), 'Port');
end


%%
function i_setTypeSL(xEnv, hIfNode, hTargetNode, sPath, bIsSLModel)
stIfInfo = mxx_xmltree('get_attributes', hIfNode, '.', 'initValue', 'signalType', 'slSignalType');

if (~isempty(stIfInfo.initValue) && ~i_isSignalFromPort(hIfNode))
    % EP-842 when adding info for MIL type, only enter init values for Parameters
    mxx_xmltree('set_attribute', hTargetNode, 'initValue', stIfInfo.initValue);
end

sSignalType = 'double'; % default type if no info available
if (bIsSLModel && ~isempty(stIfInfo.slSignalType))
    % In a Simulink model, if there is an "slSignalType" attribute, prefer its value, otherwise try to get it from the
    % "signalType" attribute.
    sSignalType = stIfInfo.slSignalType;
elseif ~isempty(stIfInfo.signalType)
    sSignalType = stIfInfo.signalType;
end

[hSignalNode, sSigMin, sSigMax] = i_addSignalNode(xEnv, hTargetNode, sSignalType, sPath);
if isempty(hSignalNode)
    xEnv.addMessage('EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', sPath);
    mxx_xmltree('add_node', hTargetNode, 'unsupportedTypeInformation');
    return;
end

if bIsSLModel
    stRangeInfo = mxx_xmltree('get_attributes', hIfNode, '.', 'slMin', 'slMax');
    sMin = stRangeInfo.slMin;
    sMax = stRangeInfo.slMax;
else
    stRangeInfo = mxx_xmltree('get_attributes', hIfNode, '.', 'min', 'max');
    sMin = stRangeInfo.min;
    sMax = stRangeInfo.max;
end

bIsIntType = i_isIntTypeNode(hSignalNode);
if ~isempty(sMin)
    % if we have a "min", enter it if
    %    a) we do _not_ have a "signal min"
    % OR b) the "min" is greater than the "signal min"
    if (isempty(sSigMin) || (str2double(sSigMin) < str2double(sMin)))
        if bIsIntType
            sMin = i_convertDoubleToIntString(sMin);
        end
        mxx_xmltree('set_attribute', hSignalNode, 'min', sMin);
    end
end
if ~isempty(sMax)
    % if we have a "max", enter it if
    %    a) we do _not_ have a "signal max"
    % OR b) the "max" is less than the "signal max"
    if (isempty(sSigMax) || (str2double(sSigMax) > str2double(sMax)))
        if bIsIntType
            sMax = i_convertDoubleToIntString(sMax);
        end
        mxx_xmltree('set_attribute', hSignalNode, 'max', sMax);
    end
end
end


%%
function sIntValue = i_convertDoubleToIntString(sDoubleValue)
if isempty(regexp(sDoubleValue, '^[+,-]?\d+$', 'once'))
    sIntValue = sprintf('%d', int64(str2double(sDoubleValue)));
else
    sIntValue = sDoubleValue;
end
end


%%
function bIsIntType = i_isIntTypeNode(hSignalNode)
sType = mxx_xmltree('get_name', hSignalNode);
bIsIntType = ~isempty(regexp(sType, '^u?int', 'once'));
end


%%
function hEnumTypeNode = i_addEnumTypeInfo(hParentNode, stTypeInfo)
hEnumTypeNode = mxx_xmltree('add_node', hParentNode, 'enumType');
mxx_xmltree('set_attribute', hEnumTypeNode, 'name', stTypeInfo.sEvalType);

for i = 1:length(stTypeInfo.astEnum)
    i_addEnumElementInfo(hEnumTypeNode, stTypeInfo.astEnum(i));
end
end


%%
function hEnumElemNode = i_addEnumElementInfo(hParentNode, stEnumElemInfo)
hEnumElemNode = mxx_xmltree('add_node', hParentNode, 'enumElement');
mxx_xmltree('set_attribute', hEnumElemNode, 'name', stEnumElemInfo.Key);
mxx_xmltree('set_attribute', hEnumElemNode, 'value', num2str(stEnumElemInfo.Value));
end


%%
function [bIsSigned, iWordLength] = i_getSignednessAndWordlength(sBaseType)
bIsSigned = ~isempty(sBaseType) && (sBaseType(1) ~= 'u');
iWordLength = str2double(regexprep(sBaseType, '^[^\d]+', ''));
end


%%
function [hSignalNode, sSigMin, sSigMax] = i_addSignalNode(xEnv, hParentNode, sSignalType, sPath)
hSignalNode = [];
sSigMin = '';
sSigMax = '';

stTypeInfo = i_typeInfo('get', sSignalType);
if ~stTypeInfo.bIsValidType
    return;
end

casAliasTypes = stTypeInfo.casAliasChain(1:end-1);
% TODO: eval alias chain
for i = 1:length(casAliasTypes)
%    disp(['alias for ', casAliasTypes{i}]);
end

if (stTypeInfo.bIsEnum)
    hSignalNode = i_addEnumTypeInfo(hParentNode, stTypeInfo);
else
    if ~isempty(regexp(stTypeInfo.sEvalType, '^fixdt\(', 'once'))
        [bIsSigned, iWordLength] = i_getSignednessAndWordlength(stTypeInfo.sBaseType);
        sSigMin = stTypeInfo.oRepresentMin.toString();
        sSigMax = stTypeInfo.oRepresentMax.toString();
        hSignalNode = i_copyFixedPointSL(xEnv, ...
            stTypeInfo.sEvalType, ...
            num2str(iWordLength) , ...
            num2str(bIsSigned), ...
            i_double_to_str(stTypeInfo.dLsb), ...
            i_double_to_str(stTypeInfo.dOffset), ...
            sSigMin, ...
            sSigMax, ...
            hParentNode);
    else
        sSignalType = stTypeInfo.sBaseType;
        if strcmp(sSignalType, 'logical')
            sSignalType = 'boolean';
        end
        if any(strcmp(sSignalType, { ...
                'double', ...
                'single', ...
                'boolean', ...
                'uint8', ...
                'int8', ...
                'uint16', ...
                'int16', ...
                'uint32', ...
                'int32'}))
            hSignalNode = mxx_xmltree('add_node', hParentNode, sSignalType);
        elseif any(strcmp(sSignalType, {'uint64','int64'}))            
            xEnv.addMessage('EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', sPath);
            hSignalNode = mxx_xmltree('add_node', hParentNode, 'unsupportedTypeInformation');
            mxx_xmltree('set_attribute', hSignalNode, 'baseType', sSignalType);
        end
    end
end
end


%%
function i_setTypeTL(xEnv, hIfNode, hTargetNode, sPath, bIsVirtual)
stIfInfo = mxx_xmltree('get_attributes', hIfNode, '.', ...
    'initValue', ...
    'signalType');
stDataType = mxx_xmltree('get_attributes', hIfNode, './ma:DataType', ...
    'tlTypeName', ...
    'tlTypeMin', ...
    'tlTypeMax', ...
    'isFloat', ...
    'enumTypeRef');
stScaling = mxx_xmltree('get_attributes', hIfNode, './ma:DataType/ma:Scaling', ...
    'lower', ...
    'upper', ...
    'lsb', ...
    'offset', ...
    'physUnit');

if ~isempty(stIfInfo.initValue)
    mxx_xmltree('set_attribute', hTargetNode, 'initValue', stIfInfo.initValue);
end

if (strcmp('Bitfield', stDataType.tlTypeName))
    % This is a bitfied. The ranges are expected to describe the range of the bitfield, which is an element of a
    % structure in which each element is given a fixed number of bits and a suitable integer type, e.g.
    % struct {
    %     unsigned int b0 : 1;
    %     unsigned int b1 : 1;
    %     unsigned int b2 : 1;
    %     unsigned int b3 : 1;
    %     unsigned int b4 : 1;
    %     unsigned int b5 : 1;
    %     unsigned int b6 : 1;
    %     unsigned int b7 : 1;
    % }
    % We will at least support any range [0, 2^n] for now, but future versions may extend this to arbitrary ranges
    % -- in which case also a signedness information would have to be provided explicitly.
    
    % TODO: Find explicit signedness information (not available in model analysis right now).
    % TODO: Scalings underneath bitfields are ignored for now.
    
    bScalingIsDefault = (sscanf(stScaling.lsb, '%e') == 1) && (sscanf(stScaling.offset, '%e') == 0);
    dMin = str2double(stDataType.tlTypeMin);
    dMax = str2double(stDataType.tlTypeMax);
    bMinInteger = double(int32(dMin)) == double(dMin);
    bMaxInteger = double(int32(dMax)) == double(dMax);
    if bMinInteger && bMaxInteger && bScalingIsDefault
        % This bitfield has integer bounds and a lsb=1,offset=0-scaling. We support this.
        hResultTypeNode = mxx_xmltree('add_node', hTargetNode, 'Bitfield');
        mxx_xmltree('set_attribute', hResultTypeNode, 'min', num2str(dMin));
        mxx_xmltree('set_attribute', hResultTypeNode, 'max', num2str(dMax));
    else
        % This is a bitfield type with non-integer bounds or non-trivial scaling. This is currently not supported.
        if ~bIsVirtual
            xEnv.addMessage('EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', sPath);
        end
        mxx_xmltree('add_node', hTargetNode, 'unsupportedTypeInformation');
    end
elseif ~isempty(stDataType.enumTypeRef) && ~bIsVirtual
    stTypeInfo = i_silTypeInfo('get', stDataType.enumTypeRef);
    i_addEnumTypeInfo (hTargetNode, stTypeInfo);
else
    hResultTypeNode = [];
    
    dLsb = sscanf(stScaling.lsb, '%e');
    dOffset = sscanf(stScaling.offset, '%e');
    bSilSignalIsFloat = strcmp(stDataType.isFloat, 'yes');
    
    bLimitsAreSet = false;
    bIsScalingNeeded = ep_sil_scaling_needed(stDataType.tlTypeName, bSilSignalIsFloat, dLsb, dOffset);
    if bIsScalingNeeded
        % The MIL type of the model is a floating-point type, while the SIL type is not OR this scaling contains relevant
        % information. We therefore need to explicitly create a fixed-point type for this type info.
        % Note that this may create fixed-point types, which may have an empty scaling, even things that may look outright
        % absurd like a Bool-based fixed-point type with lsb=1, offset = 0, min = 0, and max = 0, if the MIL type is
        % floating-point.
        bMissingTypeSinceNoCVar = i_isMissingTypeSinceNoCVar(hTargetNode);
        if (bMissingTypeSinceNoCVar)
            if ~bIsVirtual
                xEnv.addMessage('EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', sPath);
            end
            mxx_xmltree('add_node', hTargetNode, 'unsupportedTypeInformation');
        else
            % In this case a fixed point data type is created (a non-default scaling has been detected)
            hResultTypeNode = mxx_xmltree('add_node', hTargetNode, 'fixedPoint');
            mxx_xmltree('set_attribute', hResultTypeNode, 'baseType', stDataType.tlTypeName);
            mxx_xmltree('set_attribute', hResultTypeNode, 'lsb', stScaling.lsb);
            mxx_xmltree('set_attribute', hResultTypeNode, 'offset', stScaling.offset);
            
            % Note: currently in Java integration the fixed point needs to have min/max values even though not explictly
            % set by user --> for now use workaround by _always_ setting them
            % --> TODO: adapt Java side and remove here
            bLimitsAreSet = true;
        end
    else
        % No relevant fixed-point scaling is provided and the variable does not represent a floating-point MIL type via an
        % integer SIL type. We can therefore translate the built-in type directly.
        if i_is_known_type(stDataType.tlTypeName)
            hResultTypeNode = mxx_xmltree('add_node', hTargetNode, stDataType.tlTypeName);
        else
            if ~bIsVirtual
                xEnv.addMessage('EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', sPath);
            end
            mxx_xmltree('add_node', hTargetNode, 'unsupportedTypeInformation');
        end
    end
    if ~isempty(hResultTypeNode)
        bLimitsAreSet = bLimitsAreSet || ...
            ~strcmp(stScaling.lower, stDataType.tlTypeMin) || ~strcmp(stScaling.upper, stDataType.tlTypeMax);
        if bLimitsAreSet
            mxx_xmltree('set_attribute', hResultTypeNode, 'min', stScaling.lower);
            mxx_xmltree('set_attribute', hResultTypeNode, 'max', stScaling.upper);
        end
    end
end

if ~isempty(stScaling.physUnit)
    % Store the physical unit information -- if any -- at the signal's node (not at the freshly introduced type node).
    mxx_xmltree('set_attribute', hTargetNode, 'unitName', stScaling.physUnit);
end
end

%%
function bMissingTypeSinceNoCVar = i_isMissingTypeSinceNoCVar(hTargetNode)
bMissingTypeSinceNoCVar = false;
% 1. Check current node
sTLMissingTypeInfo = mxx_xmltree('get_attribute', hTargetNode, 'missingTypeSinceNoCVar');

% 2. check siltype node
if isempty(sTLMissingTypeInfo)
    hSilType = mxx_xmltree('get_nodes', hTargetNode, 'ancestor::siltype');
    if ~isempty(hSilType)
        sTLMissingTypeInfo = mxx_xmltree('get_attribute', hSilType, 'missingTypeSinceNoCVar');
    end
end

% 3 .check other signal nodes
if isempty(sTLMissingTypeInfo)
    ahSignals = mxx_xmltree('get_nodes', hTargetNode, 'ancestor::signal');
    for i=1:length(ahSignals)
        sTLMissingTypeInfo = mxx_xmltree('get_attribute', ahSignals(i), 'missingTypeSinceNoCVar');
        if ~isempty(sTLMissingTypeInfo)
            break;
        end
    end
end

if (~isempty(sTLMissingTypeInfo) && strcmp(sTLMissingTypeInfo, 'true'))
    bMissingTypeSinceNoCVar = true;
end
end

%%
function bIsKnown = i_is_known_type(sTlTypeName)
bIsKnown = any(strcmp(sTlTypeName, { ...
    'Float64', ...
    'Float32', ...
    'Int8', ...
    'UInt8', ...
    'Int16', ...
    'UInt16', ...
    'Int32', ...
    'UInt32', ...
    'Int64', ...
    'UInt64', ...
    'Int', ...
    'UInt', ...
    'Void', ...
    'Bool'}));
end


%%
function i_addCalibUsage(hCalibSourceNode, hCalibTargetNode, bUseSimulinkInfo, ahModels)

% Usage becomes the "origin" of the calibration, since "explicit_param" should be the default case.
i_copyAttribute(hCalibSourceNode, 'usage', hCalibTargetNode, 'origin');

% Restricted needs to be converted into standard boolean format.
sRestrictedValue = mxx_xmltree('get_attribute', hCalibSourceNode, 'restricted');
if strcmp(sRestrictedValue, 'yes')
    mxx_xmltree('set_attribute', hCalibTargetNode, 'restricted', 'true');
else
    mxx_xmltree('set_attribute', hCalibTargetNode, 'restricted', 'false');
end

bIsExplicitParamOrigin = strcmp(mxx_xmltree('get_attribute', hCalibSourceNode, 'usage'), 'explicit_param');
if bIsExplicitParamOrigin
    if ~bUseSimulinkInfo
        i_copyAttribute(hCalibSourceNode, 'ddPath', hCalibTargetNode, 'ddPath');
    end
    i_copyAttribute(hCalibSourceNode, 'workspace', hCalibTargetNode, 'workspace');
else
    i_copyAttribute(hCalibSourceNode, 'sfVariable', hCalibTargetNode, 'stateflowVariable');
end

% Convert ma:ModelContext nodes into usageContext nodes of the target.
ahModelContexts = mxx_xmltree('get_nodes', hCalibSourceNode, './ma:ModelContext');
for ni = 1:length(ahModelContexts)
    hModelContext = ahModelContexts(ni);
    
    hUsageContext = mxx_xmltree('add_node', hCalibTargetNode, 'usageContext');
    if bUseSimulinkInfo
        sPath = mxx_xmltree('get_attribute', hModelContext, 'slPath');
        mxx_xmltree('set_attribute', hUsageContext, 'path', i_delete_model_name_from_path(sPath));
    else
        sPath = mxx_xmltree('get_attribute', hModelContext, 'tlPath');
        mxx_xmltree('set_attribute', hUsageContext, 'path', i_delete_model_name_from_path(sPath));
        i_copyAttribute(hModelContext, 'blockKind', hUsageContext, 'targetLinkBlockKind');
    end
    mxx_xmltree('set_attribute', hUsageContext, 'physicalPath', sPath);
    
    i_copyAttribute(hModelContext, 'blockType', hUsageContext, 'simulinkBlockType');
    i_copyAttribute(hModelContext, 'blockUsage', hUsageContext, 'blockAttribute');
    i_copyAttribute(hModelContext, 'sfVariable', hUsageContext, 'stateflowVariable');
    i_copyAttribute(hModelContext, 'restriction', hUsageContext, 'restriction');
    
    i_addModelReferenceInformation(hModelContext, hUsageContext, ahModels, bUseSimulinkInfo);
end
end


%%
function bIsDummy = i_isParentVarDummy(hIfNode)
stAtt = mxx_xmltree('get_attributes', hIfNode, '..', 'isDummy');
bIsDummy = ~isempty(stAtt.isDummy) && strcmp(stAtt.isDummy, 'yes');
end


%%
function i_copyArrayType(xEnv, stCallbacks, ahIfNodes, hTargetNode, sPath, bIsSLModel)
hArrayNode = mxx_xmltree('add_node', hTargetNode, 'nonUniformArray');
[astNodes, ahIfNodes, bIs2Dim] = i_sortArrayIfNames(ahIfNodes);

% Find out if these ifNames' parent variable has been marked as a dummy variable. This information is relevant in the
% SIL data type case, where it causes variables to lose their TL-SIL type information during MA.
% TODO: Should we check each element of the array? For the moment, we only check the first ifName's parent and if it has
% isDummy=yes, we mark the whole array as having no SIL-type (but still add all available type information). This could
% lead to wrong expectations about missing types if individual elements are dummy and others are not.
if ~isempty(stCallbacks.hSetTypeMissingSinceNoCVariable)
    bAllElementsDummy = all(arrayfun(@(hIfNode) i_isParentVarDummy(hIfNode), ahIfNodes));
    if bAllElementsDummy
        stCallbacks.hSetTypeMissingSinceNoCVariable(hTargetNode);
    end
end


% Get the start index and the size of this array.
nStartIndex = astNodes(1).nIdx1;
nLastIndex = astNodes(end).nIdx1;

% Example: indices 1 2 3 4, size = 4 - 1 + 1. There could be holes (TODO: unclear whether this occurs also on models),
% so the width of the array could be smaller, but this is a safe upper bound for the relevant width, since no index
% exceeds this width.

nMaxSize = nLastIndex - nStartIndex + 1;
sWidth = sprintf('%d', nMaxSize);
mxx_xmltree('set_attribute', hArrayNode, 'size', sWidth);

stDisplayAttr = struct('startIdx', []);
if isempty(mxx_xmltree('get_nodes',  hArrayNode, 'ancestor::siltype'))
    stDisplayAttr = mxx_xmltree('get_attributes', ahIfNodes(1), '../..', 'startIdx');
    if ~isempty(stDisplayAttr.startIdx)
        mxx_xmltree('set_attribute', hArrayNode, 'startIndex', stDisplayAttr.startIdx);
    end
end
% The model analysis creates the signal name at the ifName nodes, but for array signals, we actually expect that the
% signal name is actually an attribute of the array. So we would like it to be given to the hTargetNode, which is the
% signal or port containing the array. We add it to the individual signals only if they really have a different signal
% name.
sSeenSignalName = '';
if length(astNodes) >= 1
    sSeenSignalName = mxx_xmltree('get_attribute', ahIfNodes(1), 'signalName');
    if ~isempty(sSeenSignalName)
        mxx_xmltree('set_attribute', hTargetNode, 'signalName', sSeenSignalName);
    end
end
nh = 1;
while nh <= length(astNodes)
    stNode = astNodes(nh);
    hIfNode = ahIfNodes(nh);
    
    % Unless this element has an index2 value, this is a scalar array element.
    if ~bIs2Dim
        %% There is is no index2, hence this is not a nested array.
        hSignalNode = mxx_xmltree('add_node', hArrayNode, 'signal');
        stCallbacks.hCopyScalarType(xEnv, hIfNode, hSignalNode, sPath, bIsSLModel);
        % We do not copy the accessPath attribute since it is a legacy format based on a zero-indexed access
        % path. Instead, we copy the index1 and (only differing) signalName attributes.
        
        % This is not a nested array, since the signal does not have an index2.
        i_copyAttribute(hIfNode, 'index1', hSignalNode, 'index');
        % Copy this signal name only if it differs from the value of the sSLSignalName attribute added to the hTargetNode.
        sThisSignalName = mxx_xmltree('get_attribute', hIfNode, 'signalName');
        if ~isempty(sThisSignalName) && ~strcmp(sSeenSignalName, sThisSignalName)
            % This signal name actually diverges, so need to copy it.
            % This is a bit unexpected, but should not be a problem.
            mxx_xmltree('set_attribute', hSignalNode, 'signalName', sThisSignalName);
        end
    else
        %% This is a nested array since there is an index2 value.
        
        % Collect all subsequent elements that have the same index1 value.
        nCurIndex1 = stNode.nIdx1;
        nThisElementIndex1 = nCurIndex1;
        ahNestedArrayElements = [];
        nArrayStartNHvalue = nh;
        nNestedStartIndex = stNode.nIdx2;
        while nThisElementIndex1 == nCurIndex1
            if isempty(ahNestedArrayElements)
                ahNestedArrayElements = hIfNode;
            else
                ahNestedArrayElements(end+1) = hIfNode;
            end
            nNestedLastIndex = stNode.nIdx2;
            
            % Need to look ahead and skip all matching elements in outer loop (signals will
            % be added to nested array and not directly to outer array).
            nh = nh + 1;
            if (length(astNodes) >= nh)
                % Look ahead for the next signal index.
                stNode = astNodes(nh);
                hIfNode = ahIfNodes(nh);
                
                nCurIndex1 = stNode.nIdx1;
            else
                % Reached end of signals.
                break;
            end
        end
        
        % TODO: To generalize this, it could be refactored into recursively calling this method again and submitting
        % TODO: ... the name of the index attribute (e.g. "index1") and the sThisSignalName for the name which is given
        % TODO: ... to the full array.
        
        % Add a nested array for these signals.
        hSignalNode = mxx_xmltree('add_node', hArrayNode, 'signal');
        hNestedArrayNode = mxx_xmltree('add_node', hSignalNode, 'nonUniformArray');
        
        % Set the index1 attribute to the signal.
        i_copyAttribute(ahNestedArrayElements(1), 'index1', hSignalNode, 'index');
        
        % TODO: unclear whether there could be holes in these indices.
        nNestedMaxSize = nNestedLastIndex - nNestedStartIndex + 1;
        sNestedWidth = sprintf('%d', nNestedMaxSize);
        mxx_xmltree('set_attribute', hNestedArrayNode, 'size', sNestedWidth);
        
        if ~isempty(stDisplayAttr.startIdx)
            mxx_xmltree('set_attribute', hNestedArrayNode, 'startIndex', stDisplayAttr.startIdx);
        end
        
        % Add elements to the nested array.
        for nj = 1:length(ahNestedArrayElements)
            % Create an element for this signal.
            hSignalNode = mxx_xmltree('add_node', hNestedArrayNode, 'signal');
            stCallbacks.hCopyScalarType(xEnv, ahNestedArrayElements(nj), hSignalNode, sPath, bIsSLModel);
            % We do not copy the accessPath attribute since it is a legacy format based on a zero-indexed access
            % path. Instead, we copy the index2 and (only differing) signalName attributes.
            if isempty(mxx_xmltree('get_attribute', ahNestedArrayElements(nj), 'index2'))
                sIndex2 = sprintf('%d',nNestedStartIndex + nj - 1);
                mxx_xmltree('set_attribute', hSignalNode, 'index', sIndex2);
            else
                i_copyAttribute(ahNestedArrayElements(nj), 'index2', hSignalNode, 'index');
            end
            % Copy this signal name only if it differs from the value of the sSLSignalName attribute added to the
            % hTargetNode.
            sThisSignalName = mxx_xmltree('get_attribute', ahNestedArrayElements(nj), 'signalName');
            if ~isempty(sThisSignalName) && ~strcmp(sSeenSignalName, sThisSignalName)
                % This signal name actually diverges, so need to copy it.
                % This is a bit unexpected, but should not be a problem.
                mxx_xmltree('set_attribute', hSignalNode, 'signalName', sThisSignalName);
            end
        end
        % Continue with first signal that had a different index1 (or end of signal array).
        nh = nh - 1;
    end
    nh = nh + 1;
end
end


%%
function [astNodes, ahSortedIfNodes, bIs2Dim] = i_sortArrayIfNames(ahIfNodes)
nIfs = length(ahIfNodes);
astNodes = repmat(struct( ...
    'nIdx1', 1, ...
    'nIdx2', 1), 1, nIfs);

bIs2Dim = ~isempty(mxx_xmltree('get_attribute', ahIfNodes(1), 'index2'));

stIfInfo = mxx_xmltree('get_attributes', ahIfNodes(1), '.', ...
    'initValue', ...
    'signalType', ...
    'accessPath', ...
    'signalDim');

nDim1 = 0;
nDim2 = 0;
if ~isempty(stIfInfo.signalDim)
    % get and clean '[2 1 3]' to '2 1 3'
    sSignalDim = stIfInfo.signalDim(2:end-1);
    casIdx = regexp (sSignalDim, ' ', 'split');
    
    % get number of dimensions to add
    nDimensions = str2double(casIdx(1));
    
    nDim1 = str2double(casIdx(2));
    if nDimensions == 2
        nDim2 = str2double(casIdx(3));
        bIs2Dim = 1;
    else
        nDim2 = 0;
    end
end

for i = 1:nIfs
    hIfNode = ahIfNodes(i);
    astNodes(i).nIdx1 = sscanf(mxx_xmltree('get_attribute', hIfNode, 'index1'), '%d');
    if bIs2Dim
        if ~isempty(mxx_xmltree('get_attribute', hIfNode, 'index2'))
            astNodes(i).nIdx2 = sscanf(mxx_xmltree('get_attribute', hIfNode, 'index2'), '%d');
        else
            astParent = mxx_xmltree('get_attributes', hIfNode, '../..', 'startIdx');
            if ~isempty(astParent.startIdx)
                astNodes(i).nIdx2 = str2double(astParent.startIdx);
            else
                astNodes(i).nIdx2 = 1;
            end
        end
    end
end

if bIs2Dim && nDim1==1
    for i = 1:nIfs
        astNodes(i).nIdx2 = astNodes(i).nIdx1;
        astNodes(i).nIdx1 = 1;
    end
end

% use min and max of second index to calculate 1-D index of matrix/vector
nMin2 = min([astNodes(:).nIdx2]);
nMax2 = max([astNodes(:).nIdx2]);
nWidth2 = nMax2 - nMin2 + 1;

nLinIdx = [astNodes(:).nIdx1]*nWidth2 + [astNodes(:).nIdx2];
[~, aiSortIdx] = sort(nLinIdx);

astNodes = astNodes(aiSortIdx);
ahSortedIfNodes = ahIfNodes(aiSortIdx);
end


%%
function i_copyAttribute(hSourceNode, sSourceName, hTargetNode, sTargetName)
sValue = mxx_xmltree('get_attribute', hSourceNode, sSourceName);
if ~isempty(sValue)
    mxx_xmltree('set_attribute', hTargetNode, sTargetName, sValue);
end
end


%%
function i_setMainToolsInfo(hParent, bUseSimulinkInfo)
stVersion = ver('Matlab');
sRelease = stVersion.Release;
[sVersion, sPatch] = ep_core_version_get('ML');
i_setToolInfo(hParent, 'Matlab', sRelease, sVersion, sPatch);

stVersion = ver('Simulink');
sRelease = stVersion.Release;
[sVersion, sPatch] = ep_core_version_get('SL');
i_setToolInfo(hParent, 'Simulink', sRelease, sVersion, sPatch);

if ~bUseSimulinkInfo
    %stVersion = ver('TL') The field "Release" is not consistently filled for
    %different TL versions. Therefore an empty release string is used.
    sRelease = '';
    [sVersion, sPatch] = ep_core_version_get('TL');
    i_setToolInfo(hParent, 'TargetLink', sRelease, sVersion, sPatch);
end
end


%%
function i_setToolInfo(hParent, sToolName, sRelease, sVersion, sPatch)
hToolInfo = mxx_xmltree('add_node', hParent, 'toolInfo');
mxx_xmltree('set_attribute', hToolInfo, 'name', sToolName);
mxx_xmltree('set_attribute', hToolInfo, 'release', sRelease);
mxx_xmltree('set_attribute', hToolInfo, 'version', sVersion);
mxx_xmltree('set_attribute', hToolInfo, 'patchLevel', sPatch);
end


%%
function sName = i_extractNameFromPath(sPath)
% Slashes in names are escaped by "//".
sName = regexprep(sPath, '(.)*[^/]/([^/])', '$2');
% Replacing escaped slashes in output.
sName = regexprep(sName, '//', '/');
end


%%
function i_copyPathNameAttribute(hSourceNode, sSourceName, hTargetNode, sTargetName)
sValue = mxx_xmltree('get_attribute', hSourceNode, sSourceName);
sValue = i_extractNameFromPath(sValue);
mxx_xmltree('set_attribute', hTargetNode, sTargetName, sValue);
end


%%
function sRetDate = i_convertDate(sDate)
try % try the ISO format
    sRetDate = datestr(datenum(sDate,'yyyy-mm-ddTHH:MM:SS'),'yyyy-mm-ddTHH:MM:SS');
catch
    try
        %try the MATLAB format
        sRetDate = datestr(datenum(sDate,'ddd mmm dd HH:MM:SS yyyy'),'yyyy-mm-ddTHH:MM:SS');
    catch
        try
            % try MATLAB heuristic to determine the correct format
            sRetDate = datestr(datenum(sDate),'yyyy-mm-ddTHH:MM:SS');
        catch
            % use the 1st Jan 1970 as fall back if nothing else worked out
            warning(['Failed to convert date "',sDate,'" to "yyyy-mm-ddTHH:MM:SS". Date is set to "1970-01-01T00:00:00"']);
            sRetDate = '1970-01-01T00:00:00';
        end
    end
end
end


%%
function i_addEnvNode(hSubSource, hTlVirtualSubystem, hTlModel)
ahEnvNodes = mxx_xmltree('get_nodes', hSubSource, './ma:Children/ma:Block');
for idx = 1:length(ahEnvNodes)
    hEnvNode = ahEnvNodes(idx);
    sSubSystemID = ['env_', num2str(idx)];
    
    %create new 'Env' node
    hTlNewEnvSubSystem = mxx_xmltree('add_node', hTlModel, 'subsystem');
    
    %create reference in model
    hSubSystemRef = mxx_xmltree('add_node', hTlVirtualSubystem, 'subsystem');
    mxx_xmltree('set_attribute', hSubSystemRef, 'refSubsysID', sSubSystemID);
    mxx_xmltree('set_attribute', hTlNewEnvSubSystem, 'subsysID', sSubSystemID);
    mxx_xmltree('set_attribute', hTlNewEnvSubSystem, 'scopeKind', 'ENV');
    mxx_xmltree('set_attribute', hTlNewEnvSubSystem, 'kind', 'subsystem');
    
    sName = mxx_xmltree('get_attribute', hEnvNode, 'name');
    mxx_xmltree('set_attribute', hTlNewEnvSubSystem, 'name', sName);
    
    sPath = mxx_xmltree('get_attribute', hEnvNode, 'path');
    mxx_xmltree('set_attribute', hTlNewEnvSubSystem, 'path', i_delete_model_name_from_path(sPath));
    mxx_xmltree('set_attribute', hTlNewEnvSubSystem, 'physicalPath', sPath);
    
    sSampleTime = mxx_xmltree('get_attribute', hTlVirtualSubystem, 'sampleTime');
    mxx_xmltree('set_attribute', hTlNewEnvSubSystem, 'sampleTime', sSampleTime);
end
end


%%
function i_addDummyNode(hSubSource, hTlDummySubystem, hTlModel)
ahDummyNodes = mxx_xmltree('get_nodes', hSubSource, './ma:Children/ma:Block');
for idx = 1:length(ahDummyNodes)
    hDummyNode = ahDummyNodes(idx);
    sSubSystemID = ['dummy_', num2str(idx)];
    
    %create new 'Dummy' node
    hTlNewDummySubSystem = mxx_xmltree('add_node', hTlModel, 'subsystem');
    
    %create reference in model
    hSubSystemRef = mxx_xmltree('add_node', hTlDummySubystem, 'subsystem');
    mxx_xmltree('set_attribute', hSubSystemRef, 'refSubsysID', sSubSystemID);
    mxx_xmltree('set_attribute', hTlNewDummySubSystem, 'subsysID', sSubSystemID);
    mxx_xmltree('set_attribute', hTlNewDummySubSystem, 'scopeKind', 'DUMMY');
    mxx_xmltree('set_attribute', hTlNewDummySubSystem, 'kind', 'subsystem');
    
    sName = mxx_xmltree('get_attribute', hDummyNode, 'name');
    mxx_xmltree('set_attribute', hTlNewDummySubSystem, 'name', sName);
    
    sPath = mxx_xmltree('get_attribute', hDummyNode, 'path');
    mxx_xmltree('set_attribute', hTlNewDummySubSystem, 'path', sPath);
    
    sSampleTime = mxx_xmltree('get_attribute', hTlDummySubystem, 'sampleTime');
    mxx_xmltree('set_attribute', hTlNewDummySubSystem, 'sampleTime', sSampleTime);
end
end


%%
function hResultTypeNode = i_copyFixedPointSL(~, sTypeName, sWordLength, ...
    sSigned, sScalingSlope, sScalingBias, sScalingMin, sScalingMax, hTargetNode)
hResultTypeNode = mxx_xmltree('add_node', hTargetNode, 'fixedPoint');
mxx_xmltree('set_attribute', hResultTypeNode, 'wordLength', sWordLength);
mxx_xmltree('set_attribute', hResultTypeNode, 'simulinkTypeName', sTypeName);
mxx_xmltree('set_attribute', hResultTypeNode, 'isSigned', sSigned);
mxx_xmltree('set_attribute', hResultTypeNode, 'slope', sScalingSlope);
mxx_xmltree('set_attribute', hResultTypeNode, 'bias', sScalingBias);
mxx_xmltree('set_attribute', hResultTypeNode, 'min', sScalingMin);
mxx_xmltree('set_attribute', hResultTypeNode, 'max', sScalingMax);
end


%%
function i_addModelReferenceInformation(hSource, hTarget, ahModels, bUseSimulinkInfo)
% Create model reference information
if bUseSimulinkInfo
    hModelRef = mxx_xmltree('get_nodes', hSource, './ma:ModelReference[@kind="SL"]');
else
    hModelRef = mxx_xmltree('get_nodes', hSource, './ma:ModelReference[@kind="TL"]');
end
if ~isempty(hModelRef)
    mxx_xmltree('set_attribute', hTarget, 'physicalPath', mxx_xmltree('get_attribute', hModelRef, 'path'));
    sModel = mxx_xmltree('get_attribute', hModelRef, 'model');
    for nl = 1:length(ahModels)
        hModel = ahModels(nl);
        [~, file, suffix] = fileparts(mxx_xmltree('get_attribute', hModel, 'modelPath'));
        if strcmp(sModel, [file, suffix])
            mxx_xmltree('set_attribute', hTarget, 'modelRef', mxx_xmltree('get_attribute', hModel, 'modelID'));
            break;
        end
    end
end
end


%%
function varargout = i_typeInfo(sCmd, varargin)
persistent p_oTypeInfoMap;

switch sCmd
    case 'init'
        p_oTypeInfoMap = varargin{1};
        
    case 'get'
        sType = varargin{1};
        if p_oTypeInfoMap.isKey(sType)
            varargout{1} = p_oTypeInfoMap(sType);
        else
            varargout{1} = ep_sl_type_info_get(sType);
        end
        
    otherwise
        error('EP:INTERNAL:ERROR', 'Unknown command %s.', sCmd);
end
end

%%
function varargout = i_silTypeInfo(sCmd, varargin)
persistent p_oSilTypeInfoMap;

switch sCmd
    case 'init'
        p_oSilTypeInfoMap = i_extractSilEnumTypes(varargin{1});
    case 'get'
        sType = varargin{1};
        varargout{1} = p_oSilTypeInfoMap(sType);
    otherwise
        error('EP:INTERNAL:ERROR', 'Unknown command %s.', sCmd);
end
end

%%
function oSilTypeInfoMap = i_extractSilEnumTypes(hRootNode)
ahEnumTypes = mxx_xmltree('get_nodes', hRootNode, '/ma:ModelAnalysis/ma:EnumTypes/ma:EnumType');
oSilTypeInfoMap = containers.Map;
for i = 1:length(ahEnumTypes)
    sId = mxx_xmltree('get_attribute', ahEnumTypes(i), 'id');
    oSilTypeInfoMap(sId) = i_extractEnumType(ahEnumTypes(i));
end
end

%%
function stEnumType = i_extractEnumType(hEnumType)
ahElements = mxx_xmltree('get_nodes', hEnumType, './ma:EnumElement');
nElements = length(ahElements);
stEnumType = struct(...
    'sEvalType', mxx_xmltree('get_attribute', hEnumType, 'name'), ...
    'astEnum', repmat(struct('Key', '', 'Value', []), nElements, 1));
for i = 1:nElements
    hElement = ahElements(i);
    stEnumType.astEnum(i).Key = mxx_xmltree('get_attribute', hElement, 'name');
    stEnumType.astEnum(i).Value = sscanf(mxx_xmltree('get_attribute', hElement, 'value'), '%d');
end
end

%%
function sPath = i_delete_model_name_from_path(sPath)
if ~isempty(sPath)
    if any(sPath == '/')
        sPath = regexprep(sPath, '^([^/]|(//))*/', '');
    else
        sPath = '';
    end
end
end

%%
function sDoubleStr = i_double_to_str(dValue)
sDoubleStr = sprintf('%.16e',dValue);
end

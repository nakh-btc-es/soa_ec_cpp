function ep_legacy_ma_mapping_convert(xEnv, sModelAnalysis, sMappingResultFile)
% Extracts a mapping between different architectures based on a given model analysis (ModelAnalysis.dtd).
%
% function ep_legacy_ma_xml_conv_mapping_xml_conversion(xEnv, sModelAnalysis, sTlResultFile, sSlResultFile, ...
%                                                       sCResultFile, sMappingResultFile)
%
% INPUT                     DESCRIPTION
% - xEnv                    (object)        (NON-LEGACY!) Environment
% - sModelAnalysis          (string)        The absolute path to the ModelAnalysis.xml.(ModelAnalysis.dtd)
% - sTlArchFile             (string)        The absolute path to the TlArch.xml. (simulink_architecture.xsd)
% - sSlArchFile             (string)        The absolute path to the SlArch.xml. (targetlink_architecture.xsd)
% - sCArchFile              (string)        The absolute path to the CArch.xml. (ccode_architecture.xsd)
% - sMappingResultFile      (string)        The absolute path to the output Mapping.xml. (mapping.xsd)
%
% OUTPUT                    DESCRIPTION
% -                          -
% REMARKS
% $$$COPYRIGHT$$$-2014

%% internal
% $Author: author$
% $Date: date$
% $Revision: $
%%

% init
hModelAnalysis = [];
hMappings = [];
sOutputFile = sMappingResultFile;

try
    % Load model analysis and retrieve all subsystems
    hModelAnalysis = mxx_xmltree('load', sModelAnalysis);
    oCMappingPaths = i_get_code_identifiers(hModelAnalysis);
    
    ahSubNodes = mxx_xmltree('get_nodes', hModelAnalysis, '/ma:ModelAnalysis/ma:Subsystem');
    
    % Return if no sopes are available and no architectures can be mapped
    if (length(ahSubNodes) < 1)
        mxx_xmltree('clear', hModelAnalysis);
        return;
    end
    
    % check if sl model is available
    bSlArchAvailable = ~isempty(mxx_xmltree('get_attribute', ahSubNodes(1), 'slPath'));
    
    % check if c model is available
    bCArchAvailable = true;
    
    % create header and architecture nodes
    [hMappings, hArchitectureMapping, sTlArchId, sCArchId, sSlArchId] = ...
        i_create_header_and_architecture_nodes(ahSubNodes, bSlArchAvailable, bCArchAvailable);
    
    % create scope and interface mapping
    i_create_mappings_for_scopes(oCMappingPaths, ahSubNodes, hArchitectureMapping, sTlArchId, sCArchId, sSlArchId)
    
    % clean up
    mxx_xmltree('save', hMappings, sOutputFile);
    mxx_xmltree('clear', hMappings);
    mxx_xmltree('clear', hModelAnalysis);
catch exception
    % clean up after exception
    if ~ isempty(hModelAnalysis)
        mxx_xmltree('clear', hModelAnalysis);
    end
    if ~isempty(hMappings)
        mxx_xmltree('clear', hMappings);
    end
    xEnv.rethrowException(exception);
end
end


%***********************************************************************************************************************
% INTERNAL FUNCTION DEFINITION(S)
%***********************************************************************************************************************

%***********************************************************************************************************************
% Adds the header and the architecure nodes to the Mapping.xml
%
%   PARAMETER(S)    DESCRIPTION
%   - ahSubNodes        (array)   Array of available subsystems in the model analysis.
%   - bSlArchAvailable  (boolean) True, if a SL architecture is available.
%   - bCArchAvailable   (boolean) True, if a C architecture is available.
%   OUTPUT
%   - hMappings        (handle) Root node of the Mapping.xml
%   - hArchMapping     (handle) ArchitectureMapping node of the Mapping.xml
%   - sTlArchId        (string) Id of the Tl architecture
%   - sCArchId         (string) Id of the C architecture
%   - sSlArchId        (string) Id of the Sl architecture
%***********************************************************************************************************************
function [hMappings, hArchMapping, sTlArchId, sCArchId, sSlArchId] = ...
    i_create_header_and_architecture_nodes(ahSubNodes, bSlArchAvailable, bCArchAvailable)
sTlArchId = 'id0';
sCArchId = [];
sSlArchId = [];

hMappings = mxx_xmltree('create', 'Mappings');
hArchMapping = mxx_xmltree('add_node', hMappings, 'ArchitectureMapping');

% Add TL architecture node. Use the top level subsystem node as unique name for the architecture.
hTlArchitecture = mxx_xmltree('add_node', hArchMapping, 'Architecture');
mxx_xmltree('set_attribute', hTlArchitecture, 'id', sTlArchId);
sTlModelName = i_extract_model_name_from_path(mxx_xmltree(...
    'get_attribute', ahSubNodes(1), 'tlPath'));
mxx_xmltree('set_attribute', hTlArchitecture, 'name', sTlModelName);

% Add C architecture node. Use the top level subsystem node as unique name for the architecture.
if bCArchAvailable
    sCArchId = 'id1';
    hCArchitecture = mxx_xmltree('add_node', hArchMapping, 'Architecture');
    mxx_xmltree('set_attribute', hCArchitecture, 'id', sCArchId);
    mxx_xmltree('set_attribute', hCArchitecture, 'name', [sTlModelName, ' [C-Code]']);
end

% Add SL architecture node. Use the top level subsystem node as unique name for the architecture.
if bSlArchAvailable
    sSlArchId = 'id2';
    hSlArchitecture = mxx_xmltree('add_node', hArchMapping, 'Architecture');
    mxx_xmltree('set_attribute', hSlArchitecture, 'id', sSlArchId);
    mxx_xmltree('set_attribute', hSlArchitecture, 'name', i_extract_model_name_from_path(...
        mxx_xmltree('get_attribute', ahSubNodes(1), 'slPath')));
end
end


%***********************************************************************************************************************
% Adds the mappings for scopes to the Mapping.xml
%
%   PARAMETER(S)    DESCRIPTION
%   - hModelAnalysis  (handle) Handle of the loaded model analysis.
%   - ahSubNodes      (array)  Array of available subsystems in the model analysis.
%   - hArchMapping    (handle) ArchitectureMapping node of the Mapping.xml
%   - sTlArchId       (string) Id of the Tl architecture
%   - sCArchId        (string) Id of the C architecture
%   - sSlArchId       (string) Id of the Sl architecture
%   OUTPUT
%   -
%***********************************************************************************************************************
function i_create_mappings_for_scopes(oCMappingPaths, ahSubNodes, hArchitectureMapping, sTlArchId, sCArchId, sSlArchId)
for i=1:length(ahSubNodes)
    
    % Dummy scopes are not mapped
    if (~isempty(mxx_xmltree('get_attribute', ahSubNodes(i), 'isDummy')) ...
            && strcmp(mxx_xmltree('get_attribute', ahSubNodes(i), 'isDummy'),'yes'))
        if ~isempty(sSlArchId)
            hScopeMapping = mxx_xmltree('add_node', hArchitectureMapping, 'ScopeMapping');
            i_add_path(hScopeMapping, sTlArchId, mxx_xmltree('get_attribute', ahSubNodes(i), 'tlPath'));
            i_add_path(hScopeMapping, sSlArchId, mxx_xmltree('get_attribute', ahSubNodes(i), 'slPath'));
        end
        continue;
    end
    
    hScopeMapping = mxx_xmltree('add_node', hArchitectureMapping, 'ScopeMapping');
    i_add_path(hScopeMapping, sTlArchId, mxx_xmltree('get_attribute', ahSubNodes(i), 'tlPath'));
    i_add_path(hScopeMapping, sCArchId, oCMappingPaths.get(mxx_xmltree('get_attribute', ahSubNodes(i), 'id')));
    if ~isempty(sSlArchId)
        i_add_path(hScopeMapping, sSlArchId, mxx_xmltree('get_attribute', ahSubNodes(i), 'slPath'));
    end
    
    i_create_mappings_for_inputs_and_outputs_ports(oCMappingPaths, ahSubNodes(i), hScopeMapping, sTlArchId, sCArchId, sSlArchId)
    i_create_mappings_for_parameters(oCMappingPaths, ahSubNodes(i), hScopeMapping, sTlArchId, sCArchId, sSlArchId)
    i_create_mappings_for_locals(oCMappingPaths, ahSubNodes(i), hScopeMapping, sTlArchId, sCArchId, sSlArchId)
end
end

%***********************************************************************************************************************
% Adds the mappings for input and output ports to the Mapping.xml.
%
%   PARAMETER(S)    DESCRIPTION
%   - hSubNodes       (handle) Subsystem node of the model analysis.
%   - hScopeMapping   (handle) ScopeMapping node of the Mapping.xml
%   - sTlArchId       (string) Id of the Tl architecture
%   - sCArchId        (string) Id of the C architecture
%   - sSlArchId       (string) Id of the Sl architecture
%   OUTPUT
%   -
%***********************************************************************************************************************
function i_create_mappings_for_inputs_and_outputs_ports(oCMappingPaths,hSubNode, hScopeMapping, ...
    sTlArchId, sCArchId, sSlArchId)

%% inputs and outputs
ahInputPortNodes = mxx_xmltree('get_nodes', hSubNode, './ma:Interface/ma:Input/ma:Port');
ahOutputPortNodes = mxx_xmltree('get_nodes', hSubNode, './ma:Interface/ma:Output/ma:Port');
nNumberOfInputs = length(ahInputPortNodes);
ahPortNodes = [ahInputPortNodes', ahOutputPortNodes']';

for i=1:length(ahPortNodes)
    %% Handle different cases
    ahVarNodes = mxx_xmltree('get_nodes', ahPortNodes(i), './ma:Variable');
    nVarCount = length(ahVarNodes);
    sCompositeSig = mxx_xmltree('get_attribute', ahPortNodes(i), 'compositeSig');
    for j=1:nVarCount
        
        % Exclude dummy variables specified in the legacy code
        if (~isempty(mxx_xmltree('get_attribute', ahVarNodes(j), 'isDummy')) && ...
                strcmp(mxx_xmltree('get_attribute', ahVarNodes(j), 'isDummy'), 'yes'))
            continue;
        end
        
        hInterfaceObjectMapping = mxx_xmltree('add_node', hScopeMapping, 'InterfaceObjectMapping');
        if (i <= nNumberOfInputs)
            sKind = 'Input';
        else
            sKind = 'Output';
        end
        mxx_xmltree('set_attribute', hInterfaceObjectMapping, 'kind', sKind);
        
        % TL architecture
        sPath = i_extract_name_from_path(mxx_xmltree('get_attribute', ahPortNodes(i), 'tlPath'));
        i_add_path(hInterfaceObjectMapping, sTlArchId, sPath);
        
        % SL architecture
        if ~isempty(sSlArchId)
            sPath = i_extract_name_from_path(mxx_xmltree('get_attribute', ahPortNodes(i), 'slPath'));
            i_add_path(hInterfaceObjectMapping, sSlArchId, sPath);
        end
        
        % C-Architecture
        ahIfNodes = mxx_xmltree('get_nodes', ahVarNodes(j), './ma:ifName');
        sVarPath = oCMappingPaths.get(mxx_xmltree('get_attribute', ahVarNodes(j), 'varid'));
        if length(ahIfNodes) == 1
            sAccessPath = mxx_xmltree('get_attribute', ahIfNodes(1), 'accessPath');
        else
            sAccessPath = i_get_common_access_path(ahVarNodes(j));
        end
        i_add_path(hInterfaceObjectMapping, sCArchId, sVarPath);
        
        % SignalMapping
        i_create_mappings_for_signals(ahVarNodes(j), ahIfNodes, hInterfaceObjectMapping, sTlArchId, sCArchId, ...
            sSlArchId, sCompositeSig, sAccessPath)
    end
end
end


function sName = i_extract_name_from_path(sPath)
% Slashes in names are escaped by "//".
sName = regexprep(sPath, '(.)*[^/]/([^/])', '$2');
% Replacing escaped slashes in output.
sName = regexprep(sName, '//', '/');
end


%***********************************************************************************************************************
% Adds the mappings for parameters to the Mapping.xml.
%
%   PARAMETER(S)    DESCRIPTION
%   - hSubNodes       (array)  Subsystem node of the model analysis
%   - hScopeMapping   (handle) ScopeMapping node of the Mapping.xml
%   - sTlArchId       (string) Id of the Tl architecture
%   - sCArchId        (string) Id of the C architecture
%   - sSlArchId       (string) Id of the Sl architecture
%   OUTPUT
%   -
%***********************************************************************************************************************
function i_create_mappings_for_parameters(oCMappingPaths, hSubNode, hScopeMapping, sTlArchId, sCArchId, sSlArchId)
ahCalNodes = mxx_xmltree('get_nodes', hSubNode, './ma:Interface/ma:Input/ma:Calibration');
for i=1:length(ahCalNodes)
    
    ahVarNodes = mxx_xmltree('get_nodes', ahCalNodes(i), './ma:Variable');
    nVarCount = length(ahVarNodes);
    sCompositeSig = mxx_xmltree('get_attribute', ahCalNodes(i), 'compositeSig');
    for j=1:nVarCount
        
        % Exclude dummy variables specified in the legacy code
        if (~isempty(mxx_xmltree('get_attribute', ahVarNodes(j), 'isDummy')) && ...
                strcmp(mxx_xmltree('get_attribute', ahVarNodes(j), 'isDummy'), 'yes'))
            continue;
        end
        
        % Add IOMapping
        hInterfaceObjectMapping = mxx_xmltree('add_node', hScopeMapping, 'InterfaceObjectMapping');
        mxx_xmltree('set_attribute', hInterfaceObjectMapping, 'kind', 'Parameter');
        
        % TL architecture
        sBlockPath = mxx_xmltree('get_attribute', ahCalNodes(i), 'tlBlockPath');
        sName = mxx_xmltree('get_attribute', ahCalNodes(i), 'sfVariable');
        if (isempty(sName))
            sName = mxx_xmltree('get_attribute', ahCalNodes(i), 'name');
        end
        if (isempty(sName))
            sNamePrefix = i_extract_name_from_path(sBlockPath);
            sNameSuffix = mxx_xmltree('get_attribute', ahCalNodes(i), 'usage');
            sName =  [sNamePrefix ,'[', sNameSuffix, ']'];
        end
        sPath = [sBlockPath, '/', sName];
        
        i_add_path(hInterfaceObjectMapping, sTlArchId, sPath);
        
        % SL architecture
        if ~isempty(sSlArchId)
            sBlockPath = mxx_xmltree('get_attribute', ahCalNodes(i), 'slBlockPath');
            sName = mxx_xmltree('get_attribute', ahCalNodes(i), 'sfVariable');
            if (isempty(sName))
                sName = mxx_xmltree('get_attribute', ahCalNodes(i), 'name');
            end
            if (isempty(sName))
                sNamePrefix = i_extract_name_from_path(sBlockPath);
                sNameSuffix = mxx_xmltree('get_attribute', ahCalNodes(i), 'usage');
                sName =  [sNamePrefix ,'[', sNameSuffix, ']'];
            end
            sPath = [sBlockPath, '/', sName];
            i_add_path(hInterfaceObjectMapping, sSlArchId, sPath);
        end
        
        % C-Architecture
        ahIfNodes = mxx_xmltree('get_nodes', ahVarNodes(j), './ma:ifName');
        sVarPath = oCMappingPaths.get(mxx_xmltree('get_attribute', ahVarNodes(j), 'varid'));
        if length(ahIfNodes) == 1
            sAccessPath = mxx_xmltree('get_attribute', ahIfNodes(1), 'accessPath');
        else
            sAccessPath = i_get_common_access_path(ahVarNodes(j));
        end
        i_add_path(hInterfaceObjectMapping, sCArchId, sVarPath);
        
        % SignalMapping
        i_create_mappings_for_signals(ahVarNodes(j), ahIfNodes, hInterfaceObjectMapping, sTlArchId, sCArchId, sSlArchId, ...
            sCompositeSig, sAccessPath)
        
    end
end
end


%***********************************************************************************************************************
% Adds the mappings for locals to the Mapping.xml.
%
%   PARAMETER(S)    DESCRIPTION
%   - hSubNodes       (array)  Subsystem node of the model analysis.
%   - hScopeMapping   (handle) ScopeMapping node of the Mapping.xml
%   - sTlArchId       (string) Id of the Tl architecture
%   - sCArchId        (string) Id of the C architecture
%   - sSlArchId       (string) Id of the Sl architecture
%   OUTPUT
%   -
%***********************************************************************************************************************
function i_create_mappings_for_locals(oCMappingPaths, hSubNode, hScopeMapping, sTlArchId, sCArchId, sSlArchId)
ahDispNodes = mxx_xmltree('get_nodes', hSubNode, './ma:Interface/ma:Output/ma:Display');
for i=1:length(ahDispNodes)
    ahVarNodes = mxx_xmltree('get_nodes', ahDispNodes(i), './ma:Variable');
    nVarCount = length(ahVarNodes);
    sCompositeSig = mxx_xmltree('get_attribute', ahDispNodes(i), 'compositeSig');
    
    for j=1:nVarCount
        % Exclude dummy variables specified in the legacy code
        if (~isempty(mxx_xmltree('get_attribute', ahVarNodes(j), 'isDummy')) && ...
                strcmp(mxx_xmltree('get_attribute', ahVarNodes(j), 'isDummy'), 'yes'))
            continue;
        end
        
        hInterfaceObjectMapping = mxx_xmltree('add_node', hScopeMapping, 'InterfaceObjectMapping');
        mxx_xmltree('set_attribute', hInterfaceObjectMapping, 'kind', 'Local');
        
        % TL architecture
        sPath = mxx_xmltree('get_attribute', ahDispNodes(i),'tlBlockPath');
        sName = mxx_xmltree('get_attribute', ahDispNodes(i), 'sfVariable');
        if ~isempty(sName)
            sPath  = [sPath, '/', sName]; %#ok
        else
            sPortNum = mxx_xmltree('get_attribute', ahDispNodes(i), 'portNumber');
            if ~isempty(sPortNum)
                sPath  = [sPath, '(', sPortNum, ')']; %#ok
            end
        end
        i_add_path(hInterfaceObjectMapping, sTlArchId, sPath);
        
        % SL architecture
        if ~isempty(sSlArchId)
            sSlBlockPath = mxx_xmltree('get_attribute', ahDispNodes(i), 'slBlockPath');
            if ~isempty(sSlBlockPath)
                sSfVariable = mxx_xmltree('get_attribute', ahDispNodes(i), 'sfVariable');
                if (~isempty(sSfVariable))
                    sPath = [sSlBlockPath, '/', sSfVariable];
                else
                    sPath = sSlBlockPath;
                    sPortNum = mxx_xmltree('get_attribute', ahDispNodes(i), 'portNumber');
                    if ~isempty(sPortNum)
                        sPath  = [sPath, '(', sPortNum, ')']; %#ok
                    end
                end
                i_add_path(hInterfaceObjectMapping, sSlArchId, sPath);
            end
            % Note, if no condition is fulfilled, it seems that no SL information is available. In
            % this case it is assumed that the TL/SL Use Case is active. The missing Display must be reported
            % by the legacy ModelAnalysis.
        end
        
        % C-Architecture
        ahIfNodes = mxx_xmltree('get_nodes', ahVarNodes(j), './ma:ifName');
        sVarPath = oCMappingPaths.get(mxx_xmltree('get_attribute', ahVarNodes(j), 'varid'));
        if length(ahIfNodes) == 1
            sAccessPath = mxx_xmltree('get_attribute', ahIfNodes(1), 'accessPath');
        else
            sAccessPath = i_get_common_access_path(ahVarNodes(j));
        end
        i_add_path(hInterfaceObjectMapping, sCArchId, sVarPath);
        
        % SignalMapping
        i_create_mappings_for_signals(ahVarNodes(j),  ahIfNodes, hInterfaceObjectMapping, sTlArchId, sCArchId, sSlArchId, ...
            sCompositeSig, sAccessPath)
    end
end
end


%***********************************************************************************************************************
% Adds a SignalMapping to the Mapping.xml
%
%   PARAMETER(S)    DESCRIPTION
%   - hVarNode          (handle) Var node of the if nodes
%   - ahIfNodes         (array)  IF nodes of the model analysis.
%   - hScopeMapping     (handle) InterfaceObjectMapping node of the Mapping.xml
%   - sTlArchId         (string) Id of the Tl architecture
%   - sCArchId          (string) Id of the C architecture
%   - sSlArchId         (string) Id of the Sl architecture
%   - sCompositeSig     (string) Composite signal kind of the model analysis.
%   - sCommonAccessPath (string) the common accesss path for the ahIfNodes.
%   OUTPUT
%   -
%***********************************************************************************************************************
function i_create_mappings_for_signals(hVarNode, ahIfNodes, hIoMapping, sTlArchId, sCArchId, sSlArchId, sCompositeSig, ...
    sCommonAccessPath)

bIsSignalNameTheSame = 1;
bIsArrayWithoutGaps = 1;
bIsMatrixWithoutGaps = 1;
bHasAccessPaths = 0;
dWidth1 =  mxx_xmltree('get_attribute', hVarNode, 'width1');
dWidth2 =  mxx_xmltree('get_attribute', hVarNode, 'width2'); 

%% Check if it is an array or matrix without gaps and therefore no signal mapping is needed
for i=1:length(ahIfNodes)
    if (i == 1)
       sSignalPathTmp = mxx_xmltree('get_attribute', ahIfNodes(1), 'signalName');
       
       % Check if the signal name is used by different variables. In this
       % case the signal is not mapped to one single variable and therefore
       % the mapping must be done for each signal explicitly. 
       ahIfNodesGlobalPort = mxx_xmltree('get_nodes', hVarNode, ...
           ['./../*/ma:ifName[@signalName="', sSignalPathTmp, '"]']);
       if (length(ahIfNodesGlobalPort) > length(ahIfNodes))
           bIsSignalNameTheSame = 0;
           bIsArrayWithoutGaps = 0;
           bIsMatrixWithoutGaps = 0;
           break;
       end
       
    end
    sSignalPath = mxx_xmltree('get_attribute', ahIfNodes(i), 'signalName');
    sIndex1 = mxx_xmltree('get_attribute', ahIfNodes(i), 'index1');
    sIndex2 = mxx_xmltree('get_attribute', ahIfNodes(i), 'index2');
    % Check if the signal is always the same
    if ~isempty(sSignalPath) && ~isempty(sSignalPathTmp)
        if ~strcmp(sSignalPath, sSignalPathTmp)
            bIsSignalNameTheSame = 0;
        end
        sSignalPathTmp = sSignalPath;
    end
    
    % Check if all ifNodes have index1 and width1 defined
    if isempty(sIndex1) || isempty(dWidth1) || ~isempty(dWidth2)
        bIsArrayWithoutGaps = 0;
    end
    
    % Check if all ifNodes have index2 and width2 defined
    if isempty(sIndex2) || isempty(dWidth1) || isempty(dWidth2)
        bIsMatrixWithoutGaps = 0;
    end
    
    % Needed for the decision if a pointer access is necessary
    if ~isempty(mxx_xmltree('get_attribute', ahIfNodes(i), 'accessPath'))
        bHasAccessPaths = 1;
    end
end

%% check if variable is used as pointer
sAppendPointerAccessPath = '';
sVarName = mxx_xmltree('get_attribute', hVarNode, 'globalName');
hPointerType = mxx_xmltree('get_nodes', hVarNode, ...
    ['./../../../../*/*/ma:Arg[@ext_name="',sVarName, '" and @usage="ptr"]']);
% variable must be a pointer
% variable must be accessed directly and not the fields.
if ~isempty(hPointerType) && ~bHasAccessPaths
    sAppendPointerAccessPath = '->';
end

for i=1:length(ahIfNodes)
    
    % Add TL Signal
    sSignalPathSrc = mxx_xmltree('get_attribute', ahIfNodes(i), 'signalName');
    sIndex1 = mxx_xmltree('get_attribute', ahIfNodes(i), 'index1');
    sIndex2 = mxx_xmltree('get_attribute', ahIfNodes(i), 'index2');
    sSignalPath = '';
    if ~isempty(sCompositeSig) && ~strcmp(sCompositeSig, 'mux') && ~isempty(sSignalPathSrc)
        sSignalPath = ['.', sSignalPathSrc];
    end
    if (~(bIsArrayWithoutGaps || bIsMatrixWithoutGaps) || ~bIsSignalNameTheSame)
        if ~isempty(sIndex1) && isempty(sIndex2)
            sSignalPath = [sSignalPath, '(', sIndex1 ,')']; %#ok
        end
        if ~isempty(sIndex1) && ~isempty(sIndex2)
            sSignalPath = [sSignalPath, '(', sIndex1, ',' , sIndex2, ')']; %#ok
        end
    end
    sTlSignalPath = sSignalPath;
    
    % Add SL Signal
    sSlSignalPath = '';
    if ~isempty(sSlArchId)
        sSignalPath = '';
        if ~isempty(sCompositeSig) && ~strcmp(sCompositeSig, 'mux') && ~isempty(sSignalPathSrc)
            sSignalPath = ['.', sSignalPathSrc];
        end
        sIndex1 = mxx_xmltree('get_attribute', ahIfNodes(i), 'index1');
        sIndex2 = mxx_xmltree('get_attribute', ahIfNodes(i), 'index2');
        if (~(bIsArrayWithoutGaps || bIsMatrixWithoutGaps) || ~bIsSignalNameTheSame)
            if ~isempty(sIndex1) && isempty(sIndex2)
                sSignalPath = [sSignalPath, '(', sIndex1 ,')']; %#ok
            end
            if ~isempty(sIndex1) && ~isempty(sIndex2)
                sSignalPath = [sSignalPath, '(', sIndex1, ')(' , sIndex2, ')']; %#ok
            end
        end
        sSlSignalPath = sSignalPath;
    end
    
    % Add C Signal
    if length(ahIfNodes) > 1 && (~(bIsArrayWithoutGaps || bIsMatrixWithoutGaps) || ~bIsSignalNameTheSame)
        sCurrentAccessPath = mxx_xmltree('get_attribute', ahIfNodes(i), 'accessPath');
        sCSignalPath = ['', sCurrentAccessPath(length(sCommonAccessPath)+1:end)];
    else
        sCSignalPath = '';
    end
    
    if any(~cellfun('isempty', {sTlSignalPath, sSlSignalPath, sCSignalPath}))
        hSignalMapping = mxx_xmltree('add_node', hIoMapping, 'SignalMapping');
        i_add_path(hSignalMapping, sTlArchId, sTlSignalPath);
        if ~isempty(sSlArchId)
            i_add_path(hSignalMapping, sSlArchId, sSlSignalPath);
        end
        i_add_path(hSignalMapping, sCArchId, sCSignalPath);
    end
    
    %% In this case the mapping is complete
    if ((bIsArrayWithoutGaps || bIsMatrixWithoutGaps) || bIsSignalNameTheSame)
        break;
    end
end
end


%***********************************************************************************************************************
% Adds a path node to the Mapping.xml.
%
%   PARAMETER(S)    DESCRIPTION
%   - hParent         (handle) The path node is added to the given parent node
%   - sArchId         (String) The 'refId' attribute for the path node.
%   - sPath           (string) The 'path' attribute for path node.
%   OUTPUT
%   -
%***********************************************************************************************************************
function i_add_path(hParent, sArchId , sPath)
path = mxx_xmltree('add_node', hParent, 'Path');
mxx_xmltree('set_attribute', path, 'refId', sArchId);
mxx_xmltree('set_attribute', path, 'path', sPath);
end



%%
function [oHash, sRootStepFct] = i_get_code_identifiers(hMADoc)
oHash = java.util.HashMap;
sRootStepFct = '';

ahSubsystems = i_get_root_subsystems(hMADoc);
for i = 1:length(ahSubsystems)
    hSubsys = ahSubsystems(i);
    if isempty(sRootStepFct)
       sRootStepFct = mxx_xmltree('get_attribute', hSubsys, 'stepFct');
    end
    i_handle_subsystem(oHash, [], 1, hSubsys);
end
end


%%
function ahRootSubsystem = i_get_root_subsystems(hMADoc)
ahRootSubsystem = [];
ahSubsystem = mxx_xmltree('get_nodes', hMADoc, '/ma:ModelAnalysis/ma:Subsystem');
for i = 1:length(ahSubsystem)
    hParent = mxx_xmltree('get_nodes', ahSubsystem(i), './ma:Parents');
    if isempty(hParent)
        % Closed loop case. Ignore dummy subsystems completely.
        sDummy = mxx_xmltree('get_attribute',ahSubsystem(i), 'isDummy');
        if (~isempty(sDummy) && strcmp(sDummy, 'yes'))
            ahRootSubsystem = i_get_children_subsystems(ahSubsystem(i));
        else % Normal case.
            if isempty(ahRootSubsystem)
                ahRootSubsystem = ahSubsystem(i);
            else
                ahRootSubsystem(end+1) = ahSubsystem(i); %#ok
            end
        end
    end
end
end


%%
function i_handle_subsystem(oHash, hParentSubsys, nCounter, hSubsys)

oCounterHash = java.util.HashMap;
sPathPrefix = '';
if ~isempty(hParentSubsys)
    sParentID = mxx_xmltree('get_attribute', hParentSubsys, 'id');
    sPathPrefix = [oHash.get(sParentID), '/'];
end

sId = mxx_xmltree('get_attribute', hSubsys, 'id');
sStepFct = mxx_xmltree('get_attribute', hSubsys, 'stepFct');
sModule = mxx_xmltree('get_attribute', hSubsys, 'module');

sLocalPath = [sPathPrefix, sModule, ':' int2str(nCounter), ':', sStepFct];
oHash.put(sId, sLocalPath);

oVarArgMap = i_get_var_arg_mapping(hSubsys);

ahVariables = mxx_xmltree('get_nodes', hSubsys, './ma:Interface/*/*/ma:Variable');
for k = 1:length(ahVariables)
    hVariable = ahVariables(k);
    
    sVarID = mxx_xmltree('get_attribute', hVariable, 'varid');
    sVarIdentifier = i_get_var_identifier(hVariable);
    if oVarArgMap.isKey(sVarIdentifier)
        sVarIdentifier = oVarArgMap(sVarIdentifier);
    end
    sVarIdentifier = i_add_access_path(hVariable, sVarIdentifier);
    oHash.put(sVarID, sVarIdentifier);
end


ahChildren = i_get_children_subsystems(hSubsys);
for i = 1:length(ahChildren)
    sChildModule = mxx_xmltree('get_attribute', ahChildren(i), 'module');
    sChildStep = mxx_xmltree('get_attribute', ahChildren(i), 'stepFct');
    sHashKey = [sChildModule, ':', sChildStep];
    
    nChildCounter = oCounterHash.get(sHashKey);
    if isempty(nChildCounter)
        % we are handling the first call on this level
        nChildCounter = 1;
    else
        % there was already a call on this level, so increase the counter.
        nChildCounter = nChildCounter + 1;
    end
    
    % save the counter for subsequent loop executions.
    oCounterHash.put(sHashKey, nChildCounter);
    i_handle_subsystem(oHash, hSubsys, nChildCounter, ahChildren(i));
end
end


%%
function sIdentifier = i_add_access_path(hVariable, sIdentifier)
ahIfNames = mxx_xmltree('get_nodes', hVariable, './ma:ifName');
if (length(ahIfNames) == 1)
    sAccessPath = mxx_xmltree('get_attribute', ahIfNames(1), 'accessPath');
else
    sAccessPath = i_get_common_access_path_prefix(ahIfNames);
end
if ~isempty(sAccessPath)
    sIdentifier = [sIdentifier, sAccessPath];
end
end


%%
function ahChildren = i_get_children_subsystems(hSubsys)
ahChildren = [];
ahSubsysRef = mxx_xmltree('get_nodes', hSubsys, './ma:Children/ma:SubsystemRef');
for i = 1:length(ahSubsysRef)
    sRefID = mxx_xmltree('get_attribute', ahSubsysRef(i), 'refID');
    hChildSubsys = mxx_xmltree('get_nodes', hSubsys, sprintf('/ma:ModelAnalysis/ma:Subsystem[@id="%s"]', sRefID));
    if isempty(ahChildren)
        ahChildren = hChildSubsys;
    else
        ahChildren(end+1) = hChildSubsys; %#ok
    end
end
end


%%
function oMap = i_get_var_arg_mapping(hSubsys)
oMap = containers.Map;
astRes = mxx_xmltree('get_attributes', hSubsys, './ma:Signature/ma:Args/ma:Arg', 'ext_name', 'name');
for i = 1:length(astRes)
    oMap(astRes(i).ext_name) = astRes(i).name;
end
end


%%
function sIdentifier = i_get_var_identifier(hVariable)
% note: sParamNr is either '0' or '-1'
sParamNr = mxx_xmltree('get_attribute', hVariable, 'paramNr');
if (sParamNr == '0')
    sIdentifier = mxx_xmltree('get_attribute', hVariable, 'globalName');    
else
    % case: sParamNr == '-1'
    stSub = mxx_xmltree('get_attributes', hVariable, '../../../..', 'stepFct');
    sIdentifier = [stSub.stepFct, ':return'];
end
end


%%
function sAP = i_get_common_access_path(hVariable)

sAP = '';
ahIfName = mxx_xmltree('get_nodes', hVariable, './ma:ifName');
if ~isempty(ahIfName)
    sAP = mxx_xmltree('get_attribute', ahIfName(1), 'accessPath');
end
for i=2:length(ahIfName)
    sAP_tmp = mxx_xmltree('get_attribute', ahIfName(i), 'accessPath');
    sAP = i_get_max_common_prefix(sAP, sAP_tmp);
end

% with this algorithm, we need to remove opening brackets, which might be
% left at the end of the accesspath.
if ~isempty(sAP) && sAP(length(sAP)) == '['
    sAP = sAP(1:length(sAP)-1);
end
end


%%
function sMaxPrefix = i_get_max_common_prefix(s1, s2)
nMinLength = length(s1);
if nMinLength > length(s2)
    nMinLength = length(s2);
end
nCommon = 0;
for i=1:nMinLength
    if s1(i) == s2(i)
        nCommon = nCommon + 1;
    else
        break;
    end
end
sMaxPrefix = s1(1:nCommon);
end


%%
function sName = i_extract_model_name_from_path(sPath)
% Slashes in names are escaped by "//".
sName = regexprep(sPath, '([^/])/[^/](.)*', '$1');
% Replacing escaped slashes in output.
sName = regexprep(sName, '//', '/');
end


%%
function sCommonAccessPath = i_get_common_access_path_prefix(ahIfNames)
% **************************************************************
% TODO use i_tokenize to compare on token not on character level
% If not used correctly that unexpected result would occur:
% "myStruct.field_a" \
% "myStruct.field_b" -> "myStruct.field_"
% "myStruct.field_c" /
% **************************************************************
sCommonAccessPath = mxx_xmltree('get_attribute', ahIfNames(1), 'accessPath');
for i=2:length(ahIfNames)
    sAccessPath = mxx_xmltree('get_attribute', ahIfNames(i), 'accessPath');
    if ~strncmp(sCommonAccessPath, sAccessPath, length(sCommonAccessPath))
        for j=1:length(sAccessPath)
            if ~strcmp(sAccessPath(j), sCommonAccessPath(j))
                break;
            end
        end
        sCommonAccessPath = sCommonAccessPath(1:j-1);
        if strcmp('[',sCommonAccessPath(end)) || strcmp('.',sCommonAccessPath(end))
            sCommonAccessPath = sCommonAccessPath(1:end-1);
        end
    end
    if isempty(sCommonAccessPath)
        break;
    end
end
end

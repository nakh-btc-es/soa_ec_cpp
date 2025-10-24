function ep_extraction_model_to_harness(sExtractionXml, sInHarnessXml, sOutHarnessXml, bIsTL, bDebug)

% This function extract the relevant information (from the Extraction.xml) needed to generate the MIL Harness
%
% function ep_extraction_model_to_harness(sExtractionXml, sInHarnessXml, sOutHarnessXml, bIsTL)
%
%   INPUT                  TYPE                DESCRIPTION
%    - sExtractionXml      (string)            Path to the extraction.xml from which the In/OutHarness Xmls are generated
%    - sInHarnessXml       (string)            Path to the where the generated inHarness.xml is generated
%    - sOutHarnessXml      (string)            Path to the where the generated outHarness.xml is generated
%    - bIsTL               (Boolean)           True: for TargetLink use-case, False: for Simulink UC
%                                              default: false
%
%   OUTPUT
%

%%
if (nargin < 2)
    sInHarnessXml = fullfile(pwd, 'harness_in.xml');
end
if (nargin < 3)
    sOutHarnessXml = fullfile(pwd, 'harness_out.xml');
end
if (nargin < 4)
    bIsTL = true;
end
if (nargin < 5)
    bDebug = false;
end


%%
[hExtractionRoot, oOnCleanupCloseTestDoc] = i_openXml(sExtractionXml); %#ok<ASGLU>

i_generateInHarnessXml(sInHarnessXml, hExtractionRoot, bIsTL);
i_generateOutHarnessXml(sOutHarnessXml, hExtractionRoot, bIsTL, bDebug);
end



%%
function i_cloneTypesNodesIntoHarness(hExtractionRoot, hHarness)
hTypes =  mxx_xmltree('get_nodes', hExtractionRoot, '/ExtractionModel/Types');
if isempty(hTypes)
    return;
end
hTypesInHarness = mxx_xmltree('add_node', hHarness, 'Types');

ahBusTypes = mxx_xmltree('get_nodes', hTypes, 'BusType');
if ~isempty(ahBusTypes)
    i_cloneBusNode(ahBusTypes, hTypesInHarness);
end

ahEnumTypes = mxx_xmltree('get_nodes', hTypes, 'EnumType');
if ~isempty(ahEnumTypes)
    i_cloneEnumNode(ahEnumTypes, hTypesInHarness);
end

ahAliasTypes = mxx_xmltree('get_nodes', hTypes, 'AliasType');
if ~isempty(ahAliasTypes)
    i_cloneAliasNode(ahAliasTypes, hTypesInHarness);
end
end


%%
function i_cloneBusNode(ahBusTypes, hTypesInHarness)
for i = 1: length(ahBusTypes)
    hBusTypeInHarness = mxx_xmltree('add_node', hTypesInHarness, 'BusType');
    sBusName = mxx_xmltree('get_attribute', ahBusTypes(i), 'name');
    mxx_xmltree('set_attribute', hBusTypeInHarness , 'name', sBusName);
    
    sBusIsVirtual = mxx_xmltree('get_attribute', ahBusTypes(i), 'virtual');
    mxx_xmltree('set_attribute', hBusTypeInHarness , 'virtual', sBusIsVirtual);
    ahComps = mxx_xmltree('get_nodes', ahBusTypes(i), 'Comp');
    for j = 1: length(ahComps)
        hCompInHarness = mxx_xmltree('add_node', hBusTypeInHarness, 'Comp');
        sCompName = mxx_xmltree('get_attribute', ahComps(j), 'name');
        mxx_xmltree('set_attribute', hCompInHarness , 'name', sCompName);
        sCompType = mxx_xmltree('get_attribute', ahComps(j), 'type');
        mxx_xmltree('set_attribute', hCompInHarness , 'type', sCompType);
        sCompWidth =  mxx_xmltree('get_attribute', ahComps(j), 'width');
        if ~isempty(sCompWidth)
            mxx_xmltree('set_attribute', hCompInHarness , 'width', sCompWidth);
        end
        sCompDim1 = mxx_xmltree('get_attribute', ahComps(j), 'dim1');
        if ~isempty(sCompDim1)
            mxx_xmltree('set_attribute', hCompInHarness , 'dim1', sCompDim1);
        end
        sCompDim2 = mxx_xmltree('get_attribute', ahComps(j), 'dim2');
        if ~isempty(sCompDim2)
            mxx_xmltree('set_attribute', hCompInHarness , 'dim2', sCompDim2);
        end
    end
end
end


%%
function i_cloneEnumNode(ahEnumTypes, hTypesInHarness)
for k = 1:numel(ahEnumTypes)
    hEnumType = mxx_xmltree('add_node', hTypesInHarness, 'EnumType');
    sName = mxx_xmltree('get_attribute', ahEnumTypes(k), 'name');
    mxx_xmltree('set_attribute', hEnumType, 'name',  sName);
    ahEnumElems = mxx_xmltree('get_nodes',  ahEnumTypes(k), 'EnumValue');
    for i = 1:numel(ahEnumElems)
        hEnumValue = mxx_xmltree('add_node', hEnumType, 'EnumValue');
        sNameEnumElem = mxx_xmltree('get_attribute', ahEnumElems(i), 'name');
        sOrdinalEnumElem = mxx_xmltree('get_attribute', ahEnumElems(i), 'ordinal');
        mxx_xmltree('set_attribute', hEnumValue, 'name', sNameEnumElem);
        mxx_xmltree('set_attribute', hEnumValue, 'ordinal', sOrdinalEnumElem);
    end
end
end


%%
function i_cloneAliasNode(ahAliasTypes, hTypesInHarness)
for i = 1: length(ahAliasTypes)
    hAliasTypeInHarness = mxx_xmltree('add_node', hTypesInHarness, 'AliasType');
    sName = mxx_xmltree('get_attribute', ahAliasTypes(i), 'name');
    sType = mxx_xmltree('get_attribute', ahAliasTypes(i), 'type');
    mxx_xmltree('set_attribute',  hAliasTypeInHarness, 'name', sName);
    mxx_xmltree('set_attribute',  hAliasTypeInHarness, 'type', sType);
end
end


%%
function i_generateInHarnessXml(sInHarnessXml, hExtractionRoot, bIsTL)
[hInHarness, oOnCleanupCloseDoc] = i_createXml('SFunction'); %#ok<ASGLU> onCleanup object

% hard-coded clone of <types> nodes to harness files
i_cloneTypesNodesIntoHarness(hExtractionRoot, hInHarness);

% generate the top-level node "Outputs" with sampleTimes
hExtractionRootScope = mxx_xmltree('get_nodes', hExtractionRoot, '/ExtractionModel/Scope');
sSampleTime = mxx_xmltree('get_attribute', hExtractionRootScope, 'sampleTime');
hOutports = mxx_xmltree('add_node', hInHarness, 'Outports');
mxx_xmltree('set_attribute', hOutports, 'sampleTime',  sSampleTime);

% for every input in extractionmodel add an "Output" node with needed properties to the top-level node
i_handleInPorts(hExtractionRootScope, hOutports, bIsTL);

mxx_xmltree('save', hInHarness, sInHarnessXml);
end



%%
function hOutHarness = i_generateOutHarnessXml(sOutHarnessXml, hExtractionRoot, bIsTL, bIsDebug)
[hOutHarness, oOnCleanupCloseDoc] = i_createXml('SFunction'); %#ok<ASGLU> onCleanup object

% hard-coded clone of <types> nodes to harness files
i_cloneTypesNodesIntoHarness(hExtractionRoot, hOutHarness);

% generate the top-level node "Inports"
hInports = mxx_xmltree('add_node', hOutHarness, 'Inports');
if bIsDebug
    mxx_xmltree('set_attribute', hInports, 'debug', 'true');
end

% for every Output in extraction model generate an input node in the harness
hExtractionRootScope = mxx_xmltree('get_nodes', hExtractionRoot, '/ExtractionModel/Scope');
i_handleOutPorts(hExtractionRootScope, hInports, bIsTL);

mxx_xmltree('save', hOutHarness, sOutHarnessXml);
end


%%
function i_handleInPorts(hExtractionRootScope, hOutports, bIsTL)
nVariablesCount = 0;

ahInPorts = mxx_xmltree('get_nodes', hExtractionRootScope, 'InPort');
for i = 1:length(ahInPorts)
    [stPortProps, nVariablesCount] = i_getPortProps(ahInPorts(i), nVariablesCount, false);
    i_addOutportToHarness(hOutports, stPortProps, bIsTL, '');
end

ahDataStoreRead = mxx_xmltree('get_nodes', hExtractionRootScope, 'DataStoreRead');
for i = 1:length(ahDataStoreRead)
    [stPortProps, nVariablesCount] = i_getPortProps(ahDataStoreRead(i), nVariablesCount, bIsTL);
    if bIsTL && stPortProps.isBus
        i_addBusPortToHarness(hOutports, stPortProps, 'Outport', 'DataStoreRead');
    else
        i_addOutportToHarness(hOutports, stPortProps, bIsTL, 'DataStoreRead');
    end
end
end


%%
function i_handleOutPorts(hExtractionRootScope, hInports, bIsTL)
nVariablesCount = 0;

ahOutPorts = mxx_xmltree('get_nodes', hExtractionRootScope, 'OutPort');
for i = 1:length(ahOutPorts)
    [stPortProps, nVariablesCount] = i_getPortProps(ahOutPorts(i), nVariablesCount, false);
    i_addInportToHarness(hInports, stPortProps, bIsTL, '');
end

ahDataStoreWrite = mxx_xmltree('get_nodes', hExtractionRootScope, 'DataStoreWrite');
for i = 1:length(ahDataStoreWrite)
    [stPortProps, nVariablesCount] = i_getPortProps(ahDataStoreWrite(i), nVariablesCount, bIsTL);
    if bIsTL && stPortProps.isBus
        i_addBusPortToHarness(hInports, stPortProps, 'Inport', 'DataStoreWrite');
    else
        i_addInportToHarness(hInports, stPortProps, bIsTL, 'DataStoreWrite');
    end
end
end


%%
function [stPortProps, nVariablesCount] = i_getPortProps(hPort, nVariablesCount, bSkipForBuses)
stIfName = struct( ...
    'identifier',  '', ...
    'displayName', '');

stPrototypeVar = struct(...
    'sPortNr',        '', ...   % for TL UC
    'sSignalName',    '', ...
    'sType',          '', ...
    'sWidth',         '', ...
    'sDim1',          '', ...
    'sDim2',          '', ...
    'astIfNames',     stIfName);

stPortProps = struct( ...
    'sPortNr',        '', ...
    'sSignalName',    '', ...
    'sType',          '', ...
    'sBaseType',      '', ...
    'sWidth',         '', ...
    'sDim1',          '', ...
    'sDim2',          '', ...
    'isMessage',      '', ...
    'astVariables',   stPrototypeVar);

stPortProps.sSignalName = mxx_xmltree('get_attribute', hPort, 'signalName');
stPortProps.isMessage = mxx_xmltree('get_attribute', hPort, 'isMessage');
stPortProps.isBus = strcmp('bus', mxx_xmltree('get_attribute', hPort, 'compositeSig'));
if stPortProps.isBus && bSkipForBuses
    nVariablesCount = nVariablesCount + 1;
    stPortProps.sPortNr = num2str(nVariablesCount);
else
    stPortProps.sPortNr = mxx_xmltree('get_attribute', hPort, 'portNumber');
end

% get Type of port (bus|basic types)
stPortProps.sType      = mxx_xmltree('get_attribute', hPort, 'type');
stPortProps.sBaseType  = mxx_xmltree('get_attribute', hPort, 'baseType');
stPortProps.sWidth     = mxx_xmltree('get_attribute', hPort, 'width');
stPortProps.sDim1      = mxx_xmltree('get_attribute', hPort, 'dim1');
stPortProps.sDim2      = mxx_xmltree('get_attribute', hPort, 'dim2');

% get the needed infos about the variables
ahVariables = mxx_xmltree('get_nodes', hPort , 'Variable');

for i = 1:length(ahVariables)
    hVar = ahVariables(i);
    if ~(stPortProps.isBus && bSkipForBuses)
        nVariablesCount = nVariablesCount + 1;
    end
    
    stPortProps.astVariables(i).sSignalName = ''; % on variable level never use the signal name (see EP-2443)!
    stPortProps.astVariables(i).sPortNr = int2str(nVariablesCount);  % for TL UC: generate for every variable a port id
    stPortProps.astVariables(i).sType = mxx_xmltree('get_attribute', hVar, 'type');
    stPortProps.astVariables(i).sBaseType = mxx_xmltree('get_attribute', hVar, 'baseType');
    
    stPortProps.astVariables(i).sWidth = mxx_xmltree('get_attribute', hVar, 'width');
    stPortProps.astVariables(i).sDim1 = mxx_xmltree('get_attribute', hVar, 'dim1');
    stPortProps.astVariables(i).sDim2 = mxx_xmltree('get_attribute', hVar, 'dim2');
    
    stPortProps.astVariables(i).astIfNames = ...
        mxx_xmltree('get_attributes', hVar, './ifName', 'identifier', 'displayName');
end
end


%%
function hInport = i_addInportToHarness(hParentNode, stPortProps, bIsTL, sDataStoreKind)
if (bIsTL)
    % In TL UC: generate a port for every <Variable> in extraction model
    i_generatePortsFromVariables(hParentNode, stPortProps, 'Inport', sDataStoreKind);
    
else
    % Simulink UC: generate a <Out/Inport> for every <Out/InPort>
    hInport = mxx_xmltree('add_node', hParentNode, 'Inport');
    if ~isempty(sDataStoreKind)
        mxx_xmltree('set_attribute', hInport, 'kind', sDataStoreKind);
    end
    
    i_generatePortAttributes(hInport, stPortProps);
    i_generateScalarRefs(hInport, stPortProps);
end
end


%%
function hOutport = i_addOutportToHarness(hParentNode, stPortProps, bIsTL, sDataStoreKind)
if (bIsTL)
    % In TL UC: generate a port for every <Variable> in extraction model
    i_generatePortsFromVariables(hParentNode, stPortProps, 'Outport', sDataStoreKind);
    
else
    % Simulink UC: generate a <Out/Inport> for every <Out/InPort>
    hOutport = mxx_xmltree('add_node', hParentNode, 'Outport');
    if ~isempty(sDataStoreKind)
        mxx_xmltree('set_attribute', hOutport, 'kind', sDataStoreKind);
    end
    
    i_generatePortAttributes(hOutport, stPortProps);
    i_generateScalarRefs(hOutport, stPortProps);
end
end

%%
function hPort = i_addBusPortToHarness(hParentNode, stPortProps, sPortType, sDataStoreKind)
hPort = mxx_xmltree('add_node', hParentNode, sPortType);
if ~isempty(sDataStoreKind)
    mxx_xmltree('set_attribute', hPort, 'kind', sDataStoreKind);
end

i_generatePortAttributes(hPort, stPortProps);

hScalarRefs = mxx_xmltree('add_node', hPort, 'ScalarRefs');
for i = 1:length(stPortProps.astVariables)
    astIfNames = stPortProps.astVariables(i).astIfNames;
    for j = 1:length(astIfNames)
        hScalarRef = mxx_xmltree('add_node', hScalarRefs, 'ScalarRef');
        stIfName = astIfNames(j);
        sDisplayName = stIfName.displayName;
        if ~isempty(sDisplayName)
            mxx_xmltree('set_attribute', hScalarRef, 'displayName', sDisplayName);
        end
        mxx_xmltree('set_content', hScalarRef, stIfName.identifier);
    end
end
end

%%
% For the TL harness
% sPortType = 'Inport'|'Outport'
function i_generatePortsFromVariables(hParentNode, stPortProps, sPortType, sDataStoreKind)
for i = 1:length(stPortProps.astVariables)
    hPort = mxx_xmltree('add_node', hParentNode, sPortType);
    if ~isempty(sDataStoreKind)
        mxx_xmltree('set_attribute', hPort, 'kind', sDataStoreKind);
    end
    
    i_generatePortAttributes(hPort, stPortProps.astVariables(i));
    
    astIfNames = stPortProps.astVariables(i).astIfNames;
    hScalarRefs = mxx_xmltree('add_node', hPort, 'ScalarRefs');
    for j = 1:length(astIfNames)
        stIfName = astIfNames(j);
        
        hScalarRef = mxx_xmltree('add_node', hScalarRefs, 'ScalarRef');
        sDisplayName = stIfName.displayName;
        if ~isempty(sDisplayName)
            mxx_xmltree('set_attribute', hScalarRef, 'displayName', sDisplayName);
        end
        mxx_xmltree('set_content', hScalarRef, stIfName.identifier);
    end
end
end


%%
function i_generatePortAttributes(hPort, stPortProps)
mxx_xmltree('set_attribute', hPort, 'portNr', stPortProps.sPortNr);
if ~isempty(stPortProps.sSignalName)
    mxx_xmltree('set_attribute', hPort, 'signalName', stPortProps.sSignalName);
end
if ~isempty(stPortProps.sType)
    mxx_xmltree('set_attribute', hPort, 'type', stPortProps.sType);
end
if ~isempty(stPortProps.sBaseType)
    % The Type of an UNSUPPORTED_DATATYPE is normally null
    % Nevertheless for TL Adaptive Autosar we support UINT64 bit outputs
    % and this implies that for the TL MIL simulation a type is requested.
    % The original model type is stored for this usecase into
    % unsupportedBaseType and this is set only for TL AAR and for
    % int64/uint64 bit outputs.
    mxx_xmltree('set_attribute', hPort, 'type', stPortProps.sBaseType);
end
if isfield(stPortProps,'isMessage') && ~isempty(stPortProps.isMessage)
    mxx_xmltree('set_attribute', hPort, 'isMessage', stPortProps.isMessage);
end
if isempty(stPortProps.sWidth)
    if ~isempty(stPortProps.sDim1) && ~isempty(stPortProps.sDim2)
        mxx_xmltree('set_attribute', hPort, 'dim1', stPortProps.sDim1);
        mxx_xmltree('set_attribute', hPort, 'dim2', stPortProps.sDim2);
    end
else
    mxx_xmltree('set_attribute', hPort, 'width', stPortProps.sWidth);
end
end


%%
function i_generateScalarRefs(hPort, stPortProps)
hScalarRefs = mxx_xmltree('add_node', hPort, 'ScalarRefs');
for i = 1:length(stPortProps.astVariables)
    
    astIfNames = stPortProps.astVariables(i).astIfNames;
    for j = 1:length(astIfNames)
        stIfName = astIfNames(j);
        
        hScalarRef = mxx_xmltree('add_node', hScalarRefs, 'ScalarRef');
        sDisplayName = stIfName.displayName;
        if ~isempty(sDisplayName)
            mxx_xmltree('set_attribute', hScalarRef, 'displayName', sDisplayName);
        end
        mxx_xmltree('set_content', hScalarRef, stIfName.identifier);
    end
end
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_createXml(sRootName)
sMdfDialect = ep_core_mdf('GetPreferredDialect');
hRoot = mxx_xmltree('create', sRootName);
mxx_xmltree('set_attribute', hRoot, 'mdfDialect', sMdfDialect);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end

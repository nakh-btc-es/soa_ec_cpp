function [sBusInitScriptName, astBusInfo, bVirtualBusCreationFallback] = ep_sim_harness_prepare_bus_info(stSrcModelInfo, sHarnessModelFileIn, ...
    sHarnessModelFileOut, sExtractionModelFile)
% This function creates for each virtual bus a coresponding bus object. At
% the same time it updates the harness model xml with the new created info
% This all is needed for the further usage in the s-functions
%
%%  INPUT              DESCRIPTION
%
%   stSrcModelInfo          (Struct)     Information about the source
%                                        model.
%
%   sHarnessModelFileIn     (String)     Path of the harnessIn model xml
%
%   sHarnessModelFileOut    (String)     Path of the harnessOut model xml
%
%
%%   OUTPUT              DESCRIPTION
%
%   sBusInitScriptName      (String)              Path to the bus init script
%
%   astBusInfo              (Array of struct)     Structure containing bus information


%%
sSubsysSrcModel = stSrcModelInfo.sSubsysPathPhysical;

oDesignData = i_getSLDDDesignDataSection(stSrcModelInfo.hModel);

[sBusInitScriptName, astBusInfo, bVirtualBusCreationFallback] = i_createBusInformation( ...
    sHarnessModelFileIn, sHarnessModelFileOut, sSubsysSrcModel, sExtractionModelFile, oDesignData);
end


%%
function oDesignData = i_getSLDDDesignDataSection(hModel)
sDDName = get_param(hModel, 'DataDictionary');
if ~isempty(sDDName)
    oDD = Simulink.data.dictionary.open(sDDName);
    oDesignData = getSection(oDD, 'Design Data');
else
    oDesignData = [];
end
end


%%
function [sBusObjInitFileName, astBusInfo, bVirtualBusCreationFallback] = i_createBusInformation(sHarnessModelFileIn, sHarnessModelFileOut, ...
    sSubsysSrcModel, sExtractionModelFile, oDesignData)
hHarnessIn = mxx_xmltree('load', sHarnessModelFileIn);
hHarnessOut = mxx_xmltree('load', sHarnessModelFileOut);
hExtractionModel = mxx_xmltree('load', sExtractionModelFile);
onCleanupCloseHarnessIn = onCleanup(@() mxx_xmltree('clear', hHarnessIn));
onCleanupCloseHarnessOut = onCleanup(@() mxx_xmltree('clear', hHarnessOut));
onCleanupCloseExtrModel = onCleanup(@() mxx_xmltree('clear', hExtractionModel));

% virtual bus information
[sBusObjInitFileName, astVirtualBusInfo, bVirtualBusCreationFallback] = i_prepareVirtualBusInformation( ...
    hHarnessIn, ...
    hHarnessOut, ...
    sSubsysSrcModel, ...
    hExtractionModel, ...
    sExtractionModelFile);
% bus information
astBusInfo = i_prepareBusInformation(hHarnessIn, hHarnessOut);

% write bus information
astBusInfo = [astBusInfo, astVirtualBusInfo];

oModelContext = EPModelContext.get(sSubsysSrcModel);
i_writeBusInformation(hHarnessIn, hHarnessOut, astBusInfo, oModelContext);

% write existing alias types into harness from SLDD
i_writeAliasTypes(hHarnessIn, oDesignData, 'Outport');
i_writeAliasTypes(hHarnessOut, oDesignData, 'Inport');

mxx_xmltree('save', hHarnessIn, sHarnessModelFileIn);
mxx_xmltree('save', hHarnessOut, sHarnessModelFileOut);
end

%%
function i_writeAliasTypes(hHarness, oDesignData, sPortKind)
if isempty(oDesignData)
    return;
end

% reading types
jKnownTypeNames = i_getTypeNames(hHarness);
hTypes = mxx_xmltree('get_nodes', hHarness, '/SFunction/Types');
aoEntries = oDesignData.find;

for i = 1:numel(aoEntries)
    oEntry = aoEntries(i);
    if jKnownTypeNames.contains(oEntry.Name)
        continue;
    end

    oValue = oEntry.getValue();
    if isa(oValue, 'Simulink.AliasType')
        sBaseType = oValue.BaseType;
        casTokens = regexp(sBaseType, ':\s*', 'split');
        if length(casTokens) > 1
            sBaseType = casTokens{2};
        end

        hAliasType = mxx_xmltree('add_node', hTypes, 'AliasType');
        mxx_xmltree('set_attribute', hAliasType, 'name', oEntry.Name);
        mxx_xmltree('set_attribute', hAliasType, 'type', sBaseType);
    end
end
i_removeUnusedAliasTypes(hHarness, sPortKind);
end

%%
% removing unused alias datatypes (Bug EP-2979)
function i_removeUnusedAliasTypes(hHarness, sPortKind)
jUsedTypesSet = i_getUsedTypesInSFunction(hHarness, sPortKind);

ahAliasTypeNodes = mxx_xmltree('get_nodes', hHarness, '/SFunction/Types/AliasType');
jAliasTypesMap = java.util.HashMap;
for i = 1:length(ahAliasTypeNodes)
    sAliasType = mxx_xmltree('get_attribute', ahAliasTypeNodes(i), 'name');
    sAliasBaseType = mxx_xmltree('get_attribute', ahAliasTypeNodes(i), 'type');
    jAliasTypesMap.put(sAliasType, sAliasBaseType);
end

% extend used types by nested aliastypes
for i = 1:length(ahAliasTypeNodes)
    sAliasType = mxx_xmltree('get_attribute', ahAliasTypeNodes(i), 'name');
    if jUsedTypesSet.contains(sAliasType)
        sAliasBaseType = jAliasTypesMap.get(sAliasType);
        while jAliasTypesMap.containsKey(sAliasBaseType)
            jUsedTypesSet.add(sAliasBaseType);
            sAliasBaseType = jAliasTypesMap.get(sAliasBaseType);
        end
    end
end

for i = 1:length(ahAliasTypeNodes)
    sAliasType = mxx_xmltree('get_attribute', ahAliasTypeNodes(i), 'name');
    if ~jUsedTypesSet.contains(sAliasType)
        mxx_xmltree('delete_node', ahAliasTypeNodes(i));
    end
end
end


%%
function jUsedTypesSet = i_getUsedTypesInSFunction(hHarness, sPortKind)
jUsedTypesSet = java.util.HashSet;
ahNodes = mxx_xmltree('get_nodes', hHarness, '/SFunction/Types//*/Comp');
for i = 1:length(ahNodes)
    sType = mxx_xmltree('get_attribute', ahNodes(i), 'type');
    jUsedTypesSet.add(sType);
end

ahNodes = mxx_xmltree('get_nodes', hHarness, '/SFunction/Types/EnumType');
for i = 1:length(ahNodes)
    sType = mxx_xmltree('get_attribute', ahNodes(i), 'name');
    jUsedTypesSet.add(sType);
end

ahNodes = mxx_xmltree('get_nodes', hHarness, ['/SFunction/', sPortKind, 's/', sPortKind]);
for i = 1:length(ahNodes)
    sType = mxx_xmltree('get_attribute', ahNodes(i), 'type');
    jUsedTypesSet.add(sType);
end
end


%%
function jHashSet = i_getTypeNames(hHarness)
jHashSet = java.util.HashSet;
ahNodes = mxx_xmltree('get_nodes', hHarness, '/SFunction/Types/*');
for i=1:length(ahNodes)
    sName = mxx_xmltree('get_attribute', ahNodes(i), 'name');
    jHashSet.add(sName);
end
end


%%
function [sBusInitScriptName, astVirtualBusInfo, bVirtualBusCreationFallback] = i_prepareVirtualBusInformation(hHarnessIn, hHarnessOut, ...
    sSubsysSrcModel, hExtrModel, sExtractionModelFile)
bVirtualBusCreationFallback = false;
[~, sF] = fileparts(sExtractionModelFile);
sBusInitScriptName = strrep(sF, 'ExtractionModel', 'btcVirtualBusObjectInit');
astVirtualBusInfo = [];

ahInportNodes = mxx_xmltree('get_nodes', hHarnessIn, '/SFunction/Outports/Outport[@kind="VirtualBus"]');
ahOutportNodes = mxx_xmltree('get_nodes', hHarnessOut, '/SFunction/Inports/Inport[@kind="VirtualBus"]');
if isempty(ahInportNodes) && isempty(ahOutportNodes)
    sBusInitScriptName = '';
    return;
end

astBusInfo = [];
casInportBlocks = i_getPortBlocks(ahInportNodes, sSubsysSrcModel, 'Inport');
casOutportBlocks = i_getPortBlocks(ahOutportNodes, sSubsysSrcModel, 'Outport');
casAllPortBlocks = [casInportBlocks, casOutportBlocks];
try
    astBusInfo = Simulink.Bus.createObject(getfullname(bdroot(sSubsysSrcModel)), casAllPortBlocks, sBusInitScriptName);
    
catch oEx
    try
        bVirtualBusCreationFallback = true;
        nIdx = 1;
        [casInBusNames, nIdx] = i_createBusObjectsInBaseWS(hExtrModel, ahInportNodes, 'InPort', nIdx);
        [casOutBusNames, nIdx] = i_createBusObjectsInBaseWS(hExtrModel, ahOutportNodes, 'OutPort', nIdx);
        casBusNames = [casInBusNames, casOutBusNames];
        for i = 1:numel(casBusNames)
            astBusInfo(i).busName = casBusNames{i};%#ok
        end
        i_createBusesInitFile(sBusInitScriptName, nIdx);
        
    catch oEx
        i_revertDDChanges(sSubsysSrcModel);
        rethrow(oEx);
    end
end

% Simulink.Bus.createObject creates bus objects in the SLDD if it exists
% The original dd must not be modified
i_revertDDChanges(sSubsysSrcModel);

evalin('base', sprintf('run(''%s.m'')', sBusInitScriptName));

ahPortNodes = [ahInportNodes; ahOutportNodes];
for i = 1:length(ahPortNodes)
    if (i <= length(ahInportNodes))
        sKind = 'Inport';
    else
        sKind = 'Outport';
    end
    astVirtualBusInfo = [astVirtualBusInfo, struct(...
        'PortNumber', mxx_xmltree('get_attribute', ahPortNodes(i), 'portNr'),...
        'Type', astBusInfo(i).busName, ...
        'Kind', sKind, ...
        'bIsVirtbusConversion', true)]; %#ok
    mxx_xmltree('set_attribute', ahPortNodes(i), 'type', astBusInfo(i).busName);
end
end


%%
function astBusInfo = i_prepareBusInformation(hHarnessIn, hHarnessOut)
astBusInfo = [];
sXPath = './BusType[@virtual="false"]';

% Inputs
hTypesNode = mxx_xmltree('get_nodes', hHarnessIn, '/SFunction/Types');
astRes = mxx_xmltree('get_attributes', hTypesNode, sXPath, 'name');
mxx_xmltree('delete_nodes', hTypesNode, sXPath);
for i = 1:length(astRes)
    astBusInfo = [astBusInfo, struct(...
        'PortNumber', '', ...
        'Type', astRes(i).name, ...
        'Kind', 'Inport', ...
        'bIsVirtbusConversion', false);]; %#ok
end

% Outputs
hTypesNode = mxx_xmltree('get_nodes', hHarnessOut, '/SFunction/Types');
astRes = mxx_xmltree('get_attributes', hTypesNode, sXPath, 'name');
mxx_xmltree('delete_nodes', hTypesNode, sXPath);
for i = 1:length(astRes)
    astBusInfo = [astBusInfo, struct(...
        'PortNumber', '', ...
        'Type', astRes(i).name, ...
        'Kind', 'Outport', ...
        'bIsVirtbusConversion', false);]; %#ok
end
end


%%
function i_writeBusInformation(hHarnessIn, hHarnessOut, astBusInfo, oModelContext)
if isempty(astBusInfo)
    return;
end

casInTypes = [];
casOutTypes = [];
for i = 1:length(astBusInfo)
    if strcmp(astBusInfo(i).Kind, 'Inport')
        casInTypes = [casInTypes, {astBusInfo(i).Type}]; %#ok
    else
        casOutTypes = [casOutTypes, {astBusInfo(i).Type}]; %#ok
    end
end

hTypesNode = mxx_xmltree('get_nodes', hHarnessIn, '/SFunction/Types');
i_writeBusInformationForHarness(hTypesNode, casInTypes, oModelContext);

hTypesNode = mxx_xmltree('get_nodes', hHarnessOut, '/SFunction/Types');
i_writeBusInformationForHarness(hTypesNode, casOutTypes, oModelContext);
end


%%
function i_writeBusInformationForHarness(hTypesNode, casTypes, oModelContext)
for i = 1:numel(casTypes)
    sBusType = casTypes{i};
    
    if ~i_busTypeAlreadyExists(hTypesNode, sBusType)
        oBusObject = i_getBusObject(sBusType, oModelContext);
        i_writeBusInfo(hTypesNode, sBusType, oBusObject, oModelContext);
    end
end
end


%%
function bTypeAlreadyExists = i_busTypeAlreadyExists(hTypesNode, sName)
sXPathExpr = sprintf('./BusType[@name=''%s'']', sName);
ahNodes = mxx_xmltree('get_nodes', hTypesNode, sXPathExpr);
bTypeAlreadyExists = ~isempty(ahNodes);
end


%%
function oBusObj = i_getBusObject(sBusType, oModelContext)
sExistType = sprintf('exist(''%s'', ''var'')', sBusType);
if oModelContext.evalinGlobal(sExistType)
    oBusObj = oModelContext.resolve(sBusType);
    
elseif evalin('base', sExistType)
    oBusObj = evalin('base', sBusType);
    
else
    oBusObj = [];
end
end


%%
function i_writeBusInfo(hTypesNode, sBusType, oBusObject, oModelContext)
casNestedTypes = {};

hBusType = mxx_xmltree('add_node', hTypesNode, 'BusType');
mxx_xmltree('set_attribute', hBusType, 'name', sBusType);
mxx_xmltree('set_attribute', hBusType, 'virtual', 'false');

for j = 1:length(oBusObject.Elements)
    hElement = mxx_xmltree('add_node', hBusType, 'Comp');
    sType = oBusObject.Elements(j).DataType;
    sType = regexprep(sType, '^(Bus|Enum):\s*', '');
    
    % add type description in "Types" node in case a bus element has an enum or an alias type
    sType = i_addNewTypes(sType, hTypesNode, oModelContext);
    mxx_xmltree('set_attribute', hElement, 'name', oBusObject.Elements(j).Name);
    mxx_xmltree('set_attribute', hElement, 'type', sType);
    aiDims = oBusObject.Elements(j).Dimensions;
    if (numel(aiDims) == 1)
        mxx_xmltree('set_attribute', hElement, 'width',  num2str(oBusObject.Elements(j).Dimensions));
    else
        mxx_xmltree('set_attribute', hElement, 'dim1',  num2str(aiDims(1)));
        mxx_xmltree('set_attribute', hElement, 'dim2',  num2str(aiDims(2)));
    end
    if i_existBusInModelContextOrBase(sType, oModelContext)
        casNestedTypes{end + 1} = sType; %#ok
    end
end
if ~isempty(casNestedTypes)
    i_writeBusInformationForHarness(hTypesNode, casNestedTypes, oModelContext);
end
end


%%
% Note: bus object can live in the original model context or in the base workspace if they have been created by us when
%       dealing with virtual buses that don't have any bus objects attached
%       --> always check both locations because original model might not have access to the base workspace
function bExist = i_existBusInModelContextOrBase(sType, oModelContext)
sExistEval = sprintf('exist(''%s'', ''var'') && isa(%s, ''Simulink.Bus'')', sType, sType);
bExist = oModelContext.evalinGlobal(sExistEval) || evalin('base', sExistEval);
end


%%
function sType = i_addNewTypes(sType, hTypesNode, oModelContext)
% If a bus element has an enum or an alias type, the type description is added in the "Types" node

sEvalExistVar = sprintf('exist(''%s'', ''var'')', sType);
sEvalIsaAliasType = sprintf('isa(%s, ''Simulink.AliasType'')', sType);
sEvalIsaNumericType = sprintf('isa(%s, ''Simulink.NumericType'')', sType);
sAllEval = sprintf('%s && (%s || %s)', sEvalExistVar, sEvalIsaAliasType, sEvalIsaNumericType);

bIsAliasType = oModelContext.evalinGlobal(sAllEval);

% alias type
if bIsAliasType
    i_addAliasTypeDef(hTypesNode, sType, @oModelContext.resolve);
end

% enum
sNormType = regexprep(sType, '^Enum:\s*', '');
[aoEnumMembers, casEnumNames] = oModelContext.evalinGlobal(sprintf('enumeration(''%s'')', sNormType));
if ~isempty(aoEnumMembers)
    sType = i_addEnumTypeDef(hTypesNode, sNormType, aoEnumMembers, casEnumNames);
end
end


%%
function casPortBlocks = i_getPortBlocks(ahPortNodes, sSubsysSrcModel, sKind)
casPortBlocks = cell(1, length(ahPortNodes));
for i = 1:length(ahPortNodes)
    casPortBlocks(i) = ep_find_system(sSubsysSrcModel, ...
        'LookUnderMasks', 'on', ...
        'FollowLinks',    'on', ...
        'SearchDepth',    1 , ...
        'BlockType',      sKind, ...
        'Port',           mxx_xmltree('get_attribute', ahPortNodes(i), 'portNr'));
end
end


%%
function i_addAliasTypeDef(hTypesNode, sType, hResolverFunc)
if ~i_defAlreadyExists(hTypesNode, sType, '//Types/AliasType')
    stTypeInfo = ep_sl_type_info_get(sType, hResolverFunc);
    hAliasType = mxx_xmltree('add_node', hTypesNode, 'AliasType');
    mxx_xmltree('set_attribute', hAliasType, 'name', sType);
    mxx_xmltree('set_attribute', hAliasType, 'type', stTypeInfo.sEvalType);
end
end


%%
function sType = i_addEnumTypeDef(hTypesNode, sType, aoEnumMembers, casEnumNames)
stWarningState = warning('off');
oOnCleanupRestore = onCleanup(@() warning(stWarningState));

% check also in WS
if ~i_defAlreadyExists(hTypesNode, sType, '//Types/EnumType')
    hEnumType = mxx_xmltree('add_node', hTypesNode, 'EnumType');
    mxx_xmltree('set_attribute', hEnumType, 'name', sType);
    for k = 1:numel(aoEnumMembers)
        hEnumValue = mxx_xmltree('add_node', hEnumType, 'EnumValue');
        mxx_xmltree('set_attribute', hEnumValue, 'name', casEnumNames{k});
        stMem = struct(aoEnumMembers(k));
        mxx_xmltree('set_attribute', hEnumValue, 'ordinal', int2str(stMem.Data));
    end
end
end


%%
function bDefAlreadyExists = i_defAlreadyExists(hTypesNode, sDefName, sPath)
bDefAlreadyExists = false;
ahNodes = mxx_xmltree('get_nodes', hTypesNode, sPath);
for i=1:numel(ahNodes)
    sName = mxx_xmltree('get_attribute', ahNodes(i), 'name');
    if strcmp(sDefName, sName)
        bDefAlreadyExists = true;
        break;
    end
end
end


%%
function i_revertDDChanges(sSubsysSrcModel)
sSLDD = get_param(getfullname(bdroot(sSubsysSrcModel)), 'DataDictionary');
if ~isempty(sSLDD)
    oDictionaryObj = Simulink.data.dictionary.open(sSLDD);
    if(oDictionaryObj.HasUnsavedChanges)
        oDictionaryObj.discardChanges;
        oDictionaryObj.close;
    end
end
end


%%
function astBusInfo = i_prepareBusElementsInfo(casNames, casTypes, casDim)
astBusInfo = [];

astMainBusInfo = ep_sim_bus_info_build(casNames, casTypes, casDim);

% Check the following assumptions and return early when one of them is violated:
%  1. we get some kind of info
%  2. we have exactly one root signal
%  3. the root signal is a bus with sub-signals
if (isempty(astMainBusInfo) || (numel(astMainBusInfo) ~= 1) || ~astMainBusInfo(1).bIsBus)
    return;
end

astBusInfo = astMainBusInfo(1).astBusInfo;
end


%%
function [sBusName, nBusNrPrefix] = i_createBuses(astBusInfo, nBusNrPrefix)
oBusObj = Simulink.Bus;
elems=[];
sBusName = strcat('btcBus', int2str(nBusNrPrefix));
nBusNrPrefix = nBusNrPrefix + 1;

for i = 1:numel(astBusInfo)
    if astBusInfo(i).bIsBus
        [sBusNameNew, nBusNrPrefix]= i_createBuses(astBusInfo(i).astBusInfo, nBusNrPrefix);
        astBusInfo(i).sType = ['Bus: ', sBusNameNew];
        elem = i_defineBusElem(astBusInfo(i));
        elems=[elems elem]; %#ok
        oBusObj.Elements = elems;
    else
        elem = i_defineBusElem(astBusInfo(i));
        elems=[elems elem]; %#ok
        oBusObj.Elements = elems;
    end
end
assignin('base', sBusName, oBusObj);
end


%%
function elem = i_defineBusElem(stInfo)
elem= Simulink.BusElement;
elem.Name = i_setCompliantName(stInfo.sBusElemName);
elem.Complexity = 'real';
elem.DataType = stInfo.sType;
if ~isempty(stInfo.sDim)
    sDim = stInfo.sDim;
    sDim = strrep(sDim, '[', '');
    sDim = strrep(sDim, ']', '');
    casDims = strsplit(sDim, ' ');
    if numel(casDims) == 2
        elem.Dimensions = [str2double(casDims{1}) str2double(casDims{2})];
    else
        elem.Dimensions = [str2double(casDims{2}) str2double(casDims{3})];
    end
end
% elem.Min = stInfo.DesignMin;
% elem.Max = stInfo.DesignMax;
elem.DimensionsMode = 'Fixed';
elem.SampleTime = -1;
if verLessThan('matlab' , '9.0')
    elem.DocUnits = '';
else
    elem.Unit = '';
end
elem.Description = '';
end



%%
function sCompliantName = i_setCompliantName(sName)
sName = strrep(sName, '(', '');
sName = strrep(sName, ')', '');
sName = strrep(sName, ' ', '_');
sName = strrep(sName, ':', '');
sCompliantName = sName;
end


%%
function [casBusObjNames, nIdx] = i_createBusObjectsInBaseWS(hExtrModel, ahNodes, sType, nIdx)
casBusObjNames = {};
for i=1:numel(ahNodes)
    sPortNr = mxx_xmltree('get_attribute', ahNodes(i), 'portNr');
    [casName, casType, casDim] = i_getBusInfoFromXML(hExtrModel, sPortNr, sType);
    astBusInfo = i_prepareBusElementsInfo(casName, casType, casDim);
    [sBusName, nIdx] = i_createBuses(astBusInfo, nIdx);
    casBusObjNames{end+1} = sBusName; %#ok
end
end


%%
function [casName, casType, casDim] = i_getBusInfoFromXML(hExtrModel, sPortNr, sType)
astVarNodes = mxx_xmltree('get_nodes', hExtrModel, ...
    ['/ExtractionModel/Scope/', sType, '[@portNumber="', sPortNr, '"]//Variable']);
%allocate memory
nLength = numel(astVarNodes);
casName = cell(1, nLength);
casName{1, nLength} = [];
casType = casName;
casDim = casName;

for i = 1:numel(astVarNodes)
    casName{i} = mxx_xmltree('get_attribute', astVarNodes(i), 'signalName');
    
    sIsEnum = mxx_xmltree('get_attribute', astVarNodes(i), 'isSignalTypeEnum');
    if ~isempty(sIsEnum)
        casType{i} = ['Enum: ', mxx_xmltree('get_attribute', astVarNodes(i), 'signalType')];
    else
        casType{i} = mxx_xmltree('get_attribute', astVarNodes(i), 'signalType');
    end
    
    casDim{i} = mxx_xmltree('get_attribute', astVarNodes(i), 'signalDim');
end
end


%%
function i_createBusesInitFile(sBusInitScriptName, nIdx)
sBusNames = '{';
for i = 1:nIdx-1
    sBusNames = strcat(sBusNames, '''btcBus', num2str(i), '''', ', ');
end
sBusNames = strcat(sBusNames(1:length(sBusNames)-1), '}');
evalin('base', ['Simulink.Bus.save(''', sBusInitScriptName, ''', ''object'', ', sBusNames, ');']);
end

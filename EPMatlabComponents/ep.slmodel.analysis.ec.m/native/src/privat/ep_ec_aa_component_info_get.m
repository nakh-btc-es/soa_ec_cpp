function stInfo = ep_ec_aa_component_info_get(sModelName, bWithModelMapping)
%
%


%%
if (nargin < 2)
    bWithModelMapping = true;
    if (nargin < 1)
        sModelName = bdroot(gcs);
    end
end

stInfo = struct( ...
    'sAutosarVersion',  ep_ec_model_autosar_version_get(sModelName), ...
    'sName',            '', ...
    'stPorts',          [], ...
    'stModelMapping',   []);
if isempty(stInfo.sAutosarVersion)
    warning('EP:USAGE:ERROR', 'Model "%s" is not an AUTOSAR model.', sModelName);
    return;
end

oAutosarProps = autosar.api.getAUTOSARProperties(sModelName);
sArComponentPath = get(oAutosarProps, 'XmlOptions', 'ComponentQualifiedName');
stInfo.sName = get(oAutosarProps, sArComponentPath, 'Name');

% ports info
[stInfo.stPorts, mPortToInterface] = i_getPortsAdaptiveAUTOSAR(oAutosarProps, sArComponentPath);
if bWithModelMapping
    stInfo.stModelMapping = i_getModelMapping(sModelName, mPortToInterface);
end
end


%%
function stModelMapping = i_getModelMapping(sModelName, mPortToInterface)
oAutosarMapping = autosar.api.getSimulinkMapping(sModelName);
hModel = get_param(sModelName, 'handle');

stModelMapping = struct( ...
    'astInports',         i_getInportMappings(hModel, oAutosarMapping, mPortToInterface), ...
    'astOutports',        i_getOutportMappings(hModel, oAutosarMapping, mPortToInterface), ...
    'astFunctionCallers', i_getFunctionCallerMappings(hModel, oAutosarMapping, mPortToInterface), ...
    'astFunctions',       i_getFunctionMappings(hModel, oAutosarMapping, mPortToInterface));
end


%%
function astInportMappings = i_getInportMappings(hModel, oAutosarMapping, mPortToInterface)
ahInports = i_findSystem(hModel, ...
    'SearchDepth',     1, ...
    'LookUnderMasks',  'all', ...
    'FollowLinks',     'on', ...
    'BlockType',       'Inport');
astInportMappings = i_cell2mat( ...
    arrayfun(@(h) i_getInMapping(h, oAutosarMapping, mPortToInterface), ahInports, 'UniformOutput', false));
end


%%
function astOutportMappings = i_getOutportMappings(hModel, oAutosarMapping, mPortToInterface)
ahOutports = i_findSystem(hModel, ...
    'SearchDepth',     1, ...
    'LookUnderMasks',  'all', ...
    'FollowLinks',     'on', ...
    'BlockType',       'Outport');
astOutportMappings = i_cell2mat( ...
    arrayfun(@(h) i_getOutMapping(h, oAutosarMapping, mPortToInterface), ahOutports, 'UniformOutput', false));
end


%%
function stInMapping = i_getInMapping(hRootPortBlock, oAutosarMapping, mPortToInterface)
sPortName = get_param(hRootPortBlock, 'Name');
try
    [sMappedArPortName, sEventOrFieldName] = oAutosarMapping.getInport(sPortName);

    stArMappedInterface = mPortToInterface(sMappedArPortName);

    bIsFieldName = stArMappedInterface.jFieldNames.contains(sEventOrFieldName);
    if bIsFieldName
        sArMappedEventName = '';
        sArMappedFieldName = sEventOrFieldName;
    else
        sArMappedEventName = sEventOrFieldName;
        sArMappedFieldName = '';
    end

    stInMapping = struct( ...
        'sSource',                getfullname(hRootPortBlock), ...
        'sMappedArInterfaceName', stArMappedInterface.sName, ...
        'sMappedArPortName',      sMappedArPortName, ...
        'sMappedArEventName',     sArMappedEventName, ...
        'sMappedArFieldName',     sArMappedFieldName);

catch oEx %#ok<NASGU>
    stInMapping = [];
end
end


%%
function stOutMapping = i_getOutMapping(hRootPortBlock, oAutosarMapping, mPortToInterface)
sPortName = get_param(hRootPortBlock, 'Name');
try
    [sMappedArPortName, sEventOrFieldName, bAllocMemory] = oAutosarMapping.getOutport(sPortName);

    stArMappedInterface = mPortToInterface(sMappedArPortName);

    bIsFieldName = stArMappedInterface.jFieldNames.contains(sEventOrFieldName);
    if bIsFieldName
        sArMappedEventName = '';
        sArMappedFieldName = sEventOrFieldName;
    else
        sArMappedEventName = sEventOrFieldName;
        sArMappedFieldName = '';
    end

    stOutMapping = struct( ...
        'sSource',                getfullname(hRootPortBlock), ...
        'sMappedArInterfaceName', stArMappedInterface.sName, ...
        'sMappedArPortName',      sMappedArPortName, ...
        'sMappedArEventName',     sArMappedEventName, ...
        'sMappedArFieldName',     sArMappedFieldName, ...
        'bAllocMemory',           bAllocMemory);

catch oEx %#ok<NASGU>
    stOutMapping = [];
end
end


%%
function astList = i_cell2mat(castList)
abSelect = ~cellfun(@isempty, castList);
astList  = cell2mat(castList(abSelect));
end


%%
function astFuncCallerMappings = i_getFunctionCallerMappings(hModel, oAutosarMapping, mPortToInterface)
ahCallerBlocks = i_getFuncCallerBlocks(hModel);

% get only one instance of a function caller in case of multiple callers of the same SL function
[~, aiIdxUniqProtoName] = unique(cellstr(get_param(ahCallerBlocks, 'FunctionPrototype')));
ahCallerBlocks = ahCallerBlocks(aiIdxUniqProtoName);

astFuncCallerMappings = i_cell2mat( ...
    arrayfun(@(h) i_getFuncCallerMapping(h, oAutosarMapping, mPortToInterface), ahCallerBlocks, 'UniformOutput', false));
end


%%
function stFuncCallerMapping = i_getFuncCallerMapping(hCallerBlock, oAutosarMapping, mPortToInterface)
sFunctionPrototype = get_param(hCallerBlock, 'FunctionPrototype');
sFunctionName = i_getFunctionName(sFunctionPrototype);

try
    [sMappedArPortName, sMethodOrFieldName] = oAutosarMapping.getFunctionCaller(sFunctionName);

    stArMappedInterface = mPortToInterface(sMappedArPortName);

    bIsFieldName = stArMappedInterface.jFieldNames.contains(sMethodOrFieldName);
    if bIsFieldName
        sMappedArMethodName  = '';
        sMappedArFieldName   = sMethodOrFieldName;
        sFieldAccessKind     = i_getFieldAccessKindFromSlFunctionCaller(hCallerBlock);
    else
        sMappedArMethodName  = sMethodOrFieldName;
        sMappedArFieldName   = '';
        sFieldAccessKind     = '';
    end

    % Note: also the client port on root level could be considered "source" of the required method
    stFuncCallerMapping = struct( ...
        'sSource',                getfullname(hCallerBlock), ...
        'sMappedArInterfaceName', stArMappedInterface.sName, ...
        'sMappedArPortName',      sMappedArPortName, ...
        'sMappedArMethodName',    sMappedArMethodName, ...
        'sMappedArFieldName',     sMappedArFieldName, ...
        'sFieldAccessKind',       sFieldAccessKind);

catch oEx %#ok<NASGU>
    stFuncCallerMapping = [];
end
end


%%
function sAccessKind = i_getFieldAccessKindFromSlFunctionCaller(hCallerBlock)
bHasInputs = ~isempty(get_param(hCallerBlock, 'InputArgumentSpecifications'));
if bHasInputs
    sAccessKind = 'set';
else
    sAccessKind = 'get';
end
end


%%
function astFuncMappings = i_getFunctionMappings(hModel, oAutosarMapping, mPortToInterface)
ahTriggerPortBlocks = i_getFuncTriggerPortBlocks(hModel);
astFuncMappings = i_cell2mat( ...
    arrayfun(@(h) i_getFuncMapping(h, oAutosarMapping, mPortToInterface), ahTriggerPortBlocks, 'UniformOutput', false));
end


%%
function stFuncMapping = i_getFuncMapping(hTriggerPortBlock, oAutosarMapping, mPortToInterface)
sFunctionName = [get_param(hTriggerPortBlock, 'ScopeName'), '.', get_param(hTriggerPortBlock, 'FunctionName')];
try
    [sMappedArPortName, sMethodOrFieldName] = oAutosarMapping.getFunction(sFunctionName);

    stArMappedInterface = mPortToInterface(sMappedArPortName);

    bIsFieldName = stArMappedInterface.jFieldNames.contains(sMethodOrFieldName);
    if bIsFieldName
        sMappedArMethodName  = '';
        sMappedArFieldName   = sMethodOrFieldName;
        sFieldAccessKind     = i_getFieldAccessKindFromSlFunction(get_param(hTriggerPortBlock, 'Parent'));
    else
        sMappedArMethodName  = sMethodOrFieldName;
        sMappedArFieldName   = '';
        sFieldAccessKind     = '';
    end

    % Note: also the server port on root level could be considered "source" of the provided method
    sFunctionBlock = getfullname(get_param(hTriggerPortBlock, 'Parent'));
    stFuncMapping = struct( ...
        'sSource',                sFunctionBlock, ...
        'sMappedArInterfaceName', stArMappedInterface.sName, ...
        'sMappedArPortName',      sMappedArPortName, ...
        'sMappedArMethodName',    sMappedArMethodName, ...
        'sMappedArFieldName',     sMappedArFieldName, ...
        'sFieldAccessKind',       sFieldAccessKind);

catch oEx %#ok<NASGU>
    stFuncMapping = [];
end
end


%%
function sAccessKind = i_getFieldAccessKindFromSlFunction(xSlFunc)
bHasInputs = ~isempty(i_findSystem(xSlFunc, 'SearchDepth', 1, 'BlockType', 'ArgIn'));
if bHasInputs
    sAccessKind = 'set';
else
    sAccessKind = 'get';
end
end


%%
function sFuncName = i_getFunctionName(sFunctionPrototype)
% Example prototype == '[x, y] = port.func(u1, u2, u3)' --> function-name == 'port.func'

% 1) remove the trailing chars starting with the first round bracket
sFuncName = regexprep(sFunctionPrototype, '\(.+$', '');

% 2) remove everything before and including the equals sign if there is any
sFuncName = regexprep(sFuncName, '^.+=', '');

% 3) remove leading and trailing whitespaces that might have been left over
sFuncName = strtrim(sFuncName);
end


%%
function xFoundList = i_findSystem(xContext, varargin)
xFoundList = find_system(xContext, ...
    'MatchFilter',  @Simulink.match.activeVariants, ...
    varargin{:});
end


%%
function ahCallerBlocks = i_getFuncCallerBlocks(hModel)
ahCallerBlocks = i_findSystem(hModel, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'BlockType',      'FunctionCaller');
end


%%
function ahTriggerPortBlocks = i_getFuncTriggerPortBlocks(hModel)
ahTriggerPortBlocks = i_findSystem(hModel, ...
    'BlockType',          'TriggerPort', ...
    'IsSimulinkFunction', 'on', ...
    'FunctionVisibility', 'port');
end


%%
function [stPorts, mPortToInterface] = i_getPortsAdaptiveAUTOSAR(oArProps, sArComponentPath)
stPorts = struct();
mPortToInterface = containers.Map();

mArInterfaceToInfo = containers.Map();

% -------- required ---------
casRequiredPorts = get(oArProps, sArComponentPath, 'RequiredPorts');
stPorts.astRequiredPorts = ...
    cellfun(@(s) i_getArPortInfoFromPort(oArProps, mArInterfaceToInfo, s, 'required'), casRequiredPorts);

% --------- provided ----------
casProvidedPorts = get(oArProps, sArComponentPath, 'ProvidedPorts');
stPorts.astProvidedPorts = ...
    cellfun(@(s) i_getArPortInfoFromPort(oArProps, mArInterfaceToInfo, s, 'provided'), casProvidedPorts);


% Note: For the stub code generator use the single attribute "InstanceKey" instead of separate "InstanceIdentifier"
%       and "InstanceSpecifier". The selection depends on the AUTOSAR XmlOptions settings.
bIdentifyBySpecifier = i_isIdentifyBySpecifier(oArProps);
if bIdentifyBySpecifier
    sInstanceKeyField = 'sInstanceSpecifier';
else
    sInstanceKeyField = 'sInstanceIdentifier';
end

for i = 1:numel(stPorts.astRequiredPorts)
    stPorts.astRequiredPorts(i).sInstanceKey = stPorts.astRequiredPorts(i).(sInstanceKeyField);
    mPortToInterface(stPorts.astRequiredPorts(i).sPortName) = ...
        i_transformInterfaceToMappingValue(stPorts.astRequiredPorts(i).stInterface);
end

for i = 1:numel(stPorts.astProvidedPorts)
    stPorts.astProvidedPorts(i).sInstanceKey = stPorts.astProvidedPorts(i).(sInstanceKeyField);
    mPortToInterface(stPorts.astProvidedPorts(i).sPortName) = ...
        i_transformInterfaceToMappingValue(stPorts.astProvidedPorts(i).stInterface);
end

% create namespace<->type mapping with all used types from ports
stPorts.mNamespaceTypeMapping = i_collectTypesFromPortsToMap([stPorts.astRequiredPorts stPorts.astProvidedPorts]);

% --------- required/provided ----------
% Not yet supported: PersistencyProvidedRequiredPorts
end


%%
function stInterfaceMappingValue = i_transformInterfaceToMappingValue(stInterface)
stInterfaceMappingValue = struct( ...
    'sName',        stInterface.sName, ...
    'jFieldNames',  i_getNameSet(stInterface.astFields));
end


%%
function jNameSet = i_getNameSet(astNameStructs)
jNameSet = java.util.HashSet;
for i = 1:numel(astNameStructs)
    jNameSet.add(astNameStructs(i).sName);
end
end


%%
function stPortInfo = i_getArPortInfoFromPort(oArProps, mArInterfaceToInfo, sPortPath, sPortType)
sItfPath = get(oArProps, sPortPath, 'Interface', 'PathType', 'FullyQualified');

if mArInterfaceToInfo.isKey(sItfPath)
    stInterfaceInfo = mArInterfaceToInfo(sItfPath);
else
    stInterfaceInfo = i_getInterfaceInfo(oArProps, sItfPath);
    mArInterfaceToInfo(sItfPath) = stInterfaceInfo; %#ok<NASGU> handle-object, modified for usage outside of function
end

switch sPortType
    case 'required'
        sServiceDiscoveryMode = get(oArProps, sPortPath, 'ServiceDiscoveryMode');

    case 'provided'
        sServiceDiscoveryMode = '';

    otherwise
        error('EP:INTERNAL:ERROR', 'Unknown port type %s.', sPortType);
end

bIdentifyBySpecifier = i_isIdentifyBySpecifier(oArProps);

% 'InstanceIdentifier' is only supported in 2023b, the AUTOSAR API function
% was removed from in version R2024a onwards
sInstanceIdentifier = '';
if ~bIdentifyBySpecifier
    if isMATLABReleaseOlderThan('R2024a')
        sInstanceIdentifier = get(oArProps, sPortPath, 'InstanceIdentifier');
        if isempty(sInstanceIdentifier)
            error('EP:ECAA:MODEL', [ ...
                'Inconsistent "InstanceIdentifier" data in AUTOSAR dictionary detected, ' ...
                'it occurs due to an EC bug when upgrading the AA model version to R2023b (or higher).\n' ...
                'Port "%s" may has mismatching data between the AUTOSAR dictionary and the generated C++ code.\n', ...
                'HINT: Try setting new values for all service InstanceIdentifiers, generate code and then save the model. ', ...
                'Alternatively use the InstanceSpecifier setting.\n'], sPortPath);
        end
    else
        error('EP:ECAA:MODEL', [ ...
            'The setting "Identify Service Instance Using: InstanceIdentifier" is not supported anymore since Matlab R2024a.\n' ...
            'Please use the "InstanceSpecifier" setting instead.'], sPortPath);
    end
end

sInstanceSpecifier  = get(oArProps, sPortPath, 'InstanceSpecifier');
sInstanceKey        = ''; % will be filled out later when the service identifier option is being determined

stPortInfo = struct( ...
    'sPath',                 sPortPath, ...
    'sPortType',             sPortType, ...
    'sPortName',             i_getName(oArProps, sPortPath), ...
    'sInstanceIdentifier',   sInstanceIdentifier, ...
    'sInstanceSpecifier',    sInstanceSpecifier, ...
    'sInstanceKey',          sInstanceKey, ...
    'sServiceDiscoveryMode', sServiceDiscoveryMode, ...
    'stInterface',           stInterfaceInfo);
end


%%
function stInterfaceInfo = i_getInterfaceInfo(oArProps, sItfPath)
casNamespaces = get(oArProps, sItfPath, 'Namespaces', 'PathType', 'FullyQualified');
casEvents     = get(oArProps, sItfPath, 'Events', 'PathType', 'FullyQualified');
casMethods    = get(oArProps, sItfPath, 'Methods', 'PathType', 'FullyQualified');
casFields     = get(oArProps, sItfPath, 'Fields', 'PathType', 'FullyQualified');
stInterfaceInfo = struct( ...
    'sName',         i_getName(oArProps, sItfPath), ...
    'casNamespaces', {cellfun(@(s) i_getNamespaceSymbol(oArProps, s), casNamespaces, 'UniformOutput', false)}, ...
    'astEvents',     cellfun(@(s) i_getEventInfo(oArProps, s),  casEvents), ...
    'astMethods',    cellfun(@(s) i_getMethodInfo(oArProps, s), casMethods), ...
    'astFields',     cellfun(@(s) i_getFieldInfo(oArProps, s),  casFields));
end


%%
function stEventInfo = i_getEventInfo(oArProps, sEventPath)
stType = i_getType(oArProps, sEventPath);
stEventInfo = struct( ...
    'sName',                i_getName(oArProps, sEventPath), ...
    'sImplDatatype',        stType.sType, ...
    'sSwCalibrationAccess', get(oArProps, sEventPath, 'SwCalibrationAccess'), ...
    'sDisplayFormat',       get(oArProps, sEventPath, 'DisplayFormat'), ...
    'stType',               stType);
end


%%
function stMethodInfo = i_getMethodInfo(oArProps, sMethodPath)
stMethodInfo = struct( ...
    'sName',   i_getName(oArProps, sMethodPath), ...
    'astArgs', cellfun(@(s) i_getArgInfo(oArProps, s), get(oArProps, sMethodPath, 'Arguments')));
end


%%
function stFieldInfo = i_getFieldInfo(oArProps, sFieldPath)
stType = i_getType(oArProps, sFieldPath);
stFieldInfo = struct( ...
    'sName',                i_getName(oArProps, sFieldPath), ...
    'sImplDatatype',        stType.sType, ...
    'bHasGetter',           get(oArProps, sFieldPath, 'HasGetter'), ...
    'bHasSetter',           get(oArProps, sFieldPath, 'HasSetter'), ...
    'bHasNotifier',         get(oArProps, sFieldPath, 'HasNotifier'), ...
    'sSwCalibrationAccess', get(oArProps, sFieldPath, 'SwCalibrationAccess'), ...
    'sDisplayFormat',       get(oArProps, sFieldPath, 'DisplayFormat'), ...
    'stType',               stType);
end


%%
function stArgInfo = i_getArgInfo(oArProps, sArgPath)
stType = i_getType(oArProps, sArgPath);
stArgInfo = struct( ...
    'sName',                i_getName(oArProps, sArgPath), ...
    'sDirection',           get(oArProps, sArgPath, 'Direction'), ...
    'sDisplayFormat',       get(oArProps, sArgPath, 'DisplayFormat'), ...
    'sSwCalibrationAccess', get(oArProps, sArgPath, 'SwCalibrationAccess'), ...
    'sImplDatatype',        stType.sType, ...
    'stType',               stType);
end


%%
function casDatatypeNameSpace = i_formatRawDataTypeNS(casRawDataTypeNameSpace)
casDatatypeNameSpace = {};
iCount = 1;
for i = 1:numel(casRawDataTypeNameSpace)
    casNameParts = split(casRawDataTypeNameSpace{i}, '/');
    if numel(casNameParts) > 1
        casDatatypeNameSpace{iCount} = casNameParts{2}; %#ok<AGROW>
        iCount = iCount + 1;
    end
end
end


%%
function sSymbol = i_getNamespaceSymbol(oArProps, sNamespacePath)
sSymbol = get(oArProps, sNamespacePath, 'Symbol');
end


%%
function stTypeInfo = i_getType(oArProps, sElemPath)
try
    sTypePath = char(get(oArProps, sElemPath, 'Type', 'PathType', 'FullyQualified'));
    stTypeInfo = i_getTypeInfo(oArProps, sTypePath);
catch
    stTypeInfo = i_getDefaultTypeInfo();
    stTypeInfo.sType = 'UNKNOWN_IDT';
end
end


%%
function stType = i_getTypeInfo(oArProps, sTypePath)
astSubTypes = [];
casNamespaces = {};
stBaseType = [];
sCategory = '';
[sPath, sType] = fileparts(sTypePath);
% making sure the implementation data type is used; workaround for the case the application data type and the
% implementation data type differ (e.g the application data type does not have a namespace defined, 
% but the implementation data type does - see EPDEV-83547)
% This is more a workaround since the implementation data type path is considered to be the DataTypePackage and the type
% is found only if it has the same name
% Ideally would be to have the map between a concrete application data type and it's corresponding implementation data
% type
if strcmp(sPath, get(oArProps, 'XmlOptions', 'ApplicationDataTypePackage'))
    sImplType = get(oArProps, 'XmlOptions', 'DataTypePackage');
    sTypePath = [sImplType '/' sType];
end
try %#ok<TRYNC>
    sCategory = oArProps.get(sTypePath, 'Category');
    if (strcmp('Structure', sCategory))
        casElements = oArProps.get(sTypePath, 'Elements', 'PathType', 'FullyQualified');
        for i = 1:numel(casElements)
            sElementTypePath = oArProps.get(casElements{i}, 'Type', 'PathType', 'FullyQualified');
            stSubType = i_getTypeInfo(oArProps, sElementTypePath);
            astSubTypes = [astSubTypes stSubType]; %#ok<AGROW>
        end
    elseif (strcmp('Matrix', sCategory))
        stBaseType = i_getTypeInfo(oArProps, oArProps.get(sTypePath, 'BaseType', 'PathType', 'FullyQualified'));
    end
    casRawDatatypeNamespace = oArProps.get(sTypePath, 'Namespaces');
    casNamespaces = i_formatRawDataTypeNS(casRawDatatypeNamespace);
end

stType = i_getDefaultTypeInfo();
stType.sType = sType;
stType.sCategory = sCategory;
stType.astSubTypes = astSubTypes;
stType.stBaseType = stBaseType;
stType.casNamespaces = casNamespaces;
stType.sNamespaceExpression = i_getNamespaceExpression(casNamespaces);
end


%%
function sExpression = i_getNamespaceExpression(casNamespaces)
sExpression = '';
for i = 1:numel(casNamespaces)
    sExpression = [sExpression casNamespaces{i} '::']; %#ok<AGROW>
end
end


%%
function stTypeInfo = i_getDefaultTypeInfo()
stTypeInfo = struct(...
    'sType', '', ...
    'sCategory', '', ...
    'astSubTypes', [], ...
    'stBaseType', [], ...
    'casNamespaces', {{}}, ...
    'sNamespaceExpression', '');
end


%%
function sName = i_getName(oAutosarProps, sPath) %#ok<INUSL>
bDoItClean = false;

if bDoItClean
    % this is the *clean* way but much too slow
    sName = oAutosarProps.get(sPath, 'Name'); %#ok<UNRCH> OK TODO: dead code can used for later re-factoring!
else
    sName = regexprep(sPath, '.*/', '');
end
end


%%
function bIdentifyBySpecifier = i_isIdentifyBySpecifier(oArProps)
sInstanceIdentificationKind = oArProps.get('XmlOptions', 'IdentifyServiceInstance');
bIdentifyBySpecifier = strcmp(sInstanceIdentificationKind, 'InstanceSpecifier');
end


%%
function mNamespaceTypeMap = i_collectTypesFromPortsToMap(astPorts)
mNamespaceTypeMap = containers.Map();
for i = 1:numel(astPorts)    
    astTypes = i_getAllTypesUsedInPort(astPorts(i));    
    for k = 1:numel(astTypes)
        mNamespaceTypeMap = i_addToNamespaceTypeMap(astTypes(k), mNamespaceTypeMap);            
    end
end
end


%%
function mNamespaceTypeMap = i_addToNamespaceTypeMap(stType, mNamespaceTypeMap)
sNamespace = stType.sNamespaceExpression;
if (~mNamespaceTypeMap.isKey(sNamespace))
    mNamespaceTypeMap(sNamespace) = stType;
else
    astMappedTypes = mNamespaceTypeMap(sNamespace);
    if(~any(ismember({stType.sType}, {astMappedTypes.sType})))
        mNamespaceTypeMap(sNamespace) = [astMappedTypes stType];
    end
end

astSubTypes = stType.astSubTypes;
for i = 1:numel(astSubTypes)
    mNamespaceTypeMap = i_addToNamespaceTypeMap(astSubTypes(i), mNamespaceTypeMap);
end

if (strcmp('Matrix', stType.sCategory))
    mNamespaceTypeMap = i_addToNamespaceTypeMap(stType.stBaseType, mNamespaceTypeMap);
end
end


%%
function astTypes = i_getAllTypesUsedInPort(stPort)
astTypes = [];
stItf = stPort.stInterface;
if(~isempty(stItf.astEvents))
    astTypes = [astTypes stItf.astEvents.stType];
end
if(~isempty(stItf.astMethods))
    astArgs = [stItf.astMethods.astArgs];
    if(~isempty(astArgs))
        astTypes = [astTypes astArgs.stType];
    end
end
if(~isempty(stItf.astFields))
    astTypes = [astTypes stItf.astFields.stType];
end
end


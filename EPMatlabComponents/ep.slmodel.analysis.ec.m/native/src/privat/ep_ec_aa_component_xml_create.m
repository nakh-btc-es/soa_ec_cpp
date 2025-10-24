function ep_ec_aa_component_xml_create(sModelName, sXmlFile)


%%
if (nargin < 2)
    sXmlFile = fullfile(pwd, 'aa_component.xml');
    if (nargin < 1)
        sModelName = bdroot(gcs);
    end
end

% gather info and write XML
stCompInfo = ep_ec_aa_component_info_get(sModelName);
i_exportToXml(stCompInfo, sXmlFile, sModelName);
end


%%
function i_exportToXml(stCompInfo, sXmlFile, sModelName)
hDocNode = mxx_xmltree('create', 'aa-component');
oOnCleanupClear = onCleanup(@() mxx_xmltree('clear', hDocNode));

stMLInfo = matlabRelease;
sMLVersion = char(stMLInfo.Release);

% basic info
mxx_xmltree('set_attribute', hDocNode, 'name',       stCompInfo.sName);
mxx_xmltree('set_attribute', hDocNode, 'aa_version', stCompInfo.sAutosarVersion);
mxx_xmltree('set_attribute', hDocNode, 'model_name', sModelName);
mxx_xmltree('set_attribute', hDocNode, 'matlab_version', sMLVersion);

[mKnownPorts, mKnownEvents, mKnownMethods, mKnownFields] = i_addTypesAndInterfacesAndPorts(hDocNode, stCompInfo.stPorts);
i_addEventAndMethodAndFieldReferences(stCompInfo.stModelMapping, mKnownPorts, mKnownEvents, mKnownMethods, mKnownFields);

mxx_xmltree('save', hDocNode, sXmlFile);
end


%%
function [mKnownPorts, mKnownEvents, mKnownMethods, mKnownFields] = i_addTypesAndInterfacesAndPorts(hDocNode, stPorts)
hTypesNode      = mxx_xmltree('add_node', hDocNode, 'types');
hInterfacesNode = mxx_xmltree('add_node', hDocNode, 'interfaces');
hPortsNode      = mxx_xmltree('add_node', hDocNode, 'ports');


% helper maps and sets to keep track of internal references inside the XML
jKnownInterfaces        = java.util.HashSet;
mKnownTypes             = containers.Map();
mKnownTypesNamespaces   = containers.Map();
mKnownTypesCategory     = containers.Map();
mKnownEvents            = containers.Map();
mKnownMethods           = containers.Map();
mKnownFields            = containers.Map();
mKnownPorts             = containers.Map();

allPorts = [stPorts.astRequiredPorts, stPorts.astProvidedPorts];
for i = 1:numel(allPorts)
    stPort = allPorts(i);

    % first add the referenced AR interface if not already part of XML
    sReferencedInterfaceName = stPort.stInterface.sName;
    if ~jKnownInterfaces.contains(sReferencedInterfaceName)
        i_addInterface(hInterfacesNode, stPort.stInterface, ...
            mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory, mKnownEvents, mKnownMethods, mKnownFields);
        jKnownInterfaces.add(sReferencedInterfaceName);
    end

    % now the required port node
    sPortName = stPort.sPortName;
    if strcmp(stPort.sPortType, 'required')
        sNodeName = 'rport';
    else
        sNodeName = 'pport';
    end
    hPortNode = mxx_xmltree('add_node', hPortsNode, sNodeName);
    mxx_xmltree('set_attribute', hPortNode, 'name',        sPortName);
    mxx_xmltree('set_attribute', hPortNode, 'instanceKey', stPort.sInstanceKey);
    mKnownPorts(sPortName) = hPortNode;
end

casTypes = mKnownTypes.keys;
for i = 1:numel(casTypes)
    sTypeName = casTypes{i};
    sTypeID   = mKnownTypes(sTypeName);
    sTypeKind = i_getKind(sTypeName);
    sCategory = mKnownTypesCategory(sTypeName);

    hTypeNode = mxx_xmltree('add_node', hTypesNode, 'type');
    mxx_xmltree('set_attribute', hTypeNode, 'typeId', sTypeID);
    mxx_xmltree('set_attribute', hTypeNode, 'name',   sTypeName);
    mxx_xmltree('set_attribute', hTypeNode, 'kind',   sTypeKind);

    if (strcmp('Structure', sCategory))
        mxx_xmltree('set_attribute', hTypeNode, 'category',  lower(sCategory));
    end

    i_addNamespaces(hTypeNode, mKnownTypesNamespaces(sTypeName));
end
end


%%
function sKind = i_getKind(sType)
if i_isFundamentalType(sType)
    sKind = 'fundamental';

elseif i_isPrimitiveType(sType)
    sKind = 'primitive';

else
    sKind = 'non-primitive';
end
end


%%
function bIsFundamental = i_isFundamentalType(sType)
bIsFundamental = any(strcmp(sType, {'bool', 'float', 'double'}));
end


%%
function bIsPrimitive = i_isPrimitiveType(sType)
bIsPrimitive = any(strcmp(sType, ...
    {'int8_t', 'int16_t', 'int32_t', 'int64_t', 'uint8_t', 'uint16_t', 'uint32_t', 'uint64_t'}));
end


%%
function i_addInterface(hInterfacesNode, stInterface, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory, mKnownEvents, mKnownMethods, mKnownFields)
hInterfaceNode = mxx_xmltree('add_node', hInterfacesNode, 'interface');
mxx_xmltree('set_attribute', hInterfaceNode, 'name', stInterface.sName);

i_addNamespaces(hInterfaceNode, stInterface.casNamespaces);
i_addEvents(hInterfaceNode, stInterface.sName, stInterface.astEvents, mKnownEvents, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory);
i_addMethods(hInterfaceNode, stInterface.sName, stInterface.astMethods, mKnownMethods, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory);
i_addFields(hInterfaceNode, stInterface.sName, stInterface.astFields, mKnownFields, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory);
end


%%
function i_addEvents(hInterfaceNode, sInterfaceName, astEvents, mKnownEvents, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory)
if isempty(astEvents)
    return;
end

hEventsNode = mxx_xmltree('add_node', hInterfaceNode, 'events');
for k = 1:numel(astEvents)
    stEvent = astEvents(k);

    sEventID = i_getEventID(mKnownEvents, sInterfaceName, stEvent.sName);
    sTypeRef = i_getTypeID(mKnownTypes, stEvent.sImplDatatype);

    i_addEventNode(hEventsNode, sEventID, stEvent.sName, sTypeRef);

    mKnownTypesNamespaces(stEvent.sImplDatatype) = stEvent.stType.casNamespaces;
    mKnownTypesCategory(stEvent.sImplDatatype) = stEvent.stType.sCategory;
end
end


%%
function sEventID = i_getEventID(mKnownEvents, sInterfaceName, sEventName)
sEventKey = i_getEventKey(sInterfaceName, sEventName);
if mKnownEvents.isKey(sEventKey)
    sEventID = mKnownEvents(sEventKey);
else
    nCounter = mKnownEvents.length + 1;
    sEventID = sprintf('ev%d', nCounter);
    mKnownEvents(sEventKey) = sEventID; %#ok<NASGU> handle-object, modified for usage outside of function
end
end


%%
function sFieldID = i_getFieldID(mKnownFields, sInterfaceName, sFieldName)
sFieldKey = i_getFieldKey(sInterfaceName, sFieldName);
if mKnownFields.isKey(sFieldKey)
    sFieldID = mKnownFields(sFieldKey);
else
    nCounter = mKnownFields.length + 1;
    sFieldID = sprintf('f%d', nCounter);
    mKnownFields(sFieldKey) = sFieldID; %#ok<NASGU> handle-object, modified for usage outside of function
end
end


%%
function i_addFields(hInterfaceNode, sInterfaceName, astFields, mKnownFields, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory)
if isempty(astFields)
    return;
end

hFieldsNode = mxx_xmltree('add_node', hInterfaceNode, 'fields');
for k = 1:numel(astFields)
    stField = astFields(k);

    sFieldID = i_getFieldID(mKnownFields, sInterfaceName, stField.sName);
    sTypeRef = i_getTypeID(mKnownTypes, stField.sImplDatatype);

    i_addFieldNode(hFieldsNode, sFieldID, stField.sName, sTypeRef);

    mKnownTypesNamespaces(stField.sImplDatatype) = stField.stType.casNamespaces;
    mKnownTypesCategory(stField.sImplDatatype) = stField.stType.sCategory;
end
end


%%
function i_addFieldNode(hFieldsNode, sFieldID, sFieldName, sTypeRef)
hFieldNode = mxx_xmltree('add_node', hFieldsNode, 'field');
mxx_xmltree('set_attribute', hFieldNode, 'fieldId', sFieldID);
mxx_xmltree('set_attribute', hFieldNode, 'name',    sFieldName);
if ~isempty(sTypeRef)
    mxx_xmltree('set_attribute', hFieldNode, 'typeRef', sTypeRef);
end
end


%%
function i_addMethods(hInterfaceNode, sInterfaceName, astMethods, mKnownMethods, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory)
if isempty(astMethods)
    return;
end

hMethodsNode = mxx_xmltree('add_node', hInterfaceNode, 'methods');
for k = 1:numel(astMethods)
    stMethod = astMethods(k);

    sMethodID = i_getMethodID(mKnownMethods, sInterfaceName, stMethod.sName);
    i_addMethodNode(hMethodsNode, stMethod, sMethodID, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory);
end
end


%%
function i_addMethodNode(hMethodsNode, stMethod, sMethodID, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory)
hMethodNode = mxx_xmltree('add_node', hMethodsNode, 'method');
mxx_xmltree('set_attribute', hMethodNode, 'methodId', sMethodID);
mxx_xmltree('set_attribute', hMethodNode, 'name',     stMethod.sName);
i_addMethodArgNodes(hMethodNode, stMethod.astArgs, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory);
end


%%
function i_addMethodArgNodes(hMethodNode, astArgs, mKnownTypes, mKnownTypesNamespaces, mKnownTypesCategory)
for i = 1:numel(astArgs)
    stArg = astArgs(i);

    if strcmpi(stArg.sDirection, 'In')
        sNodeName = 'in';
    else
        sNodeName = 'out';
    end
    hArgNode = mxx_xmltree('add_node', hMethodNode, sNodeName);
    mxx_xmltree('set_attribute', hArgNode, 'name',    stArg.sName);

    sTypeID = i_getTypeID(mKnownTypes, stArg.sImplDatatype);
    if ~isempty(sTypeID)
        mxx_xmltree('set_attribute', hArgNode, 'typeRef', sTypeID);
    end

    mKnownTypesNamespaces(stArg.sImplDatatype) = stArg.stType.casNamespaces;
    mKnownTypesCategory(stArg.sImplDatatype) = stArg.stType.sCategory;
end
end


%%
function sMethodID = i_getMethodID(mKnownMethods, sInterfaceName, sMethodName)
sMethodKey = i_getMethodKey(sInterfaceName, sMethodName);
if mKnownMethods.isKey(sMethodKey)
    sMethodID = mKnownMethods(sMethodKey);
else
    nCounter = mKnownMethods.length + 1;
    sMethodID = sprintf('met%d', nCounter);
    mKnownMethods(sMethodKey) = sMethodID; %#ok<NASGU> handle-object, modified for usage outside of function
end
end


%%
function sKey = i_getEventKey(sInterfaceName, sEventName)
sKey = sprintf('%s:%s', sInterfaceName, sEventName);
end


%%
function sKey = i_getMethodKey(sInterfaceName, sMethodName)
sKey = sprintf('%s:%s', sInterfaceName, sMethodName);
end


%%
function sKey = i_getFieldKey(sInterfaceName, sFieldName)
sKey = sprintf('%s:%s', sInterfaceName, sFieldName);
end


%%
function i_addEventNode(hEventsNode, sEventID, sEventName, sTypeRef)
hEventNode = mxx_xmltree('add_node', hEventsNode, 'event');
mxx_xmltree('set_attribute', hEventNode, 'eventId', sEventID);
mxx_xmltree('set_attribute', hEventNode, 'name',    sEventName);
if ~isempty(sTypeRef)
    mxx_xmltree('set_attribute', hEventNode, 'typeRef', sTypeRef);
end
end


%%
function sTypeID = i_getTypeID(mKnownTypes, sTypeName)
if isempty(sTypeName)
    sTypeID = '';
else
    if mKnownTypes.isKey(sTypeName)
        sTypeID = mKnownTypes(sTypeName);
    else
        nCounter = mKnownTypes.length + 1;
        sTypeID = sprintf('t%d', nCounter);
        mKnownTypes(sTypeName) = sTypeID; %#ok<NASGU> handle-object, modified for usage outside of function
    end
end
end


%%
function i_addNamespaces(hParentNode, casNamespaces)
if ~isempty(casNamespaces)
    hNamespacesNode = mxx_xmltree('add_node', hParentNode, 'namespaces');
    i_addNamespaceSymbolRecur(hNamespacesNode, casNamespaces);
end
end


%%
% add the first symbol in the list and continue recursively on the rest of the list until empty
function i_addNamespaceSymbolRecur(hParentNode, casNamespaces)
if ~isempty(casNamespaces)
    hNamespaceNode = mxx_xmltree('add_node', hParentNode, 'namespace');
    mxx_xmltree('set_attribute', hNamespaceNode, 'symbol', casNamespaces{1});

    i_addNamespaceSymbolRecur(hNamespaceNode, casNamespaces(2:end));
end
end


%%
function i_addEventAndMethodAndFieldReferences(stModelMapping, mKnownPorts, mKnownEvents, mKnownMethods, mKnownFields)
mKnownEventRefs = containers.Map();
mKnownMethodRefs = containers.Map();
mKnownFieldRefs = containers.Map();

% ------ inports (Events or Fields) -------
for i = 1:numel(stModelMapping.astInports)
    stInport = stModelMapping.astInports(i);

    bIsField = ~isempty(stInport.sMappedArFieldName);
    if bIsField
        hFieldRefsNode = i_getFieldRefsNode(stInport.sMappedArPortName, mKnownPorts, mKnownFieldRefs);

        [sFieldID, sAttributeName, sVarName] = i_getFieldAttributes(stInport, mKnownFields);
        i_addFieldRefNode(hFieldRefsNode, sFieldID, sAttributeName, sVarName);

    else
        hEventRefsNode = i_getEventRefsNode(stInport.sMappedArPortName, mKnownPorts, mKnownEventRefs);
    
        [sEventID, sVarName] = i_getEventAttributes(stInport, mKnownEvents);
        i_addEventRefNode(hEventRefsNode, sEventID, sVarName);
    end
end

% ------ outports (Events or Fields) -------
for i = 1:numel(stModelMapping.astOutports)
    stOutport = stModelMapping.astOutports(i);

    bIsField = ~isempty(stOutport.sMappedArFieldName);
    if bIsField
        hFieldRefsNode = i_getFieldRefsNode(stOutport.sMappedArPortName, mKnownPorts, mKnownFieldRefs);

        [sFieldID, sAttributeName, sVarName] = i_getFieldAttributes(stOutport, mKnownFields);
        i_addFieldRefNode(hFieldRefsNode, sFieldID, sAttributeName, sVarName);

    else
        hEventRefsNode = i_getEventRefsNode(stOutport.sMappedArPortName, mKnownPorts, mKnownEventRefs);
    
        [sEventID, sVarName] = i_getEventAttributes(stOutport, mKnownEvents);
        i_addEventRefNode(hEventRefsNode, sEventID, sVarName);
    end
end


% ------ function callers (Methods or Fields) ---------
for i = 1:numel(stModelMapping.astFunctionCallers)
    stFuncCaller = stModelMapping.astFunctionCallers(i);

    bIsField = ~isempty(stFuncCaller.sMappedArFieldName);
    if bIsField
        hFieldRefsNode = i_getFieldRefsNode(stFuncCaller.sMappedArPortName, mKnownPorts, mKnownFieldRefs);

        [sFieldID, sAttributeName, sFuncName] = i_getFieldAttributesForCaller(stFuncCaller, mKnownFields);
        i_addFieldRefNode(hFieldRefsNode, sFieldID, sAttributeName, sFuncName);

    else
        hMethodRefsNode = i_getMethodRefsNode(stFuncCaller.sMappedArPortName, mKnownPorts, mKnownMethodRefs);

        [sMethodID, sFuncName] = i_getMethodAttributesForCaller(stFuncCaller, mKnownMethods);
        i_addMethodRefNode(hMethodRefsNode, sMethodID, sFuncName);
    end
end

% ------ functions (Methods or Fields) ------
for i = 1:numel(stModelMapping.astFunctions)
    stFunction = stModelMapping.astFunctions(i);

    bIsField = ~isempty(stFunction.sMappedArFieldName);
    if bIsField
        hFieldRefsNode = i_getFieldRefsNode(stFunction.sMappedArPortName, mKnownPorts, mKnownFieldRefs);

        [sFieldID, sAttributeName, sFuncName] = i_getFieldAttributesForFunction(stFunction, mKnownFields);
        i_addFieldRefNode(hFieldRefsNode, sFieldID, sAttributeName, sFuncName);

    else
        hMethodRefsNode = i_getMethodRefsNode(stFunction.sMappedArPortName, mKnownPorts, mKnownMethodRefs);
    
        [sMethodID, sFuncName] = i_getMethodAttributesForFunction(stFunction, mKnownMethods);
        i_addMethodRefNode(hMethodRefsNode, sMethodID, sFuncName);
    end
end
end


%%
function hEventRefsNode = i_getEventRefsNode(sPortName, mKnownPorts, mKnownEventRefs)
if mKnownEventRefs.isKey(sPortName)
    hEventRefsNode = mKnownEventRefs(sPortName);
else
    hPortNode = mKnownPorts(sPortName);
    hEventRefsNode = mxx_xmltree('add_node', hPortNode, 'event-refs');
    mKnownEventRefs(sPortName) = hEventRefsNode; %#ok<NASGU> handle-object, modified here for outside usage
end
end


%%
function [sEventID, sVarName] = i_getEventAttributes(stPort, mKnownEvents)
sEventKey = i_getEventKey(stPort.sMappedArInterfaceName, stPort.sMappedArEventName);
sEventID = mKnownEvents(sEventKey);

sVarName = Eca.aa.CodeSymbols.getEventVariable( ...
    stPort.sMappedArInterfaceName, ...
    stPort.sMappedArPortName, ...
    stPort.sMappedArEventName);
end


%%
function [sFieldID, sAttributeName, sVarName] = i_getFieldAttributes(stPort, mKnownFields)
sFieldKey = i_getFieldKey(stPort.sMappedArInterfaceName, stPort.sMappedArFieldName);
sFieldID = mKnownFields(sFieldKey);

sAttributeName = 'notifierVar';
sVarName = Eca.aa.CodeSymbols.getFieldVariable( ...
    stPort.sMappedArInterfaceName, ...
    stPort.sMappedArPortName, ...
    stPort.sMappedArFieldName);
end


%%
function i_addEventRefNode(hEventRefsNode, sEventID, sVarName)
hEventRefNode = mxx_xmltree('add_node', hEventRefsNode, 'event-ref');
mxx_xmltree('set_attribute', hEventRefNode, 'eventRef', sEventID);
mxx_xmltree('set_attribute', hEventRefNode, 'var', sVarName);
end


%%
function hMethodRefsNode = i_getMethodRefsNode(sPortName, mKnownPorts, mKnownMethodRefs)
if mKnownMethodRefs.isKey(sPortName)
    hMethodRefsNode = mKnownMethodRefs(sPortName);
else
    hPortNode = mKnownPorts(sPortName);
    hMethodRefsNode = mxx_xmltree('add_node', hPortNode, 'method-refs');
    mKnownMethodRefs(sPortName) = hMethodRefsNode; %#ok<NASGU> handle-object, modified here for outside usage
end
end


%%
function hFieldRefsNode = i_getFieldRefsNode(sPortName, mKnownPorts, mKnownFieldRefs)
if mKnownFieldRefs.isKey(sPortName)
    hFieldRefsNode = mKnownFieldRefs(sPortName);
else
    hPortNode = mKnownPorts(sPortName);
    hFieldRefsNode = mxx_xmltree('add_node', hPortNode, 'field-refs');
    mKnownFieldRefs(sPortName) = hFieldRefsNode; %#ok<NASGU> handle-object, modified here for outside usage
end
end


%%
function [sMethodID, sFuncName] = i_getMethodAttributesForCaller(stFuncCaller, mKnownMethods)
sMethodKey = i_getMethodKey(stFuncCaller.sMappedArInterfaceName, stFuncCaller.sMappedArMethodName);
sMethodID = mKnownMethods(sMethodKey);

sFuncName = Eca.aa.CodeSymbols.getRequiredMethodFunc( ...
    stFuncCaller.sMappedArInterfaceName, ...
    stFuncCaller.sMappedArPortName, ...
    stFuncCaller.sMappedArMethodName);
end


%%
function [sFieldID, sAttributeName, sFuncName] = i_getFieldAttributesForCaller(stFuncCaller, mKnownFields)
sFieldKey = i_getFieldKey(stFuncCaller.sMappedArInterfaceName, stFuncCaller.sMappedArFieldName);
sFieldID = mKnownFields(sFieldKey);

if strcmp(stFuncCaller.sFieldAccessKind, 'get')
    sAttributeName = 'getterFunc';
    sFuncName = Eca.aa.CodeSymbols.getRequiredFieldGetterFunc( ...
        stFuncCaller.sMappedArInterfaceName, ...
        stFuncCaller.sMappedArPortName, ...
        stFuncCaller.sMappedArFieldName);
else
    sAttributeName = 'setterFunc';
    sFuncName = Eca.aa.CodeSymbols.getRequiredFieldSetterFunc( ...
        stFuncCaller.sMappedArInterfaceName, ...
        stFuncCaller.sMappedArPortName, ...
        stFuncCaller.sMappedArFieldName);
end
end


%%
function [sMethodID, sFuncName] = i_getMethodAttributesForFunction(stFunction, mKnownMethods)
sMethodKey = i_getMethodKey(stFunction.sMappedArInterfaceName, stFunction.sMappedArMethodName);
sMethodID = mKnownMethods(sMethodKey);

sFuncName = Eca.aa.CodeSymbols.getProvidedMethodFunc( ...
    stFunction.sMappedArInterfaceName, ...
    stFunction.sMappedArPortName, ...
    stFunction.sMappedArMethodName);
end


%%
function [sFieldID, sAttributeName, sFuncName] = i_getFieldAttributesForFunction(stFunction, mKnownFields)
sFieldKey = i_getFieldKey(stFunction.sMappedArInterfaceName, stFunction.sMappedArFieldName);
sFieldID = mKnownFields(sFieldKey);

if strcmp(stFunction.sFieldAccessKind, 'get')
    sAttributeName = 'getterFunc';
    sFuncName = Eca.aa.CodeSymbols.getProvidedFieldGetterFunc( ...
        stFunction.sMappedArInterfaceName, ...
        stFunction.sMappedArPortName, ...
        stFunction.sMappedArFieldName);
else
    sAttributeName = 'setterFunc';
    sFuncName = Eca.aa.CodeSymbols.getProvidedFieldSetterFunc( ...
        stFunction.sMappedArInterfaceName, ...
        stFunction.sMappedArPortName, ...
        stFunction.sMappedArFieldName);
end
end


%%
function i_addMethodRefNode(hMethodRefsNode, sMethodID, sFuncName)
hEventRefNode = mxx_xmltree('add_node', hMethodRefsNode, 'method-ref');
mxx_xmltree('set_attribute', hEventRefNode, 'methodRef', sMethodID);
mxx_xmltree('set_attribute', hEventRefNode, 'func', sFuncName);
end


%%
function i_addFieldRefNode(hFieldRefsParentNode, sFieldID, sAttributeName, sAttributeValue)
hFieldRefNode = mxx_xmltree('get_nodes', hFieldRefsParentNode, sprintf('./field-ref[@fieldRef="%s"]', sFieldID));
if isempty(hFieldRefNode)
    hFieldRefNode = mxx_xmltree('add_node', hFieldRefsParentNode, 'field-ref');
    mxx_xmltree('set_attribute', hFieldRefNode, 'fieldRef', sFieldID);
end
mxx_xmltree('set_attribute', hFieldRefNode, sAttributeName, sAttributeValue);
end



function ep_sl_model_constraints_export(stModel, sFile)
% Exports constraints XML based on the provided SL model data.
%
% function ep_sl_model_constraints_export(stModel, sFile)
%
%   INPUT               DESCRIPTION
%     stModel             (struct)  SL model data
%     sFile               (string)  full path to export XML
%


%%
if (nargin < 2)
    sFile = fullfile(pwd, 'sl_constraints.xml');
end
i_createConstraintFile(stModel, sFile);
end


%%
function i_createConstraintFile(stModel, sXmlFileName)
hConstRoot = mxx_xmltree('create', 'architectureConstraints');
xOnCleanupClose = onCleanup(@() i_closeAndSaveDoc(hConstRoot, sXmlFileName));

if isempty(stModel.astParams)
    return;
end

for i = 1:numel(stModel.astSubsystems)
    stSubsystem = stModel.astSubsystems(i);
    
    astScopeParams = i_getParamsAsSeenFromScope(stModel.astParams, stSubsystem.astParamRefs);
    if ~isempty(astScopeParams)
        hScope = mxx_xmltree('add_node', hConstRoot, 'scope');
        mxx_xmltree('set_attribute', hScope, 'path', i_removeModelPrefix(stSubsystem.sVirtualPath));
        
        bAssAdded = i_addAssumptionsToScope(hScope, astScopeParams);
        if ~bAssAdded
            mxx_xmltree('delete_node', hScope);
        end
    end
end
end


%%
function i_closeAndSaveDoc(hDoc, sFile)
mxx_xmltree('save', hDoc, sFile);
mxx_xmltree('clear', hDoc);
end


%%
function astScopeParams = i_getParamsAsSeenFromScope(astParams, astScopeParamRefs)
astScopeParams = [];
if (isempty(astParams) || isempty(astScopeParamRefs))
    return;
end

% select only the parameters that are available in the context of the scope
astScopeParams = astParams([astScopeParamRefs(:).iVarIdx]);

% iterate on the reduced set and reduce the block references to the ones relevant for the scope
for k = 1:length(astScopeParams)
    astScopeParams(k).astBlockInfo = astScopeParams(k).astBlockInfo(astScopeParamRefs(k).aiBlockIdx);
end
end


%%
function bAnyAssAdded = i_addAssumptionsToScope(hScope, astParams)
bAnyAssAdded = false;

if isempty(astParams)
    return;
end

mKnownParams = i_createKnownParamsMap(astParams);
jParamsForSkipping = java.util.HashSet();
for k = 1:length(astParams)
    stParam = astParams(k);
    jParamsForSkipping.add(i_getKeyFromParam(stParam));
    
    for m = 1:length(stParam.astBlockInfo)
        stBlockInfo = stParam.astBlockInfo(m);
        
        % skip not resticted calibrations
        oConstraint = stBlockInfo.oConstraint;
        if oConstraint.isEmptyKind()
            continue;
        end
        
        if oConstraint.isArrayKind()
            bAssAdded = i_addSignalArrayAssumption(hScope, stParam, oConstraint);
        else
            bAssAdded = i_addSignalParamAssumption(hScope, stParam, oConstraint, mKnownParams, jParamsForSkipping);
        end
        bAnyAssAdded = bAnyAssAdded || bAssAdded;
    end
end
end


%%
function mKnownParams = i_createKnownParamsMap(astParams)
mKnownParams = containers.Map();
for i = 1:numel(astParams)
    sKey = i_getKeyFromParam(astParams(i));
    mKnownParams(sKey) = astParams(i);
end
end


%%
function sKey = i_getKeyFromParam(stParam)
sKey = i_getKey(stParam);
end


%%
function sKey = i_getKeyFromVariable(stVar)
sKey = i_getKey(stVar);
end


%%
function sName = i_getKey(stParamVar)
if strcmp(stParamVar.sSourceType, 'model workspace')
    sName = [stParamVar.sSource ':' stParamVar.sRawName];
else
    sName = stParamVar.sRawName;
end
end


%%
function stConstraintParam = i_matchParam(stVar, mKnownParams)
sKey = i_getKeyFromVariable(stVar);
if mKnownParams.isKey(sKey)
    stConstraintParam = mKnownParams(sKey);
else
    stConstraintParam = [];
end
end


%%
function bAssAdded = i_addSignalParamAssumption(hScope, stParam, oConstraint, mKnownParams, jParamsForSkipping)
bAssAdded = false;

% check if the constraint needs to be represented by a signal-signal constraint
oValueParam = oConstraint.getValueParam();
if oValueParam.isVariable()
    stConstraintParam = i_matchParam(oValueParam.getVariable(), mKnownParams);
    if ~isempty(stConstraintParam)
        if ~jParamsForSkipping.contains(i_getKeyFromParam(stConstraintParam))
            bAssAdded = i_addSignalSignalAssumption(hScope, stParam, oConstraint, stConstraintParam);
        end
        return;
    end
end

% after excluding possibility for a signal-signal constraint, assuming now that we have a signal-value constraint 
stConstraintValue = oValueParam.getValue();

% if we have a signal-value constraint, we have to ensure that the expression represeting the value is fixed and cannot
% be changed during simulations by one of the Parameters that is accepted as a test interface object by EP
bIsValueExpressionFixed = true;
for i = 1:numel(stConstraintValue.astExpressionVars)
    sExpressionVarKey = i_getKeyFromVariable(stConstraintValue.astExpressionVars(i));
    if mKnownParams.isKey(sExpressionVarKey)
        bIsValueExpressionFixed = false;
        break;
    end
end

if bIsValueExpressionFixed
    bAssAdded = i_addSignalValueAssumption(hScope, stParam, oConstraint, stConstraintValue);
end
end


%%
function sConstraintValue = i_getValueString(stConstraintValue)
sConstraintValue = sprintf('%.16e', stConstraintValue.xVal);
end


%%
function bAssAdded = i_addSignalValueAssumption(hScope, stParam, oConstraint, stConstraintValue)
bAssAdded = false;
iParamEntries = prod(stParam.aiWidth);
iValueEntries = numel(stConstraintValue.xVal);

bIsNumberOfElemsEqual = iParamEntries == iValueEntries;
bIsParamScalar = iParamEntries == 1; 
bIsValueScalar = iValueEntries == 1;

bIsConsistent = bIsNumberOfElemsEqual || bIsParamScalar || bIsValueScalar;
if ~bIsConsistent
    warning('EP:INVALID_CONSTRAINT', ...
        'Found "param" assumption with inconsistent dimensions for the parameters "%s".', stParam.sName);
    return;
end

hAssumptionsNode = mxx_xmltree('add_node', hScope, 'assumptions');
mxx_xmltree('set_attribute', hAssumptionsNode, 'origin', oConstraint.getOrigin());

sRelop = lower(oConstraint.getRelop());

iAssumptions = max(iParamEntries, iValueEntries);
if (iAssumptions == 1)
    sSigLeft  = i_makeUniqueNameWithPath(stParam);
    sConstraintValue = i_getValueString(stConstraintValue);
    i_addSignalValueNode(hAssumptionsNode, sSigLeft, sConstraintValue, sRelop);
    
else
    casSigLeft = i_getParamArrayEntries(stParam, iAssumptions);
    casConstraintValue = i_getValueArrayEntries(stConstraintValue, iAssumptions);
    for i=1:iAssumptions
        i_addSignalValueNode(hAssumptionsNode, casSigLeft{i}, casConstraintValue{i}, sRelop);
    end
end
bAssAdded = true;
end


%%
function bAssAdded = i_addSignalSignalAssumption(hScope, stParam, oConstraint, stConstraintParam)
bAssAdded = false;
iParamEntries = prod(stParam.aiWidth);
iConstParamEntries = prod(stConstraintParam.aiWidth);

bIsNumberOfElemsEqual = iParamEntries == iConstParamEntries;
bIsParamScalar = iParamEntries == 1; 
bIsConstParamScalar = iConstParamEntries == 1;

bIsConsistent = bIsNumberOfElemsEqual || bIsParamScalar || bIsConstParamScalar;
if ~bIsConsistent
    warning('EP:INVALID_CONSTRAINT', ...
        'Found "param" assumption with inconsistent dimensions for the parameters "%s".', stParam.sName);
    return;
end

hAssumptionsNode = mxx_xmltree('add_node', hScope, 'assumptions');
mxx_xmltree('set_attribute', hAssumptionsNode, 'origin', oConstraint.getOrigin());

sRelop = lower(oConstraint.getRelop());

iAssumptions = max(iParamEntries, iConstParamEntries);
if (iAssumptions == 1) 
    sSigLeft  = i_makeUniqueNameWithPath(stParam);
    sSigRight = i_makeUniqueNameWithPath(stConstraintParam);
    i_addSignalSignalNode(hAssumptionsNode, sSigLeft, sSigRight, sRelop);
    
else
    casSigLeft = i_getParamArrayEntries(stParam, iAssumptions);
    casSigRight = i_getParamArrayEntries(stConstraintParam, iAssumptions);
    for i=1:iAssumptions
        i_addSignalSignalNode(hAssumptionsNode, casSigLeft{i}, casSigRight{i}, sRelop);
    end
end
bAssAdded = true;
end


%%
function casSig = i_getParamArrayEntries(stParam, iAssumptions)
sName = i_makeUniqueNameWithPath(stParam);
aiWidth = stParam.aiWidth;
casSig = cell(1, iAssumptions);
if all(aiWidth == 1)        
    casSig(:) = {sName};
else
    if any(aiWidth == 1)
        for i = 1:prod(aiWidth)
            casSig{i} = sprintf('%s(%i)', sName, i);
        end
    else
        n = 1;
        for i = 1:aiWidth(1)
           for j = 1:aiWidth(2)
               casSig{n} = sprintf('%s(%i)(%i)', sName, i, j);
               n = n+1;
           end
        end
    end
end
end


%%
function casSig = i_getValueArrayEntries(stConstraintValue, iAssumptions)
xValue = stConstraintValue.xVal;
aiWidth = size(xValue);
casSig = cell(1, iAssumptions);
if all(aiWidth == 1)        
    casSig(:) = {sprintf('%.16e', xValue);};
else
    if any(aiWidth == 1)
        for i = 1:prod(aiWidth)
            casSig{i} = sprintf('%.16e', xValue(i));
        end
    else
        n = 1;
        for i = 1:aiWidth(1)
           for j = 1:aiWidth(2)
               casSig{n} = sprintf('%.16e', xValue(i,j));
               n = n+1;
           end
        end
    end
end
end


%%
function bAssAdded = i_addSignalArrayAssumption(hScope, stParam, oConstraint)
bAssAdded = false;
if ~i_isVector(stParam)
    warning('EP:INVALID_CONSTRAINT', 'Found "array" assumption for the non-vector parameter "%s".', stParam.sName);
    return;
end
nElems = prod(stParam.aiWidth);
if (nElems < 2)
    return;
end


hAssumptionsNode = mxx_xmltree('add_node', hScope, 'assumptions');
mxx_xmltree('set_attribute', hAssumptionsNode, 'origin', oConstraint.getOrigin());

sRelop = lower(oConstraint.getRelop());
sName = stParam.sName;
for i = 2:nElems
    sSigLeft  = sprintf('%s(%i)', sName, (i - 1));
    sSigRight = sprintf('%s(%i)', sName, i);
    
    i_addSignalSignalNode(hAssumptionsNode, sSigLeft, sSigRight, sRelop);
end
bAssAdded = true;
end


%%
function i_addSignalSignalNode(hParentNode, sSigLeft, sSigRight, sRelop)
hSigSigNode = mxx_xmltree('add_node', hParentNode, 'signalSignal');
mxx_xmltree('set_attribute', hSigSigNode, 'signal1',  sSigLeft);
mxx_xmltree('set_attribute', hSigSigNode, 'relation', sRelop);
mxx_xmltree('set_attribute', hSigSigNode, 'signal2',  sSigRight);
end


%%
function i_addSignalValueNode(hParentNode, sSigLeft, sValueRight, sRelop)
hSigSigNode = mxx_xmltree('add_node', hParentNode, 'signalValue');
mxx_xmltree('set_attribute', hSigSigNode, 'signal',   sSigLeft);
mxx_xmltree('set_attribute', hSigSigNode, 'relation', sRelop);
mxx_xmltree('set_attribute', hSigSigNode, 'value',    sValueRight);
end


%%
function bIsVec = i_isVector(stParam)
bIsVec = isvector(stParam.xValue);
end


%%
function sPath = i_removeModelPrefix(sPath)
if any(sPath == '/')
    sPath = regexprep(sPath, '^[^/]+/', '');
else
    sPath = ''; % model as toplevel subsystem
end
end


%%
function sName = i_makeUniqueNameWithPath(stParam)
sPath = i_removeModelPrefix(stParam.astBlockInfo(1).sVirtualPath);
sName = [sPath, '/', stParam.sName];
end
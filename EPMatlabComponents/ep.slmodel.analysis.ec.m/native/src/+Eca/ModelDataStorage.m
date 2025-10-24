classdef ModelDataStorage < handle
    properties (SetAccess = private, Hidden = true)
        sModelContext = '';
        oDD = [];
        sInitScript = '';
        sFallbackScript = [tempname(pwd()), '.m'];
        
        hGetTypeInfoFunc = [];
        hGetVarFunc = [];
        
        bStorageTargetSet = false;
        mTypesToInstance
        mTypesAoB
    end
    
    methods
        function oObj = ModelDataStorage(sModelContext)
            try
                get_param(sModelContext, 'handle');
            catch oEx
                error('EP:USAGE_ERROR', 'Model context is invalid.');
            end
            oObj.sModelContext = getfullname(sModelContext);
            
            hModelResolveFunc = @(s) Simulink.data.evalinGlobal(sModelContext, s);
            oObj.hGetTypeInfoFunc = @(t) ep_core_feval('ep_sl_type_info_get', t, hModelResolveFunc);
            oObj.hGetVarFunc = hModelResolveFunc;
            oObj.mTypesToInstance = containers.Map();
            oObj.mTypesAoB = containers.Map();
        end
        
        function bIsSet = isTargetSet(oObj)
            bIsSet = oObj.bStorageTargetSet;
        end
        
        function oObj = setDD(oObj, oDD)
            if oObj.bStorageTargetSet
                error('EP:USAGE_ERROR', 'Storage target is aleady set. Cannot re-set it.');
            end
            oObj.oDD = oDD;
            oObj.bStorageTargetSet = true;
        end
        
        function oObj = setInitScript(oObj, sInitScript)
            if oObj.bStorageTargetSet
                error('EP:USAGE_ERROR', 'Storage target is aleady set. Cannot re-set it.');
            end
            oObj.sInitScript = sInitScript;
            oObj.bStorageTargetSet = true;
        end
        
        function sTypeInstance = getTypeInstanceScalar(oObj, sType)
            if oObj.mTypesToInstance.isKey(sType)
                sTypeInstance = oObj.mTypesToInstance(sType);
            else
                sTypeInstance = i_findOrCreateTypeInstance(oObj, sType);
                oObj.mTypesToInstance(sType) = sTypeInstance;
            end
        end
        
        function sTypeInstance = getTypeInstanceArrayOfBuses(oObj, sBusType, aiCompiledDim)
            sBusType = regexprep(sBusType, '^Bus:\s*', ''); % rm Bus: prefix since internal methods assume this
            sTypeInstance = i_getBusArrayTypeInstanceName(sBusType, aiCompiledDim);
            if ~oObj.mTypesAoB.isKey(sTypeInstance)
                i_createAndPersistArrayOfBusesInstance(oObj, sTypeInstance, sBusType, aiCompiledDim);
                oObj.mTypesAoB(sTypeInstance) = true;
            end
        end
        
        function sTypeInstance = getTypeInstance(oObj, sType, aiCompiledDim)
            if (nargin < 3)
                bIsScalar = true; % simple scalar
            else
                bIsScalar = isequal(aiCompiledDim, [1 1]) || isequal(aiCompiledDim, [2 1 1]);
            end
            
            sTypeInstance = oObj.getTypeInstanceScalar(sType);
            if (~isempty(sTypeInstance) && ~bIsScalar)
                if startsWith(sTypeInstance, 'BTC_EP_BUS_')
                    sTypeInstance = oObj.getTypeInstanceArrayOfBuses(sType, aiCompiledDim);
                else
                    sTypeInstance = sprintf('repmat(%s, %s)', sTypeInstance, i_getDimsAsString(aiCompiledDim));
                end
            end
        end
        
        function sValueInstance = getValueInstance(oObj, sType, aiCompiledDim)
            if (nargin < 3)
                bIsScalar = true; % simple scalar
            else
                bIsScalar = isequal(aiCompiledDim, [1 1]) || isequal(aiCompiledDim, [2 1 1]);
            end
            
            % use type instance as value instance as default ...
            sValueInstance = oObj.getTypeInstanceScalar(sType);
            if (~isempty(sValueInstance) && startsWith(sValueInstance, 'BTC_EP_'))
                % ... but for Simulink.Parameters use the Value property
                if isempty(oObj.oDD)
                    sValueInstance = sprintf('%s.Value', sValueInstance);
                else
                    sValueInstance = sprintf('%s.Value', sValueInstance);
                    sValueInstance = ...
                        sprintf('Simulink.data.evalinGlobal(''%s'', ''%s'')', oObj.sModelContext, sValueInstance);
                    
                end
            end
            if (~isempty(sValueInstance) && ~bIsScalar)
                sValueInstance = sprintf('repmat(%s, %s)', sValueInstance, i_getDimsAsString(aiCompiledDim));
            end
        end
    end
    
    methods (Hidden = true)        
        function stInfo = getTypeInfo(oObj, sType)
            try
                stInfo = feval(oObj.hGetTypeInfoFunc, sType);
            catch
                stInfo = [];
            end
        end
                
        function xVar = getVariable(oObj, sVariableName)
            try
                xVar = feval(oObj.hGetVarFunc, sVariableName);
            catch
                xVar = [];
            end
        end
        
        function persistContent(oObj, sContent)
            if isempty(sContent)
                return;
            end
            if ~oObj.bStorageTargetSet
                warning('EP:USAGE_ERROR:FALLBACK', ...
                    'Storage target is not set. Persisting to temporary file: %s.', oObj.sFallbackScript);
                i_addInitScriptContent(oObj.sFallbackScript, sContent, true);
                return;
            end
            
            if ~isempty(oObj.oDD)
                i_addContentDD(oObj.oDD, sContent);
            else
                i_addInitScriptContent(oObj.sInitScript, sContent, true);
            end
        end        
    end
end


%%
function i_createAndPersistArrayOfBusesInstance(oObj, sTypeInstance, sBusType, aiCompiledDim)
sValueInstance = getValueInstance(oObj, sBusType, aiCompiledDim);
sDims = ['[', i_getDimsAsString(aiCompiledDim), ']'];
sContent = i_getContentParamCreation(sTypeInstance, ['Bus: ', sBusType], sValueInstance, sDims);
oObj.persistContent(sContent);
end     


%%
function sDimString = i_getDimsAsString(aiCompiledDim)
nDims = aiCompiledDim(1);

switch nDims
    case 1
        nLength = aiCompiledDim(2);
        if (nLength > 1)
            sDimString = sprintf('%d, 1', nLength); % array signal --> column values
        else
            sDimString = '1';
        end
        return;
        
    case 2
        sDimString = sprintf('%d, %d', aiCompiledDim(2), aiCompiledDim(3));
        
    otherwise
        error('EP:NOT_SUPPORTED', 'Only supporting 1-dim or 2-dim types.');
end
end


%%
function sTypeInstanceName = i_getBusArrayTypeInstanceName(sType, aiCompiledDim)
sDimString = i_getDimsAsString(aiCompiledDim);
sDimKey = ['__D', strrep(sDimString, ', ', 'c_')];
sTypeInstanceName = ['BTC_EP_AOB_', sType, sDimKey];
end


%%
function sTypeInstance = i_findOrCreateTypeInstance(oObj, sType)
sTypeInstance = '';

stInfo = oObj.getTypeInfo(sType);
if isempty(stInfo)
    return;
end

if stInfo.bIsValidType
    sTypeInstance = i_getNonStructTypeInstance(stInfo, oObj);
else
    if stInfo.bIsBus
        sTypeInstance = i_createAndPersistBusType(stInfo, oObj);
    end
end
end


%%
function sTypeInstance = i_createAndPersistBusType(stInfo, oObj)
oBus = oObj.getVariable(stInfo.sType);

aoElements = oBus.Elements;
nElems = numel(aoElements);
casFields = cell(1, nElems);
for i = 1:nElems
    oElem = aoElements(i);
    
    aiDims = oElem.Dimensions;
    aiDims = [numel(aiDims), aiDims]; %#ok<AGROW> % normalize to CompileDimension standard notation
    
    casFields{i} = sprintf('  ''%s'', %s', oElem.Name, oObj.getValueInstance(oElem.DataType, aiDims));
end
sFieldsStr = strjoin(casFields, ', ...\n');

casStructValueStr = { ...
    'struct( ...', ...
    [sFieldsStr, ')']};
sStructValueStr = strjoin(casStructValueStr, '\n');

sTypeInstance = sprintf('BTC_EP_BUS_%s', stInfo.sType);

sContent = i_getContentParamCreation(sTypeInstance, ['Bus: ', stInfo.sType], sStructValueStr);
oObj.persistContent(sContent);
end


%%
function sTypeInstance = i_getNonStructTypeInstance(stInfo, oObj)
if stInfo.bIsEnum
    sEnumType = stInfo.casAliasChain{end};
    sTypeInstance = sprintf('%s.%s', sEnumType, stInfo.astEnum(1).Key);
    return;
end

if strcmp(stInfo.sBaseType, 'boolean')
    sTypeInstance = 'false';
    return;
end

if startsWith(stInfo.sEvalType, 'fixdt(')
    sTypeInstance = i_createAndPersistFxpType(stInfo, oObj);
else
    sTypeInstance = sprintf('%s(0)', stInfo.sBaseType);
end
end


%%
function sTypeInstance = i_createAndPersistFxpType(stInfo, oObj)
if isvarname(stInfo.sType)
    sUniquePost = stInfo.sType;
else
    sUniquePost = num2hex(java.lang.String(stInfo.sType).hashCode);
end
sTypeInstance = sprintf('BTC_EP_%s', sUniquePost);

sContent = i_getContentParamCreation(sTypeInstance, stInfo.sEvalType, i_getRepresentableValue(stInfo));
oObj.persistContent(sContent);
end


%%
function sValue = i_getRepresentableValue(stInfo)
% note: use zero as default if possible (potentially impossible only for FxpTypes) 
% also take care of non-zero offset (aka bias); here it could be that zero is not part of the reprentable range
if (~stInfo.bIsFxp || i_isZeroInAllowedRange(stInfo))
    sValue = '0';
else
    sValue = sprintf('%.17g', stInfo.dOffset);
end
end


%%
function bIsInAllowedRange = i_isZeroInAllowedRange(stTypeInfo)
oValZero = ep_sl.Value(0);
bIsInAllowedRange = ...
    (stTypeInfo.oRepresentMin.compareTo(oValZero) <= 0) && ...
    (stTypeInfo.oRepresentMax.compareTo(oValZero) >= 0);
end


%%
function sContent = i_getContentParamCreation(sParamName, sDataType, sValue, sDims)
casLines = { ...
    sprintf('%s = Simulink.Parameter;', sParamName), ...
    sprintf('%s.DataType = ''%s'';', sParamName, sDataType), ...
    sprintf('%s.Value = %s;', sParamName, sValue)};
if (nargin > 4)
    casLines{end + 1} = sprintf('%s.Dimensions = %s;', sParamName, sDims);
end

sContent = sprintf('%s\n', casLines{:});
end


%%
function i_addInitScriptContent(sInitScript, sContent, bEvalinBase)
if (nargin < 3)
    bEvalinBase = false;
end
if isempty(sContent)
    return;
end

sContent = [newline(), sContent]; % prepend a newline to *new* content
i_addContent(sInitScript, sContent);
if bEvalinBase
    i_evalinBase(sContent);
end
end


%%
function i_addContent(sFile, sContent)
hFid = fopen(sFile, 'a'); % IMPORTANT: use _append_ to add content at the end of file
if (hFid > 0)
    oOnCleanupClose = onCleanup(@() fclose(hFid));
    
    fprintf(hFid, '%s', sContent);
else
    fprintf('\n[ERROR] Could not write to file "%s".\n', sFile);
end
end


%%
function i_addContentDD(oDD, sContent)
sTmpScript = ['tmp' datestr(now,30), '.m']; %#ok<TNOW1,DATST> 
i_addContent(sTmpScript, sContent);

oSectionData = oDD.getSection('Design Data');
oSectionData.importFromFile(sTmpScript);
oDD.saveChanges();

delete(sTmpScript);
end


%%
function i_evalinBase(sContent)
sTmpScript = [tempname(pwd), '.m'];
i_addContent(sTmpScript, sContent);

try %#ok<TRYNC>
    evalin('base', ['run(''', sTmpScript, ''');']);
end

delete(sTmpScript);
end


function stResult = ep_model_tl_params_get(varargin)
% Returns the Parameters of a Simulink model. 
%
% function stResult = stResult = ep_model_tl_params_get(varargin)
%
%   INPUT               DESCRIPTION
%       varargin           (key-values)   arbitrary number of key-value pairs
%
%  -------- KEY ---------- VALUE ---------------------------------------------------------------------------------------
%         Environment      (object)          EPEnvirionment object
%         ModelContext     (string/handle)   name/handle of a model or path/handle of a model block
%                                            Note: it is assumed that the model is already loaded in memory
%
%
%   OUTPUT              DESCRIPTION
%       stResult              (struct)  the result struct
%         .astParams          (array)     structs with following info:
%           .sName            (string)      name of Parameter in workspace as used for EP 
%                                           (note: specially for model workspace parameters name of the mode is prepended)
%           .sRawName         (string)      name of Parameter in workspace as used in model
%           .sSource          (string)      'base workspace' | '<name-of-SLDD>'
%           .sSourceType      (string)      'base workspace' | 'data dictionary' | 'model workspace'
%           .sSourceAccess    (string)      optional path information needed to access the paramter
%           .bIsModelArg      (boolean)     true, if the parameter is a model workspace parameter that is marked as model
%                                           argument also
%           .sClass           (string)      class of Parameter (default: double)
%           .sType            (string)      type of Parameter (default: double)
%           .aiWidth          (array)       parameter's dimensions
%           .astBlockInfo     (array)       structs with following info:
%             .sPath          (string)        model path of block
%             .sBlockType     (string)        type of block
%             .stUsage        (string)        struct with usages in Block as fieldnames
%                .(<Usage>)   (string)          expression in block where Variable is used
%
%   REMARKS
%     Provided Model and associated TL DataDictionary are assumed to be open.
%


%%
[xEnv, stOpt] = i_evalArgs(varargin{:});
astParams = i_searchParams(xEnv, stOpt);
stResult = struct( ...
    'astParams',  astParams);
end


%%
function astParams = i_searchParams(xEnv, stOpt)
astParams = [];

sCurrDd = i_getCurrentDd();
if isempty(sCurrDd)
    return;
end

astBlockRefs = i_getCalibrationBlockRefs(stOpt);
astAccess = arrayfun(@i_getAccessInfo, astBlockRefs);
astParams = i_translateAccessInfosToParams(astAccess, sCurrDd);

abSelect = arrayfun(@(st) ~isempty(st.astBlockInfo), astParams);
astParams = astParams(abSelect);

astParams = i_adaptVirtualLocations(astParams, stOpt.sModelContext);
end


%%
function astParams = i_translateAccessInfosToParams(astAccess, sCurrDd)
mKnownParams = containers.Map();
astParams = [];

for i = 1:numel(astAccess)
    stAccess = astAccess(i);
    if stAccess.bIsDdRef
        sKey = stAccess.sDdAccess;
    else
        sKey = stAccess.sName;
    end
    
    if ~stAccess.bIsValid
        continue;
    end
    
    if mKnownParams.isKey(sKey)
        iIdx = mKnownParams(sKey);
        astParams(iIdx).astBlockInfo = i_extendArray( ...
            astParams(iIdx).astBlockInfo, i_getBlockInfos(stAccess.sName, stAccess.sBlockPath, stAccess)); %#ok<AGROW>
    else
        astParams = i_extendArray(astParams, i_translateToParam(stAccess, sCurrDd));
        mKnownParams(sKey) = numel(astParams);
    end   
end
end


%%
function astBlockInfos = i_getBlockInfos(sName, sBlockPath, stAccess)
astBlockInfos = ep_param_block_info_get(sName, sBlockPath);

% select only the block infos that match the target expression of the access
if strcmp(stAccess.sUsage, 'sf-const')
    sTargetExpression = stAccess.sName;
else
    sTargetExpression = stAccess.sExpression;
end
abSelect = arrayfun(@(st) i_matchExpression(st, sTargetExpression), astBlockInfos);
astBlockInfos = astBlockInfos(abSelect);
end


%%
function bIsMatch = i_matchExpression(stBlockInfo, sTargetExpression)
bIsMatch = false;
casFields = fieldnames(stBlockInfo.stUsage);
for i = 1:numel(casFields)
    sFoundExpression = strtrim(stBlockInfo.stUsage.(casFields{i}));
    bIsMatch = strcmp(sFoundExpression, sTargetExpression);
    if bIsMatch
        return; % early return for first match
    end
end
end


%%
function astArray = i_extendArray(astArray, stElem)
if isempty(astArray)
    astArray = stElem;
else
    astArray = [astArray, stElem];
end
end


%%
function stParam = i_translateToParam(stAccess, sCurrDd)
if stAccess.bIsDdRef
    sSource       = sCurrDd;
    sSourceType   = 'TL data dictionary';
    sSourceAccess = stAccess.sDdAccess;
else
    sSource       = '';
    sSourceType   = 'base workspace';
    sSourceAccess = '';
end
stParam = struct( ...
    'sName',         stAccess.sName, ...
    'sRawName',      stAccess.sName, ...
    'sSource',       sSource, ...
    'sSourceType',   sSourceType, ...
    'sSourceAccess', sSourceAccess, ...
    'bIsModelArg',   false, ...
    'sClass',        stAccess.stProps.sClass, ...
    'sType',         stAccess.stProps.sType, ...
    'xValue',        stAccess.stProps.xValue, ...
    'aiWidth',       stAccess.stProps.aiWidth, ...
    'sMin',          stAccess.stProps.sMin, ...
    'sMax',          stAccess.stProps.sMax, ...
    'astBlockInfo',  i_getBlockInfos(stAccess.sName, stAccess.sBlockPath, stAccess));
end


%%
function stAccess = i_getAccessInfo(stBlockRef)
stAccess = struct( ...
    'bIsValid',          false, ...
    'sName',             '', ...
    'sBlockPath',        '', ...
    'sUsage',            '', ...
    'sExpression',       '', ...
    'bIsDdRef',          false, ...
    'sDdAccess',         '', ...
    'stProps',           []);

[stAccess.sBlockPath, stAccess.sUsage, sAccessExpr] = i_getUsageAndAccessExpression(stBlockRef);
if isempty(sAccessExpr)
    return;
end

stExprInfo = atgcv_m01_expression_info_get(sAccessExpr, stAccess.sBlockPath, true);
stAccess.sExpression = stExprInfo.sExpression;

bCanBeUsedForMIL = stExprInfo.bIsValid && (stExprInfo.bIsLValue || strcmp(stExprInfo.sFuncName, 'ddv'));
if ~bCanBeUsedForMIL
    return;
end

stAccess.bIsDdRef = strcmp(stExprInfo.sFuncName, 'ddv');
if stAccess.bIsDdRef
    [stAccess.sDdAccess, stAccess.stProps] = i_getDdAccessAndPropertiesFromDdExpressionInfo(stExprInfo);
    
    stAccess.sName = regexprep(stAccess.sDdAccess, '.*/', '');
else
    hResolverFunc = atgcv_m01_generic_resolver_get(stAccess.sBlockPath);
    stAccess.stProps = atgcv_m01_ws_var_info_get(stExprInfo.sExpression, hResolverFunc);
    
    stAccess.sName = stAccess.sExpression;
end

stAccess.bIsValid = true;
end


%%
function [sDdAccess, stProps] = i_getDdAccessAndPropertiesFromDdExpressionInfo(stExpression)
[~, ~, hDdVar] = eval(stExpression.sExpression);
sDdAccess = dsdd('GetAttribute', hDdVar, 'path');
stProps = struct( ...
    'sClass',    'double', ...
    'sType',     'double', ...
    'sUserType', 'double', ...
    'xValue',    stExpression.xValue, ...
    'aiWidth',   size(stExpression.xValue), ...
    'sMin',      i_double2String(dsdd('GetMin', hDdVar)), ...
    'sMax',      i_double2String(dsdd('GetMax', hDdVar)));
end


%%
function sString = i_double2String(dDouble)
if isempty(dDouble)
    sString = '';
else
    sString = sprintf('%.17g', dDouble);
end
end


%%
function [sBlockPath, sUsage, sAccessExpr] = i_getUsageAndAccessExpression(stBlockRef)
bIsSfObject = strcmp(stBlockRef.objectKind, 'sfobject');
if bIsSfObject
    [sBlockPath, sUsage, sAccessExpr] = i_getUsageAndAccessExpressionFromSfObjectRef(stBlockRef);

else
    [sBlockPath, sUsage, sAccessExpr] = i_getUsageAndAccessExpressionFromBlockRef(stBlockRef);
end
end


%%
function [sBlockPath, sUsage, sAccessExpr] = i_getUsageAndAccessExpressionFromBlockRef(stBlockRef)
sAccessExpr = '';

sBlockPath = stBlockRef.object;
sUsage = regexprep(stBlockRef.propertyName, '\.class$', '');

stTlcg = get_tlcg_data(sBlockPath);
if isfield(stTlcg, sUsage)
    stUsageInfo = stTlcg.(sUsage);
    if isfield(stUsageInfo, 'value')
        sAccessExpr = stUsageInfo.value;
    end
end
end


%%
function [sBlockPath, sUsage, sAccessExpr] = i_getUsageAndAccessExpressionFromSfObjectRef(stBlockRef)
sAccessExpr = '';
sUsage = '';

casSplit = strsplit(stBlockRef.object, '.');
sBlockPath = casSplit{1};
sNameSF = casSplit{2};

oSfRoot = sfroot;
oData = oSfRoot.find('Path', sBlockPath, '-and', 'Name', sNameSF);
if isempty(oData)
    return;
end

switch oData.Scope
    case 'Parameter'
        sUsage = 'sf-param';
        sAccessExpr = oData.Name;
        
    case 'Constant'
        sUsage = 'sf-const';
        sAccessExpr = oData.getPropValue('Props.InitialValue');
        
    otherwise
        % do nothing
end
end


%%
function astBlockRefs = i_getCalibrationBlockRefs(stInfo)
astBlockRefs = [];

[bExist, hPool] = dsdd('Exist', '/Pool');
if ~bExist
    return;
end

ahCalClasses = i_getClassesWithInfo(hPool, {'readwrite', 'bypassing_readwrite'});
for i = 1:numel(ahCalClasses)
    astBlockRefs = ...
        [astBlockRefs, reshape(tlFindDDReferences(ahCalClasses(i), 'IncludeDataDictionary', 'off', 'System', stInfo.sModelContext), 1, [])]; %#ok<AGROW>
end
end


%%
function ahClasses = i_getClassesWithInfo(hDdSearchRoot, casAllowedInfoValues)
ahClasses = [];
for i = 1:numel(casAllowedInfoValues)
    sInfoValue = casAllowedInfoValues{i};
    
    ahClassesTmp = dsdd( ...
        'Find',       hDdSearchRoot, ...
        'ObjectKind', 'VariableClass', ...
        'Property',   {'name', 'Info', 'value', sInfoValue});    
    ahClasses = [ahClasses, reshape(ahClassesTmp, 1, [])]; %#ok<AGROW>
end
end


%%
function sCurrDd = i_getCurrentDd()
sCurrDd = '';
try %#ok<TRYNC>
    sCurrDd = dsdd('GetDDAttribute', 0, 'fileName');
    if ~isempty(sCurrDd)
        [~, f, e] = fileparts(sCurrDd);
        sCurrDd = [f, e];
    end
end
end


%%
function [xEnv, stOpt] = i_evalArgs(varargin)
xEnv = [];
stOpt = struct();

caxKeyValues = varargin;
if (mod(length(caxKeyValues), 2) ~= 0)
    error('EP:MODEL_ANA:USAGE_ERROR', 'Number of key-values is inconsistent.');
end
for i = 1:2:length(caxKeyValues)
    sKey   = caxKeyValues{i};
    xValue = caxKeyValues{i + 1};
    
    switch lower(sKey)
        case 'environment'
            xEnv = xValue;

        case 'modelcontext'
            stOpt.sModelContext = get_param(xValue, 'Name');
            
        otherwise
            error('EP:MODEL_ANA:USAGE_ERROR', 'Unknown key "%s".', sKey);
    end
end

if isempty(xEnv)
    % DEBUG Workflow: In case that we do not get the Environment object from the integration, we create a new one and
    % clear it after usage.
    xEnv = EPEnvironment();
    stOpt.oCleanupEnviroment = onCleanup(@() xEnv.clear);
end

if ~isfield(stOpt, 'sModelContext')
    % DEBUG Workflow: In case that we do not get the model context from the integration, we use the currently active
    % model.
    stOpt.sModelContext = bdroot(gcs);
end
end


%%
function astParams = i_adaptVirtualLocations(astParams, sModelContext)
mModelToVirtualPaths = i_getMapModelToVirtualPaths(sModelContext);
for i = 1:numel(astParams)
    astParams(i).astBlockInfo = i_arrayfun( ...
        @(st) i_adaptVirtualPath(st, mModelToVirtualPaths), ...
        astParams(i).astBlockInfo);
end
end


%%
function mModelToVirtualPaths = i_getMapModelToVirtualPaths(sModelContext)
mModelToVirtualPaths = containers.Map;

astTree = atgcv_m01_model_tree_get(bdroot(sModelContext));
for i = 1:numel(astTree)
    sModelName = astTree(i).sPath;
    sVirtualPath = astTree(i).sVirtualPath;
    
    if ~strcmp(sModelName, sVirtualPath)
        i_addToMap(mModelToVirtualPaths, sModelName, sVirtualPath);
    end
end
end


%%
function i_addToMap(mMap, sKey, sValue)
if mMap.isKey(sKey)
    mMap(sKey) = i_extendArray(mMap(sKey), {sValue}); %#ok<NASGU>
else
    mMap(sKey) = {sValue}; %#ok<NASGU> mMap is a handle and does not need to be returned!
end
end


%%
function astBlocks = i_adaptVirtualPath(stBlock, mModelToVirtualPaths)
sModelName = i_getModelNameOfBlock(stBlock.sPath);
if mModelToVirtualPaths.isKey(sModelName)
    casVirtualPaths = mModelToVirtualPaths(sModelName);
    
    nVirtualLocations = numel(casVirtualPaths);
    astBlocks = repmat(stBlock, 1, nVirtualLocations);
    for i = 1:nVirtualLocations
        sRegExp = ['^', regexptranslate('escape', sModelName)];
        astBlocks(i).sVirtualPath = regexprep(astBlocks(i).sPath, sRegExp, casVirtualPaths{i}, 'once');
    end
else
    astBlocks = stBlock; % nothing to be adapted sPath and sVirtualPath are the same
end
end


%%
function sModelName = i_getModelNameOfBlock(sPath)
if any(sPath == '/')
    sModelName = regexprep(sPath, '/.*', '');
else
    sModelName = sPath;
end
end


%%
% this function is needed for lower ML versions (e.g. ML2015a)
% newer ML versions have a better "arrayfun" method that can directly produce arrays of any type
%
function axElemOut = i_arrayfun(hFunc, axElemIn)
axElemOut = i_cell2mat(arrayfun(hFunc, axElemIn, 'uni', false));
end


%%
% needed as a workaround helper for i_arrayfun
%
function axElem = i_cell2mat(caxElem)
caxElem(cellfun(@isempty, caxElem)) = []; % remove the empty elements from the cell array
if isempty(caxElem)
    axElem = [];
else
    nElem = numel(caxElem);
    axElem = reshape(caxElem{1}, 1, []);
    for i = 2:nElem
        axElem = [axElem, reshape(caxElem{i}, 1, [])]; %#ok<AGROW>
    end
end
end
function [astParams, casMissing] = atgcv_m01_model_params_get(stEnv, stOpt)
% Returns the Parameters of a Simulink model.
%
% function astParams = atgcv_m01_model_params_get(stEnv, stOpt)
%
%   INPUT               DESCRIPTION
%       stEnv              (struct)  Environment with Messenger handle
%       stOpt              (struct)  Options:
%         .sModelContext   (string)    either model name or block path      (default == <bdroot(gcs())>)
%         .bIncludeModelWS (boolean)   flag if model workspace shall be considered  
%                                      (default depends on ML version: true for ML >= ML2017b; false otherwise)
%         .casParamNames   (cell)      white list of names to be considered (default == {})
%         .SearchMethod    (string)    'compiled' | 'cached'                (default == 'compiled')
%
%   OUTPUT              DESCRIPTION
%       astParams            (array)   structs with following info:
%         .sName             (string)    name of Parameter in workspace as used for EP 
%                                        (note: specially for model workspace parameters the name of the model is prepended)
%         .sRawName          (string)    name of Parameter in workspace as used in model
%         .sSource           (string)    'base workspace' | '<name-of-SLDD>'  | '<name-of-model>'
%         .sSourceType       (string)    'base workspace' | 'data dictionary' | 'model workspace'
%         .sSourceAccess    (string)      optional path information needed to access the paramter
%         .bIsModelArg       (boolean)   true, if the parameter is a model workspace parameter that is marked as model
%                                        argument also
%         .sClass            (string)    class of Parameter (default: double)
%         .sType             (string)    type of Parameter (default: double)
%         .aiWidth           (array)     Parameter's dimensions
%         .astBlockInfo      (array)     structs with following info:
%            .sPath          (string)      model path of block
%            .sBlockType     (string)      type of block
%            .stUsage        (string)      struct with usages in Block as fieldnames
%               .(sUsage)    (string)      expression in block where Variable is used
%       casMissing           (strings)   all Parameters that have been provided as an optional argument but were not
%                                        found inside the model
%
%   REMARKS
%     Provided Model is assumed to be open.
%


%% check/set inputs
if (nargin < 2)
    if (nargin < 1)
        stEnv = 0;
    end
    stOpt = struct();
end
stOpt = i_checkSetOptions(stOpt);

%% main
aoVars = ep_model_variables_get(stOpt.sModelContext, stOpt.SearchMethod, stOpt.bIncludeModelWS);

if ~isempty(stOpt.casParamNames)
    [aoVars, casMissing] = i_filterWhiteList(aoVars, stOpt.casParamNames);
else
    casMissing = {};
end
astParams = i_getParamInfo(stEnv, aoVars, stOpt.sModelContext);
astParams = i_filterInvalidParams(stEnv, astParams);
end



%%
function astParams = i_filterInvalidParams(stEnv, astParams)
if isempty(astParams)
    return;
end
abIsHighDim = arrayfun(@i_isParamHighDim, astParams);

astInvalid = astParams(abIsHighDim);
for i = 1:length(astInvalid)
    stInvalid = astInvalid(i);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_PARAM_MATRIX', 'param', stInvalid.sName);
end
astParams = astParams(~abIsHighDim);

oTypes = ep_sl.Types.getInstance();
abIsSupportedType = arrayfun(@(st) oTypes.isSupported(st.sType), astParams);
astInvalid = astParams(~abIsSupportedType);
for i = 1:length(astInvalid)
    stInvalid = astInvalid(i);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_SUPPORTED_SIMULINK_PARAMETER', 'parameter', stInvalid.sName);
end
astParams = astParams(abIsSupportedType);

abIsSupportedValue = arrayfun(@i_isSupportedValue, astParams);
astInvalid = astParams(~abIsSupportedValue);
for i = 1:length(astInvalid)
    stInvalid = astInvalid(i);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_SUPPORTED_SIMULINK_PARAMETER_VALUE', 'parameter', stInvalid.sName);
end
astParams = astParams(abIsSupportedValue);
end


%%
function bIsHighDim = i_isParamHighDim(stParam)
bIsHighDim = (length(stParam.aiWidth) > 2);
end


%%
function bIsSupValue = i_isSupportedValue(stParam)
bIsSupValue = ~isa(stParam.xValue, 'Simulink.data.Expression');
end


%%
function astParams = i_getParamInfo(~, aoVars, sModelContext)
if isempty(aoVars)
    astParams = [];
    return;
end

% Note: For higher ML versions (ML2019a and higher), we can have the same variable defined in multiple
% namespaces ("base ws", "main SLDD", "sub SLDD", ...). Simulink has a "merged" view on these namespaces and
% ensures that all corresponding definitions have to match. Therefore, we also can merge different namespaces into one.
astMergedVars = i_mergeGlobalNamespaces(aoVars);

astParams = struct( ...
    'sName',         {astMergedVars(:).sName}, ...
    'sRawName',      {astMergedVars(:).sRawName}, ...
    'sSource',       {astMergedVars(:).sSource}, ...
    'sSourceType',   {astMergedVars(:).sSourceType}, ...
    'sSourceAccess', '', ...
    'bIsModelArg',   false, ...
    'sClass',        '', ...
    'sType',         '', ...
    'xValue',        [], ...
    'aiWidth',       [], ...
    'sMin',          '', ...
    'sMax',          '', ...
    'stCoderInfo',   [], ...
    'astBlockInfo',  []);

mModelToVirtualPaths = i_createMappingFromModelsToVirtualPaths(sModelContext);

abValid = true(size(astParams));
for i = 1:length(astParams)
    sParamName = astMergedVars(i).sRawName;
    
    if strcmp(astMergedVars(i).sSourceType, 'model workspace')
        sSourceModelName = astMergedVars(i).sSource;
        casVirtualPathsOfSourceModel = mModelToVirtualPaths(sSourceModelName);
        
        astParams(i).bIsModelArg = i_isModelArgument(astMergedVars(i).sRawName, sSourceModelName);
        astParams(i).astBlockInfo = ...
            i_getBlockInfosForModelWorkspaceParameter(astMergedVars(i), casVirtualPathsOfSourceModel);
        
    else
        astParams(i).astBlockInfo = ep_param_block_info_get(astMergedVars(i), astMergedVars(i).casBlocks);
    end

    abValid(i) = ~isempty(astParams(i).astBlockInfo);
    if abValid(i)
        hResolverFunc = atgcv_m01_generic_resolver_get(astParams(i).astBlockInfo(1).sPath);
        [stProps, abValid(i)] = atgcv_m01_ws_var_info_get(sParamName, hResolverFunc);
        if abValid(i)
            astParams(i).sClass      = stProps.sClass;
            astParams(i).sType       = stProps.sType;
            astParams(i).xValue      = stProps.xValue;
            astParams(i).aiWidth     = stProps.aiWidth;
            astParams(i).sMin        = stProps.sMin;
            astParams(i).sMax        = stProps.sMax;
            astParams(i).stCoderInfo = stProps.stCoderInfo;
        end
    end
end
astParams = astParams(abValid);
end


%%
function astBlockInfo = i_getBlockInfosForModelWorkspaceParameter(stMergedVar, casVirtualPathsOfSourceModel)
astBlockInfo = [];
for i = 1:numel(casVirtualPathsOfSourceModel)
    sVirtualPathOfModel = casVirtualPathsOfSourceModel{i};
    
    astBlockInfoPart = ep_param_block_info_get(stMergedVar, stMergedVar.casBlocks, sVirtualPathOfModel);
    astBlockInfo = horzcat(astBlockInfo, astBlockInfoPart); %#ok<AGROW>
end
end


%%
function bIsModelArg = i_isModelArgument(sParamName, sModelName)
casModelParamNames = strsplit(get_param(sModelName, 'ParameterArgumentNames'), ',');
bIsModelArg = any(strcmp(sParamName, casModelParamNames));
end


%%
function mModelToVirtualPaths = i_createMappingFromModelsToVirtualPaths(xModelContext)
mModelToVirtualPaths = containers.Map;

astTreeElems = atgcv_m01_model_tree_get(xModelContext);

% note: the very first element of the tree is the model context with a virtual path equal to its real model path
%       all other tree elements are models with an according virtual path where they are referenced from
%       --> to build up a map from the model name to all it's virtual paths start from index == 2 and set the root
%           model's virtual path to empty first
mModelToVirtualPaths(bdroot(astTreeElems(1).sPath)) = {''};

for i = 2:numel(astTreeElems)
    stTreeElem = astTreeElems(i);
    sReferencedModelName = stTreeElem.sPath;
        
    if mModelToVirtualPaths.isKey(sReferencedModelName)
        casVirtualPaths = mModelToVirtualPaths(sReferencedModelName);
        casVirtualPaths{end + 1} = stTreeElem.sVirtualPath; %#ok<AGROW>        
    else
        casVirtualPaths = {stTreeElem.sVirtualPath};
    end
    mModelToVirtualPaths(sReferencedModelName) = casVirtualPaths;
end
end


%%
function astVars = i_mergeGlobalNamespaces(aoVars)
if isempty(aoVars)
    astVars = [];
    return;
end

astVars = i_createVarInfoForMerging(aoVars(1));
if (numel(aoVars) < 2)
    return;
end

% add first variable to map of known variables
mVarsToIndex = containers.Map;
mVarsToIndex(astVars.sName) = 1;

% loop over the rest of the variables and merge variables with the same name
for i = 2:numel(aoVars)
    oNewVar = aoVars(i);    
    stNewVar = i_createVarInfoForMerging(oNewVar);
    
    if mVarsToIndex.isKey(stNewVar.sName)
        iIdx = mVarsToIndex(stNewVar.sName);
        astVars(iIdx) = i_mergeVarInfos(astVars(iIdx), stNewVar);
    else
        iIdx = numel(astVars) + 1; % increase number of known vars
        astVars(iIdx) = stNewVar;
        mVarsToIndex(stNewVar.sName) = iIdx;
    end
end
end


%%
function [sName, sRawName] = i_getName(oVar)
sRawName = oVar.Name;
if strcmp(oVar.SourceType, 'model workspace')
    sName = [oVar.Source ':' oVar.Name];
else
    sName = sRawName;
end
end


%%
function stVar = i_mergeVarInfos(stVar, stVarToBeMerged)
stVar.casBlocks = horzcat(stVar.casBlocks, stVarToBeMerged.casBlocks);
stVar.aoVars = horzcat(stVar.aoVars, stVarToBeMerged.aoVars);
end


%%
function stVar = i_createVarInfoForMerging(oVar)
[sName, sRawName] = i_getName(oVar);
stVar = struct( ...
    'sName',       sName, ...
    'sRawName',    sRawName, ...
    'sSource',     oVar.Source, ...
    'sSourceType', oVar.SourceType, ...
    'casBlocks',   {reshape(oVar.UsedByBlocks, 1, [])}, ...
    'aoVars',      oVar);
end


%%
function [aoVars, casMissing] = i_filterWhiteList(aoVars, casWhiteListNames)
casMissing = casWhiteListNames; % start with assuming no Var from list was found
if isempty(aoVars)
    return;
end
if isempty(casWhiteListNames)
    aoVars = [];
    return;
end

casExtVarNames = arrayfun(@i_getName, aoVars, 'UniformOutput', false);

% note: casVarNames can contain the *same* variable name multiple times!
% the command "ismember" in the next line is needed because it will find each occurrence
abFound = ismember(casExtVarNames, casWhiteListNames);
aoVars = aoVars(abFound);

casFoundNames = unique(casExtVarNames(abFound));
casMissing = setdiff(casWhiteListNames, casFoundNames);
end


%%
function stOpt = i_checkSetOptions(stOpt)
if (~isfield(stOpt, 'sModelContext') || isempty(stOpt.sModelContext))
    stOpt.sModelContext = bdroot(gcs());
else
    try
        get_param(stOpt.sModelContext, 'name');
    catch oEx
        error('ATGCV:MOD_ANA:ERROR', 'Model context "%s" is not available.\n%s', stOpt.sModelContext, oEx.message);
    end
end

if (~isfield(stOpt, 'bIncludeModelWS') || isempty(stOpt.bIncludeModelWS))
    stOpt.bIncludeModelWS = ~verLessThan('matlab', '9.3');
end

if (~isfield(stOpt, 'casParamNames') || isempty(stOpt.casParamNames))
    stOpt.casParamNames = {};
else
    stOpt.casParamNames = cellstr(stOpt.casParamNames);
end

if ~isfield(stOpt, 'SearchMethod')
    stOpt.SearchMethod = 'compiled';
else
    if ~any(strcmp(stOpt.SearchMethod, {'compiled', 'cached'}))
        error('ATGCV:MOD_ANA:ERROR', 'Unknown SearchMethod "%s".', stOpt.SearchMethod);
    end
end

if ~isfield(stOpt, 'VariableFilterFunc')
    stOpt.VariableFilterFunc = [];
end
end


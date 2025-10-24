function astDsms = atgcv_m01_model_datastores_get(stEnv, stOpt)
% Returns the Parameters of a Simulink model. 
%
% function astDatastores = atgcv_m01_model_datastores_get(stEnv, stOpt)
%
%   INPUT               DESCRIPTION
%       stEnv              (struct)  Environment with Messenger handle
%       stOpt              (struct)  Options:
%         .sModelContext   (string)    either model name or block path
%         .SearchMethod    (string)    'compiled' | 'cached' (default=compiled) 
%
%   OUTPUT              DESCRIPTION
%       astDsms            (array)   structs with following info:
%         .sName           (string)    name of the DataStore
%         .sPath           (string)    path of the DataStoreMemory block (empty for global DataStores)
%         .sVirtualPath    (string)    virtual path of the DataStoreMemory block (empty for global DataStores)
%         .astUsingBlocks  (array)     structs with following info:
%            .sPath        (string)      path of the block using the DataStore
%            .sVirtualPath (string)      virtual path of the block using the DataStore
%            .sBlockType   (string)      type of the block using the DataStore
%            .bIsReader    (boolean)     true, if the block is a reader of the DataStore; otherwise false
%            .bIsWriter    (boolean)     true, if the block is a writer of the DataStore; otherwise false
%
%   REMARKS
%     Provided Model is assumed to be open.
%


%% check/set inputs
% Note: stEnv is not used since currently messages are not produced
if (nargin < 2)
    stOpt = struct();
    if (nargin < 1)
        stEnv = 0;
    end
end
stOpt = i_checkSetOptions(stOpt);

astTree = atgcv_m01_model_tree_get(stOpt.sModelContext);
if isempty(astTree)
    astDsms = [];
else
    astLocalDsms  = i_findAllLocalDataStores(astTree);
    astGlobalDsms = i_findAllGlobalDataStores(stOpt.sModelContext, stOpt.SearchMethod);
    astGlobalDsms = i_removeShadowedDsms(astGlobalDsms, astLocalDsms);
    astDsms = [astLocalDsms, astGlobalDsms];
end

astDsms = i_evaluateType(stEnv, astDsms, bdroot(stOpt.sModelContext));
end


%%
function astDsms = i_evaluateType(stEnv, astDsms, sModelContext)
astDsms = arrayfun(@(stDsm) i_addSignalInfo(stDsm, sModelContext), astDsms);
abHasValidType = false(size(astDsms));
for i = 1:numel(astDsms)
    stDsm = astDsms(i);
    
    % Note: if the type info is empty, something went wrong; 
    %       unfortunately, in this case no info about the type can be issued
    stTypeInfo = stDsm.stSignalInfo.stTypeInfo;
    if ~isempty(stTypeInfo)
        if i_isTypeAccepted(stDsm.oSig)
            abHasValidType(i) = true;            
        else
            if strcmpi(stTypeInfo.sType, 'auto')
                i_issueUnspecifiedTypeMessage(stEnv, stDsm);
            else
                i_issueUnsupportedTypeMessage(stEnv, stDsm);
            end
        end
    end
end
astDsms = astDsms(abHasValidType);
end


%%
function bDoAccept = i_isTypeAccepted(oSig)
bDoAccept = oSig.isValid;
if bDoAccept
    oTypes = ep_sl.Types.getInstance();
    
    aoSignals = oSig.getLeafSignals;
    for i = 1:length(aoSignals)
        bDoAccept = bDoAccept && oTypes.isSupported(aoSignals(i).getType);
    end
end
end


%%
function i_issueUnspecifiedTypeMessage(stEnv, stDsm)
osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LOCAL_DS_UNSPECIFIED_TYPE', ...
    'ds_name', stDsm.sName, ...
    'ds_path', stDsm.sPath);
end


%%
function i_issueUnsupportedTypeMessage(stEnv, stDsm)
if isempty(stDsm.sPath)
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:GLOBAL_DS_UNSUPPORTED_TYPE', ...
        'ds_name', stDsm.sName);
else
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LOCAL_DS_UNSUPPORTED_TYPE', ...
        'ds_name', stDsm.sName, ...
        'ds_path', stDsm.sPath);
end
end


%%
% if local and global DSMs have the same name, the local one is shadowing the global one
% --> in this case remove the using blocks of the global variable when also referenced for the local data store
function astGlobalDsms = i_removeShadowedDsms(astGlobalDsms, astLocalDsms)
if (isempty(astGlobalDsms) || isempty(astLocalDsms))
    return;
end

xLocalDsmMap = containers.Map;
for i = 1:numel(astLocalDsms)
    sDsmName = astLocalDsms(i).sName;
    if xLocalDsmMap.isKey(sDsmName)
        xLocalDsmMap(sDsmName) = [xLocalDsmMap(sDsmName), astLocalDsms(i)];
    else
        xLocalDsmMap(sDsmName) = astLocalDsms(i);
    end
end

aiIsFullyShadowed = false(size(astGlobalDsms));
for i = 1:numel(astGlobalDsms)
    sDsmName = astGlobalDsms(i).sName;
    if xLocalDsmMap.isKey(sDsmName)
        astShadowingLocalDsm = xLocalDsmMap(sDsmName);
        
        for k = 1:numel(astShadowingLocalDsm)
            stShadowingLocalDsm = astShadowingLocalDsm(k);
            
            casUsingBlocksLocal  = {stShadowingLocalDsm.astUsingBlocks(:).sPath};
            casUsingBlocksGlobal = {astGlobalDsms(i).astUsingBlocks(:).sPath};
            [~, aiNonShadowed] = setdiff(casUsingBlocksGlobal, casUsingBlocksLocal);
            
            astGlobalDsms(i).astUsingBlocks = astGlobalDsms(i).astUsingBlocks(aiNonShadowed);
            if isempty(astGlobalDsms(i).astUsingBlocks)
                aiIsFullyShadowed(i) = true;
            end
        end
    end
end
if any(aiIsFullyShadowed)
    astGlobalDsms(aiIsFullyShadowed) = [];
end
end


%%
function stDsm = i_addSignalInfo(stDsm, sModelContext)
stDsm.sModelContext = sModelContext;
stDsm.stSignalInfo = atgcv_m01_datastore_signal_info_get(stDsm);
[stDsm.oSig, stDsm.oStateSig] = ep_datastore_signal_info_get(stDsm);
end


%%
function astDsms = i_getLocalDataStores(xModelContext)
% Note: important to start at the root of the model context block, since the local DSM blocks from the ancestor blocks
%       may have an influence on the model context block
hModelContext = get_param(bdroot(xModelContext), 'handle');
ahDsmBlocks = ep_find_system(hModelContext, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'BlockType',      'DataStoreMemory');

astDsms = reshape(arrayfun(@i_createLocalDsmInfo, ahDsmBlocks), 1, []);
end


%%
function stDsm = i_createLocalDsmInfo(hDsmBlock)
sBlockPath = getfullname(hDsmBlock);
sDsName = get_param(hDsmBlock, 'DataStoreName');
stDsm = i_createDsmInfo( ...
    sDsName, ...
    sBlockPath, ...
    sBlockPath, ...
    i_getUsingBlocks(hDsmBlock));
end


%%
function stDsm = i_createDsmInfo(sName, sBlockPath, sVirtualPath, astUsingBlocks)
stDsm = struct( ...
    'sName',          sName, ...
    'sPath',          sBlockPath, ...
    'sVirtualPath',   sVirtualPath, ...
    'oSig',           [], ...
    'oStateSig',      [], ...
    'stSignalInfo',   [], ...
    'astUsingBlocks', astUsingBlocks);
end


%%
function astDsms = i_findAllLocalDataStores(astTree)
if isempty(astTree)
    astDsms = [];
    return;
end
    
casAllContexts = unique({astTree(:).sPath});
xModelDsmMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
for i = 1:numel(casAllContexts)
    sContext = casAllContexts{i};
    xModelDsmMap(sContext) = i_getLocalDataStores(sContext);
end

astDsms = xModelDsmMap(astTree(1).sPath);
for i = 2:numel(astTree)
    sRefModel = astTree(i).sPath;
    sVirtualPath = astTree(i).sVirtualPath;
    astDsms = [astDsms, i_adaptVirtualPaths(xModelDsmMap(sRefModel), sRefModel, sVirtualPath)]; %#ok<AGROW>
end

astDsms = astDsms(arrayfun(@(stDsm) ~isempty(stDsm.astUsingBlocks), astDsms));
end


%%
function astData = i_adaptVirtualPaths(astData, sRefModel, sRefBlock)
sRegExp = ['^', regexptranslate('escape', sRefModel)];
astData = arrayfun(@(stData) i_regexpReplaceVirtualPathsForBlock(stData, sRegExp, sRefBlock), astData);
for i = 1:numel(astData)
    astData(i).astUsingBlocks = ...
        arrayfun(@(stBlock) i_regexpReplaceVirtualPathsForBlock(stBlock, sRegExp, sRefBlock), astData(i).astUsingBlocks);
end
end


%%
function stBlock = i_regexpReplaceVirtualPathsForBlock(stBlock, sRegExp, sReplacement)
stBlock.sVirtualPath = regexprep(stBlock.sVirtualPath, sRegExp, sReplacement, 'once');
end


%%
function astBlocks = i_getUsingBlocks(hDsmBlock)
% Note: inofficial/undocumented function in Simulink
sHTML = dataStoreRWddg_cb(hDsmBlock, 'getRWBlksHTML');
casBlocks = i_getBlocksFromHTML(sHTML);

sDsName = get_param(hDsmBlock, 'DataStoreName');
astBlocks = cellfun(@(s) i_getAccessorBlockInfo(sDsName, s, s), casBlocks);
end


%%
function casBlocks = i_getBlocksFromHTML(sHTML)
casBlocks = {};

ccasBlocks = regexp(sHTML, '<a[^>]+hilite[^>]+>(.+?)</a>', 'tokens');
if isempty(ccasBlocks)
    return;
end
ccasHandles = regexp(sHTML, '<a[^>]+matlab:eval.+?str2num\(['']+([^'']+)['']', 'tokens');
if (numel(ccasHandles) ~= numel(ccasBlocks))
    % INTERNAL ERROR: number of blocks is not equal to number of handles
    return;
end

astBlocks = struct( ...
    'sPathFromHTML',   horzcat(ccasBlocks{:}), ...
    'sHandleFromHTML', horzcat(ccasHandles{:}));

% !Note: important to interpret the paths since the HTML versions do have differences in whitespaces and special chars
casBlocks = arrayfun(@i_interpretBlockPathHTML, astBlocks, 'UniformOutput', false);
casBlocks(cellfun(@isempty, casBlocks)) = [];
end


%%
% Note: HTML contains model paths and handle numbers 
%       --> try to intepret first the handle; if this does not work out, try the block path
%       --> return an empty string if block path cannot be found
function sPath = i_interpretBlockPathHTML(stBlock)
try
    hHandle = eval(stBlock.sHandleFromHTML);
    sPath = getfullname(hHandle);
    return;
catch
end
try
    sPath = getfullname(stBlock.sPathFromHTML);
    return;
catch
end
sPath = '';
end


%%
function stBlock = i_getAccessorBlockInfo(sSignalName, sBlockPath, sVirtualPath)
sBlockType = get_param(sBlockPath, 'BlockType');
switch lower(sBlockType)
    case 'datastoreread'
        bIsWriter = false;
        
        sDsName = get_param(sBlockPath, 'DataStoreName');
        bIsReader = strcmp(sDsName, sSignalName);
        
    case 'datastorewrite'
        bIsReader = false;
        
        sDsName = get_param(sBlockPath, 'DataStoreName');
        bIsWriter = strcmp(sDsName, sSignalName);
        
    otherwise
        if (i_isStateflow(sBlockPath, sBlockType) && i_isDataStoreInStateflowBlock(sSignalName, sBlockPath))
            bIsReader = true;
            bIsWriter = true;
        else
            bIsReader = false;
            bIsWriter = false;
        end
end

stBlock = i_createBlockInfo( ...
    sBlockPath, ...
    sVirtualPath, ...
    sBlockType, ...
    bIsReader, ...
    bIsWriter);
end


%%
function bIsSF = i_isStateflow(sBlockPath, sBlockType)
bIsSF = strcmpi(sBlockType, 'SubSystem') && atgcv_sl_block_isa(sBlockPath, 'Stateflow');
end


%%
function bIsDs = i_isDataStoreInStateflowBlock(sDataName, sChart)
bIsDs = false;

oSfChart = atgcv_m01_sf_block_object_get(sChart);
if ~isempty(oSfChart)
    oSfData = oSfChart.find( ...
        '-isa', 'Stateflow.Data', ...
        'Name',  sDataName, ...
        'Scope', 'Data Store Memory');
    bIsDs = ~isempty(oSfData);
end
end


%%
function stBlock = i_createBlockInfo(sPath, sVirtualPath, sType, bIsReader, bIsWriter)
stBlock = struct( ...
    'sPath',        sPath, ...
    'sVirtualPath', sVirtualPath, ...
    'sBlockType',   sType, ...
    'bIsReader',    bIsReader, ...
    'bIsWriter',    bIsWriter);
end


%%
function stOpt = i_checkSetOptions(stOpt)
if (~isfield(stOpt, 'sModelContext') || isempty(stOpt.sModelContext))
    stOpt.sModelContext = gcb;
    if isempty(stOpt.sModelContext)
        stOpt.sModelContext = bdroot();
    end
else
    try
        get_param(stOpt.sModelContext, 'name');
    catch oEx
        error('ATGCV:MOD_ANA:ERROR', 'Model context "%s" is not available.\n%s', stOpt.sModelContext, oEx.message);
    end
end

if ~isfield(stOpt, 'SearchMethod')
    stOpt.SearchMethod = 'compiled';
else
    if ~any(strcmp(stOpt.SearchMethod, {'compiled', 'cached'}))
        error('ATGCV:MOD_ANA:ERROR', 'Unknown SearchMethod "%s".',stOpt.SearchMethod);
    end
end
end


%%
function astDsms = i_findAllGlobalDataStores(sModelContext, sSearchMethod)
aoVars = i_getGlobalSimulinkSignals(sModelContext, sSearchMethod);
if isempty(aoVars)
    astDsms = [];
else
    astDsms = i_getRelevantDataStores(aoVars, sModelContext);
end
end


%%
function aoVars = i_getGlobalSimulinkSignals(sModelContext, sSearchMethod)
aoVars = ep_model_variables_get(sModelContext, sSearchMethod);
if ~isempty(aoVars)
    hResolverFunc = atgcv_m01_generic_resolver_get(sModelContext);
    aoVars = aoVars(arrayfun(@(oVar) i_isaSimulinkSignal(oVar.Name, hResolverFunc), aoVars));
end
end


%%
function astDsms = i_getRelevantDataStores(aoVars, sModelContext)
astDsms = repmat(i_createDsmInfo('', '', '', []), 1, 0);
for i = 1:numel(aoVars)
    oVar = aoVars(i);
    
    astRelevantDsBlocks = i_getDsReadWriteBlocksInContext(oVar, sModelContext);
    if ~isempty(astRelevantDsBlocks)
        astDsms(end + 1) = i_createDsmInfo(oVar.Name, '', '', astRelevantDsBlocks); %#ok<AGROW>
    end
end
end


%%
function bIsSimulinkSig = i_isaSimulinkSignal(sVarName, hResolverFunc)
try
    bIsSimulinkSig = isa(feval(hResolverFunc, sVarName), 'Simulink.Signal');
catch
    bIsSimulinkSig = false;
end
end


%%
function sVirtualPath = i_getVirtualPath(sVirtualParent, sBlock)
if isempty(sVirtualParent)
    sVirtualPath = sBlock;
else
    [~, sRelBlock] = strtok(sBlock, '/');
    sVirtualPath = [sVirtualParent, sRelBlock];
end
end


%%
function astBlockInfos = i_getDsReadWriteBlocksInContext(oVar, sModelContext)
astBlockInfos = i_getDsReadWriteBlockInfos(oVar.Name, oVar.UsedByBlocks);
astBlockInfos = astBlockInfos(arrayfun(@(stBlock) i_startsWith(stBlock.sVirtualPath, sModelContext), astBlockInfos));
end


%%
function bStartsWith = i_startsWith(sString, sPrefix)
sRegExp = ['^', regexptranslate('escape', sPrefix)];
bStartsWith = ~isempty(regexp(sString, sRegExp, 'once'));
end


%%
function astBlockInfos = i_getDsReadWriteBlockInfos(sSignalName, casBlocks, sVirtualParent)
if (nargin < 3)
    sVirtualParent = '';
end

nBlocks = numel(casBlocks);
astBlockInfos = repmat(i_createBlockInfo('', '', '', false, false), 1, nBlocks);

aiModelRefIdx = [];
for i = 1:nBlocks
    sBlock = casBlocks{i}; % real path
    sVirtualPath = i_getVirtualPath(sVirtualParent, sBlock);
   
    sBlockType = get_param(sBlock, 'BlockType');    
    if strcmpi(sBlockType, 'ModelReference')
        aiModelRefIdx(end + 1) = i; %#ok<AGROW>
        if strcmp(get_param(sBlock, 'ProtectedModel'), 'on')
            %do not search any further within protected model reference
        else   
            sModelRef = get_param(sBlock, 'ModelName');
            aoVars = Simulink.findVars(sModelRef, 'Name', sSignalName, 'SearchMethod', 'cached');
            if (length(aoVars) == 1)
                astRefBlockInfos = i_getDsReadWriteBlockInfos(sSignalName, aoVars.UsedByBlocks, sVirtualPath);
                astBlockInfos = [astBlockInfos, astRefBlockInfos]; %#ok<AGROW>
            end
        end
    else
        astBlockInfos(i) = i_getAccessorBlockInfo(sSignalName, sBlock, sVirtualPath);
    end
end
astBlockInfos(aiModelRefIdx) = [];

% Note: remove all blocks that are neither reader nor writer
astBlockInfos = astBlockInfos(arrayfun(@(stBlock) stBlock.bIsReader || stBlock.bIsWriter, astBlockInfos));
end

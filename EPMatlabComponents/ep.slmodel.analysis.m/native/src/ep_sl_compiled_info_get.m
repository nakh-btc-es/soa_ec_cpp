function astBlocks = ep_sl_compiled_info_get(varargin)
% Get interface info for the provided blocks in compiled mode.
%
% function astBlocks = ep_sl_compiled_info_get(stEnv, casBlocks, sModelDir)
%
%   INPUT               DESCRIPTION
%     stEnv              (struct)      error messenger environment
%     casBlocks          (cell)        full paths to model blocks
%                                      (for referenced models the real SL path 
%                                      and _not_ the virtual path)
%     sModelDir     (dir)              optional: if provided, the "compile" process is performed in this directory
%
%   OUTPUT              DESCRIPTION
%     astBlocks          (array)       structs with following fields: 
%       .sPath           (string)      model path to block 
%       .astInports      (array)       array describing inports
%       .astOutports     (array)       array describing outports
%       .astLocals       (array)       array describing locals (Note: except for SF Charts always empty)
%       .sErrorMsg       (string)      error that occured during gathering
%                                      interface info for this particular block
%       .bIsInfoComplete (bool)        "true" if info is complete, otherwise "false"
%


%% input check
astBlocks = [];

[stEnv, stArgs] = i_evalArgs(varargin{:});
if (isempty(stArgs.casBlocksWithInnerView) && isempty(stArgs.casBlocksWithOuterView))
    return;
end

%% optional
if ~isempty(stArgs.sModelDir)
    xOnCleanupReturnPwd = i_changeCurrentDir(stArgs.sModelDir); %#ok<NASGU> onCleanup object
end
i_clearPersistenceInUsedFuncs;
xOnCleanupClearPersistence = onCleanup(@i_clearPersistenceInUsedFuncs);

%% main
astBlocks = i_initInfo(stArgs.casBlocksWithInnerView, stArgs.casBlocksWithOuterView);
astBlocks = i_getInfoPorts(stEnv, astBlocks);

if (~isempty(astBlocks) && any(~[astBlocks(:).bIsInfoComplete]))
    i_issueCompiledInfoErrors(stEnv, astBlocks(~[astBlocks(:).bIsInfoComplete]));
end
end


%%
% Handle two possible usages:
% (1) Legacy usage: stEnv, casBlocks, sModelDir
% OR 
% (2) key-values
%           'Environment'     --> stEnv
%           'InnerViewBlocks' --> casBlocks
%           'OuterViewBlocks' --> casExtraBlocks
%           'ModelDir'        --> sModelDir
%
function [stEnv, stArgs] = i_evalArgs(varargin)
stEnv = 0;
stArgs = struct( ...
    'casBlocksWithInnerView', {{}}, ...
    'casBlocksWithOuterView', {{}}, ...
    'sModelDir',              '');

bIsDebugUsage = isempty(varargin);
if bIsDebugUsage
    stArgs.casBlocksWithInnerView = {gcb};
    return;
end

bIsLegacyUsage = ~ischar(varargin{1});
if bIsLegacyUsage
    stEnv = varargin{1};
    stArgs.casBlocksWithInnerView = varargin{2};
    if (nargin > 2)
        stArgs.sModelDir = varargin{3};
    end
else    
    caxKeyValues = varargin;
    if (mod(length(caxKeyValues), 2) ~= 0)
        error('EP:MODEL_ANA:USAGE_ERROR', 'Number of key-values is inconsistent.');
    end
    for i = 1:2:length(caxKeyValues)
        sKey   = caxKeyValues{i};
        xValue = caxKeyValues{i + 1};
        
        switch lower(sKey)
            case 'environment'
                stEnv = xValue;
                
            case 'innerviewblocks'
                stArgs.casBlocksWithInnerView = xValue;
                
            case 'outerviewblocks'
                stArgs.casBlocksWithOuterView = xValue;
                
            case 'modeldir'
                stArgs.sModelDir = xValue;
                
            otherwise
                error('EP:MODEL_ANA:USAGE_ERROR', 'Unknown key "%s".', sKey);
        end
    end
end
end


%%
function i_clearPersistenceInUsedFuncs()
clear atgcv_m01_bus_obj_store;
end


%%
function xOnCleanupReturnPwd = i_changeCurrentDir(sDir)
if ~exist(sDir, 'dir')
    warning('INTERN:ERROR', 'Provided directory "%s" not found.', sDir);
    xOnCleanupReturnPwd = [];
else
    sPwd = pwd();
    xOnCleanupReturnPwd = onCleanup(@() cd(sPwd));
    cd(sDir);
end
end


%%
function i_issueCompiledInfoErrors(stEnv, astBlocks)
for i = 1:length(astBlocks)
    sBlockPath = astBlocks(i).sPath;
    sErrorMsg  = astBlocks(i).sErrorMsg;
    if ~isempty(sErrorMsg)
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:ERROR_COMPILED_INFO', 'block_path', sBlockPath, 'err_msg', sErrorMsg);
    else
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:INCOMPLETE_COMPILED_INFO', 'block_path', sBlockPath);
    end
end
end


%%
function astBlocks = i_initInfo(casBlocksInner, casBlocksOuter)
if ~isempty(casBlocksInner)
    casRootModelsInner = reshape(bdroot(casBlocksInner), 1, []);
else
    casRootModelsInner = {};
end
if ~isempty(casBlocksOuter)
    casRootModelsOuter = reshape(bdroot(casBlocksOuter), 1, []);
else
    casRootModelsOuter = {};
end

% replace each root model with its parent model (if there is any)
casRootModels = [casRootModelsInner, casRootModelsOuter];
oChildToParentModelMap = i_getChildToParentModelMap(casRootModels);

casParentRootModelsInner = cellfun(@(sModel) oChildToParentModelMap(sModel), casRootModelsInner, 'UniformOutput', false);
casParentRootModelsOuter = cellfun(@(sModel) oChildToParentModelMap(sModel), casRootModelsOuter, 'UniformOutput', false);

if isempty(casBlocksInner)
    astBlocksInner = [];
else
    astBlocksInner = struct( ...
        'sParentRootModel', casParentRootModelsInner, ...
        'sRootModel',       casRootModelsInner, ...
        'sPath',            casBlocksInner, ...
        'astInports',       [], ...
        'astOutports',      [], ...
        'astLocals',        [], ...
        'sErrorMsg',        '', ...
        'sStepSize',        '', ...
        'cadSampleTime',    {{}}, ...
        'bInnerView',       true, ...
        'bIsInfoComplete',  false);
end

if isempty(casBlocksOuter)
    astBlocksOuter = [];
else
    astBlocksOuter = struct( ...
        'sParentRootModel', casParentRootModelsOuter, ...
        'sRootModel',       casRootModelsOuter, ...
        'sPath',            casBlocksOuter, ...
        'astInports',       [], ...
        'astOutports',      [], ...
        'astLocals',        [], ...
        'sErrorMsg',        '', ...
        'sStepSize',        '', ...
        'cadSampleTime',    {{}}, ...
        'bInnerView',       false, ...
        'bIsInfoComplete',  false);
end

astBlocks = [astBlocksInner, astBlocksOuter];
end


%%
function oChildToParentModelMap = i_getChildToParentModelMap(casModels)
oChildToParentModelMap = containers.Map;
if isempty(casModels)
    return;
end

casModels = unique(casModels);
if (numel(casModels) < 2)
    oChildToParentModelMap(casModels{1}) = casModels{1};
    return;
end

astRefInfo = cellfun(@i_getModelRefInfo, casModels);

% sort from model with the highest number of references to the lowest
% --> this way a parent model is sorted always before a child model
[~, aiSortedIdx] = sort([astRefInfo(:).nRefs]);
astRefInfo = astRefInfo(aiSortedIdx(end:-1:1));
for i = 1:numel(astRefInfo)
    stRefInfo = astRefInfo(i);
    
    % if a model is not part of the childToParent map, it means that it is a parent itself
    % --> include it into the map by adding all its child relationships
    if ~oChildToParentModelMap.isKey(stRefInfo.sModel)
        for k = 1:numel(stRefInfo.casRefs)
            oChildToParentModelMap(stRefInfo.casRefs{k}) = stRefInfo.sModel;
        end
    end
end
end


%%
function stRefInfo = i_getModelRefInfo(sModel)
casRefMdls = ep_find_mdlrefs(sModel);
stRefInfo = struct( ...
    'sModel',  sModel, ...
    'casRefs', {casRefMdls}, ...
    'nRefs',   numel(casRefMdls));
end


%%
% TODO: change algo to compile all models at once (should be more performant?)
%
% handle blocks model-wise:
% 1) get all blocks from one model
% 2) compile model
% 3) get info for the corresponding blocks
% 4) free model
function astBlocks = i_getInfoPorts(stEnv, astBlocks)
casRootModels = {astBlocks(:).sRootModel};

casModels = unique(casRootModels);
for i = 1:length(casModels)
    sCurrentModel = casModels{i};
    
    % compile model
    xOnCleanupModelFree = i_compileSingleModel(stEnv, sCurrentModel); %#ok<NASGU>
    atgcv_m01_persistent('iBusStrictLevel', i_getCurrentBusStrictLevel(sCurrentModel));
    aiSelectedBlocks = find(strcmp(sCurrentModel, casRootModels));
    for j = 1:length(aiSelectedBlocks)
        iIdx = aiSelectedBlocks(j);
        sBlockPath = astBlocks(iIdx).sPath;
        try
            [astBlocks(iIdx).astInports, astBlocks(iIdx).astOutports, astBlocks(iIdx).bInnerView] = ...
                ep_sl_block_compiled_ports_info_get(stEnv, sBlockPath, astBlocks(iIdx).bInnerView);
            if i_isSfChart(sBlockPath)
                astBlocks(iIdx).astLocals = ep_sl_sfchart_locals_info_get(stEnv, sBlockPath);
            end
            [astBlocks(iIdx).cadSampleTime, astBlocks(iIdx).sStepSize] = i_getCompiledSampleTime(sBlockPath);
            astBlocks(iIdx).bIsInfoComplete = i_checkInfoComplete(astBlocks(iIdx));
            
        catch oEx
            astBlocks(iIdx).sErrorMsg = oEx.message;
        end
    end
    clear xOnCleanupModelFree;
end
end


%%
function bIsSFChart = i_isSfChart(sBlockPath)
bIsSFChart = atgcv_sl_block_isa(sBlockPath, 'Stateflow');
end


%%
function [cadSampleTime, sStepSize] = i_getCompiledSampleTime(sBlockPath)
cadSampleTime = {};
sStepSize = '';

try
    sType = get_param(sBlockPath, 'Type');
    if strcmp('block', sType)
        cadSampleTime = get_param(sBlockPath, 'CompiledSampleTime');
    elseif strcmp('block_diagram', sType)
        sStepSize = i_getCompiledStepSize(sBlockPath);
    end
catch %#ok<CTCH>
end
% Note: CompiledSample time is either a double array [x, y] or a cell array of
%       double arrays {[x1, y1], [x2, y2], ...}
%  -->  always return a cell array
if ~iscell(cadSampleTime)
    cadSampleTime = {cadSampleTime};
end
end


%%
function sCompiledStepSize = i_getCompiledStepSize(sModelName)
sCompiledStepSize = get_param(sModelName, 'CompiledStepSize');
end


%%
function sCompiledStepSize = i_tryToGetSampleTimeFromRootIO(sModelName)
sCompiledStepSize = '';

dSampleTime = Inf;
casRootInports = ep_find_system(sModelName, 'SearchDepth', 1, 'BlockType', 'Inport');
casRootOutports = ep_find_system(sModelName, 'SearchDepth', 1, 'BlockType', 'Outport');
casRootPorts = [reshape(casRootInports, 1, []), reshape(casRootOutports, 1, [])];
for i = 1:numel(casRootPorts)
    adSampleTime = get_param(casRootPorts{i}, 'CompiledSampleTime');
    if isnumeric(adSampleTime)
        d = adSampleTime(1);
        if (isfinite(d) && (d > 0))
            dSampleTime = min(dSampleTime, d);
        end
    end
end

if isfinite(dSampleTime)
    sCompiledStepSize = sprintf('%.17g', dSampleTime);
end
end


%%
function bIsComplete = i_checkInfoComplete(stBlock)
bIsComplete = true;
if ~isempty(stBlock.astInports)
    bIsComplete = all([stBlock.astInports(:).bIsInfoComplete]);
end
if (bIsComplete && ~isempty(stBlock.astOutports))
    bIsComplete = all([stBlock.astOutports(:).bIsInfoComplete]);
end
end


%%
function xOnCleanupFreeModel = i_compileSingleModel(stEnv, sModelName)
astWarnSettings = warning();
warning('off', 'all');
if atgcv_use_tl()
    % switch off interactive display of TL errors/warnings
    xTlBatchMode = ds_error_get('BatchMode');
    ds_error_set('BatchMode', 'on');
end

i_trySettingBusStrictMode(stEnv, sModelName);

oEx = [];
nMaxTry = 2;
nTry = 0;
bFixSuccess = true;
while (bFixSuccess && (nTry < nMaxTry))
    try
        nTry = nTry + 1;
        feval(sModelName, [], [], [], 'compile');
        break;
    catch oEx
        bFixSuccess = atgcv_m01_compile_exceptions_handle(sModelName, oEx);
    end
end
if ~bFixSuccess
    rethrow(oEx);
end

xOnCleanupFreeModel = onCleanup(@() i_freeSingleModel(sModelName));

% NOTE:  the removing of SimHandles is needed as a workaround for TL issue
%        without this a following CodeGen will fail
% NOTE2: actually it is just needed if Logging is active in the Model
%        also probably it is not needed for higher versions of TL
if atgcv_use_tl() 
    atgcv_last_tlds_handle_clear(sModelName);
    ds_error_set('BatchMode', xTlBatchMode);
end
warning(astWarnSettings);
end


%%
function i_trySettingBusStrictMode(stEnv, sModel)
iLevel = i_getSettingsUseBusStrictMode();
if (iLevel > 0)
    try
        iCurrentLevel = i_getCurrentBusStrictLevel(sModel);
        if (iCurrentLevel < iLevel)
            if (iLevel == 1)
                sStrictLevel = 'ErrorLevel1';
            elseif (iLevel == 2)
                sStrictLevel = 'WarnOnBusTreatedAsVector';
            else
                sStrictLevel = 'ErrorOnBusTreatedAsVector';
            end
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:STRICT_BUS_DIAG_SET', 'model', sModel, 'value', sStrictLevel);
            set_param(sModel, 'StrictBusMsg', sStrictLevel);
        end
    catch oEx
        warning('ATGCV:MOD_ANA', 'Setting strict BusMode failed.\n%s', oEx.message);
    end
end
end


%%
% the following Levels are supported
%
%  'none' | 'warning'           ==  0
%  'ErrorLevel1'                ==  1 
%  'WarnOnBusTreatedAsVector'   ==  2
%  'ErrorOnBusTreatedAsVector'  ==  3
%
function iLevel = i_getCurrentBusStrictLevel(sModel)
iLevel = 0;
sCurrentLevel = get_param(sModel, 'StrictBusMsg');
switch sCurrentLevel 
    case 'ErrorLevel1'
        iLevel = 1;
    case 'WarnOnBusTreatedAsVector'
        iLevel = 2;
    case 'ErrorOnBusTreatedAsVector'
        iLevel = 3;
end
end


%%
% the following Levels are supported
%
%  'none' | 'warning'           ==  0
%  'ErrorLevel1'                ==  1  (default Level for ET)
%  'WarnOnBusTreatedAsVector'   ==  2
%  'ErrorOnBusTreatedAsVector'  ==  3
%
function iUseBusStrictMode = i_getSettingsUseBusStrictMode()
iUseBusStrictMode = 1;
try
    sVal = atgcv_global_property_get('model_strict_bus');
    if any(strcmpi(sVal, {'0', 'off', 'false', 'no'}))
        iUseBusStrictMode = 0;
    elseif any(strcmpi(sVal, {'1', 'on', 'true', 'yes'}))
        iUseBusStrictMode = 1;
    elseif strcmpi(sVal, '2')
        iUseBusStrictMode = 2;
    end
catch %#ok<CTCH>
end
end


%%
function i_freeSingleModel(sModelName)
astWarnSettings = warning();
warning('off', 'all');

if atgcv_use_tl()
    % switch off interactive display of TL errors/warnings
    xTlBatchMode = ds_error_get('BatchMode');
    ds_error_set('BatchMode', 'on');
end
try
    feval(sModelName, [], [], [], 'term');
    
catch oEx
    warning('ATGCV:MODEL_ANA:WARNING', 'Could not terminate model.\n%s', oEx.message);
end

if atgcv_use_tl()
    ds_error_set('BatchMode', xTlBatchMode);
end
warning(astWarnSettings);
end


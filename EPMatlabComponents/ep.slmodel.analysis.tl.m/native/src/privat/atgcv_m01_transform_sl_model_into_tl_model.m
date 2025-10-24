function stModelOut = atgcv_m01_transform_sl_model_into_tl_model(stEnv, stModelIn)
% Transform info from a Simulink signal into a faked TL info structure (Note: pure Legacy approach).
%
% function stModelOut = atgcv_m01_transform_sl_model_into_tl_model(stEnv, stModelIn)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)    messenger environment
%     stModelIn         (struct)    the SL model structure
%
%   OUTPUT              DESCRIPTION
%     stModelOut        (struct)    the faked (adapted) TL model structure
%


%%
stModelOut = struct( ...
    'sModelMode',    'SL', ...
    'sName',         stModelIn.sName, ...
    'sModelFile',    stModelIn.sModelFile, ...
    'sModelPath',    fileparts(stModelIn.sModelFile), ...
    'sDdPath',       '', ...
    'astSubsystems', i_fakeTLSubs(stModelIn.astSubsystems), ...
    'astCalVars',    i_fakeCalVars(stModelIn.astParams), ...
    'astDispVars',   i_fakeDispVars(stEnv, stModelIn.astLocals), ...
    'astDsmVars',    []);

% Note: for SL model info we do not need to remap the block infos for ModelReferences!
% <--> the astBlockInfo of CalVars and DispVars already has
%      1) a sTlPath field describing the _virtual_ path
%      2) a sModelPath field describing the _real_ path
% ==> so, skip the Remapping step
bDoRemap = false;
stModelOut = atgcv_m01_local_ifs_to_subs_assign(stModelOut, [], bDoRemap);

if ~isempty(stModelIn.astDsms)
    stModelOut.astDsmVars = i_fakeDsmVars(stModelIn.astDsms);
    astUsages = atgcv_m01_dsms_to_subs_assign(stEnv, stModelIn.astSubsystems, stModelIn.astDsms);
    for i = 1:numel(stModelOut.astSubsystems)
        stModelOut.astSubsystems(i).astDsmReaderRefs = astUsages(i).astDsmReaderRefs;
        stModelOut.astSubsystems(i).astDsmWriterRefs = astUsages(i).astDsmWriterRefs;
    end
end
end


%%
function astDsmVars = i_fakeDsmVars(astDsms)
if isempty(astDsms)
    astDsmVars = [];
else
    astDsmVars = struct( ...
        'hVar',         [], ...
        'stInfo',       i_fakeDsmVarInfos(astDsms), ...
        'astBlockInfo', i_fakeDsmBlockInfos(astDsms), ...
        'stDsm',        [], ...
        'stModelDsm',   i_fakeModelDsms(astDsms));
end
end


%%
function castModelDsms = i_fakeModelDsms(astDsms)
castModelDsms = arrayfun(@i_extendDsmWithSignals, astDsms, 'UniformOutput', false);
end


%%
function stModelDsm = i_extendDsmWithSignals(stDsm)
stModelDsm = stDsm;

stInfo = stDsm.stSignalInfo;
stModelDsm.astSignals = i_createDsmSigInfo( ...
    stInfo.stTypeInfo.sType, ...
    stInfo.dMin, ...
    stInfo.dMax, ...
    stInfo.aiDimensions);
end


%%
function stSigInfo = i_createDsmSigInfo(sType, dMin, dMax, aiSize)
if (isempty(dMin) || ~isfinite(dMin))
    sMin = '';
else
    sMin = sprintf('%.17g', dMin);
end
if (isempty(dMax) || ~isfinite(dMax))
    sMax = '';
else
    sMax = sprintf('%.17g', dMax);
end
iWidth = prod(aiSize);
nDim = numel(aiSize);
aiDim = [nDim, reshape(aiSize(:), 1, [])];

stSigInfo = struct( ...
    'sName',      '', ...
    'sType',      sType, ...
    'sUserType',  sType, ...
    'sMin',       sMin, ...
    'sMax',       sMax, ...
    'xDesignMin', [], ...
    'xDesignMax', [], ...
    'iWidth',     iWidth, ...
    'aiDim',      aiDim);
stSigInfo.astSubSigs = i_extendSubSignals(stSigInfo);
end


%%
function astSubSigs = i_extendSubSignals(stSignal)
stSubSig = rmfield(stSignal, 'iWidth');
stSubSig.iSubSigIdx = [];
stSubSig.iIdx = [];

if (~isfield(stSignal, 'iWidth') || isempty(stSignal.iWidth))
    iWidth = 1;
else
    iWidth = stSignal.iWidth;
end

astSubSigs = repmat(stSubSig, 1, iWidth);
for k = 1:iWidth
    astSubSigs(k).iIdx = k;
    if (iWidth > 1)
        % note: add subsig index only if we have a non-scalar signal
        astSubSigs(k).iSubSigIdx = k;
    end
end
end


%%
function castInfos = i_fakeDsmVarInfos(astDsms)
castInfos = arrayfun(@i_getEmptyVarInfo, astDsms, 'UniformOutput', false);
end


%%
function castBlockInfos = i_fakeDsmBlockInfos(astDsms)
castBlockInfos = arrayfun(@i_fakeDsmBlockInfo, astDsms, 'UniformOutput', false);
end


%%
function astBlockInfos = i_fakeDsmBlockInfo(stDsm)
astBlockInfos = ...
    arrayfun(@(stUsingBlock) i_createBlockInfo(stUsingBlock.sPath, stUsingBlock.sVirtualPath), stDsm.astUsingBlocks);
end


%%
function astCalVars = i_fakeCalVars(astParams)
if isempty(astParams)
    astCalVars = [];
else
    astCalVars = struct( ...
        'hVar',         [], ...
        'stInfo',       i_fakeParamVarInfos(astParams), ...
        'astBlockInfo', i_fakeParamBlockInfos(astParams), ...
        'stCal',        i_fakeParamCals(astParams), ...
        'stParam',      arrayfun(@(x) x, astParams, 'UniformOutput', false));
end
end


%%
function castInfos = i_fakeParamVarInfos(astParams)
castInfos = arrayfun(@i_getEmptyVarInfo, astParams, 'UniformOutput', false);
end


%%
function stInfo = i_getEmptyVarInfo(~)
stInfo = [];
end


%%
function castCals = i_fakeParamCals(astParams)
castCals = arrayfun(@i_fakeParamCal, astParams, 'UniformOutput', false);
end


%%
function stCal = i_fakeParamCal(stParam)
stCal = struct( ...
    'sWorkspaceVar', stParam.sName, ...
    'sPoolVarPath',  '', ...
    'sNameTemplate', '', ...
    'sUniqueName',   stParam.sName, ...
    'sKind',         'explicit', ...
    'sType',         stParam.sType, ...
    'sClass',        stParam.sClass, ...
    'xValue',        stParam.xValue, ...
    'sMin',          stParam.sMin, ...
    'sMax',          stParam.sMax, ...
    'aiWidth',       stParam.aiWidth);
end


%%
function castBlockInfos = i_fakeParamBlockInfos(astParams)
castBlockInfos = arrayfun(@i_fakeParamBlockInfo, astParams, 'UniformOutput', false);
end


%%
function astBlockInfos = i_fakeParamBlockInfo(stParam)
[casBlockUsages, casParamValues] = i_getUsagesAndValues(stParam.astBlockInfo);
astBlockInfos = struct( ...
    'hBlockVar',        [], ...
    'sSignalName',      '', ...
    'hVariableRef',     [], ...
    'hBlock',           [],  ...
    'sTlPath',          {stParam.astBlockInfo(:).sVirtualPath}, ...
    'sBlockKind',       {stParam.astBlockInfo(:).sBlockKind}, ...
    'sBlockType',       {stParam.astBlockInfo(:).sBlockType}, ...
    'sBlockUsage',      casBlockUsages, ...
    'stSfInfo',         [], ...
    'sParamValue',      casParamValues, ...
    'sRestriction',     '', ...
    'sConstraintKind',  '', ...
    'xConstraintVal',   [], ...
    'sModelPath',       {stParam.astBlockInfo(:).sPath});
end


%%
function [casUsages, casValues] = i_getUsagesAndValues(astParamBlockInfos)
nInfos = length(astParamBlockInfos);
casUsages = cell(1, nInfos);
casValues = cell(1, nInfos);
for i = 1:nInfos
    casFields = fieldnames(astParamBlockInfos(i).stUsage);
    if ~isempty(casFields)
        sField = casFields{1};
        casUsages{i} = sField;
        casValues{i} = astParamBlockInfos(i).stUsage.(sField);
    else
        casUsages{i} = '';
        casValues{i} = '';
    end
end
end


%%
function astDispVars = i_fakeDispVars(stEnv, astLocals)
if isempty(astLocals)
    astDispVars = [];
else
    astDispVars = i_fakeDispVar(stEnv, astLocals(1));
    for i = 2:length(astLocals)
        astDispVars = [astDispVars, i_fakeDispVar(stEnv, astLocals(i))]; %#ok<AGROW>
    end
end
end


%%
% Note: if Local references multiple ports, each one will induce its own DispVar
function astDispVars = i_fakeDispVar(stEnv, stLocal)
if isempty(stLocal.aiPorts)
    caiPortNumbers = {[]};
else
    caiPortNumbers = num2cell(stLocal.aiPorts);
end
astDispVars = struct( ...
    'hVar',         [], ...
    'astBlockInfo', i_fakeBlockInfoForLocal(stLocal), ...
    'stInfo',       [], ...
    'iPortNumber',  caiPortNumbers, ...
    'aiOutIdx',     []);
nDisps = length(astDispVars);
aiVarBlockMap = ones(1, nDisps);
[astDispVars, abValid] = atgcv_m01_disp_vars_signal_info_add(stEnv, astDispVars, stLocal.stCompInfo, aiVarBlockMap, false);

astInvalid = astDispVars(~abValid);
for i = 1:length(astInvalid)
    stInvalid = astInvalid(i);
    sBlockInfo = sprintf('%s(#%i)', stInvalid.astBlockInfo(1).sTlPath, stInvalid.iPortNumber);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_MATRIX_DISP_SIGNAL', 'block_path',  sBlockInfo);
end
astDispVars = astDispVars(abValid); % Note: should be put into messenger as warning
if isempty(astDispVars)
    astDispVars = [];
end
end


%%
function stBlockInfo = i_createBlockInfo(sPath, sVirtualPath)
stBlockInfo = struct( ...
    'hBlockVar',        [], ...
    'sSignalName',      '', ...
    'hVariableRef',     [], ...
    'hBlock',           [],  ...
    'sTlPath',          sVirtualPath, ...
    'sBlockKind',       get_param(sPath, 'MaskType'), ...
    'sBlockType',       get_param(sPath, 'BlockType'), ...
    'sBlockUsage',      '', ...
    'stSfInfo',         [], ...
    'sParamValue',      '', ...
    'sRestriction',     '', ...
    'sModelPath',       sPath);
end


%%
function stBlockInfo = i_fakeBlockInfoForLocal(stLocal)
stBlockInfo = i_createBlockInfo(stLocal.sPath, stLocal.sVirtualPath);

if (strcmpi(stBlockInfo.sBlockType, 'SubSystem') && atgcv_sl_block_isa(stLocal.sPath, 'Stateflow'))
    stBlockInfo.sBlockKind  = 'Stateflow';
    stBlockInfo.stSfInfo    = i_fakeSfInfoLocal(stLocal);
    stBlockInfo.sBlockUsage = lower(stBlockInfo.stSfInfo.sSfScope); % output or local
end
end


%%
function stSfInfo = i_fakeSfInfoLocal(stLocal)
if isempty(stLocal.aiPorts)
    sVarName   = stLocal.sName;
    sChartPath = stLocal.sPath;
    sRelPath   = stLocal.sSfRelPath;
else
    iPort = stLocal.aiPorts(1);
    stPort = stLocal.stCompInfo.astOutports(iPort);

    sVarName   = get_param(stPort.sPath, 'Name');
    sChartPath = get_param(stPort.sPath, 'Parent');
    sRelPath   = '';
end
stSfInfo = atgcv_m01_sfblock_variable_info_get(0, sChartPath, sVarName, sRelPath);
end


%%
function astSubOuts = i_fakeTLSubs(astSubIns)
if (numel(astSubIns) < 1)
    astSubOuts = [];
else
    astSubOuts = arrayfun(@i_fakeTLSub, astSubIns);
end
end


%%
function stSubOut = i_fakeTLSub(stSubIn)
sKind = 'subsystem';
if ~isempty(stSubIn.sSFClass)
    sKind = 'stateflow';
end
stSubOut = struct( ...
    'sKind',           sKind, ...
    'sTlPath',         stSubIn.sVirtualPath, ...
    'sSlPath',         stSubIn.sVirtualPath, ...
    'hSub',            [], ...
    'hFunc',           [], ...
    'hFuncInstance',   [], ...
    'sStepFunc',       '', ...
    'sModuleName',     '', ...
    'sModuleType',     '', ...
    'sStorage',        '', ...
    'stProxyFunc',     '', ...
    'iParentIdx',      stSubIn.iParentIdx, ...
    'bIsToplevel',     isempty(stSubIn.iParentID), ...
    'bIsDummy',        stSubIn.bIsDummy, ...
    'bIsEnv',          false, ...
    'hModelRefBlock',  [], ...
    'sModelPath',      stSubIn.sPath, ...
    'sModelPathSl',    stSubIn.sPath, ...
    'stInterface',     atgcv_m01_if_from_comp_if_derive(stSubIn.stCompInfo, stSubIn.sPath, stSubIn.sVirtualPath), ...
    'stFuncInterface', [], ...
    'stSubInterface',  [], ...
    'stCompInterface', stSubIn.stCompInfo);
end



function stInfo = ep_ec_autosar_meta_info_get(varargin)

%%
stArgs = i_evalArgs(varargin{:});

sMatFile = '';
sDebugReuseInfoMat = getenv('BTC_EP_EC_REUSE_AR_META_INFO_FILE');
if ~isempty(sDebugReuseInfoMat)
    sMatFile = fullfile(pwd, sDebugReuseInfoMat);
    if exist(sMatFile, 'file')
        stMat = load(sMatFile, 'stInfo');
        stInfo = stMat.stInfo;
        stInfo.oAutosarProps = autosar.api.getAUTOSARProperties(stArgs.ModelName);
        stInfo.oAutosarSLMapping = autosar.api.getSimulinkMapping(stArgs.ModelName);
        return;
    end
end

stInfo = i_getAutosarMetaInfo(stArgs.Environment, stArgs.ModelName);

if ~isempty(sMatFile)
    save(sMatFile, 'stInfo');
end
end


%%
function stInfo = i_getAutosarMetaInfo(xEnv, sModelName)
stInfo = struct();

% Autosar interfaces info
fprintf('## Extracting Autosar Info ...\n');
tic

% General info
oKind = Eca.ModelKind.get(sModelName);
stInfo.bIsAdaptiveAutosar = oKind.isAdaptiveAUTOSAR(); 

stInfo.oAutosarProps     = autosar.api.getAUTOSARProperties(sModelName);
stInfo.oAutosarSLMapping = autosar.api.getSimulinkMapping(sModelName);

stInfo.sArComponentPath = get(stInfo.oAutosarProps, 'XmlOptions', 'ComponentQualifiedName');
stInfo.sArComponentName = get(stInfo.oAutosarProps, stInfo.sArComponentPath, 'Name');
stInfo.sAutosarVersion  = ep_ec_model_autosar_version_get(sModelName);


% app to impl data types
try
    oUtils = autosar.api.Utils;
    stInfo.mApp2Imp = oUtils.app2ImpMap(sModelName);
catch
    stInfo.mApp2Imp = containers.Map;
end

% ports/behavior info
if stInfo.bIsAdaptiveAutosar
    bWithModelMapping = false;
    stInfoAA = ep_ec_aa_component_info_get(sModelName, bWithModelMapping);
    stInfo.stPorts = stInfoAA.stPorts;
    stInfo.aoRunnables = []; % TODO there are no Runnables in AA
    
else
    stInfo.stPorts = i_getPortsClassicAUTOSAR( ...
        sModelName, ...
        stInfo.oAutosarProps, ...
        stInfo.oAutosarSLMapping, ...
        stInfo.sArComponentPath);
    stInfo.aoRunnables = i_getRunnablesClassicAUTOSAR(xEnv, ...
        sModelName, ...
        stInfo.oAutosarProps, ...
        stInfo.oAutosarSLMapping, ...
        stInfo.sArComponentPath);
end

fprintf('Autosar meta information analysis time : %g\n', toc);
end


%%
function stPorts = i_getPortsClassicAUTOSAR(sModelName, oArProps, oAutosarSLMapping, sArComponentPath)
stPorts = struct();

% -------- receiver ---------
casReceiverPorts = get(oArProps, sArComponentPath, 'ReceiverPorts', 'PathType', 'FullyQualified');
stPorts.astReceiverPorts = cellfun(@(s) i_getArPortInfoFromPort(oArProps, s), casReceiverPorts);

casModeReceiverPorts = get(oArProps, sArComponentPath, 'ModeReceiverPorts', 'PathType', 'FullyQualified');
stPorts.astModeReceiverPorts = cellfun(@(s) i_getArSwitchModeInfoForPort(oArProps, s), casModeReceiverPorts);

casNvReceiverPorts = get(oArProps, sArComponentPath, 'NvReceiverPorts', 'PathType', 'FullyQualified');
stPorts.astNvReceiverPorts = cellfun(@(s) i_getArPortInfoFromPort(oArProps, s), casNvReceiverPorts);

% --------- sender ----------
casSenderPorts = get(oArProps, sArComponentPath, 'SenderPorts', 'PathType', 'FullyQualified');
stPorts.astSenderPorts = cellfun(@(s) i_getArPortInfoFromPort(oArProps, s), casSenderPorts);

casModeSenderPorts = get(oArProps, sArComponentPath, 'ModeSenderPorts', 'PathType', 'FullyQualified');
stPorts.astModeSenderPorts = cellfun(@(s) i_getArSwitchModeInfoForPort(oArProps, s), casModeSenderPorts);

casNvSenderPorts = get(oArProps, sArComponentPath, 'NvSenderPorts', 'PathType', 'FullyQualified');
stPorts.astNvSenderPorts = cellfun(@(s) i_getArPortInfoFromPort(oArProps, s), casNvSenderPorts);

% --------- sender/receiver ----------
casSenderReceiverPorts = get(oArProps, sArComponentPath, 'SenderReceiverPorts', 'PathType', 'FullyQualified');
stPorts.astSenderReceiverPorts = cellfun(@(s) i_getArPortInfoFromPort(oArProps, s), casSenderReceiverPorts);

casNvSenderReceiverPorts = get(oArProps, sArComponentPath, 'NvSenderReceiverPorts', 'PathType', 'FullyQualified');
stPorts.astNvSenderReceiverPorts = cellfun(@(s) i_getArPortInfoFromPort(oArProps, s), casNvSenderReceiverPorts);

% ----------- client --------------------
casClientPorts = get(oArProps, sArComponentPath, 'ClientPorts', 'PathType', 'FullyQualified');
mCallers = i_getAllCallerBlocks(sModelName, oAutosarSLMapping);
stPorts.astClientPorts = cellfun(@(s) i_getClientPortInfoFromPort(oArProps, s, mCallers), casClientPorts);

% ----------- other --------------------
stPorts.astIRVs = i_getAllIRVInfos(oArProps, sArComponentPath);
end


%%
function mCallers = i_getAllCallerBlocks(sModelName, oAutosarSLMapping)
casCallerBlocks = ep_find_system(sModelName,...
    'FollowLinks',      'on', ...
    'LookUnderMasks',   'all', ...
    'BlockType',        'FunctionCaller');

mCallers = containers.Map;
for i = 1:numel(casCallerBlocks)
    sFunc = i_getFuncName(casCallerBlocks{i});
    
    try
        [sPort, sOperation] = oAutosarSLMapping.getFunctionCaller(sFunc);
    catch
        % seem to be a normal function caller not connected to AUTOSAR at all --> in this case ignore
        continue;
    end
    
    sKey = i_getOpCallKey(sPort, sOperation);
    if mCallers.isKey(sKey)
        mCallers(sKey) = [mCallers(sKey), casCallerBlocks(i)]; % note: used as one-elem cell
    else
        mCallers(sKey) = casCallerBlocks(i); % note: used as one-elem cell
    end
end
end


%%
function sKey = i_getOpCallKey(sPortName, sOperationName)
sKey = [sPortName, ':', sOperationName];
end


%%
function sFunc = i_getFuncName(sCallerBlock)
sFunc = '';

sPrototype = get_param(sCallerBlock, 'FunctionPrototype');
sExtractedFunc = regexprep(sPrototype, '.*?(\w+)\(.*', '$1');
if (numel(sExtractedFunc) < numel(sPrototype))
    sFunc = sExtractedFunc;
end
end


%%
function astIRVsInfo = i_getAllIRVInfos(oArProps, sArComponentPath)
sIB = get(oArProps, sArComponentPath, 'Behavior', 'PathType', 'FullyQualified');
casIrvs = get(oArProps, sIB, 'IRV', 'PathType', 'FullyQualified');
astIRVsInfo = cellfun(@(s) i_getIRVInfo(oArProps, s), casIrvs);
end


%%
function stIRVInfo = i_getIRVInfo(oArProps, sIRVPath)
stIRVInfo = struct( ...
    'sPath',         sIRVPath, ...
    'sName',         i_getName(oArProps, sIRVPath), ...
    'sImplDatatype', i_getType(oArProps, sIRVPath));
end


%%
function stPortInfo = i_getArSwitchModeInfoForPort(oArProps, sPortPath)
sItfPath = get(oArProps, sPortPath, 'Interface', 'PathType', 'FullyQualified');
sItfModeGroupPath = get(oArProps, sItfPath, 'ModeGroup', 'PathType', 'FullyQualified');

stPortInfo = struct( ...
    'sPath',      sPortPath, ...
    'sPortName',  i_getName(oArProps, sPortPath), ...
    'sItfName',   i_getName(oArProps, sItfPath), ...
    'sModeGroup', i_getName(oArProps, sItfModeGroupPath));
end


%%
function stPortInfo = i_getArPortInfoFromPort(oArProps, sPortPath)
sItfPath   = get(oArProps, sPortPath, 'Interface', 'PathType', 'FullyQualified');
casDEPaths = get(oArProps, sItfPath, 'DataElements', 'PathType', 'FullyQualified');

stPortInfo = struct( ...
    'sPath',          sPortPath, ...
    'sPortName',      i_getName(oArProps, sPortPath), ...
    'sItfName',       i_getName(oArProps, sItfPath), ...
    'astDataElement', cellfun(@(s) i_getDataElemInfo(oArProps, s), casDEPaths));
end


%%
function stPortInfo = i_getClientPortInfoFromPort(oArProps, sPortPath, mCallers)
sPortName  = i_getName(oArProps, sPortPath);
sItfPath   = oArProps.get(sPortPath, 'Interface', 'PathType', 'FullyQualified');
casOpPaths = oArProps.get(sItfPath, 'Operations', 'PathType', 'FullyQualified');

stPortInfo = struct( ...
    'sPath',           sPortPath, ...
    'sPortName',       sPortName, ...
    'sItfName',        i_getName(oArProps, sItfPath), ...
    'astOperations',   cellfun(@(s) i_getOperationInfo(oArProps, s, sPortName, mCallers), casOpPaths));
end


%%
function stElemInfo = i_getDataElemInfo(oArProps, sDataElemPath)
stElemInfo = struct( ...
    'sName',         i_getName(oArProps, sDataElemPath), ...
    'sImplDatatype', i_getType(oArProps, sDataElemPath));
end


%%
function sType = i_getType(oArProps, sElemPath)
try
    sType = char(get(oArProps, sElemPath, 'Type'));
catch
    sType = 'UNKNOWN_IDT';
end
end


%%
function stOpInfo = i_getOperationInfo(oAutosarProps, sOpPath, sPortName, mCallers)
sOpName = i_getName(oAutosarProps, sOpPath);

sKey = i_getOpCallKey(sPortName, sOpName);
if mCallers.isKey(sKey)
    casCallerBlocks = mCallers(sKey);
else
    casCallerBlocks = {};
end

stOpInfo = struct( ...
    'sName',           sOpName, ...
    'casCallerBlocks', {casCallerBlocks});
end


%%
function sName = i_getName(oAutosarProps, sPath) %#ok<INUSD>
bDoItClean = false;

if bDoItClean
    % this is the *clean* but *slow* way of doing it
    sName = oAutosarProps.get(sPath, 'Name'); %#ok<UNRCH> OK TODO: dead code can used for later re-factoring!
else
    sName = regexprep(sPath, '.*/', '');
end
end


%%
function stArgs = i_evalArgs(varargin)
stArgs = struct( ...
    'Environment', [], ...
    'ModelName',   i_getCurrentModel());

casValidKeys = fieldnames(stArgs);
stUserArgs = ep_core_transform_args(varargin, casValidKeys);

casFoundKeys = fieldnames(stUserArgs);
for i = 1:numel(casFoundKeys)
    sKey = casFoundKeys{i};
    stArgs.(sKey) = stUserArgs.(sKey);
end

if isempty(stArgs.ModelName)
    error('EP:EC:MODEL_NAME_UNDEFINED', 'No model provided.');
end
if isempty(stArgs.Environment)
    stArgs.Environment = EPEnvironment();
    stArgs.oOnCleanupCleanEnv = onCleanup(@() stArgs.Environment.clear());
else
    stArgs.oOnCleanupCleanEnv = [];
end
end


%%
function sModel = i_getCurrentModel()
try
    sModel = bdroot(gcs);
catch
    sModel = '';
end
end


%%
function aoRunnables = i_getRunnablesClassicAUTOSAR(xEnv, sModelName, oAutosarProps, oAutosarSLMapping, sArComponentPath)
casRunArPath = find(oAutosarProps, sArComponentPath, 'Runnable', 'PathType', 'FullyQualified');
aoRunnables = repmat(Eca.MetaAutosarRunnable, 1, numel(casRunArPath));
if verLessThan('matlab' , '9.9')
    sInitialize = 'InitializeFunction';
    sFctKind = 'StepFunction';
else
    sInitialize = 'Initialize';
    sFctKind = 'Periodic';
end
for k = 1:numel(casRunArPath)
    aoRunnables(k).sName = i_getName(oAutosarProps, casRunArPath{k});
    aoRunnables(k).sSymbol = get(oAutosarProps, casRunArPath{k}, 'symbol');
    
    if i_isFunctionKind(oAutosarSLMapping, sInitialize, aoRunnables(k).sName)
        aoRunnables(k).bIsInitFunction = true;
        continue;
    end
    
    if i_isFunctionKind(oAutosarSLMapping, sFctKind, aoRunnables(k).sName)
        aoRunnables(k).bIsStepFunction = true;
        aoRunnables(k).bIsModeled = true;
        aoRunnables(k).sSubsysPath = i_searchOnRootLevel(xEnv, sModelName);
        continue;
    end
    
    [bIsSlFunction, sSubPath] = i_isSimulinkFunction(sModelName, oAutosarSLMapping, aoRunnables(k).sSymbol);
    if bIsSlFunction
        aoRunnables(k).sSubsysPath = sSubPath;
        aoRunnables(k).bIsModeled = true;
        aoRunnables(k).bIsSlFunction = true;
        continue;
    end
    
    [bIsExpFunc, sTrigPortName] = i_isExportFunction(oAutosarSLMapping, aoRunnables(k).sName, sModelName);
    if bIsExpFunc
        aoRunnables(k).bIsExportFunction = true;
        aoRunnables(k).bIsModeled = true;
        aoRunnables(k).sSubsysPath = ep_ec_trigger_port_subsystem_trace([sModelName, '/', sTrigPortName]);
        aoRunnables(k).sRootInputTrigBlkName = sTrigPortName;
        continue;
    end
    
    % cannot process this runnable
    aoRunnables(k).sSubsysPath = '';
end
end


%%
function [bIsExpFunc, sTrigPortName] = i_isExportFunction(oArMap, sRunName, sModelName)
casRootFunCallTrig = ep_find_system(sModelName, ...
    'SearchDepth',        1, ...
    'BlockType',          'Inport', ...
    'OutputFunctionCall', 'on');
casRootFunCallTrigNames = get_param(casRootFunCallTrig, 'Name');

bIsExpFunc = false;
sTrigPortName = '';

for iTrig = 1:numel(casRootFunCallTrigNames)
    try %#ok<TRYNC>
        if verLessThan('matlab' , '9.9')
            sExpFct = casRootFunCallTrigNames{iTrig};
        else
            sExpFct = strcat('ExportedFunction:', casRootFunCallTrigNames{iTrig});
        end
        sExportRunnableName = getFunction(oArMap, sExpFct);
        if strcmp(sExportRunnableName, sRunName)
            bIsExpFunc = true;
            sTrigPortName = casRootFunCallTrigNames{iTrig};
            break;
        end
    end
end
end


%%
function [bIsSlFunction, sSubsysPath] = i_isSimulinkFunction(sModelName, oArMap, sRunSymbol)
bIsSlFunction = false;
sSubsysPath = '';
if verLessThan('matlab' , '9.9')
    sSLFct = sRunSymbol;
else
    sSLFct = strcat('SimulinkFunction:', sRunSymbol);
end
try oArMap.getFunction(sSLFct);
    casTriggerPorts = ep_find_system(sModelName, ...
        'BlockType',          'TriggerPort', ...
        'IsSimulinkFunction', 'on', ...
        'FunctionName',       sRunSymbol);
    if ~isempty(casTriggerPorts)
        bIsSlFunction = true;
        sSubsysPath = get_param(char(casTriggerPorts{1}), 'Parent');
    end
catch
end
end


%%
function bTrue = i_isFunctionKind(oArMap, sKind, sRunName)
try
    sName = getFunction(oArMap, sKind);
catch
    sName = '';
end
if ~isempty(sName)
    bTrue = strcmp(sName, sRunName);
else
    bTrue = false;
end
end


%%
function sRootSub = i_searchOnRootLevel(xEnv, sSearchRoot)
sRootSub = '';

astSubs = ep_model_subsystems_get( ...
    'Environment',  xEnv, ...
    'ModelContext', sSearchRoot);
if ~isempty(astSubs)
    sRootSub = astSubs(1).sPath;
end
end


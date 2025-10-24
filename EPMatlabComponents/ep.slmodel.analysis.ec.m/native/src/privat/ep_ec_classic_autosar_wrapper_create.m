function stResult = ep_ec_classic_autosar_wrapper_create(stArgs)
% Creates a wrapper model for classic AUTOSAR models that can be used as a testing framework.
%
% function stResult = ep_ec_classic_autosar_wrapper_create(stArgs)
%
%  INPUT              DESCRIPTION
%    stArgs                  (struct)  Struct containing arguments for the wrapper creation with the following fields
%      .ModelName                (string)          Name of the open AUTOSAR model.
%      .InitScript               (string)          The init script (full file) of the AUTOSAR model.
%      .WrapperName              (string)          Name of the wrapper to be created.
%      .OpenWrapper              (boolean)         Shall model be open after creation?
%      .GlobalConfigFolderPath   (string)          Path to global EC configuration settings.
%      .Environment              (object)          EPEnvironment object for progress.
%      
%
%  OUTPUT            DESCRIPTION
%    stResult                   (struct)          Return values ( ... to be defined)
%      .sWrapperModel           (string)            Full path to created wrapper model. (might be empty if not
%                                                   successful)
%      .sWrapperInitScript      (string)            Full path to created init script. (might be empty if not
%                                                   successful or if not created)
%      .sWrapperDD              (string)            Full path to created SL DD. (might be empty if not
%                                                   successful or if not created)
%      .bSuccess                (bool)              Was creation successful?
%      .casErrorMessages        (cell)              Cell containing warning/error messages.
%
% 
%   REQUIREMENTS
%     Original AUTOSAR model is assumed to be open.
%


%%
stResult = struct( ...
    'sWrapperModel',      '', ...
    'sWrapperInitScript', '', ...
    'sWrapperDD',         '', ...
    'bSuccess',           false, ...
    'casErrorMessages',   {{}});

if (nargin < 1)
    stArgs = i_getDefaultArgs();
end
fSetProgress = @(varargin) stArgs.Environment.setProgress(varargin{:});
nTotal = 12;
nCurrent = 0;
fSetProgress(nCurrent, nTotal, 'Starting creation');
sModelName = stArgs.ModelName;
sWrapperModelName = stArgs.WrapperName;

% change into the model directory to avoid creating artifacts like "slprj" into invalid file location
sModelPath = fileparts(get_param(sModelName, 'FileName'));
sWrapperModelFile = fullfile(sModelPath, [sWrapperModelName '.slx']);

% now switch to the model path if we are not there already
sCurrentPath = pwd;
if ~strcmpi(sModelPath, sCurrentPath)
    cd(sModelPath);
    onCleanupReturnToCurrentDir = onCleanup(@() cd(sCurrentPath));
end

nCurrent = nCurrent + 1;
fSetProgress(nCurrent, nTotal, ['Compiling model ', sModelName]);
try
    oRestoreModel = i_compileModel(sModelName); %#ok<NASGU> onCleanup object for restoring normal mode of model
catch oEx
    sCause = oEx.getReport('basic', 'hyperlinks', 'off');
    fprintf('[ERROR] Model "%s" cannot be initialized:\n\n%s', sModelName, sCause);
    stResult.casErrorMessages{end + 1} = ...
        sprintf('Model "%s" cannot be initialized. For detailed messages see the Matlab console.', sModelName);
    return;
end

hWrapperModel = [];
try
    % Get root input function-call ports
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Analysing trigger ports');
    astFuncCallInports = i_getFuncCallInports(sModelName);
    
    stArShortInfo = ep_ec_autosar_short_info_get(sModelName);
    bIsExportedFuncModel = strcmp(stArShortInfo.sStyle, 'function-call-based');
    if (~bIsExportedFuncModel && (numel(stArShortInfo.casRunnables) ~= 1))
        stResult.casErrorMessages{end + 1} = sprintf( ...
            'Model "%s" is a rate-based AUTOSAR model with more than one runnable. A wrapper for it cannot be created.', ...
            sModelName);
        return;
    end
    
    % create empty wrapper model
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Creating empty wrapper model and adapting configuration settings');
    
    i_saveAndCloseOpenModel(sWrapperModelName);
    
    hWrapperModel = ep_new_model_create(sWrapperModelName);
    sWrapperTag = ep_ec_tag_get('autosar wrapper model complete');
    set_param(sWrapperModelName, 'Tag', sWrapperTag);
    
    dCompiledStepSize = get_param(sModelName, 'CompiledStepSize');
    oWrapperConfig = i_adaptConfigSet(sWrapperModelName, sModelName, dCompiledStepSize);
    i_addAutosarInitFunctionCall(oWrapperConfig, stArShortInfo);
    i_addStubForRteDummyFunc(oWrapperConfig, 'dummy_caller_rte_funcs'); % currently a hack! name should be *centralized*
    
    % add a data storage for additional data
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Establishing data persistence');
    oWrapperData = Eca.WrapperModelData(sWrapperModelName, sModelName);
    sModelDD = get_param(sModelName, 'DataDictionary');
    if ~isempty(sModelDD)
        oWrapperData.referenceDD(sModelDD);
    else
        oWrapperData.addInitScriptContent(...
            sprintf('%% Init script for AUTOSAR wrapper model: %s', sWrapperModelName));
    end
    if ~isempty(stArgs.InitScript)
        oWrapperData.addInitScriptContent(i_getInitModelCommands(stArgs.InitScript, sModelPath));
    end    
    
    % --- SUT block -----------------
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Adding SUT block');
    stSutBlock = ep_ec_model_wrapper_sut_block_create('TargetModel', sWrapperModelName, 'OrigModel', sModelName);
    i_addAndWireRootPorts(sWrapperModelName, stSutBlock.astInports, stSutBlock.astOutports);    
    
    % --- Test Clients --------------
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Adding test clients');
    adSutBlockPos = get(stSutBlock.hVariantSub, 'Position');
    [astSrvFunCallsInfo, ~, casIntRunnables] = ...
        i_addCorrespondingFunCallerBlocks(sWrapperModelName, sModelName, adSutBlockPos, oWrapperData, getfullname(stSutBlock.hVariantSub));
    
    % --- Scheduler -----------------
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Adding scheduler');
    dCompiledStepSize = get_param(sModelName, 'CompiledStepSize');
    
    if ((numel(astFuncCallInports) + numel(astSrvFunCallsInfo)) > 0)
        hSchedulerSub = i_addAndConnectScheduler( ...
            sWrapperModelName, ...
            dCompiledStepSize, ...
            stSutBlock.hVariantSub, ...
            astFuncCallInports, ...
            astSrvFunCallsInfo(end:-1:1));
    else
        hSchedulerSub = [];
    end
    
    % --- Mock Servers --------------
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Adding mock servers');
    stMockSrvArgs = struct( ...
        'sWrapperModelName',  sWrapperModelName, ...
        'sModelName',         sModelName, ...
        'xDummySub',          stSutBlock.hDummySub, ...
        'aiMdlRefBlkPos',     adSutBlockPos, ...
        'stAutosarInfo',      stArShortInfo, ...
        'casIntRunnables',    {casIntRunnables}, ...
        'oWrapperData',       oWrapperData);
    
    stResultMocks = i_mockServersCreate(stMockSrvArgs, getfullname(stSutBlock.hVariantSub));
    astDataStores = stResultMocks.astDataStoreInfo;

    % --- Codegen Block -------------
    adCodegenBlockPos = i_getCodegenBlockPosition(hSchedulerSub, stSutBlock.hVariantSub);
    ep_ec_model_wrapper_block_codegen_create(sWrapperModelName, adCodegenBlockPos);
    
    sMappingHeaderName = 'BTC_EP_wrapper_rte_mapping.h';
    sMappingHeaderFile = fullfile(sModelPath, sMappingHeaderName);
    i_avoidOverwrite(sMappingHeaderFile);
    if ~stResultMocks.mCodeFuncUsedToRequired.isempty()
        i_createRteMappingHeader(oWrapperConfig, stResultMocks.mCodeFuncUsedToRequired, sMappingHeaderFile);
    end
    
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Storing additional data');
    oWrapperData.persistContent(i_getDataStoreInitCommands(astDataStores, oWrapperData));
    
    % delete irrelevant blocks in dummy block
    i_finalizeDummyBlock(stSutBlock);
    
    % handle special case: rate-based AUTOSAR model with one runnable
    if ~bIsExportedFuncModel
        sRunnableNameToCall = stArShortInfo.casRunnables{1};
        if stArShortInfo.bIsMultiInstance
            sRunnableNameToCall = ep_ec_ar_multi_instance_adapter_function_get(sRunnableNameToCall);
        end
        i_addRunnableCaller(stSutBlock.hDummySub, sRunnableNameToCall);
    end
    
    % evaluate DD and init-script info
    sWrapperInitScript = i_removeIfInitScriptNotNeeded(oWrapperData.getInitScript());
    sWrapperDD = oWrapperData.getFileDD();
    
    % evaluate post-hook function
    nCurrent = nCurrent + 1;
    fSetProgress(nCurrent, nTotal, 'Evaluating hook function');
    stAdditionalInfo = struct( ...
        'Model',                 sModelName, ...
        'WrapperModel',          sWrapperModelName, ...
        'WrapperInitScriptFile', sWrapperInitScript, ...
        'SchedulerSubsystem',    getfullname(hSchedulerSub));
    i_evalPostHook(stArgs.GlobalConfigFolderPath, sModelPath, stAdditionalInfo);    
    
catch oEx
    i_cleanupAfterAbort(hWrapperModel);
    
    sCause = oEx.getReport('basic', 'hyperlinks', 'off');
    fprintf('[ERROR] Failed creating wrapper for model "%s":\n\n%s\n\n', sModelName, sCause);
    stResult.casErrorMessages{end + 1} = ...
        sprintf('Failed creating wrapper for model "%s". For detailed messages see the Matlab console.', sModelName);
    return;
end

% when we are here, everything is fine and valid --> save the wrapper model
nCurrent = nCurrent + 1;
fSetProgress(nCurrent, nTotal, 'Saving system');
i_avoidOverwrite(sWrapperModelFile);
save_system(sWrapperModelName, sWrapperModelFile, 'SaveDirtyReferencedModels', true);

% now open model if requested
if stArgs.OpenWrapper
    set(hWrapperModel, 'Open', 'on');
else
    % if wrapper is not kept open, close it when done
    oOnCleanupCloseWrapper = onCleanup(@() close_system(sWrapperModelName, 0));
end

nCurrent = nCurrent + 1;
fSetProgress(nCurrent, nTotal, 'Creation successful');

stResult.bSuccess = true;
stResult.sWrapperModel = sWrapperModelFile;
stResult.sWrapperInitScript = sWrapperInitScript;
stResult.sWrapperDD = sWrapperDD;
end


%%
function i_addRunnableCaller(hSub, sRunnableName)
hFunCallerBlk = add_block('built-in/FunctionCaller', [getfullname(hSub) '/Call_' sRunnableName]);

sFunPrototype = sprintf('%s()', sRunnableName);
set(hFunCallerBlk, 'FunctionPrototype', sFunPrototype);
end


%%
% note: the wrapper init script is only needed, if it contains more than just commented lines
function sWrapperInitScript = i_removeIfInitScriptNotNeeded(sWrapperInitScript)
if (isempty(sWrapperInitScript) || ~exist(sWrapperInitScript, 'file'))
    return;
end

bIsNeeded = false;

sContent = fileread(sWrapperInitScript);
if isempty(sContent)
    bIsNeeded = false;
end

casLines = strsplit(sContent, '\n');
for i = 1:numel(casLines)
    % check if the line is a comment starting with a "%"; if it is not, we have a command and the init script is needed
    if isempty(regexp(casLines{i}, '^\s*%', 'once'))
        bIsNeeded = true;
        break;
    end
end

if ~bIsNeeded
    delete(sWrapperInitScript);
    sWrapperInitScript = '';
end
end


%%
function stResultMocks = i_mockServersCreate(stMockSrvArgs, sVariantSubsystem)
% Before adding mock servers and corresponding callers into the inner dummy variant, make the dummy variant active.
% Otherwise the performance of setting code prototypes for SLFunctions/-Callers will drop dramatically.
%
oRestoreVariant = i_switchVariantToDummy(sVariantSubsystem); %#ok<NASGU> onCleanup object

stResultMocks = ep_ec_model_wrapper_mock_server_callers_create(stMockSrvArgs);
end


%%
function oRestoreVariant = i_switchVariantToDummy(sVariantSubsystem)
sCurrentVariant = get_param(sVariantSubsystem, 'OverrideUsingVariant');
if ~strcmp(sCurrentVariant, 'orig')
    error('EP:DEV:ERROR', 'Expecting variant "orig" to be the overriding active variant.');
end
set_param(sVariantSubsystem, 'OverrideUsingVariant', 'dummy');

oRestoreVariant = onCleanup(@() set_param(sVariantSubsystem, 'OverrideUsingVariant', sCurrentVariant));
end


%%
% Delete unnecessary blocks in the dummy subsystem and adds signal names for outports if necessary.
% Important: Has to be done as one of the last steps else potential problems in the codemapping are caused.
function i_finalizeDummyBlock(stSutBlock)
i_deleteBlocks(stSutBlock);
addterms(stSutBlock.hDummySub);
i_addOutportSignalNames(stSutBlock);
end


%%
function i_addOutportSignalNames(stSutBlock)
mPortNum2SigName = i_getPortNumToSignalNameMapping(stSutBlock.astOutports);
ahOutportBlocks = find_system(stSutBlock.hDummySub, 'SearchDepth', 1, 'BlockType', 'Outport');
% for the Output signal also add a name to mimick the original model as closely as possible
for i = 1:numel(ahOutportBlocks)
    hOutPortBlock = ahOutportBlocks(i);

    sPortNum = get_param(hOutPortBlock, 'Port');
    if mPortNum2SigName.isKey(sPortNum)
        sSigName = mPortNum2SigName(sPortNum);

        stPorts = get_param(hOutPortBlock, 'PortHandles');
        hLine = get_param(stPorts.Inport, 'Line');
        if (hLine > 0)
            set_param(hLine, 'Name', sSigName);
        end
    end
end
end


%%
function mPortNum2SigName = i_getPortNumToSignalNameMapping(astPorts)
mPortNum2SigName = containers.Map;
for i = 1:numel(astPorts)
    stPort = astPorts(i);
    if ~isempty(stPort.sSigName)
        sPortNum = sprintf('%d', stPort.nPortNum);
        mPortNum2SigName(sPortNum) = stPort.sSigName;
    end
end
end


%%
% Deletes unnecessary blocks in the dummy block. Should be done at the end
% else problems in the codemapping are caused.
function i_deleteBlocks(stSutBlock)

ahBlkBlackListRunnable = stSutBlock.ahBlkBlackListRunnable;
for i = 1:numel(ahBlkBlackListRunnable)
    delete_block(ahBlkBlackListRunnable(i));
end

cahBlksBlackListInRunnable = stSutBlock.cahBlksBlackListInRunnable;
for k = 1:numel(cahBlksBlackListInRunnable)
    ahBlksToDelete = cahBlksBlackListInRunnable{k};
    for j = 1:numel(ahBlksToDelete)
        try
            delete_block(ahBlksToDelete(j));
        catch
            % just ignore
        end
    end
end
end


%%
function i_cleanupAfterAbort(hWrapperModel)
if ~isempty(hWrapperModel)
    try %#ok<TRYNC>
        close_system(hWrapperModel, 0);
    end
end
end


%%
function i_avoidOverwrite(sFileToBeWritten)
if ~exist(sFileToBeWritten, 'file')
    return;
end

nTries = 0;
nMaxTries = 100;
sBakFileBase = [sFileToBeWritten, '.bak'];
sBakFile = sBakFileBase;
while exist(sBakFile, 'file')
    nTries = nTries + 1;
    if (nTries > nMaxTries)
        error('EP:WRAPPER_CREATE_FAILED', ...
            ['File "%s" cannot be created because it already exists. ', ...
            'Ranaming existing file failed because number of such backup files exceeds maximum.'], ...
            sFileToBeWritten);
    end
    
    sBakFile = sprintf('%s_%.3d', sBakFileBase, nTries);
end
fprintf('\n[INFO] To avoid overwriting data, moving file "%s" to "%s".\n\n', sFileToBeWritten, sBakFile);
movefile(sFileToBeWritten, sBakFile, 'f');
end


%%
function i_saveAndCloseOpenModel(sModelName)
bIsLoaded = ~isempty(find_system('SearchDepth', 0, 'Name', sModelName, 'Type', 'block_diagram'));
if bIsLoaded
    fprintf('\n[INFO] Saving and closing model "%s" in order to proceed".\n\n', sModelName);
    close_system(sModelName, 1);
end
end


%%
function oOnCleanupTerminateCompileMode = i_compileModel(sModelName)
eval([sModelName, '([], [], [], ''compile'');']);
oOnCleanupTerminateCompileMode = onCleanup(@() i_terminateModelRobustly(sModelName));
end


%%
function i_terminateModelRobustly(sModelName)
try
    feval(sModelName, [], [], [], 'term');
catch oEx %#ok<NASGU> 
    % be robust
end
end


%%
function i_addAutosarInitFunctionCall(oWrapperConfig, stArShortInfo)
if isempty(stArShortInfo.sInitRunnable)
    warning('EP:EC:NO_AUTOSAR_INIT_RUNNABLE_FOUND', 'Init runnable of the AUTOSAR model was not found.');
    return;
end

if stArShortInfo.bIsMultiInstance
    sAdapterInitFunc = ep_ec_ar_multi_instance_adapter_function_get(stArShortInfo.sInitRunnable);
    sAdapterStepFunc = ep_ec_ar_multi_instance_adapter_function_get(stArShortInfo.casRunnables{1});
    sDeclareEntryFunctions = [...
        '/* BTC-EP -- declare adapter init and step model functions */', ...
        newline, ...
        'extern void ', sAdapterInitFunc, '();', ...
        newline, ...
        'extern void ', sAdapterStepFunc, '();', ...
        newline];
    i_appendConfigProperty(oWrapperConfig, 'CustomHeaderCode', sDeclareEntryFunctions);

    sCallInitFunction = [ ...
        '/* BTC-EP -- call the AUTOSAR model adapter init function */', ...
        newline, ...
        sAdapterInitFunc, '();', ...
        newline];
    i_appendConfigProperty(oWrapperConfig, 'CustomInitializer', sCallInitFunction);
    
else
    sIncludeHeader = [...
        '/* BTC-EP -- include the AUTOSAR model RTE header for the init function */', ...
        newline, ...
        '#include "Rte_', stArShortInfo.sComponentName, '.h"', ...
        newline];
    i_appendConfigProperty(oWrapperConfig, 'CustomHeaderCode', sIncludeHeader);

    sCallInitFunction = [ ...
        '/* BTC-EP -- call the AUTOSAR model init function */', ...
        newline, ...
        stArShortInfo.sInitRunnable, '();', ...
        newline];
    i_appendConfigProperty(oWrapperConfig, 'CustomInitializer', sCallInitFunction);
end
end


%%
function i_addStubForRteDummyFunc(oWrapperConfig, sDummyFuncName)
sDummyFuncStub = [...
    '/* BTC-EP -- stub implementation for dummy function */', ...
    newline, ...
    sprintf('void %s() {}', sDummyFuncName), ...
    newline];
i_appendConfigProperty(oWrapperConfig, 'CustomSourceCode', sDummyFuncStub);
end


%%
function i_appendConfigProperty(oConfig, sPropName, sAddContent)
sContentNow = oConfig.get_param(sPropName);
if isempty(sContentNow)
    sContentNow = ''; % avoid empty array []
end
oConfig.set_param(sPropName, sprintf('%s\n%s', sContentNow, sAddContent));
end


%%
function i_createRteMappingHeader(oWrapperConfig, mCodeFuncUsedToRequired, sHeaderFile)
bWasCreated = i_createMappingHeaderFile(mCodeFuncUsedToRequired, sHeaderFile);

if bWasCreated
    [~, f, e] = fileparts(sHeaderFile);
    sHeaderName = [f, e];
    i_appendConfigProperty(oWrapperConfig, 'CustomHeaderCode', sprintf('#include "%s"\n', sHeaderName));
end
end


%%
function bWasCreated = i_createMappingHeaderFile(mCodeFuncUsedToRequired, sHeaderFile)
bWasCreated = false;

casUsedFuncs = mCodeFuncUsedToRequired.keys;

casDefines = cellfun( ...
    @(sFunc) sprintf('#define %s %s', sFunc, mCodeFuncUsedToRequired(sFunc)), casUsedFuncs, 'UniformOutput', false);
sContentDefines = sprintf('%s\n', casDefines{:});

sContent = [ ...
    '#ifndef BTC_EP_WRAPPER_RTE_MAPPING_H', newline, ...
    '#define BTC_EP_WRAPPER_RTE_MAPPING_H', newline, ...
    newline, ...
    sContentDefines, ...
    newline, ...
    '#endif'];

hFid = fopen(sHeaderFile, 'w');
if (hFid > 0)
    oOnCleanupClose = onCleanup(@() fclose(hFid));
    
    fprintf(hFid, '%s', sContent);
    bWasCreated = true;
else
    fprintf('\n[ERROR] Could not create mapping header "%s".\n', sHeaderFile);
end
end


%%
function oWrapperConfigSet = i_adaptConfigSet(sWrapperModelName, sModelName, dCompiledStepSize)
oOrigConfigSet = getActiveConfigSet(sModelName);
oWrapperConfigSet = copy(oOrigConfigSet);

% Set FixedStep parameter to dCompiledStepSize  in case is set to auto
dSampleTime = str2double(get_param(oWrapperConfigSet, 'FixedStep'));
if (isempty(dSampleTime)  || isequal(dSampleTime, -1) || ~isfinite(dSampleTime))
    oWrapperConfigSet.set_param('FixedStep', dCompiledStepSize)
    casContentLines = { ...
        sprintf('\n[EP:WARNING]: Fundamental sample time of the original model was found to be set to ''auto''.'), ...
        sprintf('Setting it to the sample time computed in compiled mode ''CompiledSampletime'': %s.\n', num2str(dCompiledStepSize)), ...
        };
    sContent = strjoin(casContentLines, '\n');
    fprintf(sContent);
end

% rename the config set to wrapper-specific name
sWrapperConfigName = 'WrapperModelConfigSet';
set_param(oWrapperConfigSet, 'Name', sWrapperConfigName);

% target needs to be ERT instead of AUTOSAR
set_param(oWrapperConfigSet, 'SystemTargetFile', 'ert.tlc');
i_repairWrapperConfigAfterTargetSwitch(oWrapperConfigSet, oOrigConfigSet);

% checks for scheduling times would lead to wrong issues --> switch them off
set_param(oWrapperConfigSet, 'EnableRefExpFcnMdlSchedulingChecks' , 'off');

% global types/variables in orig model and wrapper can clash --> try to avoid this by sightly changing the macro
sGlobalTypeMacro = oWrapperConfigSet.getProp('CustomSymbolStrType');
oWrapperConfigSet.setProp('CustomSymbolStrType', ['w_', sGlobalTypeMacro]);
sGlobalVarMacro = oWrapperConfigSet.getProp('CustomSymbolStrGlobalVar');
oWrapperConfigSet.setProp('CustomSymbolStrGlobalVar', ['w_', sGlobalVarMacro]);
oWrapperConfigSet.setProp('CustomSymbolStrModelFcn', '$R$N');

% RTE names can be very long --> extend the max allowed length to max
oWrapperConfigSet.set_param('MaxIdLength', '256');

% TODO: not clear why this is needed?
oWrapperConfigSet.set_param('MultiTaskCondExecSysMsg', 'Error');

oWrapperConfigSet.set_param('UnderSpecifiedDataTypeMsg', 'off');

%ensure that the right replacement mode for datatypes is active
if ~verLessThan('matlab', '23.2') %#ok<VERLESSMATLAB>
    oWrapperConfigSet.set_param('DataTypeReplacement', 'CoderTypedefs');
end

% set adapted config as active config of wrapper
attachConfigSet(sWrapperModelName, oWrapperConfigSet);
setActiveConfigSet(sWrapperModelName, sWrapperConfigName);
end


%%
% Restoring the replacement type settings, because they are set to default after the target switch
function i_repairWrapperConfigAfterTargetSwitch(oWrapperConfigSet, oOrigConfigSet)
casParameterSet = i_getParameterWhitelist();
for i = 1:numel(casParameterSet)
    % checking that the given parameter is available for both configs
    sParam = casParameterSet{i};
    try
        sWrapperVal = oWrapperConfigSet.getProp(sParam);
        sOrigVal = oOrigConfigSet.getProp(sParam);
    catch
        continue;
    end
    if ~isequal(sWrapperVal, sOrigVal)
        bSettingAllowed = oWrapperConfigSet.getPropEnabled(sParam);
        if(bSettingAllowed)
            oWrapperConfigSet.set_param(sParam, sOrigVal);
        end
    end
end
end


%%
function casParameterSet = i_getParameterWhitelist()
casParameterSet = { ...
    'EnableUserReplacementTypes', ...
    'ReplacementTypes', ...
    'BooleanTrueId', ...
    'BooleanFalseId', ...
    'MaxIdInt64', ...
    'MaxIdInt32', ...
    'MaxIdInt16', ...
    'MaxIdInt8', ...
    'MaxIdUint64', ...
    'MaxIdUint32', ...
    'MaxIdUint16', ...
    'MaxIdUint8', ...
    'MinIdInt64', ...
    'MinIdInt32', ...
    'MinIdInt16', ...
    'MinIdInt8'};
end


%%
function [astSrvFunCallsInfo, astServerRunaInfo, casIntRunnables] = ...
    i_addCorrespondingFunCallerBlocks(sWrapperModelName, sModelName, aiMdlRefBlkPos, oWrapperData, sVariantSubsystem)
oRestoreVariant = i_switchVariantToDummy(sVariantSubsystem); %#ok<NASGU> onCleanup object

stArgs = struct( ...
    'WrapperModel',      sWrapperModelName, ...
    'OrigModel',         sModelName, ...
    'ReferencePosition', aiMdlRefBlkPos, ...
    'oWrapperData',      oWrapperData);

[astSrvFunCallsInfo, astServerRunaInfo, casIntRunnables] = ep_ec_model_wrapper_fcn_callers_create(stArgs);
end


%%
function sContent = i_getInitModelCommands(sOrigInitScript, sModelPath)
sContent = '';
if isempty(sOrigInitScript)
    return;
end

[sScriptPath, sScriptName] = fileparts(sOrigInitScript);
if strcmpi(sModelPath, sScriptPath)
    % script is lying next to the model (and wrapper model) --> simply call the original script by name
    sContent = sprintf('%s;\n', sScriptName);
    return;
end

sWarningMsg = 'Original model init script could not be called. The wrapper model might be in an invalid state.';
casContentLines = { ...
    sprintf('if ~isempty(which(''%s''))', sScriptName), ...
    sprintf('  %s;', sScriptName), ...
    sprintf('else'), ...
    sprintf('  if exist(''%s'', ''file'')', sOrigInitScript), ...
    sprintf('    run(''%s'');', sOrigInitScript), ...
    sprintf('  else'), ...
    sprintf('    warning(''EP:CRITICAL'', ''%s'');', sWarningMsg), ...
    sprintf('  end'), ...
    sprintf('end')};
sContent = strjoin(casContentLines, '\n');
end


%%
function sContent = i_getDataStoreInitCommands(astDataStoreInfo, oWrapperData)
sContent = '';

for iDS = 1:numel(astDataStoreInfo)
    sDSName = astDataStoreInfo(iDS).sDSName;
    [bEnum, sEnumType] = i_isEnumType(astDataStoreInfo(iDS).sDSDataType);
    if bEnum
        sInitValue = [sEnumType '.' char(evalin('base', [sEnumType '.getDefaultValue']))];
    else
        sInitValue = i_getInitValue(astDataStoreInfo(iDS).sDSDataType, astDataStoreInfo(iDS).nDSDim, oWrapperData);
    end
    sTmp = [sDSName '= Simulink.Signal;\n', ...
        sDSName '.StorageClass = ''ExportedGlobal'';\n', ...
        sDSName '.DataType = ''', astDataStoreInfo(iDS).sDSDataType,''';\n', ...
        sDSName '.Dimensions = ', mat2str(astDataStoreInfo(iDS).nDSDim),';\n',...
        sDSName '.Complexity = ''real'';\n',...
        sDSName '.InitialValue = ''', sInitValue,''';'];
    
    sContent = sprintf('%s\n\n%s', sContent, sprintf(sTmp));
end
end


%%
function sInitValue = i_getInitValue(sDataType, aiDim, oWrapperData)
sInitValue = ''; % default init value is an empty string; so SL/EC is able to use defaults on his own
try %#ok<TRYNC> 
    stInfo = oWrapperData.getTypeInfo(sDataType);
    if (~stInfo.bIsFxp || i_isZeroInAllowedRange(stInfo))
        sInitValue = '';
    else
        sInitValue = oWrapperData.oStorage.getTypeInstance(sDataType, aiDim);
    end
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
function astFuncCallInports = i_getFuncCallInports(sModelName)
casBlks = cellstr(ep_find_system(sModelName, ...
    'SearchDepth',        1, ...
    'BlockType',          'Inport', ...
    'OutputFunctionCall', 'on'));
astFuncCallInports = cellfun(@i_getFunCallInportInfo, casBlks);
end


%%
function stInfo = i_getFunCallInportInfo(xInport)
sName = get_param(xInport, 'Name');
stInfo = struct( ...
    'hHdl',        get_param(xInport, 'Handle'), ...
    'sName',       sName, ...
    'sEventName',  i_getEventName(xInport), ...
    'nPortNumber', str2double(get_param(xInport, 'Port')), ...
    'dSampleTime', i_getSampleTime(xInport));
end


%%
function sEventName = i_getEventName(xInport)
hInport = get_param(xInport, 'Handle');
casOutputSignalNames = get_param(hInport, 'OutputSignalNames');
if isempty(casOutputSignalNames)
    sName = get_param(xInport, 'Name');
    sEventName = ['Call_' sName];
else
    sEventName = casOutputSignalNames{1};
    if isempty(sEventName)
        sName = get_param(xInport, 'Name');
        sEventName = ['Call_' sName];
    end
end
end


%%
function dSampleTime = i_getSampleTime(xBlock)
dSampleTime = str2double(get_param(xBlock, 'SampleTime'));
if (isempty(dSampleTime)  || isequal(dSampleTime, -1) || ~isfinite(dSampleTime))
    adSampleTime = get_param(xBlock, 'CompiledSampleTime');
    dSampleTime = adSampleTime(1);
end
end


%%
function hSchedulerSub = i_addAndConnectScheduler(sWrapperModelName, dCompiledStepSize, hVariantSub, astCltFunCallsInfo, astSrvFunCallsInfo)
nServerRunCalls = numel(astSrvFunCallsInfo);
nRunCalls = numel(astCltFunCallsInfo);
nCalls = nServerRunCalls + nRunCalls;

stVariantSubPorts = get_param(hVariantSub, 'PortHandles');

% default order (for now): first the server runnable calls, then the normal runnable calls
mEventDestPort = containers.Map();
astCalls = repmat(struct( ...
    'sEventName',    '', ...
    'nTriggerTicks', 1, ...
    'sColor',        'black'), 1, nCalls);
for i = 1:nCalls
    if (i <= nServerRunCalls)
        iServerRunIdx = i;
        
        sEventName = astSrvFunCallsInfo(iServerRunIdx).sEventName;
        
        astCalls(i).sEventName = sEventName;
        astCalls(i).nTriggerTick = 1; % note: server runnables are called each step per default
        astCalls(i).sColor = 'lightBlue';
        
        % memorize the destination port of the event
        stPortHandles = get_param(astSrvFunCallsInfo(iServerRunIdx).hParentSubSys, 'PortHandles');
        hEventDestPort = stPortHandles.Trigger;
        mEventDestPort(sEventName) = hEventDestPort;
    else
        iRunIdx = i - nServerRunCalls;
        
        sEventName = astCltFunCallsInfo(iRunIdx).sEventName;
        
        astCalls(i).sEventName = sEventName;
        astCalls(i).nTriggerTick = i_computeTriggerTicks(dCompiledStepSize, astCltFunCallsInfo(iRunIdx).dSampleTime);
        
        % memorize the destination port of the event
        hEventDestPort = stVariantSubPorts.Inport(astCltFunCallsInfo(iRunIdx).nPortNumber);
        mEventDestPort(sEventName) = hEventDestPort;
    end
end
stResult = ep_ec_model_wrapper_scheduler_create( ...
    'Location', sWrapperModelName, ...
    'Calls',    astCalls);
hSchedulerSub = stResult.hSchedulerSub;

casEventNames = stResult.mEventSrcPort.keys;
for i = 1:numel(casEventNames)
    sEventName = casEventNames{i};
    
    add_line(sWrapperModelName, stResult.mEventSrcPort(sEventName), mEventDestPort(sEventName), 'autorouting', 'on');
end
end


%%
function nTicks = i_computeTriggerTicks(dCompiledStepSize, varargin)
dBlkSampleTime= varargin{1};
if (dBlkSampleTime<=0)
    nTicks=1;
else
    dSampleTime = str2double(dCompiledStepSize);
    nTicks= round(varargin{1}/dSampleTime);
end
end


%%
function i_addAndWireRootPorts(sTargetSub, astInports, astOutports)
for i = 1:numel(astInports)
    stPort = astInports(i);
    
    if stPort.bIsFunctionCall
        continue;
    end
    
    hPortBlock = add_block('built-in/Inport', [sTargetSub '/' stPort.sName],...
        'MakeNameUnique',       'on',...
        'Position',             i_getIdealPortBlockPosition(stPort.hVariantPort), ...
        'OutDataTypeStr',       stPort.sOutDataTypeStr, ...
        'PortDimensions',       stPort.nDim, ...
        'BusOutputAsStruct',    stPort.sOutputAsVirtualBus, ...
        'showname',             'on');
    
    stPortHandles = get_param(hPortBlock, 'PortHandles');
    add_line(sTargetSub, stPortHandles.Outport, stPort.hVariantPort);
end

for i = 1:numel(astOutports)
    stPort = astOutports(i);
    
    hPortBlock = add_block('built-in/Outport', [sTargetSub '/' stPort.sName],...
        'MakeNameUnique',       'on',...
        'Position',             i_getIdealPortBlockPosition(stPort.hVariantPort), ...
        'OutDataTypeStr',       stPort.sOutDataTypeStr, ...
        'PortDimensions',       stPort.nDim, ...
        'BusOutputAsStruct',    stPort.sOutputAsVirtualBus, ...
        'showname',             'on');
    
    stPortHandles = get_param(hPortBlock, 'PortHandles');
    add_line(sTargetSub, stPort.hVariantPort, stPortHandles.Inport);
end
end


%%
function adBlockPos = i_getIdealPortBlockPosition(hPort)

% common port block properties
dBlockDistance = 70;
dBlockWidth = 30;
dHalfBlockHeight = 7;
dBlockHeight = dHalfBlockHeight + dHalfBlockHeight;

adPortPos = get_param(hPort, 'Position');
bIsInport = strcmpi(get_param(hPort, 'PortType'), 'inport');
if bIsInport
    adLeftUpper = adPortPos - [(dBlockDistance + dBlockWidth), dHalfBlockHeight];
else
    adLeftUpper = adPortPos + [dBlockDistance, -dHalfBlockHeight];
end
adRightLower = adLeftUpper + [dBlockWidth, dBlockHeight];
adBlockPos = [adLeftUpper, adRightLower];
end


%%
function [bTrue, sEnumType] = i_isEnumType(sDataTypeStr)
bTrue = false;
sEnumType = '';
if strncmp(sDataTypeStr, 'Enum:', 5)
    bTrue = true;
    sEnumType = strtrim(sDataTypeStr(6:end));
elseif ~isempty(enumeration(bTrue))
    bTrue = true;
    sEnumType = sDataTypeStr;
end
end


%%
function i_evalPostHook(sGlobalConfigPath, sModelPath, stAdditionalInfo)
% message entries not needed --> use empty env object for now
oEnv = [];

stECConfigs = ep_ec_configurations_get(oEnv, sGlobalConfigPath, sModelPath);
stHooks = stECConfigs.stHookFiles;
sHookName = 'ecahook_post_wrapper_create';
ep_ec_hook_file_eval(oEnv, sHookName, stHooks.(sHookName), stAdditionalInfo);
end


%%
function stArgs = i_getDefaultArgs()
sModelName = bdroot;
if isemtpy(sModelName)
    error('USAGE:ERROR', 'No active current model available.');
end

oEnvironment = EPEnvironment();
stArgs = struct ( ...
    'ModelName',              sModelName, ...
    'InitScript',             '', ...
    'WrapperName',            ['Wrapper_', sModelName], ...
    'OpenWrapper',            false, ...
    'GlobalConfigFolderPath', '', ...
    'Environment',            oEnvironment, ...
    'oOnCleanupClearEnv',     onCleanup(@() oEnvironment.clear()));
end


%%
function adPosition = i_getCodegenBlockPosition(hScheduler, hSutBlock)
dHeight = 45;
dWidth  = 120;
if ~isempty(hScheduler)
    adRefPos = get_param(hScheduler, 'Position');
    dSpacing = 25;
    adUpperLeft  = [adRefPos(1) + (adRefPos(3) - adRefPos(1))/2 - dWidth/2, adRefPos(2) - (dHeight + dSpacing)];
    adLowerRight = [adUpperLeft(1) +  dWidth, adUpperLeft(2) + dHeight];
else
    adRefPos = get_param(hSutBlock, 'Position');
    dSpacing = 150;
    adUpperLeft = [adRefPos(1) - (dWidth + dSpacing), adRefPos(2)];
    adLowerRight = [adUpperLeft(1) + dWidth , adUpperLeft(2) + dHeight];
end
adPosition = [adUpperLeft, adLowerRight];
end


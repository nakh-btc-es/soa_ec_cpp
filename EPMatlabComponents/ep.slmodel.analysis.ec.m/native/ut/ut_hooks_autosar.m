function ut_hooks_autosar
% Testing the hook calls functionality on low level for AUTOSAR workflow.
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('AR_sum_multiply', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

% hooks
stHooks = ep_ec_registry_hooks_get();

% note: placing hooks next to the model!
sHooksDir = sTestRoot;
casHookNames = fieldnames(stHooks);
for i = 1:numel(casHookNames)
    sHookName = casHookNames{i};

    sMockFile = fullfile(sHooksDir, strcat(sHookName, '.m'));
    sObserverFile = fullfile(sHooksDir, strcat(sHookName, '_result.mat'));
    ut_helper_hook_mock(sMockFile, sObserverFile);
end


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
casHooksNotCalledInThisWorkflow = { ...
    'ecahook_autosar_wrapper_function_info', ...
    'ecahook_post_wrapper_create'};


stDefaultInfo = struct( ...
    'sModelPath',           pwd(), ...
    'sModelName',           'sum_multiply_autosar', ...
    'sInitFilePath',        pwd(), ...
    'sInitFileName',        'autosar_init', ...
    'sStubCodeFolder',      fullfile(pwd(), 'sum_multiply_autosar_ep_stubs'), ...
    'casReferencedModels',  {cell(1, 0)}, ...
    'bIsWrapperMode',       false, ...
    'sWrappedAutosarModel', '');
for i = 1:numel(casHookNames)
    sHookName = casHookNames{i};
    
    [astSettings, astAddInfo] = i_evalHookInput(sHooksDir, sHookName);
    
    nCalls = numel(astAddInfo);    
    if any(strcmp(sHookName, casHooksNotCalledInThisWorkflow))
        SLTU_ASSERT_TRUE(0 == nCalls, ...
            'Expecting hook %s to never be called in this workflow!', sHookName);
        continue;
        
    elseif (nCalls < 1)
        SLTU_FAIL('Expected hook "%s" to be called.', sHookName);
        continue;
    end
    
    % for a non-Wrapper workflow all hooks are called once at the most
    SLTU_ASSERT_TRUE(nCalls == 1, 'Hook "%s" expected to be called once in this workflow.', sHookName);
    stFoundInfo = astAddInfo(1);
    
    % check the settings
    SLTU_ASSERT_TRUE(i_isDefaultSettings(stHooks, sHookName, astSettings), ...
        'Expecting hook %s to be called with default settings!', sHookName);
    
    % check the additional info
    switch sHookName
        case {'ecahook_pre_analysis', ...
        	'ecahook_simulationtime_get_fun', ...           
        	'ecahook_legacy_code', ...
        	'ecahook_ignore_code', ...
        	'ecahook_stub_include_files'}
            SLTU_ASSERT_EQUAL_FLAT_STRUCT(stDefaultInfo, stFoundInfo);
            
        case 'ecahook_param_blacklist'
            [stAutosarMetaInfo, stFoundInfo] = i_splitStruct(stFoundInfo, 'stAutosarMetaInfo', 'ecahook_param_blacklist');
            SLTU_ASSERT_EQUAL_FLAT_STRUCT(stDefaultInfo, stFoundInfo);
            SLTU_ASSERT_FALSE(isempty(stAutosarMetaInfo), 'Expecting non-empty AUTOSAR meta info.');
            
        case 'ecahook_post_analysis'
            [sAddModelinfoFile, stFoundInfo] = i_splitStruct(stFoundInfo, 'sAddModelinfoFile', 'ecahook_post_analysis');
            [sCodeModelFile, stFoundInfo] = i_splitStruct(stFoundInfo, 'sCodeModelFile', 'ecahook_post_analysis');
            [sMappingFile, stFoundInfo] = i_splitStruct(stFoundInfo, 'sMappingFile', 'ecahook_post_analysis');
            SLTU_ASSERT_EQUAL_FLAT_STRUCT(stDefaultInfo, stFoundInfo);
            SLTU_ASSERT_TRUE(exist(sAddModelinfoFile, 'file'));
            SLTU_ASSERT_TRUE(exist(sCodeModelFile, 'file'));
            SLTU_ASSERT_TRUE(exist(sMappingFile, 'file'));
            
        otherwise
            error('UT:ERROR', 'UT not prepared for hook: %s.', sHookName);
    end
end
end


%%
function [xFieldVal, stSplitStruct] = i_splitStruct(stStruct, sFieldName, sHookName)
if isfield(stStruct, sFieldName)
    xFieldVal = stStruct.(sFieldName);
    stSplitStruct = rmfield(stStruct, sFieldName);
else
    xFieldVal = [];
    stSplitStruct = stStruct;
    SLTU_FAIL('Expecting hook "%s" to get additional info "%s".', sHookName, sFieldName);
end
end


%%
function [astSettings, astAddInfos] = i_evalHookInput(sHooksDir, sHookName)
astSettings = [];
astAddInfos  = [];

astHookResultFiles = dir(fullfile(sHooksDir, [sHookName, '_result*.mat']));
for i = 1:numel(astHookResultFiles)
    sResultMatFile = fullfile(astHookResultFiles(i).folder, astHookResultFiles(i).name);
    
    oMat = matfile(sResultMatFile);
    if isempty(astSettings)
        astSettings = oMat.stSettings;
        astAddInfos = oMat.stAdditionalInfo;
    else
        astSettings(end + 1) = oMat.stSettings; %#ok<AGROW>
        astAddInfos(end + 1) = oMat.stAdditionalInfo; %#ok<AGROW>
    end
end
end


%%
function bIsDefault = i_isDefaultSettings(stHooks, sHookName, astFoundSettings)
sDefaultSettingsFunc = stHooks.(sHookName);
if isempty(sDefaultSettingsFunc)
    bIsDefault = true;
    return;
end

stDefaultSettings = feval(sDefaultSettingsFunc);

bIsDefault = all(arrayfun(@(st) isequal(stDefaultSettings, st), astFoundSettings));
end

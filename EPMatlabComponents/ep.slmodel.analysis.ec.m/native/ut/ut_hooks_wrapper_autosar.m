function ut_hooks_wrapper_autosar
% Testing the hook calls functionality on low level for Wrapper AUTOSAR workflow.
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('ClientServerExample', 'EC', sTestRoot);
sModelFile  = stTestData.sWrapperModelFile;
sInitScript = stTestData.sWrapperModelInitScriptFile;

% hooks
stHooks = ep_ec_registry_hooks_get();

sHooksDir = fullfile(sTestRoot, 'hooks');
mkdir(sHooksDir);
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
stExtraArg.GlobalConfigFolderPath = sHooksDir;
ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir, stExtraArg);


%% assert
casHooksNotCalledInThisWorkflow = { ...
    'ecahook_post_wrapper_create', ...
    'ecahook_autosar_wrapper_function_info'};


stDefaultInfo = struct( ...
    'sModelPath',           pwd(), ...
    'sModelName',           'Wrapper_SWC', ...
    'sInitFilePath',        pwd(), ...
    'sInitFileName',        'init_Wrapper_SWC', ...
    'sStubCodeFolder',      fullfile(pwd(), 'Wrapper_SWC_ep_stubs'), ...
    'casReferencedModels',  {{'SWC'}}, ...
    'bIsWrapperMode',       false, ...
    'sWrappedAutosarModel', 'SWC');
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
        
    % check the settings
    SLTU_ASSERT_TRUE(i_isDefaultSettings(stHooks, sHookName, astSettings), ...
        'Expecting hook %s to be called with default settings!', sHookName);
    
    % check the additional info
    switch sHookName
        case {'ecahook_simulationtime_get_fun', 'ecahook_legacy_code'}
            SLTU_ASSERT_TRUE(nCalls == 1, 'Hook "%s" expected to be called once in this workflow.', sHookName);
            stFoundInfo = astAddInfo(1);
            i_assertionHelperMethod(stDefaultInfo, stFoundInfo);
            
        case {'ecahook_ignore_code', 'ecahook_stub_include_files'}
            SLTU_ASSERT_TRUE(nCalls == 2, 'Hook "%s" expected to be called twice in this workflow.', sHookName);
            stFoundInfo1 = astAddInfo(1);
            i_assertionHelperMethod(stDefaultInfo, stFoundInfo1);
            
            stSecondInfo = stDefaultInfo;
            stSecondInfo.bIsWrapperMode = true; % second time is called with WrapperMode active!
            stFoundInfo2 = astAddInfo(2);
            i_assertionHelperMethod(stSecondInfo, stFoundInfo2);
            
        case 'ecahook_pre_analysis'
            SLTU_ASSERT_TRUE(nCalls == 1, 'Hook "%s" expected to be called once in this workflow.', sHookName);
            stFoundInfo = astAddInfo(1);
            stExpPreInfo = stDefaultInfo;
            stExpPreInfo.sWrappedAutosarModel = ''; % pre-analysis does not get any info about Wrapper-attributes
            i_assertionHelperMethod(stExpPreInfo, stFoundInfo);
            
        case 'ecahook_param_blacklist'
            SLTU_ASSERT_TRUE(nCalls == 2, 'Hook "%s" expected to be called twice in this workflow.', sHookName);
            stFoundInfo1 = astAddInfo(1);
            [stAutosarMetaInfo1, stFoundInfo1] = i_splitStruct(stFoundInfo1, 'stAutosarMetaInfo', 'ecahook_param_blacklist');
            i_assertionHelperMethod(stDefaultInfo, stFoundInfo1);

            SLTU_ASSERT_FALSE(isempty(stAutosarMetaInfo1), 'Expecting non-empty AUTOSAR meta info for first call.');
            
            stSecondInfo = stDefaultInfo;
            stSecondInfo.bIsWrapperMode = true; % second time is called with WrapperMode active!
            stFoundInfo2 = astAddInfo(2);
            [stAutosarMetaInfo2, stFoundInfo2] = i_splitStruct(stFoundInfo2, 'stAutosarMetaInfo', 'ecahook_param_blacklist');
            i_assertionHelperMethod(stSecondInfo, stFoundInfo2);

            SLTU_ASSERT_TRUE(isempty(stAutosarMetaInfo2), 'Expecting empty AUTOSAR meta info.');
            
        case 'ecahook_post_analysis'
            SLTU_ASSERT_TRUE(nCalls == 1, 'Hook "%s" expected to be called once in this workflow.', sHookName);
            stFoundInfo = astAddInfo(1);
            [sAddModelinfoFile, stFoundInfo] = i_splitStruct(stFoundInfo, 'sAddModelinfoFile', 'ecahook_post_analysis');
            [sCodeModelFile, stFoundInfo] = i_splitStruct(stFoundInfo, 'sCodeModelFile', 'ecahook_post_analysis');
            [sMappingFile, stFoundInfo] = i_splitStruct(stFoundInfo, 'sMappingFile', 'ecahook_post_analysis');

            i_assertionHelperMethod(stDefaultInfo, stFoundInfo);
            
            SLTU_ASSERT_TRUE(exist(sAddModelinfoFile, 'file'));
            SLTU_ASSERT_TRUE(exist(sCodeModelFile, 'file'));
            SLTU_ASSERT_TRUE(exist(sMappingFile, 'file'));
            
        otherwise
            error('UT:ERROR', 'UT not prepared for hook: %s.', sHookName);
    end
end
end

%%
function i_assertionHelperMethod(stDefaultInfo, stFoundInfo)

SLTU_ASSERT_TRUE(strcmp(stFoundInfo.sModelName, stDefaultInfo.sModelName));
SLTU_ASSERT_TRUE(strcmp(stFoundInfo.sInitFileName, stDefaultInfo.sInitFileName));
SLTU_ASSERT_TRUE(stFoundInfo.bIsWrapperMode == stDefaultInfo.bIsWrapperMode);
SLTU_ASSERT_TRUE(strcmp(stFoundInfo.sWrappedAutosarModel, stDefaultInfo.sWrappedAutosarModel));
SLTU_ASSERT_TRUE(isequal(stFoundInfo.casReferencedModels, stDefaultInfo.casReferencedModels));

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
astAddInfos = [];

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


function ut_ar_rate_based_multi_runnable_wrapper
% Handling for rate-based models with multiple runnables.
%


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();


%% arrange
sSuiteName = 'UT_EC';
sModelName = 'ar_mrate_many';

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', sModelName]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelName, sSuiteName, sTestRoot); %#ok<ASGLU>
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% act
stResultWrapper = ep_ec_model_wrapper_create( ...
    'ModelFile',    sModelFile, ...
    'InitScript',   sInitScript, ...
    'IsBatchMode',  true);


%% assert
SLTU_ASSERT_FALSE(stResultWrapper.bSuccess, ...
    'Creating wrapper for rate-based AR model with more than one runnable shall not be possible.');
end

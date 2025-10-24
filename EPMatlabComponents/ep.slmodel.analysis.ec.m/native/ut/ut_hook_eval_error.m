function ut_hook_eval_error
% Testing the hook calls functionality on low level. TODO: Not clear what this test is testing?
%


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('datastore', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

% hooks
sHooksResultDir = fullfile(sTestRoot, 'hookResults');
mkdir(sHooksResultDir);

sMockFile = fullfile(sTestRoot, 'ecahook_ignore_code.m');
sObserverFile = fullfile(sHooksResultDir, 'ecahook_ignore_code_result.mat');
ut_helper_hook_mock(sMockFile, sObserverFile, {'bOk = false;'}, {'error(''UT:MOCK'', ''Fake error!'');'});


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
oMat = matfile(sObserverFile);
SLTU_ASSERT_TRUE(~oMat.bOk, 'The evaluation of ''ecahook_ignore_code'' hook should produce an error!');
end

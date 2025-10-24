function ut_data_stores_ReadWrite_02
% Check support for Data Stores.
%

%%
if verLessThan('matlab', '9.3')
    MU_MESSAGE('SKIPPING TEST: Currently test model only available for ML2017b and higher.');
    return;
end

%% prepare test
sModelKey  = 'data_stores_09';
sSuiteName = 'UT_SL';
sTestDataDir = fullfile(ut_testdata_dir_get(), [sSuiteName, '_data_stores_ReadWrite_02']);

sltu_cleanup();
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot);

sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

stOverrides.DSReadWriteObservable=true;

%% act
stResult = ut_ep_sl_model_analyze(xEnv, sModelFile, sInitScript, sResultDir, stOverrides);


%% assert
sExpectedSlArch = fullfile(sTestDataDir, 'slArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedSlConstr = fullfile(sTestDataDir, 'slConstr.xml');
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedSlConstr, stResult.sSlConstr);

sExpectedMessages = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);
end

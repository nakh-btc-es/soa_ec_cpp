function ut_data_type_int64
% Check handling of data type int64.
%

%%
if verLessThan('matlab', '9.6')
    MU_MESSAGE('SKIPPING TEST: Data type int64 only available since ML2019a.');
    return;
end
if ~verLessThan('matlab', '9.8')
    MU_MESSAGE('SKIPPING TEST: Model only suited for ML lower ML2020a.');
    return;
end


%% prepare test
sModelKey  = 'DataTypeInt64';
sSuiteName = 'SL';
sTestDataDir = fullfile(ut_testdata_dir_get(), [sSuiteName, '_', sModelKey]);

sltu_cleanup();
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot);

sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ep_sl_model_analyze(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sExpectedSlArch = fullfile(sTestDataDir, 'slArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedSlConstr = fullfile(sTestDataDir, 'slConstr.xml');
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedSlConstr, stResult.sSlConstr);

sExpectedMessages = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);
end




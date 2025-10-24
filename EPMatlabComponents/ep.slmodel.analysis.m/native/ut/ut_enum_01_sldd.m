function ut_enum_01_sldd


%%
if verLessThan('matlab', '9.1')
    MU_MESSAGE('SKIPPING TEST: Avoiding side-effects between EnumClasses and SL-DD for ML version < ML2016b.');
    return;
end


%% prepare test
sModelKey  = 'enum_01_sldd';
sSuiteName = 'UT_SL';
sTestDataDir = fullfile(ut_testdata_dir_get(), [sSuiteName, '_', sModelKey]);

% note: Enum & SLDD is both used --> clear classes is required!
sltu_cleanup('ClearClasses', true);
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot);

sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

% note: Enum & SLDD is both used --> clear classes is required!
xOnCleanupClearClasses = onCleanup(@() sltu_cleanup('ClearClasses', true));
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv, xOnCleanupClearClasses}));


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




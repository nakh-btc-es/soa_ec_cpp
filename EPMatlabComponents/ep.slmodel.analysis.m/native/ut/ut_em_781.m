function ut_em_781
%   Checking fixed point handling.
%


%%
if ~SLTU_ASSUME_FXP_TOOLBOX
    return;
end


%% prepare test
sModelKey  = 'em_781';
sSuiteName = 'UT_SL';
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
bIsLowerML2017b = verLessThan('matlab', '9.3');
if bIsLowerML2017b
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2015a', 'slArch.xml');
else
    bIsLowerML2018a = verLessThan('matlab', '9.4');
    if bIsLowerML2018a
        sExpectedSlArch = fullfile(sTestDataDir, 'ml2017b', 'slArch.xml');
    else
        sExpectedSlArch = fullfile(sTestDataDir, 'ml2018a', 'slArch.xml');
    end
end
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedSlConstr = fullfile(sTestDataDir, 'slConstr.xml');
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedSlConstr, stResult.sSlConstr);

sExpectedMessages = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);
end




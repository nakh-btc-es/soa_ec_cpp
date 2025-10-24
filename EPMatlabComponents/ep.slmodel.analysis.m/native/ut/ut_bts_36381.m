function ut_bts_36381
%   Checking fixes for BTS/36381:
%
%   BTS/36381:
%     Model reference causes Profile creation fail
%
%


%% prepare test
sEnc       = 'Shift_JIS';
sModelKey  = 'bug_36381';
sSuiteName = 'UT_SL';
sTestDataDir = fullfile(ut_testdata_dir_get(), [sSuiteName, '_', sModelKey]);

sltu_cleanup();
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot, sEnc);

sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ep_sl_model_analyze(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
bIsLowerML2021a = verLessThan('matlab', '9.10');
if bIsLowerML2021a
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2015a', 'slArch.xml');
elseif verLessThan('matlab', '9.12')
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2021a', 'slArch.xml');
else
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2022a', 'slArch.xml');
end

SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedSlConstr = fullfile(sTestDataDir, 'slConstr.xml');
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedSlConstr, stResult.sSlConstr);

sExpectedMessages = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);
end




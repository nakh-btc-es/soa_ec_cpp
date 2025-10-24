function ut_variant_subsystems
% Check support for variant subsystems.
%

%% prepare test
sModelKey  = 'SimulinkVariantSubsystems';
sSuiteName = 'SL';
sTestDataDir = fullfile(ut_testdata_dir_get(), [sSuiteName, '_', sModelKey]);

sltu_cleanup();
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot);

sModelFile    = stTestData.sSlModelFile;
sInitScript   = stTestData.sSlInitScriptFile;
sAddModelInfo = stTestData.sSlAddModelInfoFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stAddOpt = struct( ...
    'AddModelInfoFile', sAddModelInfo);
stResult = ut_ep_sl_model_analyze(xEnv, sModelFile, sInitScript, sResultDir, stAddOpt);


%% assert
bIsLowerML2019a = verLessThan('matlab', '9.6');
if bIsLowerML2019a
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2015a', 'slArch.xml');
elseif verLessThan('matlab', '23.2')
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2019a', 'slArch.xml');
else
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2023b', 'slArch.xml');
end
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedSlConstr = fullfile(sTestDataDir, 'slConstr.xml');
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedSlConstr, stResult.sSlConstr);

sExpectedMessages = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);
end

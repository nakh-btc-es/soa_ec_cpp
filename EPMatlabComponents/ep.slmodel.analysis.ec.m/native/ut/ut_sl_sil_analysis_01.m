function ut_sl_sil_analysis_01
% Testing the functionality: SL SIL Diagnostics run for models.
%


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('datastore', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ec_model_analyse_sl_sil(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), 'datastore_sl_sil');

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

ut_ec_assert_valid_message_file(stResult.sMessages, ...
    {'EP:SLC:INFO', 'EP:SLC:WARNING', 'ATGCV:MOD_ANA:DS_USAGE_READWRITE'});
end

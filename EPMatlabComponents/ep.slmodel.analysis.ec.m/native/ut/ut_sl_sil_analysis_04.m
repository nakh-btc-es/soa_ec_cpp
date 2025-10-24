function ut_sl_sil_analysis_04
% Simple generic check for EC.
%


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = ...
    sltu_prepare_ats_env('wrapper_exportfunc_slsil', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ec_model_analyse_sl_sil(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), 'wrapper_exportfunc_slsil');

if verLessThan('matlab', '9.5') % lower ML2018b
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2017b', 'SlArch.xml');
else
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2018b', 'SlArch.xml');
end
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

ut_ec_assert_valid_message_file(stResult.sMessages, { ...
    'EP:SLC:INFO', ...
    'ATGCV:MOD_ANA:LIMITATION_UNSUPPORTED_TYPE_INTERFACE'});
end


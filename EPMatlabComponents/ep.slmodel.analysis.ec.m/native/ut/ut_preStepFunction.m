function ut_preStepFunction
% Simple generic check for EC.


%%
if ~verLessThan('matlab', '9.6')
    MU_MESSAGE('TEST SKIPPED: Model only suited for Matlab versions lower-equal ML2018b.');
    return;
end

%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestDataDir = fullfile(ut_get_testdata_dir(), 'preStepFunction');

sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('PreStepFunction', 'embeddedcoder', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

ut_ec_assert_valid_message_file(stResult.sMessages, {'EP:SLC:INFO', 'EP:SLC:WARNING'});
end


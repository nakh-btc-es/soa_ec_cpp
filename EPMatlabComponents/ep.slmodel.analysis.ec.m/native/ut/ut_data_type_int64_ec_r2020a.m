function ut_data_type_int64_ec_r2020a
% check int64 limitation
%

if verLessThan('matlab', '9.8')
    MU_MESSAGE('Skipping the test, because this version of the model is only available for ML2020a due to a stateflow bug in R2020a. ');
    return;
end

%% prepare test
sltu_cleanup();

% as long as not officially supported set the 64bit support manually for the test
onCleanupResetToggle = sltu_feature_toggle_set('ALLOW_64_BIT', true); %#ok<NASGU> onCleanup object 

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = ...
    sltu_prepare_ats_env('DataTypeInt64_R2020', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), 'DataTypeInt64');

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch2020.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

if verLessThan('matlab', '24.1')
    sExpectedCodeModelFile = fullfile(sTestDataDir,'/ml2020a', 'CodeModel.xml');
else
    sExpectedCodeModelFile = fullfile(sTestDataDir,'/ml2024a', 'CodeModel.xml');
end

SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedMsgFile = fullfile(sTestDataDir, 'Msg2020.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMsgFile, stResult.sMessages);
end
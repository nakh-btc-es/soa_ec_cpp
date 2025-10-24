function ut_data_type_int64_ec
% check int64 limitation
%

if verLessThan('matlab', '9.6')
    MU_MESSAGE('Skipping the test, because built-in type int64 in only available since ML2019a.');
    return;
end
if ~verLessThan('matlab', '9.8')
    MU_MESSAGE('Skipping the test, because this version of the model should not be tested with ML2020a and higher due to a Stateflow bug.');
    return;
end

%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = ...
    sltu_prepare_ats_env('DataTypeInt64', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), 'DataTypeInt64');

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedMsgFile = fullfile(sTestDataDir, 'Msg.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMsgFile, stResult.sMessages);
end
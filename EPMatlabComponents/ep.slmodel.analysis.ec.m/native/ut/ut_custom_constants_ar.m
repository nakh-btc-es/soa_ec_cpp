function ut_custom_constants_ar
% Test to check constants support for EC with customized list of storage
% classes to consider
%

%%
if verLessThan('matlab', '9.5')
    MU_MESSAGE('TEST SKIPPED: Test only suited for Matlab versions greater than/equal to ML2018b.');
    return;
end

%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('AR_CustomConstants', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), 'AR_CustomConstants');

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedConstantsFile = fullfile(sTestDataDir, 'ecConstants.xml');
SLTU_ASSERT_VALID_CONSTANTS(stResult.sConstantsFile);
SLTU_ASSERT_EQUAL_CONSTANTS_FILE(sExpectedConstantsFile, stResult.sConstantsFile);

sExpectedMessages = fullfile(sTestDataDir, 'Messages.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);

%%change config
copyfile(fullfile(sTestDataDir, 'ecacfg_analysis_autosar.m'), fileparts(sResultDir));

%% act anew
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);

%% check updated list of constants
sExpectedConstantsFile = fullfile(sTestDataDir, 'ecConstants2.xml');
SLTU_ASSERT_VALID_CONSTANTS(stResult.sConstantsFile);
SLTU_ASSERT_EQUAL_CONSTANTS_FILE(sExpectedConstantsFile, stResult.sConstantsFile);


end


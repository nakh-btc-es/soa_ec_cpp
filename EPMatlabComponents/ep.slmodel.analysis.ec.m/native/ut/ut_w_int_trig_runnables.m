function ut_w_int_trig_runnables
% Test to cover AR wrapper creation for models containing internally triggered runnables
%

%%
if verLessThan('matlab', '9.12')
    MU_MESSAGE('TEST SKIPPED: Internally triggered runnables were first introduced in ML2022a. Skipping the test.');
    return;
end

%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'ar_internal_runnable';
bWithWrapperCreation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCreation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), sModelName);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedMessages = fullfile(sTestDataDir, 'Messages.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);
end


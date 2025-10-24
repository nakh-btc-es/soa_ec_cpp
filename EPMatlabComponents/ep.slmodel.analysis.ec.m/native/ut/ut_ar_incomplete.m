function ut_ar_incomplete
% Checks wrapper creation for AR models with an "incomplete" interface (EP-3341).
%


%%
if verLessThan('matlab', '9.9')
    MU_MESSAGE('TEST SKIPPED: Model is using AR PortParams and is not suited for ML lower than ML2020b.');
    return;
end

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'ar_incomplete';
bWithWrapperCreation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCreation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), [sSuiteName, '_', sModelName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
% for full stubbing check, check also if compilable
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedMessagesFile = fullfile(sTestDataDir, 'errors.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages);
end

function ut_w_multi_instance_epdev_75159
% UT to check wrapper creation for multi-instance use-case
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end

%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'ar_multi_instance_epdev_75159';
bWithWrapperCreation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCreation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['W_', sModelName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);
end


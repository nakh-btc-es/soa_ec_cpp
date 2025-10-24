function ut_w_client_multi_instance
% UT to check wrapper creation for multi-instance use-case
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end

%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'EC';
sModelName = 'AR_MultiInstanceClient';
bWithWrapperCreation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCreation);


%% assert
if verLessThan('matlab', '9.6')
    sVerPath = 'ml2018b';
elseif verLessThan('matlab', '9.9')
    sVerPath = 'ml2019a';
else
    sVerPath = 'ml2020b';
end
sTestDataDir = fullfile(ut_get_testdata_dir(), ['W_', sModelName], sVerPath);

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


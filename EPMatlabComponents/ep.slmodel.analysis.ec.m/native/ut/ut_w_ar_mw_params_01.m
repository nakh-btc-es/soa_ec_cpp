function ut_w_ar_mw_params_01
% Generic check for EC including the creation of a wrapper for the AUTOSAR model.
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'ar_mw_params_01';
bWithWrapperCeation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCeation);


%% assert
if verLessThan('matlab', '9.6')
    sVersionDir = 'ml2018b';
elseif verLessThan('matlab', '9.9')
    sVersionDir = 'ml2019a';
else
    sVersionDir = 'ml2020b';
end
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_w_', sModelName], sVersionDir);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

% for full stubbing check, check also if compilable
sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedMessages = fullfile(sTestDataDir, 'Messages.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);
end

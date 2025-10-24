function ut_w_boolean_settings
% This tests checks that all relevant settings are copied into the wrapper mdl.
% When there is a mismatch between the wrapper- and ar-model settings, i.e. boolean identifiers,
% it can lead to a compile error in EP.
% This behavior was first observed in Bug EP-2979.

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end

if verLessThan('matlab', '9.6')
    MU_MESSAGE('TEST SKIPPED: Model only suited for Matlab versions equal and higher than ML2019a.');
    return;
end

%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'ar_boolean_id_settings';
bWithWrapperCeation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCeation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelName]);

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

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, {'EP:SLC:INFO'});
end
function ut_w_ar_cs_arrays
% Checks wrapper creation for AR models with CS communication with diffent types of arrays and matrices
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'ar_bus_array_server';
bWithWrapperCreation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCreation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelName]);

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

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, {'EP:SLC:INFO', 'EP:SLC:WARNING'});
end

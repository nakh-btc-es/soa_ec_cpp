function ut_w_small_ar_cs_aob
% Checks wrapper creation for AR models with CS communication with array of busses (aob)
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'small_ar_cs_aobs';
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

if verLessThan('matlab', '9.4')
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2017b', 'CodeModel.xml');
else
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2019b', 'CodeModel.xml');
end

% for full stubbing check, check also if compilable
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, {'EP:SLC:INFO', 'EP:SLC:WARNING'});
end

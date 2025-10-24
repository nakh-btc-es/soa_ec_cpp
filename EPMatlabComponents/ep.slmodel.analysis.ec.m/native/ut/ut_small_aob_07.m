function ut_small_aob_07
% Handling of Array-of-Buses and different StorageClasses.
%

%% arrange and act
sModelUT = 'small_aob_07';
stResult = ut_ec_ut_model_analyse(sModelUT);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelUT]);

if verLessThan('matlab', '9.9')
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2018b', 'SlArch.xml');
else
    sExpectedSlArch = fullfile(sTestDataDir, 'ml2020b', 'SlArch.xml');
end
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

% for full stubbing check, check also if compilable
bCheckCompilable = true;
sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedMessagesFile = fullfile(sTestDataDir, 'errors.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages);
end

function ut_epdev_69288
% Checking stubbing for Get/Set storage class.
%
% EPDEV-69288: Wrong stubbing for interfaces with StorageClass GetSet where either Get or Set function attribute is empty.
%


%% arrange and act
sModelUT = 'get_set_funcs'; 
stResult = ut_ec_ut_model_analyse(sModelUT);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelUT]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

% for full stubbing check, check also if compilable
bCheckCompilable = true;
bIncludeLibraryFiles = true;
sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel, bIncludeLibraryFiles);

% from ML2020b on the message for the output signal "out_X" is changing to using the Alias name "myX" instead of "out_X"
if verLessThan('matlab', '9.9')
    sExpectedMessagesFile = fullfile(sTestDataDir, 'ml2018b', 'errors.xml');
else
    sExpectedMessagesFile = fullfile(sTestDataDir, 'ml2020b', 'errors.xml');
end
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages, {'EP:SLC:WARNING'});
end


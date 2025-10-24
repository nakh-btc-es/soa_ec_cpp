function ut_many_stubs_bus_preserve_dim()
% Checking stubbing for bus signals.
%
if verLessThan('matlab', '9.10')
    MU_MESSAGE('Skipping the test, because EC could preserve of the dimentions of bus elements only in ML2021a and higher.');
    return;
end

%% arrange and act
sModelUT = 'many_stubs_bus_preserve_dim'; 
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

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, {'EP:SLC:INFO','EP:SLC:WARNING'});
end


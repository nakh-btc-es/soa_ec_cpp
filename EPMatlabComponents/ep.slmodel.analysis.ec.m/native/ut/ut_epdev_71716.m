function ut_epdev_71716
% Checking if alias/identifier names of PIM signals are found correctly.
%
% EPDEV-71716: Automatic mapping of autosar PerInstanceMemory is not working when an identifier/alias name is defined.
%


%%
if verLessThan('matlab', '9.10')
    MU_MESSAGE('Skipping the test, because this UT is only relevant for ML2021a and above!');
    return;
end

%% arrange and act
sModelUT = 'perinstancememory_alias'; 
stResult = ut_ec_ut_model_analyse(sModelUT);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelUT]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

casIgnoreMsg = {'EP:SLC:WARNING'};
sExpectedMessagesFile = fullfile(sTestDataDir, 'errors.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages, casIgnoreMsg);
end


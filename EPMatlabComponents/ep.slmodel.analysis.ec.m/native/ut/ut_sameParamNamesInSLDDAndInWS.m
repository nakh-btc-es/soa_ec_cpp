function ut_sameParamNamesInSLDDAndInWS
% Simple generic check for EC.
%


%% Testing new features introduced in ML2019a
if verLessThan('matlab', '9.6')
    MU_MESSAGE('TEST SKIPPED: Model only suited for Matlab versions equal and higher than ML2019a.');
    return;
end

%% act
stResult = ut_ec_ats_model_analyse('SameParamNamesInSLDDAndInWS');


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), 'SameParamNamesInSLDDAndInWS');

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

ut_ec_assert_valid_message_file(stResult.sMessages, {'EP:SLC:INFO', 'EP:SLC:WARNING'});
end


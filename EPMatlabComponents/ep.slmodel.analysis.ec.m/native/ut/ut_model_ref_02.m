function ut_model_ref_02
% Bugfix for EPDEV-54328: Locals are ignored when being located inside masked subsystems with mask-parameters.
%

%% arrange and act
sModelUT = 'model_ref_02';
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

sExpectedSlConstr = fullfile(sTestDataDir, 'slConstr.xml');
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedSlConstr, stResult.sSlConstr);

if verLessThan('matlab' , '9.9')
    sExpectedMessagesFile = fullfile(sTestDataDir, 'errors.xml');
else
    sExpectedMessagesFile = fullfile(sTestDataDir, 'errors_2020b.xml');
end
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages);
end

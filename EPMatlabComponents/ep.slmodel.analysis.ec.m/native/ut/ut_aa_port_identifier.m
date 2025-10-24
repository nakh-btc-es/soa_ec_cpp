function ut_aa_port_identifier
% Simple AA model analysis test.
%

%% arrange and act
if verLessThan('matlab', '23.2') %#ok<VERLESSMATLAB>
    MU_MESSAGE('TEST SKIPPED: UT is only relevant for ML2023b and above!');
    return;
end

if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end

stMLInfo = matlabRelease;
bIsML2023bUpdate6 = (strcmp(stMLInfo.Release, 'R2023b') &&  stMLInfo.Update ==6);

sModel   = 'aa_port_identifier';
sSuite   = 'UT_EC';
stResult = ut_ec_pool_model_analyse(sSuite, sModel);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), [sSuite, '_', sModel]);
if bIsML2023bUpdate6   
    sTestDataDir = fullfile(ut_get_testdata_dir(), [sSuite, '_', sModel], 'ml2023b');
end

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
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

sExpectedAaComponent = fullfile(sTestDataDir, 'stubCodeAA.xml');
SLTU_ASSERT_VALID_EC_AA_COMPONENT(stResult.sStubAA);
SLTU_ASSERT_EQUAL_EC_AA_COMPONENT(sExpectedAaComponent, stResult.sStubAA);

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, { ...
    'EP:SLC:INFO'});
end

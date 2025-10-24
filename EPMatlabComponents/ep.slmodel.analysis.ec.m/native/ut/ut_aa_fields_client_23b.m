function ut_aa_fields_client_23b
% Generic check for EC including the creation of a wrapper for the AUTOSAR Adaptive model.
%


%%
stMLInfo = matlabRelease;
bIsML2023bUpdate6 = (strcmp(stMLInfo.Release, 'R2023b') &&  stMLInfo.Update ==6);
if ~bIsML2023bUpdate6
    MU_MESSAGE('TEST SKIPPED: UT is only relevant for ML2023b!');
    return;
end

if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end

%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'aa_fields_client_wrapper_ecaa243';
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), [sSuiteName, '_', sModelName]);

sExpectedSlArch = fullfile(sTestDataDir, 'slArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedAaComponent = fullfile(sTestDataDir, 'stubCodeAA.xml');
SLTU_ASSERT_VALID_EC_AA_COMPONENT(stResult.sStubAA);
SLTU_ASSERT_EQUAL_EC_AA_COMPONENT(sExpectedAaComponent, stResult.sStubAA);
end

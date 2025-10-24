function ut_aa_stellantis_heatedseats_23b
% Generic check for EC including the creation of a wrapper for the AUTOSAR Adaptive model,
% checks methods with bus/structure arguments,
% checks for namespace typedefs headers.

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
sSuiteName = 'EC';
sModelName = 'AA_Stellantis_HeatedSeats_Wrapper_ECAA243';
bWithWrapperCeation = false;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCeation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), [sSuiteName, '_', sModelName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedAaComponent = fullfile(sTestDataDir, 'stubCodeAA.xml');
SLTU_ASSERT_VALID_EC_AA_COMPONENT(stResult.sStubAA);
SLTU_ASSERT_EQUAL_EC_AA_COMPONENT(sExpectedAaComponent, stResult.sStubAA);

sExpectedMessages = fullfile(sTestDataDir, 'Messages.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);

sTypedefDir = fullfile(strrep(stResult.stModel.sModelFile, '.slx', '_ert_rtw'), 'btc_typedefs');
dExpectedHeaders = 142;
i_ASSERT_COMPLETE_TYPEDEF_HEADERS(sTypedefDir, dExpectedHeaders);
end


%%
function i_ASSERT_COMPLETE_TYPEDEF_HEADERS(sPath, dExpectedHeaders)
if ~exist(sPath, 'dir')
    MU_FAIL('Expected directory "btc_typedefs" not found.')
end

astContent = dir(fullfile(sPath, '*.h'));
if ~(numel(astContent) == dExpectedHeaders)
    MU_FAIL('The btc_typedef directory does not contain the expected number of headers.')
end

casTypdefHeaders = {astContent.name};
for i = 1:numel(casTypdefHeaders)
    if (~startsWith(casTypdefHeaders{i}, 'impl_type_'))
        MU_FAIL('Wrong file found in btc_typedef directory.')
    end
end
end


function ut_ep_2511
% Checking AUTOSAR RTE stubbing: Bugfix --> EP-2511: Explicit Receiver with ErrorStatus is handled wrongly
%


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% arrange
sSuiteName = 'EC';
sModelName = 'ar_explicit_implicit_sr'; 


%% act
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), [sSuiteName, '_', sModelName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

% for full stubbing check, check also if compilable
if verLessThan('matlab', '9.6')
    MU_MESSAGE('Skipping code compile check: EC below ML2019a is producing inconsistent RTE header for IStatus.');
    bCheckCompilable = false;
else
    bCheckCompilable = true;
end
sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

sExpectedMessagesFile = fullfile(sTestDataDir, 'errors.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages);
end


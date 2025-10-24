function ut_ar_model_qsr
% Checking newly supported SenderReceiver access modes: QueuedExplicitReceiver/-Sender
%



%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%%
if verLessThan('matlab', '9.7')
    MU_MESSAGE('TEST SKIPPED: Model for ML2019b and higher. Reason: Message signals in AUTOSAR context.');
    return;
end


%% arrange
sSuiteName = 'EC';
sModelName = 'ar_model_qsr';
bWithWrapperCeation = false; % note: Wrapper creation does only yield correct result for ML2021a and higher.


%% act
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCeation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), [sSuiteName, '_', sModelName]);

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

sExpectedMessagesFile = fullfile(sTestDataDir, 'errors.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages);
end


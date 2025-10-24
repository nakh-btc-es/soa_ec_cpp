function ut_reuse_code_without_code
% UT for the reuse existing code feature in EC context.
% Simple test to see if the model analysis runs into an error when the ReuseExistingCode setting is used,
% but no code is present.

%% arrange
sltu_cleanup();
sModelName = 'reuse_code_01';
sSuiteName = 'UT_EC';

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', sModelName]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelName, sSuiteName, sTestRoot); %#ok onCleanup object
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% load the model to be analysed
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false); %#ok<NASGU> onCleanup object


%% act
stOverrideArgs = struct('ReuseExistingCode', 'yes');
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs);


%% assert
if ~stResult.bSuccess
    oEx = stResult.oException;
    MU_ASSERT_EQUAL(oEx.identifier, 'EP:CODE_GEN:EC_MISSING_EXISTING_CODE', ...
        ['Wrong exception has been thrown: ' oEx.identifier]);

    sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelName]);
    sExpectedMessagesFile = fullfile(sTestDataDir, 'MessagesForMissingCode.xml');
    SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages);
else
    MU_FAIL('Expected an error thrown by the analysis about missing code.')
end
end

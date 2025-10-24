function ut_variant_unsupported_mode
% Test of rejection mechanism of variant with unsupported variant control configuration mode ({'(sim)'} {'(codegen)'}).
% Checks if the error message contains all offending variant blocks responsible for the rejection.
%

if verLessThan('matlab', '9.9')
    MU_MESSAGE('Skipping the test, because this UT is only relevant for ML2020b and above ');
    return;
end

%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, ~, sResultDir, stTestData] = ...
    sltu_prepare_ats_env('variant_sim_codegen', 'UT_EC', sTestRoot); %#ok<ASGLU> onCleanup object
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% act
[stResult, oEx] = ut_ec_model_analyse(sModelFile, sInitScript, sResultDir);


%% assert
SLTU_ASSERT_FALSE(isempty(oEx), 'Missing expected exception for non-supported kind of model.');

sTestDataDir = ep_core_canonical_path(fullfile(ut_testdata_dir_get(), 'UT_EC_variant_sim_codegen'));
sExpectedMessageFile = fullfile(sTestDataDir, 'errors.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, stResult.sMessageFile);
end
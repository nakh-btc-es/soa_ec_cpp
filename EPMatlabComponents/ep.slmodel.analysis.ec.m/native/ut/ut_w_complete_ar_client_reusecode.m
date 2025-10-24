function ut_w_complete_ar_client_reusecode
% Simple generic check for EC.
% Adapted the UT to simultaneously test ReuseExistingCode feature (EPDEV-68624).
%


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();

sAtsName = 'complete_ar_client';

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sAtsName, 'EC', sTestRoot);

% stOrigModel = stTestData.astSubModels(1);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

% (1)  Setting Simulink diagnostic "underspecified datatypes" to error to test fix EP-2169.
load_system(sModelFile)
set_param(bdroot,'UnderSpecifiedDataTypeMsg', 'error');
save_system(sModelFile)

%% act
% (2) create wrapper
stResultWrapper = ep_ec_model_wrapper_create( ...
    'ModelFile',    sModelFile, ...
    'InitScript',   sInitScript);
if ~stResultWrapper.bSuccess
    MU_FAIL_FATAL(sprintf('Creating wrapper failed: %s', strjoin(stResultWrapper.casErrorMessages, '; ')));
end
evalin('base', 'clear all;')

sModelFile = stResultWrapper.sWrapperModel;
sInitScript = stResultWrapper.sWrapperInitScript;

% (3) load model and generate code like the user
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

[~, sWrapperModelName, ~] = fileparts(sModelFile);
ep_ec_model_wrapper_codegen(sWrapperModelName);

% (4) execute analysis with reuse code option
stOverrideArgs = struct('ReuseExistingCode', 'yes');
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['W_', sAtsName]);

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

ut_ec_assert_valid_message_file(stResult.sMessages, { ...
    'EP:SLC:INFO', ...
    'EP:SLC:WARNING'});
end

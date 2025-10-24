function ut_epdev_66758
% filtering from mapping.xml and CodeModel.xml the invalid subsystems according to the selected subsystems in AddModelInfo.xml


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();

sPwd = pwd;
sSuiteName = 'UT_EC';
sModelName = 'ar_array_interfaces';
sTestRoot = fullfile(sPwd, ['tmp_', sModelName]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelName, sSuiteName, sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sTestDataDir = fullfile(ut_get_testdata_dir(), 'EPDEV_66758');

% copy ecacfg_analysis_autosar to the test folder
sltu_copy_file(fullfile(sTestDataDir, 'ecacfg_analysis_autosar.m'), sTestRoot);

%% optional act: wrapper creation
stResultWrapper = ep_ec_model_wrapper_create('ModelFile', sModelFile);
if ~stResultWrapper.bSuccess
    MU_FAIL_FATAL(sprintf('Creating wrapper failed: %s', strjoin(stResultWrapper.casErrorMessages, '; ')));
end
evalin('base', 'clear all;')

sModelFile = stResultWrapper.sWrapperModel;
sInitScript = stResultWrapper.sWrapperInitScript;

%% load the model to be analysed
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false); %#ok<NASGU> onCleanup object
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);

%% assert : use case with stConfig.General.bExcludeScopesWithMissingIOMapping = true;
if ~verLessThan('matlab', '9.9')
    sTestDataDir = fullfile(sTestDataDir, 'ForMLHigherThan2020a');
end

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);


%% assert : use case with stConfig.General.bExcludeScopesWithMissingIOMapping = false;
delete(fullfile(sTestRoot, 'ecacfg_analysis_autosar.m'));
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArchFull.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'MappingFull.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModelFull.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

end

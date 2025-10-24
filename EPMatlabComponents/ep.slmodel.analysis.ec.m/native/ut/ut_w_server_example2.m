function ut_w_server_example2
% Simple generic check for EC.
%


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();

sAtsName = 'ServerExample2';

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sAtsName, 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% act
% (1) create wrapper
stResultWrapper = ep_ec_model_wrapper_create( ...
    'ModelFile',    sModelFile, ...
    'InitScript',   sInitScript);
if ~stResultWrapper.bSuccess
    MU_FAIL_FATAL(sprintf('Creating wrapper failed: %s', strjoin(stResultWrapper.casErrorMessages, '; ')));
end
evalin('base', 'clear all;')

sModelFile = stResultWrapper.sWrapperModel;
sInitScript = stResultWrapper.sWrapperInitScript;

% (2) do full analysis
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['W_', sAtsName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

if verLessThan('matlab', '9.4')
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2017b', 'CodeModel.xml');
else
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2018a', 'CodeModel.xml');
end
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

ut_ec_assert_valid_message_file(stResult.sMessages, { ...
    'EP:SLC:INFO', ...
    'EP:SLC:WARNING'});
end

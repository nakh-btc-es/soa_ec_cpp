function ut_reuse_code_userpath_relocated
% UT for the reuse existing code feature in EC context.
% Simple test to see if the model analysis runs without error when the ReuseExistingCode setting is used,
% while a user-defined path is specified in the ecacfg config and this path is not the original path but a relocated one.

%% arrange
sltu_cleanup();
sModelName = 'reuse_code_02';
sSuiteName = 'UT_EC';

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', sModelName]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelName, sSuiteName, sTestRoot); %#ok onCleanup object
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

%%
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false); %#ok<NASGU> onCleanup object

sUserPathCodegen = fullfile(pwd, 'test', 'userpath_codegen');
mkdir(sUserPathCodegen);
cd(sUserPathCodegen);
rtwbuild(gcs, 'generateCodeOnly', true);
cd('../..');
sRealUserPath = fullfile(pwd, 'test', 'userpath');
movefile(sUserPathCodegen, sRealUserPath);


%% act
stOverrideArgs = struct('ReuseExistingCode', 'yes');
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelName]);

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

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, { ...
    'EP:SLC:INFO'});
end

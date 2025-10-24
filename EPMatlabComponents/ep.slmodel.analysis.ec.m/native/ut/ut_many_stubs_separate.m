function ut_many_stubs_separate
% UT for creating the required ccode-stubs with default settings in separate stub files,
% when extra headers are specified

%% arrange
sltu_cleanup();
sModelName = 'many_stubs';
sSuiteName = 'UT_EC';

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', sModelName]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelName, sSuiteName, sTestRoot); %#ok onCleanup object
sModelFile = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

%% load the model to be analysed
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false); %#ok<NASGU> onCleanup object


%% act
% delete custom config file to have default setting (spearate file stubs, when specified in header argument)
sCfgFile = fullfile(sTestRoot, 'ecacfg_analysis.m');
delete(sCfgFile);
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);

casExistingHeaders = {'getSet.h', 'input.h', 'param.h'};

%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

% for full stubbing check, check also if code is compilable and that are libfiles(stubs) are present
bCheckCompilable = true;
bIncludeLibraryFiles = true;
sCodeModelPath = fullfile(sTestDataDir, 'separate');
sExpectedCodeModelFile = fullfile(sCodeModelPath, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel, bIncludeLibraryFiles);

% check that existing the header files are not additionally generated in the stubfolder
[~, sModelFileName, ~]  = fileparts(sModelFile);
for i = 1:numel(casExistingHeaders)
    sHeaderPath = fullfile(sTestRoot, [sModelFileName '_ep_stubs'], casExistingHeaders{i});
    SLTU_ASSERT_TRUE( exist(sHeaderPath, 'file') == 0)
end

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, { ...
    'EP:SLC:INFO','EP:SLC:WARNING'});
end

function ut_sl_import
% Testing basic functionality of the SL import.
%


%% prepare test
sModelKey = 'PowerWindowSimple';
sSuiteName = 'SL';
sTestDataDir = fullfile(ut_testdata_dir_get(), [sSuiteName, '_', sModelKey]);

sltu_cleanup();
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, ~, sResultDir, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot); %#ok<ASGLU>

sModelFile    = stTestData.sSlModelFile;
sInitScript   = stTestData.sSlInitScriptFile;
sAddModelInfo = stTestData.sSlAddModelInfoFile;

sSlArchFile   = fullfile(sResultDir, 'slArch.xml');
sMessageFile  = fullfile(sResultDir, 'error.xml');
sCompilerFile = fullfile(sResultDir, 'compiler.xml');


%% act
stResult = ep_arch_analyze_sl_model(...
    'SlModelFile',        sModelFile, ...
    'SlInitScript',       sInitScript, ...
    'AddModelInfo',       sAddModelInfo, ...
    'TestMode',           'GreyBox', ...
    'ParameterHandling',  'ExplicitParam', ...
    'SlResultFile',       sSlArchFile, ...
    'MessageFile',        sMessageFile, ...
    'FixedStepSolver',    'yes', ...
    'CompilerFile',       sCompilerFile);


%% assert
sExpectedSlArch = fullfile(sTestDataDir, 'slArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(sSlArchFile);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, sSlArchFile);

sExpectedMessages = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, sMessageFile);
end



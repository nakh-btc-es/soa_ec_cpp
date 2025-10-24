function ut_sl_pre_analyse
% Testing basic functionality of the SL pre analysis.
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
sMessageFile  = fullfile(sResultDir, 'error.xml');


%% act
stResult = ep_arch_pre_analyze_sl_model(...
    'SlModelFile',        sModelFile, ...
    'SlInitScript',       sInitScript, ...
    'ParameterHandling',  'ExplicitParam', ...
    'MessageFile',        sMessageFile);


%% assert
casExpectedParams = {'auto_down_time'  'auto_up_time'  'emergency_down_time'  'position_endstop_top'};
SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedParams, stResult.stResultParameter.casName);
end



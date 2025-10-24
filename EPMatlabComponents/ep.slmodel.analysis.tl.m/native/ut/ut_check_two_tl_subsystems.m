function ut_check_two_tl_subsystems
%

%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'two_tl_subsystems';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), [sUTSuite, '_check_', sUTModel]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));



%% =============== act --- case1: no TL subsystem path provided --> error =====================
[stResult, oEx] = ut_ep_model_check(xEnv, sModelFile, 'TlInitScript', sInitScript);    

% assert
MU_ASSERT_TRUE(~isempty(oEx), 'Expecting exception for finding more than one TL subsystem inside the model.');

sExpectedMessageFile = fullfile(sTestDataDir, 'error_multi_tl_subsystems.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, stResult.sMessageFile);


%% =============== act --- case2: wrong TL subsystem path provided --> error ====================
[stResult, oEx] = ut_ep_model_check(xEnv, sModelFile, 'TlInitScript', sInitScript, 'TlSubsystem', 'xxx');    

% assert
MU_ASSERT_TRUE(~isempty(oEx), 'Expecting exception for finding more than one TL subsystem inside the model.');

sExpectedMessageFile = fullfile(sTestDataDir, 'error_wrong_tl_subsystem_name.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, stResult.sMessageFile);


%% =============== act --- case3: first TL subsystem path provided ====================
sTlSubsystem = 'two_tl_subsys/top_A';
[stResult, oEx] = ut_ep_model_check(xEnv, sModelFile, 'TlInitScript', sInitScript, 'TlSubsystem', sTlSubsystem);    

% assert
MU_ASSERT_TRUE(isempty(oEx), 'No error expected.');
MU_ASSERT_EQUAL(sTlSubsystem, stResult.sTlSubsystem);

sExpectedMessageFile = fullfile(sTestDataDir, 'error_empty.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, stResult.sMessageFile);


%% =============== act --- case4: second TL subsystem path provided ====================
sTlSubsystem = 'two_tl_subsys/some_frame/top_B';
[stResult, oEx] = ut_ep_model_check(xEnv, sModelFile, 'TlInitScript', sInitScript, 'TlSubsystem', sTlSubsystem);    

% assert
MU_ASSERT_TRUE(isempty(oEx), 'No error expected.');
MU_ASSERT_EQUAL(sTlSubsystem, stResult.sTlSubsystem);

sExpectedMessageFile = fullfile(sTestDataDir, 'error_empty.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, stResult.sMessageFile);
end


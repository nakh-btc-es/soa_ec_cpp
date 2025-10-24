function ut_closed_loop_04
%

%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'closed_loop_04';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), [sUTSuite, '_', sUTModel]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sTlModel',        sModel, ...
    'bAddEnvironment', true, ...
    'xEnv',            xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
[sMessageFile, oEx] = ut_ep_model_analyse(stOpt);


%% assert
MU_ASSERT_TRUE(~isempty(oEx), 'Expecting exception for invalid closed loop model.');

sExpectedMessageFile = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end


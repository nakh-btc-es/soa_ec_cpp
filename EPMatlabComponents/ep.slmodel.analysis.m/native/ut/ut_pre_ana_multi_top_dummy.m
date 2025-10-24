function ut_pre_ana_multi_top_dummy
% Check pre-analysis workflow.
%

%% prepare test
sModelKey  = 'MultiTopDummy';
sSuiteName = 'SL';

sltu_cleanup();
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, ~, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot);

sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
astSubs = ep_model_subsystems_get( ...
    'Environment',  xEnv, ...
    'ModelContext', sModel);

%% assert
casExpectedSubs = { ...
    'multi_top', ...
    'multi_top/top_A', ...
    'multi_top/top_B'};
casFoundSubs = {astSubs(:).sPath};
SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedSubs, casFoundSubs);
end






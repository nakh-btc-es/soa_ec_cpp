function ut_pre_ana_single_top_dummy_ec
% Test the handling of one toplevel subsystems and root IOs and fcn-call Inports on root level.
% --> In this case the model level shall *not* be avaiable as SUT scope.
%

%%
if verLessThan('matlab', '9.1')
    MU_MESSAGE('TEST SKIPPED: EmbeddedCoder model is supported only for R2016b and higher.');
    return;
end


%% prepare test
sModelKey  = 'SingleTopDummy_EC';
sSuiteName = 'EC';

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
    'single_top/top_A'};
casFoundSubs = {astSubs(:).sPath};
SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedSubs, casFoundSubs);
end






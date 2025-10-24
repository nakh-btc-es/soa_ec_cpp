function ut_pre_ana_param_sldd
% Check pre-analysis workflow.
%

%% prepare test
sModelKey  = 'SimulinkParameterSLDD';
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


%% act I
stResult = ep_model_params_get(...
    'Environment',  xEnv, ...
    'ModelContext', sModel);

%% assert I
casExpectedFound = {'paramA', 'paramB', 'paramC', 'paramD'};
casFound = {stResult.astParams(:).sName};
SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedFound, casFound);

casExpectedMissing = {};
casMissing = stResult.casMissing;
SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedMissing, casMissing);


%% act II
evalin('base', 'paramX = Simulink.Parameter;'); % add an *unused* parameter
stResult = ep_model_params_get(...
    'Environment',  xEnv, ...
    'ModelContext', sModel, ...
    'Parameters', {'paramB', 'paramD', 'paramX'});

%% assert II
casExpectedFound = {'paramB', 'paramD'};
casFound = {stResult.astParams(:).sName};
SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedFound, casFound);

casExpectedMissing = {'paramX'};
casMissing = stResult.casMissing;
SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedMissing, casMissing);
end




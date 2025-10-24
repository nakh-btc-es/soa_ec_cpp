function ut_sf_state_param_01
% Check handling of SF parameters (EPDEV-42873).
%


%% prepare test
ut_cleanup();

sPwd      = pwd;
sTestRoot = fullfile(sPwd, 'sf_params_01');


sDataDir = fullfile(ut_local_testdata_dir_get(), 'sf_param_limitation');

sTlModel      = 'sf_state_param';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sTlInitScript = fullfile(sTestRoot, 'start.m');
sDdFile       = fullfile(sTestRoot, 'default.dd');
%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);
xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript, true);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',         sDdFile, ...
    'sTlModel',        sTlModel, ...
    'sTlInitScript',   sTlInitScript, ...
    'bParamSupport',   true, ...
    'bAddEnvironment', true, ... % import as Closed-Loop
    'xEnv',            xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert

% Check number of calibrations
hTlResultFile = mxx_xmltree('load', stOpt.sTlResultFile);
nCals= length(mxx_xmltree('get_nodes', hTlResultFile, '//subsystem[@subsysID="ss1"]/calibration'));
MU_ASSERT_EQUAL(nCals, 1, ...
    sprintf('Unexpected number of parameters in subsystem1. Expected %d, but found %d', 1, nCals));

nCals= length(mxx_xmltree('get_nodes', hTlResultFile, '//subsystem[@subsysID="ss2"]/calibration'));
MU_ASSERT_EQUAL(nCals, 1, ...
    sprintf('Unexpected number of parameters in subsystem2. Expected %d, but found %d', 1, nCals));

% Check number of usageContext
nUsageContext = length(mxx_xmltree('get_nodes', hTlResultFile, '//subsystem[@subsysID="ss1"]/*/usageContext'));
MU_ASSERT_EQUAL(nUsageContext, 1, ...
    sprintf('Unexpected number of usageContext in subsystem. Expected %d, but found %d', 1, nUsageContext));
mxx_xmltree('clear', hTlResultFile);
end


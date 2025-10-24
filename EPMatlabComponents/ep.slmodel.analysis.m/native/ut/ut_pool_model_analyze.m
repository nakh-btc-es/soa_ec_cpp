function stResult = ut_pool_model_analyze(sSuiteName, sModelKey, stOverrideArgs)
% Convenience function for generic UT testing the XML results of SL analysis for pool models: either ATS or UT.


%% prepare
sltu_cleanup();

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', sModelKey]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot);

sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false); %#ok<NASGU> onCleanup object


%% act
if (nargin < 3)
    stResult = ut_ep_sl_model_analyze(xEnv, sModelFile, sInitScript, sResultDir);
else
    stResult = ut_ep_sl_model_analyze(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs);
end

% note: add Env cleanup object to return struct to avoid the automatic deleting of the results folder too early
stResult.xOnCleanupDoCleanupEnv = xOnCleanupDoCleanupEnv;
end




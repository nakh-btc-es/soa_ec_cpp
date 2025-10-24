function stResult = ut_ep_sl_model_analyze(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs)
% Convenience function for generic UT testing the XML results of SL analysis for some arbitrary model.


%%
if (nargin < 5)
    stOverrideArgs = struct();
end

stArgs = ut_sl_args_get(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs);
[stModel, astModules] = ep_sl_model_info_get(xEnv, stArgs);
xEnv.exportMessages(stArgs.MessageFile);

stResult = struct( ...
    'sSlArch',           stArgs.SlArchFile, ...
    'sSlConstr',         stArgs.SlConstrFile, ...
    'sMessages',         stArgs.MessageFile, ...
    'stModel',           stModel, ...
    'astModules',        astModules);
end


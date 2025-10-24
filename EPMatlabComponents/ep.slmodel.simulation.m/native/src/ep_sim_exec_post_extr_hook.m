function ep_sim_exec_post_extr_hook(xEnv, stArgs, stExtractInfo)
% This function calls the post extraction hook.
%
% ep_sim_exec_post_extr_hook(xEnv, stArgs, stExtractInfo)
%
%  INPUT              DESCRIPTION
%   - xEnv           (object)  environment
%   - stArgs         (struct)  information about extraction model creation
%   - stExtractInfo  (struct)  information about the extraction model

% New interface for support
ep_core_eval_hook('ep_hook_post_model_extraction', ...
    'OriginalModelFile', stArgs.ModelFile, ...
    'OriginalInitScript', stArgs.InitScriptFile, ...
    'SimulationModelFile', stExtractInfo.ExtractionModel ,  ....
    'SimulationInitScript', stExtractInfo.InitScript, ...
    'SubsystemPath',  i_getScopePathFromOrgModel(stArgs), ...
    'Kind', stArgs.OriginalSimulationMode);
end


%%
function sScopePath = i_getScopePathFromOrgModel(stArgs)
hExtModel =  mxx_xmltree('load', stArgs.ExtractionModelFile);
xOnCleanupClose = onCleanup(@() mxx_xmltree('clear', hExtModel));
sScopePath = mxx_xmltree('get_attribute', mxx_xmltree('get_nodes', hExtModel, '/ExtractionModel/Scope'), 'physicalPath');
end
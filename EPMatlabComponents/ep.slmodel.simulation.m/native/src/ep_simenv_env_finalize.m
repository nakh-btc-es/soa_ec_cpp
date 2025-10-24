function ep_simenv_env_finalize(xEnv, sWarnStatus, sBatchMode, sModelName)
% Finalize of the simulation environment
% function ep_simenv_env_finalize(xEnv, sWarnStatus, sBatchMode, sModelName)
%
%   INPUT               DESCRIPTION
%     xEnv               Environment settings.
%     sWarnStatus        Warn status
%     sBatchMode         Batch mode
%     sModelName         Name of the model
%   OUTPUT              DESCRIPTION
%




%%
warning(sWarnStatus);

%% read TL message dialog
if atgcv_use_tl
    ep_simenv_tlmsg_eval(xEnv);
end

if atgcv_use_tl
    ds_error_set('BatchMode', sBatchMode);
end

% setting the SF Debug mode BTS/21566
try
    sfprivate('testing_stateflow_in_bat', 0);
catch
    xEnv.addMessage('EP:SLAPI:SF_DEBUG_MODE', 'model', sModelName);
end
end

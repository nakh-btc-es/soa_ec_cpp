function oOnCleanupRestoreChanges = ep_simenv_env_init(xEnv, sModelName, bEnableStateFlowDebug)
% Initialize the simulation environment with a suitable running mode (batch-mode).
%
% function oOnCleanupRestoreChanges = ep_simenv_env_init(xEnv, sModelName, bEnableStateFlowDebug)
%
%   INPUT               DESCRIPTION
%     xEnv                    Environment settings.
%     sModelName              Name of the model
%     bEnableStateFlowDebug   Enable Stateflow debug
%
%   OUTPUT              DESCRIPTION
%    oOnCleanupRestoreChanges  cleanup-object that restores the previous running mode and evaluates error messages


%%
% setting the SF Debug mode BTS/21566
bRestoreSF = false;
if bEnableStateFlowDebug
    try
        sfprivate('testing_stateflow_in_bat', 1);
        bRestoreSF = true;
    catch
        xEnv.addMessage('EP:SLAPI:SF_DEBUG_MODE', 'model', sModelName);
    end
end

stOrigWarningState = warning;
warning(''); %#ok this resets the warning
warning('off');

bRestoreNonBatchModeTL = false;
if atgcv_use_tl
    ds_error_clear;
    ds_msgdlg('Clear');
    sBatchMode = ds_error_get('BatchMode');
    if ~strcmp(sBatchMode, 'on')
        %ds_error_set('BatchModePrintMessage', 'off');
        ds_error_set('BatchMode', 'on');
        bRestoreNonBatchModeTL = true;
    end
end

oOnCleanupRestoreChanges = onCleanup( ...
    @() i_restoreChanges(xEnv, sModelName, bRestoreSF, stOrigWarningState, bRestoreNonBatchModeTL));
end


%%
function i_restoreChanges(xEnv, sModelName, bRestoreSF, stOrigWarningState, bRestoreNonBatchModeTL)
warning(stOrigWarningState);

if atgcv_use_tl
    ep_simenv_tlmsg_eval(xEnv);
end

if bRestoreSF
    try
        sfprivate('testing_stateflow_in_bat', 0);
    catch
        xEnv.addMessage('EP:SLAPI:SF_DEBUG_MODE', 'model', sModelName);
    end
end

if bRestoreNonBatchModeTL
    ds_error_set('BatchMode', 'off');
end
end

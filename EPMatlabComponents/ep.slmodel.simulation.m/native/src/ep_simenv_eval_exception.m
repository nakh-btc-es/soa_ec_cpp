function ep_simenv_eval_exception(xEnv, oSimException, sSimModelName, sVecName)
% Evaluate a simulation exception if non-empty.
%
% function ep_simenv_eval_exception(xEnv, oSimException)
%
%   INPUT               DESCRIPTION
%     xEnv               Environment settings.
%
%   OUTPUT              DESCRIPTION
%



%%
if isempty(oSimException)
    return;
end
if (strcmp(oSimException.identifier, 'Simulink:SL_CallbackEvalErr') && ...
        ~isempty(strfind(oSimException.message, 'TargetLink license check failed') ) )
    xEnv.throwException(...
        xEnv.addMessage('EP:SLAPI:TARGETLINK_LICENSE_FAILED', ...
        'model', sSimModelName, ...
        'text',  oSimException.message));
else
    sMsg = xEnv.getReport(oSimException);
    xEnv.addMessage('EP:SIM:FAILED', 'stimvec', sVecName, 'text', sMsg);
    xEnv.rethrowException(oSimException);
end
end

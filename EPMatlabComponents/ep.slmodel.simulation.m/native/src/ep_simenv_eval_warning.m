function ep_simenv_eval_warning(xEnv)
% Evaluate a potential last Matlab warning from the simulation if existing.
%
% function ep_simenv_eval_warning(xEnv)
%
%   INPUT               DESCRIPTION
%     xEnv               Environment settings.
%
%   OUTPUT              DESCRIPTION
%



%%  main internal functionality
[sMsg, sWarnID] = lastwarn;
if (isempty(sWarnID) || isempty(sMsg) || i_isAcceptedAndIgnoredWarning(sWarnID))
    return;
end

sMsg = sprintf('[%s] %s', sWarnID, i_replaceUnprintableChars(sMsg));
xEnv.addMessage('EP:SIM:WARNING', 'msg', sMsg);
end


%%
function bIsAccepted = i_isAcceptedAndIgnoredWarning(sWarnID)
bIsAccepted = any(strcmp(sWarnID, { ...
    'Simulink:blocks:AssertionAssert', ...
    'MATLAB:DELETE:Permission', ...
    'Simulink:Commands:FindSystemVariantsOptionRemoval'}));
end


%%
function sMsg = i_replaceUnprintableChars(sMsg)
sMsg(sMsg<32 & sMsg~=char(10) & sMsg~=char(9) & sMsg~=char(13)) = ' '; %#ok<CHARTEN>
end

function bErrorsFound = ep_simenv_tlmsg_eval(xEnv)
% Evaluate the TL messages.
%
% function bErrorsFound = ep_simenv_tlmsg_eval(xEnv)
%
%   INPUT               DESCRIPTION
%     xEnv               Environment settings.
%   OUTPUT              DESCRIPTION
%     bErrorsFound          (logical)   true when errors have been found
%


%%
bErrorsFound = false;

% Report all kink of warnings and errors
sTlBatchMode = ds_error_get('batchmode');
ds_error_set('batchmode', 'on');
oOnCleanupRestore = onCleanup(@() ds_error_set('batchmode', sTlBatchMode));

aiExcludedMsgNums = i_getExcludedMessageNumbers();
astMessages = ds_error_get('AllMessages');
casIDs = {};
casMessages = {};

for i = 1:length(astMessages)
    stMsg = astMessages(i);
    if (isstruct(stMsg) && isfield(stMsg, 'type'))
        if any(stMsg.number == aiExcludedMsgNums)
            continue;
        end       
        [sMessengerID, sMsg] = i_getMessageInfo(stMsg);
        casIDs{end+1} = sMessengerID; %#ok
        casMessages {end+1} = sMsg; %#ok
        sMsgType = stMsg.type;
        if strcmp(sMsgType, 'error') || strcmp(sMsgType, 'fatal')
            bErrorsFound = true;
        end
    end
end

ccasMsgs = cellfun(@(s) {'tlmsg', s}, casMessages, 'uni', false);
xEnv.addMessages(casIDs, ccasMsgs);

ds_msgdlg('Clear');
ds_msgdlg('Close');
end


%%
function aiExcludedMessageNums = i_getExcludedMessageNumbers()
aiExcludedMessageNums = ds_error_get('DefaultExcludedMessages');
end


%%
function [sMessengerID, sMsg] = i_getMessageInfo(stMsg)
switch lower(stMsg.type)
    case {'note', 'advice'}
        sMsgPattern    = 'N%s: %s\nNote #%s: %s:\n%s';     
        sMessengerID   = 'ATGCV:SIM:DS_MSGDLG_NOTE';
    case 'warning'
        sMsgPattern    = 'W%s: %s\nWarning #%s: %s:\n%s';     
        sMessengerID   = 'ATGCV:SIM:DS_MSGDLG_WARNING';
    case 'error'
        sMsgPattern    = 'E%s: %s\nError #%s: %s:\n%s';      
        sMessengerID   = 'ATGCV:SIM:DS_MSGDLG_ERROR';
    case 'fatal'
        sMsgPattern    = 'E%s: %s\nFatal Error #%s: %s:\n%s';       
        sMessengerID   = 'ATGCV:SIM:DS_MSGDLG_ERROR';
        
    otherwise
        return;
end
sMsg = sprintf(sMsgPattern, ...
    int2str(stMsg.number), ...
    stMsg.title, ...
    int2str(stMsg.number), ...
    stMsg.objectName, ...
    stMsg.msg);
end

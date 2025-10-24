function [astMessages, xMessagesMap] = sltu_read_messages_from_env(xEnv)

sMsgFile = [tempname(), '.xml'];
oOnCleanupRemoveFile = onCleanup(@() i_robustDelete(sMsgFile));

xEnv.exportMessages(sMsgFile);
[astMessages, xMessagesMap] = sltu_read_messages(sMsgFile);
end


%%
function i_robustDelete(sFile)
if exist(sFile, 'file')
    delete(sFile);
end
end

function SLTU_ASSERT_VALID_MESSAGE_FILE(sMessageFile, casIgnoreIds)
% Checks that the message file only contains known IDs and also only the exptected ones.
%


%%
if (nargin < 2)
    casIgnoreIds = {}; % as default do not accept any message ==> any message in message file will lead to a FAILED
end

%%
[~, oMessagesMap] = sltu_read_messages(sMessageFile);

casFoundIds = oMessagesMap.keys;
casUnexpectedIds = setdiff(casFoundIds, casIgnoreIds);

if isempty(casUnexpectedIds)
    MU_PASS(); % just for statistics reported in MUNIT report
else
    for i = 1:numel(casUnexpectedIds)
        sMsgId = casUnexpectedIds{i};
        
        astMessages = oMessagesMap(sMsgId);
        for k = 1:numel(astMessages)
            SLTU_FAIL(sprintf('Found unexpected message "%s : %s".', sMsgId, i_messageStructToString(astMessages(k))));
        end
    end
end
end


%%
function sMsg = i_messageStructToString(stMsg)
casKeys = fieldnames(stMsg.stKeyValues);
nKeys = numel(casKeys);
if (nKeys < 1)
    sMsg = '';
    return;
end

casKeyVals = cell(1, nKeys);
for i = 1:nKeys
    sKey = casKeys{i};    
    casKeyVals{i} = [sKey, '=', stMsg.stKeyValues.(sKey)];
end
sMsg = sprintf('%s, ', casKeyVals{:});
sMsg = ['{', sMsg(1:end-2), '}'];
end

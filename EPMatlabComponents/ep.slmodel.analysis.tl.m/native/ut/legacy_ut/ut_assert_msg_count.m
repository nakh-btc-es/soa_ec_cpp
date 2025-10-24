function ut_assert_msg_count(sErrFile, varargin)
caxKeyVals = varargin;
nKeyVals = numel(caxKeyVals);

%% no exptected values -> nothing to do
if (nKeyVals < 1)
    MU_MESSAGE('??? nothing to check ???');
    return;
end

%%
[astMsgs, xMsgMap] = ut_read_error_file(sErrFile);

%% mode 1: checking for *overall* number
if (nKeyVals == 1)
    nExpectedNum = caxKeyVals{1};
    nFound = numel(astMsgs);
    
    MU_ASSERT_TRUE(nFound == nExpectedNum, sprintf( ...
        'Expecting %d messages instead of %d in message file.', nExpectedNum, nFound));    
    return;
end


%% mode 2: checking for
MU_ASSERT_TRUE(mod(nKeyVals, 2) == 0, 'Inconsistent key-value pairs: [message, expected count number].');
for i = 1:2:nKeyVals
    sMsgID = caxKeyVals{i};
    nExpectedNum = caxKeyVals{i + 1};
    
    nFound = 0;
    if xMsgMap.isKey(sMsgID)
        nFound = numel(xMsgMap(sMsgID));
    end
    MU_ASSERT_TRUE(nFound == nExpectedNum, sprintf( ...
        'Expecting %d messages instead of %d with ID = "%s".', nExpectedNum, nFound, sMsgID));    
end
end

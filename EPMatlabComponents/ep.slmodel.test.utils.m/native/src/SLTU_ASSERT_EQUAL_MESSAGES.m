function SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMsgFile, sTestMsgFile, casIgnoredIds)
% Asserts that the Message XML file is equal to the expected XML file.
%

%%
if (nargin < 3)
    casIgnoredIds = {};
end

if ~exist(sExpectedMsgFile, 'file')
    if SLTU_update_testdata_mode()
        MU_MESSAGE('Creating expected version of the Message XML. No equality checks performed!');
        sltu_copyfile(sTestMsgFile, sExpectedMsgFile);
    else
        SLTU_FAIL('No expected values found. Cannot perform any checking.');
    end
else
    casExpectedMessages = i_getMessages(sExpectedMsgFile, casIgnoredIds);
    casTestMessages = i_getMessages(sTestMsgFile, casIgnoredIds);
    
    [casMissing, casUnexpected] = i_compareMessages(casExpectedMessages, casTestMessages);
    bDiffsFound = ~isempty(casMissing) || ~isempty(casUnexpected);
    if bDiffsFound && SLTU_update_testdata_mode()
        MU_MESSAGE('Updating expected values in the Message XML. No equality checks performed!');
        sltu_copyfile(sTestMsgFile, sExpectedMsgFile);
        return;
    end
    i_reportMessages(casMissing, casUnexpected);
end
end


%%
function casMessages = i_getMessages(sMessageFile, casIgnoredIds)
casMessages = {};

astMessages = sltu_read_messages(sMessageFile);
if (~isempty(astMessages) && ~isempty(casIgnoredIds))
    abIsIgnoredMessage = arrayfun(@(st) any(strcmpi(st.id, casIgnoredIds)), astMessages);
    astMessages(abIsIgnoredMessage) = [];
end
if isempty(astMessages)
    return;
end

casMessages = arrayfun(@i_getMessageAsString, astMessages, 'UniformOutput', false);
end


%%
function sMessage = i_getMessageAsString(stMessage)
casKeyVals = [fieldnames(stMessage.stKeyValues); struct2cell(stMessage.stKeyValues)];
if isempty(casKeyVals)
    sKeyVals = '';
else
    sKeyVals = sprintf('%s -> "%s", ', casKeyVals{:}); % strjoin all key-values in this pattern: <key> -> "<value>"
    sKeyVals(end-1:end) = []; % remove the last two chars
end
sMessage = sprintf('%s(%s)', stMessage.id, sKeyVals);
sMessage = i_replaceAbsFileDirPaths(sMessage);
end


%%
function sMessage = i_replaceAbsFileDirPaths(sMessage)
sLinuxFilePathPattern = '"/[^"]+/([^"]+)"'; % assuming something like: "/tmp/x/y/c.txt"
sMessage = regexprep(sMessage, sLinuxFilePathPattern, '"<parent-path>/$1"');

sWindowsFilePathPattern = '"\w:[^"]+\\([^"]+)"'; % assuming something like: "C:\x\y\c.txt"
sMessage = regexprep(sMessage, sWindowsFilePathPattern, '"<parent-path>/$1"');
end


%%
function [casMissing, casUnexpected] = i_compareMessages(casExpectedMessages, casTestMessages)
casMissing = setdiff(casExpectedMessages, casTestMessages);
casUnexpected = setdiff(casTestMessages, casExpectedMessages);
end


%%
function i_reportMessages(casMissing, casUnexpected)
if (isempty(casMissing) && isempty(casUnexpected))
    MU_PASS(); % just for statistics reported in MUNIT report
else
    for i = 1:numel(casMissing)
        SLTU_FAIL('Expected message "%s" not found.', casMissing{i});
    end
    for i = 1:numel(casUnexpected)
        SLTU_FAIL('Unexpected message "%s" found.', casUnexpected{i});
    end
end
end

function [astMessages, xMessagesMap] = ut_read_error_file(sErrFile)
if ~exist(sErrFile, 'file')
    error('UT:ERROR', 'File "%s" not found.', sErrFile);
end

hDoc = mxx_xmltree('load', sErrFile);
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

astMessages = arrayfun(@i_readMessage, mxx_xmltree('get_nodes', hDoc, '/Messages/Message'));

if (nargout > 1)
    xMessagesMap = i_evalAsMap(astMessages);
end
end


%%
function xMessagesMap = i_evalAsMap(astMessages)
xMessagesMap = containers.Map;
for i = 1:numel(astMessages)
    i_addToMap(xMessagesMap, astMessages(i).id, astMessages(i));
end
end


%%
function i_addToMap(xMap, xKey, xVal)
if xMap.isKey(xKey)
    xMap(xKey) = [xMap(xKey), xVal]; %#ok<NASGU> map object changes
else
    xMap(xKey) = xVal; %#ok<NASGU> map object changed
end
end


%%
function stMessage = i_readMessage(hMessageNode)
stMessage = struct( ...
    'id',          mxx_xmltree('get_attribute', hMessageNode, 'id'), ...
    'stKeyValues', i_readKeyValues(hMessageNode));
end


%%
function stKeyValues = i_readKeyValues(hMessageNode)
ahKeyValNodes = mxx_xmltree('get_nodes', hMessageNode, './KeyValue');

stKeyValues = struct();
for i = 1:numel(ahKeyValNodes)
    hKeyValNode = ahKeyValNodes(i);
    
    sKey = mxx_xmltree('get_attribute', hKeyValNode, 'key');
    sValue = mxx_xmltree('get_attribute', hKeyValNode, 'value');
    
    stKeyValues.(sKey) = sValue;
end
end


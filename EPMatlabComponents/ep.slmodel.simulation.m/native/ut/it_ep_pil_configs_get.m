function it_ep_pil_configs_get()
% Tests the ep_sim_* method
%


%%
sMessageFile = fullfile(pwd, 'Messages_pil_configs.xml');
if exist(sMessageFile, 'file')
    delete(sMessageFile);
end

casConfigs = ep_pil_configs_get('MessageFile', sMessageFile); %#ok
% does not matter if casConfigs is filled or not
% only that no exception is thrown

if exist(sMessageFile, 'file')
    xDocInit = mxx_xmltree('load',sMessageFile);
    axNodeList = mxx_xmltree('get_nodes', xDocInit, '//Message'); 
   
    sMessage = '';
    for i = 1:length(axNodeList)
        sId = mxx_xmltree('get_attribute', axNodeList(i), 'id');
        sMessage = sprintf('%s\n%s', sMessage, sId);
        axKeyValues = mxx_xmltree('get_nodes', axNodeList(i), 'KeyValue');
        for j = 1:length(axKeyValues)
            sKey = mxx_xmltree('get_attribute', axKeyValues(i), 'key');
            sValue = mxx_xmltree('get_attribute', axKeyValues(i), 'value');
            sMessage = sprintf('%s\n   Key: %s, Value: %s', sMessage, sKey, sValue);
        end
    end
    MU_ASSERT_TRUE(isempty(axNodeList), ['unexpected message:', sMessage]);
    mxx_xmltree('clear', xDocInit);
    
    delete(sMessageFile);
else
    MU_FAIL('Message file was not created.');
end

if exist(sMessageFile, 'file')
end
end









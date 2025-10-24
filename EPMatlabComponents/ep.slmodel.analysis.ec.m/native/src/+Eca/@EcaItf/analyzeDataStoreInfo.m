function astDataStores = analyzeDataStoreInfo(oEca)
astDataStores = [];

caxArgs = {'ModelContext', oEca.sModelName, 'SearchMethod', 'cached'};
if ~isempty(oEca.EPEnv)
    caxArgs(end+1:end+2) = {'Environment', oEca.EPEnv}; 
end
try
    astDataStores = ep_core_feval('ep_model_datastores_get', caxArgs{:});
catch oEx
    warning([ ...
        '## An issue happened during the analysis of Data store interfaces, therefore they cannot be reported in the diagnostrics report. ', ...
        'One or multiple Data Stores are probably covered by a limitation. ', ...
        'Hint: Keep EmbeddedPlatform open while running the diagnostics scripts or import the model in EP for further detail messages.']);
end
end

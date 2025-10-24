function ut_ep_attr_startIdx_is_valid()
% Tests that the xsd validation works if the startIdx attribute is set in the Logging node.

%% prepare
ep_tu_cleanup();

sPwd = pwd;
sTestdataDir = fullfile(fileparts(sPwd), 'data');
ep_sim_argcheck('LoggingAnalysisFile', ...
    struct('LoggingAnalysisFile', ... 
    fullfile(sTestdataDir, 'LoggingAnalysis_xsdCheckWithStartIdx.xml')), {'xsdvalid', 'LoggingAnalysis.xsd'});

end


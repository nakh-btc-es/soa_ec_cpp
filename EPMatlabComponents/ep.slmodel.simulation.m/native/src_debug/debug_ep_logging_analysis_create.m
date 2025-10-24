function debug_ep_logging_analysis_create(sExtractionModelFile, nUsage, bFullLogging, bEnableTLLogging, bBreakModelRefs)
% Just for debugging purposes a script that creates a LoggingAnalysis XML from the provided info.
%     -                     -
%


%%
hExDoc = mxx_xmltree('load', sExtractionModelFile);
oOnCleanupCloseExDoc = onCleanup(@() mxx_xmltree('clear', hExDoc));

hExtractSub = mxx_xmltree('get_nodes', hExDoc, '/ExtractionModel/Scope');
if numel(hExtractSub) ~= 1
    error('DEBUG:ERROR', 'Unexpected number of scopes.');
end
sPhysPath = mxx_xmltree('get_attribute', hExtractSub, 'physicalPath');
mxx_xmltree('set_attribute', hExtractSub, 'mappingPath', sPhysPath); % for debug assume 1:1 mapping

sLoggingAnalysis = 'LoggingAnalysis.xml';
sAnalysisFile = fullfile(pwd, sLoggingAnalysis);

hLoggingAnalysis = mxx_xmltree('create', 'LoggingAnalysis');
oOnCleanupCloseAnaDoc = onCleanup(@() mxx_xmltree('clear', hLoggingAnalysis));

if bEnableTLLogging
    mxx_xmltree('set_attribute', hLoggingAnalysis, 'kind', 'TL');    
    atgcv_m13_tl_logging_analyze(hExtractSub, bBreakModelRefs, bFullLogging, hLoggingAnalysis);
    
else
    mxx_xmltree('set_attribute', hLoggingAnalysis, 'kind', 'SL');
    
    atgcv_m13_logging_analyze(stEnv, hExtractSub, nUsage, bFullLogging, hLoggingAnalysis, bBreakModelRefs);    
end
mxx_xmltree('save', hLoggingAnalysis, sAnalysisFile);
end


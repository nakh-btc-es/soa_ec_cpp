function atgcv_mil_model_logging(stEnv, xSubsystem, nUsage, sDestModel, bFullLogging, bEnableTLLogging, bBreakModelRefs, oProgress)
% Logs the objects in the given model with the information of the model analysis
%
% function atgcv_mil_model_logging(stEnv, xSubsystem, nUsage, sModel, bFullInterLog, bEnableTLLogging, oProgress)
%
%   INPUTS               DESCRIPTION
%
%     stEnv              (struct)     Environment structure
%     xSubsystem         (entity)     Entity of the ModelAnalysis (see
%                                     ModelAnalysis.dtd)
%
%     nUsage             (integer)    1, if we handle a TargetLink model
%                                     2, if we handle a Simulink model
%
%     sModel             (string)     full path name to the original model,
%                                     - loaded assumed.
%     bFullInterLog     (boolean)     full interface logging, when true
%     bEnableTLLogging   (bool)       Enable TL Logging mode
%     bBreakModelRefs    (bool)       true, if model references are broken and we have a monolithic extraction model
%     iSub2RefConversion (number)     0 = no model reference conversion
%                                     1 = simple model reference conversion
%                                     2 = model reference conversion with one indirection
%     oProgress          (object)     object for showing progress
%
%
%

%%
sResultPath = stEnv.sResultPath;

atgcv_progress_set(oProgress, 'current', 1, 'total', 5);

sLoggingAnalysis = sprintf('%s_logging.xml', sDestModel);
sAnalysisFile = fullfile(sResultPath, sLoggingAnalysis);
hLoggingAnalysis = mxx_xmltree('create', 'LoggingAnalysis');
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hLoggingAnalysis));

if bEnableTLLogging
    mxx_xmltree('set_attribute', hLoggingAnalysis, 'kind', 'TL');    
    atgcv_m13_tl_logging_analyze(xSubsystem, bBreakModelRefs, bFullLogging, hLoggingAnalysis);
    
else
    mxx_xmltree('set_attribute', hLoggingAnalysis, 'kind', 'SL');
    
    atgcv_m13_logging_analyze(stEnv, xSubsystem, nUsage, bFullLogging, hLoggingAnalysis, bBreakModelRefs);
    
    ahLogging = ep_em_entity_find(hLoggingAnalysis, './/Logging');    
    if ~isempty(ahLogging)
        atgcv_progress_set(oProgress, 'current', 3, 'total', 5);
        
        atgcv_m13_logging_setting(stEnv, hLoggingAnalysis);
        
        atgcv_progress_set(oProgress, 'current', 4, 'total', 5);
        
        hDestMdl = get_param(sDestModel, 'Handle');
        set_param(hDestMdl, 'SignalLogging', 'on');
        set_param(hDestMdl, 'SignalLoggingName', 'et_logsout');
        
    else
        hDestMdl = get_param(sDestModel, 'Handle');
        set_param(hDestMdl, 'SignalLogging', 'on');
    end    
end
atgcv_progress_set(oProgress, 'current', 5, 'total', 5);

mxx_xmltree('save', hLoggingAnalysis, sAnalysisFile);
end


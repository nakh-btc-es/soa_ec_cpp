function ep_da_enable_logging(xEnv, stModelArgs, stFlagArgs)
% This function receives the extraction model generated for a failed B2B test and enables the mil logging for a set of
% extra displays available in the given sExtractionModelXMLFile
%
% function stExtractInfo = ep_da_enable_mil_logging(varargin)
%
%  INPUT              DESCRIPTION
%
%         sExtractionModelXMLFile*  (string)   Path to the extraction model XML file that contains the extra displays
%                                               for which the logging must be enabled
%
%         sExtractionModelFile*     (string)   Path to the extraction model.slx file that was generated for a failed B2B test
%
%         EnableSubsystemLogging*   (boolean)  Logging should be enabled (Default : false)
%
%         BreakLinks*               (boolean)  Break Links to Libraries (Default : true)
%
%         ModelRefMode*             (integer)  Model Reference Mode (0- Keep refs | 1- Copy refs | 2- Break refs)
%
%         sTopLevelSubsystem*       (string)   Path to the top level subsystem in the extraction model
%
%         MessageFile               (file)     The absoulte path to the message file for recording errors/warnings/info messages.



%% init environment
try
    [xOnCleanUpCloseFile, xOnCleanUpChangeDir] = i_enable_logging_for_deviation_analysis(xEnv, stModelArgs, stFlagArgs); %#ok
catch oEx
    EPEnvironment.cleanAndThrowException(xEnv, oEx, []);
end
end


%%
function [xOnCleanUpCloseFile, xOnCleanUpChangeDir] = i_enable_logging_for_deviation_analysis(xEnv, stModelArgs, stFlagArgs)
[xSubsys, xOnCleanUpCloseFile] = i_open_extraction_model_file(stModelArgs.sExtractionModelXMLFile);
xRoot = mxx_xmltree('get_root', xSubsys);
bIsTlModel = ~strcmp(mxx_xmltree('get_attribute', xRoot, 'type'), 'SimulinkArchitecture');

[~, sExtrModelName] = fileparts(stModelArgs.sExtractionModel);
if ~bdIsLoaded(sExtrModelName)
    stParam = struct(...
        'sModelFile', stModelArgs.sExtractionModel, ...
        'caInitScripts', {{}}, ...
        'bIsTL', bIsTlModel, ...
        'bCheck', false,... % bInitModel
        'casAddPaths', {{}}, ...
        'bActivateMil', true);
    ep_core_model_open(xEnv, stParam);
end

stSrcModelInfo = struct(...
    'nUsage', i_getUsage(bIsTlModel),...
    'xSubsys', xSubsys);
stExtrModelInfo = struct(...
    'sName', sExtrModelName);
stArgs = struct(...
    'Mode', stFlagArgs.sMode, ...
    'BreakLinks', stFlagArgs.bBreakLinks, ...
    'ModelRefMode', stFlagArgs.iModelRefMode, ...
    'EnableSubsystemLogging', stFlagArgs.bEnableSubsystemLogging);

ep_em_entity_attribute_set(stSrcModelInfo.xSubsys, 'mappingPath', stModelArgs.sTopLevelSubsystem);

sPwd = pwd;
sExtractionModelLocation = fileparts(stModelArgs.sExtractionModelXMLFile);
cd(sExtractionModelLocation);

% enable the logging
xOnCleanUpChangeDir = onCleanup(@() cd(sPwd));
ep_tl_enable_logging(xEnv, stSrcModelInfo, stExtrModelInfo, stArgs);

% save the modifications and do not close the model
atgcv_m13_save_model(sExtrModelName, false, false);

cd(sPwd);
end


%%
function nUsage = i_getUsage(bIsTlModel)
nUsage = 2;
if (bIsTlModel)
    nUsage = 1;
end
end


%%
function [hSubsystem, xOnCleanUpCloseFile] = i_open_extraction_model_file(sExtractionModelFile)
hDoc = mxx_xmltree('load', sExtractionModelFile );
xOnCleanUpCloseFile = onCleanup(@() mxx_xmltree('clear', hDoc));
xModelAnalysis = mxx_xmltree('get_root', hDoc);
sUid = mxx_xmltree('get_attribute', xModelAnalysis, 'ref');
hSubsystem = mxx_xmltree('get_nodes', xModelAnalysis, sprintf('//Scope[@uid="%s"]', sUid));
end
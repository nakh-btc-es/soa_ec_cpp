function ep_sim_write_derived_values(xEnv, sAnalysisFile, castLoggedSubsystems, nVecLength)
% This method evaluates the logged values and stores them into an MDF file.
%
% function ep_sim_write_derived_values(xEnv, sAnalysisFile, castLoggedSubsystems, nVecLength)
%
%   INPUTS               DESCRIPTION
%     xEnv                      (object)     Environment object
%     sAnalysisFile             (string)     full path file to analysis of logging
%     castLoggedSubsystem       (cell)       structs with info about subsystems to be logged 
%     nVecLength                (number)     length of the vector
%
%   OUTPUT               DESCRIPTION
%     -                     -
%


%%
if isempty(castLoggedSubsystems)
    % nothing to do
    return;
end

%%
if (nVecLength > intmax('uint32'))
    error('DERIVE:ERROR', 'Vector length greater than %s is not supported.', intmax('uint32'));
end

hDoc = mxx_xmltree('load', sAnalysisFile);
hLoggingAnalysis = mxx_xmltree('get_root', hDoc);
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

% dependent on the logging kind we have different logging evaluations
if i_isLoggingTLDS(hLoggingAnalysis)
    hLoggingEvalFunc = @ep_sim_tlds_to_log_data;
else
    oLogVar = i_getLogVarFromBase();
    hLoggingEvalFunc = @(x, y) ep_sim_logvar_to_log_data(x, y, oLogVar);
end

astLogggedSubs = cell2mat(castLoggedSubsystems);
casLoggedSubIDs = {astLogggedSubs(:).sScopeUID};

ahSubsystems = mxx_xmltree('get_nodes', hLoggingAnalysis, '//Subsystem');
for i = 1:length(ahSubsystems)
    hSub = ahSubsystems(i);
    
    sScopeID = mxx_xmltree('get_attribute', hSub, 'id');
    iFound = find(strcmp(sScopeID, casLoggedSubIDs));
    if (numel(iFound) ~= 1)
        continue;
    end
    stScopeInfo = castLoggedSubsystems{iFound};
    
    % evaluate the logging data
    astLogData = feval(hLoggingEvalFunc, xEnv, hSub);
    
    i_writeDataToFile(xEnv, astLogData, stScopeInfo, nVecLength);
end
end


%%
function i_writeDataToFile(xEnv, astLogData, stScopeInfo, nVecLength)
[astInLogs, astOutLogs, astParamLogs, astLocalLogs] = i_splitLogData(xEnv, astLogData);

ep_sim_log_data_to_mdf_write(stScopeInfo.sInputsMDF, astInLogs, nVecLength);
ep_sim_log_data_to_mdf_write(stScopeInfo.sOutputsMDF, astOutLogs, nVecLength);
ep_sim_log_data_to_mdf_write(stScopeInfo.sParamsMDF, astParamLogs, 1);
ep_sim_log_data_to_mdf_write(stScopeInfo.sLocalsMDF, astLocalLogs, nVecLength);
end


%%
function [astInLogs, astOutLogs, astParamLogs, astLocalLogs] = i_splitLogData(xEnv, astLogData)
if isempty(astLogData)
    astInLogs    = [];
    astOutLogs   = [];
    astParamLogs = [];
    astLocalLogs = [];
else
    casKinds = {astLogData(:).sKind};

    astInLogs    = astLogData(strcmp('Input',     casKinds));
    astParamLogs = astLogData(strcmp('Parameter', casKinds));
    astLocalLogs = astLogData(strcmp('Local',     casKinds));
    astOutLogs   = astLogData(strcmp('Output',    casKinds));

    if ~i_isLogAvailable(astInLogs) || ~i_isLogAvailable(astParamLogs)
        xEnv.addMessage('ATGCV:SLAPI:DERIVATION_INCOMPLETE');
        %error('DERIVE:ERROR', 'Some interface objects could not be logged. Derivation failed.');        
    end
end
end

%%
function isAvailable = i_isLogAvailable(astLogs)
isAvailable = true;
for i=1:length(astLogs)
    if isempty(astLogs(i).anStep)
        isAvailable = false;
        break;
    end
end
end

%%
function oLogVar = i_getLogVarFromBase()
oLogVar = [];

sLogVar = 'et_logsout';
bFoundLogVar = evalin('base', ['exist(''', sLogVar, ''', ''var'');']);
if bFoundLogVar    
    oLogVar = evalin('base', sLogVar);
end
end


%%
function bIsTLDS = i_isLoggingTLDS(hLoggingAnalysis)
bIsTLDS = strcmp('TL', mxx_xmltree('get_attribute', hLoggingAnalysis, 'kind'));
end



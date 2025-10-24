function ep_simenv_tlds_logging_old_approch(xEnv, sTempDir, sLoggingFile, nLength)
% Evaluate the TL tlds database.
%
% function ep_simenv_tlds_eval(xEnv,sLoggingFile)
%
%   INPUT               DESCRIPTION
%     xEnv               Environment settings.
%     sLoggingFile       Logging information file
%     nLength            Length of simulation
%   OUTPUT              DESCRIPTION
%


%%
hDoc = mxx_xmltree('load', sLoggingFile);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

i_evalLogsByTLDS(xEnv, sTempDir, hDoc, nLength);
end



%%
function i_evalLogsByTLDS(xEnv, sTempDir, hLoggingDoc, nLength)
if isempty(hLoggingDoc)
    return;
end

xLoggingAnalysis = mxx_xmltree('get_root', hLoggingDoc);
sKind = mxx_xmltree('get_attribute', xLoggingAnalysis, 'kind');
if ~strcmp(sKind, 'TL') % only the TL logging is alowed here
    return;
end

if ~exist('tl_access_logdata', 'file')
    xEnv.addMessage('ATGCV:SIM:TL_LOGGING_LIMITATION');
    return;
end

iCompare = atgcv_version_p_compare('TL4.0p3'); % note: empty if TL not installed
bIsNewTL = ~isempty(iCompare) && (iCompare >= 0);
bLoggingSupportedByTLDS = bIsNewTL || (nLength > 1);
if ~bLoggingSupportedByTLDS
    xEnv.addMessage('EP:SIM:TL_LOGGING_LENGTH_LIMITATION', 'steps', num2str(nLength));
end

simlabel = tl_access_logdata('GetLastSimulationLabel');
if isempty(simlabel)
    xEnv.addMessage('ATGCV:SIM:TL_LOGGING_LIMITATION');
    return;
end
oOnCleanupDeleteSim = onCleanup(@() tl_access_logdata('DeleteSimulation', simlabel));

ahLoggings = mxx_xmltree('get_nodes', xLoggingAnalysis, '/LoggingAnalysis/Subsystem/Logging');
arrayfun(@(h) i_evalLoggingData(xEnv, sTempDir, simlabel, h), ahLoggings);
end


%%
function i_evalLoggingData(xEnv, sTempDir, simlabel, hLoggingNode)
iStartIdx = 1; % default

sExplicitStartIdx = mxx_xmltree('get_attribute', hLoggingNode, 'startIdx');
if ~isempty(sExplicitStartIdx)
    iStartIdx = str2double(sExplicitStartIdx);
end

ahAccess = mxx_xmltree('get_nodes', hLoggingNode, './Access');
arrayfun(@(h) i_evalLoggingAccessData(xEnv, sTempDir, simlabel, iStartIdx, h), ahAccess);
end


%%
function i_evalLoggingAccessData(xEnv, sTempDir, simlabel, iStartIdx, hAccess)
[bSuccess, sDisplayName] = i_evalData(xEnv, sTempDir, simlabel, iStartIdx, hAccess);
if ~bSuccess
    xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', 'name', sDisplayName);
end
end


%%
function [bSuccess, sDisplayName] = i_evalData(xEnv, sTempDir, simlabel, iStartIdx, hAccess)
bSuccess = false;

stAccess = mxx_xmltree('get_attributes', hAccess, '.', ...
    'displayName', ...
    'block', ...
    'signalName', ...
    'index1', ...
    'index2');
sDisplayName = stAccess.displayName;
if isempty(simlabel)
    return;
end

try
    signallogdata = ep_simenv_tlds_get_logged_signal(simlabel, stAccess.block, stAccess.signalName);
    
    if ~isempty(signallogdata)
        stData = signallogdata.signal;
        adTimes = stData.t;
        values = stData.y;
        
        if ~isempty(stAccess.index1)
            iIdx1 = str2double(stAccess.index1) + 1 - iStartIdx;
            if ~isempty(stAccess.index2)
                iIdx2 = str2double(stAccess.index2) + 1 - iStartIdx;                
                adValues = values(iIdx1, iIdx2, :);                
            else
                adValues = values(iIdx1, :);
            end
        else
            adValues = values;
        end
        
        if isequal(length(adTimes), length(adValues))
            sIfId = mxx_xmltree('get_attribute', hAccess, 'ifid');
            ep_simenv_values2mat(sTempDir, sIfId, adTimes, adValues);
            bSuccess = true;
        end
    end
    
catch oEx
    xEnv.addMessage('ATGCV:MIL_GEN:INTERNAL_ERROR', ...
        'script', 'ep_simenv_tlds_eval', ...
        'text',   [oEx.identifier, ' ' ,oEx.message]);
end
end

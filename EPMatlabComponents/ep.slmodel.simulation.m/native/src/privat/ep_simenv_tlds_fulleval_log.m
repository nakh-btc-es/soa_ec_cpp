function ep_simenv_tlds_fulleval_log(xEnv, sLoggingAnalysisFile, nLength, sDerivedVecName)
% Evaluate the TL_SIL logging data
%
% function ep_simenv_tlds_fulleval_log(xEnv, sLoggingAnalysisFile, nLength, sDerivedVecName)
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION

%
%   REMARKS
%
%   (c) 2011 by Embedded Systems AG, Germany

%% internal
%
%
%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2011
%
%%


iCompare = atgcv_version_p_compare('TL4.0p3'); % note: empty if TL not installed
bIsNewTL = ~isempty(iCompare) && (iCompare >= 0);
bValid = bIsNewTL || (nLength > 1);
if ~bValid
    xEnv.throwException(...
        xEnv.addMessage('ATGCV:SIM:TL_LOGGING_LENGTH_LIMITATION', ...
        'steps', num2str(nLength)));
end

% check if we can access TLDS logging data via API
bExistLogAccess = exist('tl_access_logdata', 'file') == 2;
if( ~bExistLogAccess )
    xEnv.throwException(...
        xEnv.addMessage('ATGCV:SIM:TL_LOGGING_LIMITATION'));
end
simlabel = tl_access_logdata('GetLastSimulationLabel');
if isempty(simlabel)
    % TODO: replace with its own message!!!!
    xEnv.throwException(...
        xEnv.addMessage('ATGCV:SIM:TL_LOGGING_LIMITATION'));
end
xOnCleanupCloseSimHandle = ...
    onCleanup(@() tl_access_logdata('DeleteSimulation', simlabel));


ep_simenv_eval_logged_values(xEnv, ...
    simlabel, ...
    sLoggingAnalysisFile, ...
    sDerivedVecName);


end

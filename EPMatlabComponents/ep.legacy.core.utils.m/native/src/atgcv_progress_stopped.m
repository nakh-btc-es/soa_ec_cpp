function bIsStopped = atgcv_progress_stopped(oProgress)
% Checks if progress is stopped
%
% function  bIsStopped = atgcv_progress_stopped(oProgress)
%
%   INPUT               DESCRIPTION
%     oProgress           (object)  The progress object.
%
%
%   <et_copyright>
%%


bIsStopped = false;



if isempty(oProgress)
    return;
end


bIsStopped = oProgress.getStopFlag();



%**************************************************************************
% END OF FILE
%**************************************************************************



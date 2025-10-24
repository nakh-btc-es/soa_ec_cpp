function atgcv_progress_stop(oProgress, sMsg)
% Stops the progress object and 
%
% function atgcv_progress_set(oProgress, [param,value]*)
%
%   INPUT               DESCRIPTION
%     oProgress           (object)  The progress object.
%
%
%   <et_copyright>
%%




if isempty(oProgress)
    return;
end


atgcv_progress_set(oProgress, 'msg', sMsg);

oProgress.setStopFlag();




%**************************************************************************
% END OF FILE
%**************************************************************************

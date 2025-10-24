function stInfo = atgcv_progress_info_get(oProgress)
% Get information about progress.
%
% function stInfo = atgcv_progress_info_get(oProgress)
%
%   INPUT               DESCRIPTION
%     oProgress           (object)  The progress object.
%
%   OUTPUT              DESCRIPTION
%     stInfo              (struct)
%       .current                current number of performed steps.
%       .total                  total number of performed steps.
%       .msg                    message string.
%
%
%   <et_copyright>





stInfo.current = 0;
stInfo.total   = 0;
stInfo.msg     = '';


if isempty(oProgress)
    return;
end



stInfo.current = oProgress.getCurrentPing();
stInfo.total = oProgress.getTotalPing();
stInfo.msg = char(oProgress.getMessage());




%**************************************************************************
% END OF FILE
%**************************************************************************

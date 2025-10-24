function atgcv_progress_fill(oProgress)
% Set "current" of progress to "total" number.
%
% function atgcv_progress_fill(oProgress)
%
%   INPUT               DESCRIPTION
%     oProgress           (object)  The progress object.
%
%   OUTPUT              DESCRIPTION
%
%
%   <et_copyright>

if ((nargin < 1) || ...
    isempty(oProgress) )
    return;
end

nTotal = oProgress.getTotalPing();
atgcv_progress_set(oProgress, 'current', nTotal);
end

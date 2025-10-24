function caoProgress = atgcv_progress_children_create(varargin)
% Creates children progress objects for the given progress
%
% function caoProgress = atgcv_progress_children_create(oProgress, anWeights, abPropagateMessage)
%
%   INPUT               DESCRIPTION
%     oProgress           (object)   The parent progress object
%     anWeights           (array)    Array of weights. Size of array
%                                    defines the number of returned
%                                    children objects.
%     abPropagateMessage  (array)    (optional parameter)
%                                    Array of boolean values. Defines for
%                                    each progress object, if progress
%                                    messages shall be posted to the
%                                    parent.
%                                    (default is FALSE --> no posting)
%
%   OUTPUT              DESCRIPTION
%     caoProgress          (cell)    Cell-array of children progress
%                                    objects.
% 
%   <et_copyright>

[oProgress, canWeights, cabPropagateMessage] =  i_param_check(varargin{:});
caoProgress = cell(1, length(canWeights));
if isempty(oProgress)
    % return empty child objects for empty parent progress
    return;
end

oProgressVector = oProgress.createChildProcesses(  ...
    atgcv_m2j(canWeights),  atgcv_m2j(cabPropagateMessage) );
caoProgress = atgcv_j2m( oProgressVector );





%%
% Checks and interprets the given arguments.
function [oProgress, canWeights, cabPropagateMessage] = i_param_check(varargin)

stEnv = 0;

if nargin < 2
    e = osc_messenger_add(stEnv, 'ATGCV:STD:WRONG_PARAM_CNT');
    osc_throw(e);
end

oProgress = varargin{1};



canWeights = num2cell(int32(varargin{2}));


if nargin <= 2
    % default: no posting of message to parent
    abPropagateMessage = false(1, length(canWeights));
else
    abPropagateMessage = logical(varargin{3});
    if length(abPropagateMessage) ~= length(canWeights)
        e = osc_messenger_add(stEnv, 'ATGCV:STD:WRONG_PARAM_VAL', ...
            'param_name', 'abPropagateMessage', 'wrong_value', 'invalid array size');
        osc_throw(e);
    end
end

cabPropagateMessage = num2cell(abPropagateMessage);
return;



%**************************************************************************
% END OF FILE
%**************************************************************************

function atgcv_progress_set(varargin)
% Set values in progress object.
%
% function atgcv_progress_set(oProgress, [param,value]*)
%
%   INPUT               DESCRIPTION
%     oProgress           (object)  The progress object.
%     param               (string)  Name of the parameter.
%     value               (depends) Value of the parameter.
%
%   Allowed Param, Value pairs
%
%       'current', (integer)    Current number of performed steps.
%       'total', (integer)      Total number of steps in progress.
%       'msg', (string)         Message string to show.
%
%   <et_copyright>
%%
try
    stEnv = 0;
    nIndex = 1;
    
    if nargin < 1
        e = osc_messenger_add(stEnv, 'ATGCV:STD:WRONG_PARAM_CNT');
        osc_throw(e);
    end
    
    
    if mod(nargin,2) ~= 1
        e = osc_messenger_add(stEnv, 'ATGCV:STD:WRONG_PARAM_CNT');
        osc_throw(e);
    end
    
    oProgress = varargin{nIndex}; nIndex = nIndex+1;
    if isempty(oProgress)
        return;
    end
    
    
    if oProgress.getStopFlag()
        return; % no exception yet
    end
    
    % initializing new values with the old values.
    newCurrent = oProgress.getCurrentPing();
    newTotal   = oProgress.getTotalPing();
    newMsg     = char(oProgress.getMessage());
    
    
    % overwrite new values with the given parameter.
    for i=nIndex:2:length(varargin)
        param = varargin{i}; nIndex = nIndex+1;
        value = varargin{i+1}; nIndex = nIndex+1;
        
        switch param
            case 'current'
                newCurrent = value;
            case 'total'
                newTotal = value;
            case 'msg'
                newMsg = value;
            otherwise
                e = osc_messenger_add(stEnv, ...
                    'ATGCV:STD:WRONG_PARAM_VAL', ...
                    'param_name', 'param', 'wrong_value', param);
                osc_throw(e);
        end
    end
    oProgress.setProgress( newCurrent, newTotal, newMsg );
    
    
catch
    osc_throw(osc_lasterror);
end



%**************************************************************************
% END OF FILE
%**************************************************************************

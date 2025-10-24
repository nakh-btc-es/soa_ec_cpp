function varargout = sltu_tmp_env(varargin)
% Setting/getting the current temporary test data directory
%
% Do not use this function. Use tu_tmp_env in ep.test.utils.m
%

%% read
if (nargin < 1)
    varargout{1} = tu_tmp_env;
    return;
end
 
%% write
if ((nargin > 0) && (nargout < 1))
    tu_tmp_env(varargin);
    return;
end

%% error
error('SLTU:TMP_ENV:WRONG_USAGE', 'Wrong usage. Plese read the docu.');
end

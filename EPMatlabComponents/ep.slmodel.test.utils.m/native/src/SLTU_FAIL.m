function SLTU_FAIL(sMessage, varargin)
% Register a failed assertion with the specified message. No logical test is performed.
%
% function SLTU_FAIL(sMessage, varargin)
%
%   PARAMETER(S)    DESCRIPTION
%   - sMessage       Optional message displayed in report if the assert fails.


%%
if (nargin < 1)
    sMessage = '';
else
    if (nargin > 1)
        sMessage = sprintf(sMessage, varargin{:});
    end
end

%%
SLTU_assert('SLTU_FAIL', 1, [': ', sMessage]);
end

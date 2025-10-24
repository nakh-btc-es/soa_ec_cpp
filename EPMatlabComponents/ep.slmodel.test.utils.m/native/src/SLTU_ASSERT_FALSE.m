function SLTU_ASSERT_FALSE(bCondition, sMessage, varargin)
% Assert that condition is FALSE.
%
% function SLTU_ASSERT_FALSE(bCondition, sMessage, varargin)
%
%   PARAMETER(S)    DESCRIPTION
%   - bCondition     Assert condition.
%   - sMessage       Message displayed in report if the assert fails.


%%
if (nargin < 2)
    sMessage = '';
else
    if (nargin > 2)
        sMessage = sprintf(sMessage, varargin{:});
    end
end

%%
try
    bFailed = logical(bCondition);
catch
    error('SLTU:ASSERT_TRUE:ERROR', 'Condition cannot be evaluated.');
end

%%
SLTU_assert('SLTU_ASSERT_FALSE', bFailed, [': ', sMessage]);
end

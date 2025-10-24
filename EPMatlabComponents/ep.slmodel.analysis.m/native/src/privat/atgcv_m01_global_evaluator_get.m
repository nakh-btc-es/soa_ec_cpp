function hEvalFunc = atgcv_m01_global_evaluator_get(xModelContext)
if (nargin < 1)
    xModelContext = [];
end

if (~isempty(xModelContext) && i_hasEPResolver())
    oMc = EPModelContext.get(xModelContext);
    hEvalFunc = @(sExpression) oMc.evalinGlobal(sExpression);
else
    hEvalFunc = @i_defaultEvalFunc;
end
end


%%
function bHasResolver = i_hasEPResolver()
bHasResolver = ~isempty(which('EPModelContext'));
end


%%
% Note: the default eval func is simply the evaluation within the base workspace
%
function varargout = i_defaultEvalFunc(sExpression)
[varargout{1:nargout}] = evalin('base', sExpression);
end


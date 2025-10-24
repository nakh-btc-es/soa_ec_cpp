function hResolverFunc = atgcv_m01_expression_resolver_get(xModelContext)
% Returns a resolver function that can evaluate expression strings in model context.
%
% function hResolverFunc = atgcv_m01_expression_resolver_get(xModelContext)
%
%   INPUT               DESCRIPTION
%     xModelContext     (string/handle)   optional: the model context as string or handle
%                                         (note: if not provided or empty, the global workspace is taken as context)
%
%   OUTPUT              DESCRIPTION
%     hResolverFunc      (handle)         the function that can translate expressions in model context
%
%   ------------------------ Note -------------------------
%     The signature of the resolver function is the following
%
%     [xResult, nScope] = <resolver func>(sExpression)
%
%      INPUT               DESCRIPTION
%        sExpression       (string)       the expression to be evaluated
%
%   OUTPUT              DESCRIPTION
%        xResult           (xxx)          the result of the evaluation
%        nScope            (0|1|...)      integer status of the evaluation
%                                         0:     evaluation failed
%                                         not 0: evaluation successful
%
%   <et_copyright>

%%
if (nargin < 1)
    xModelContext = [];
end

if ~isempty(xModelContext)
    oMc = EPModelContext.get(xModelContext);
    hResolverFunc = @(sExpression) i_resolveInModelContext(sExpression, oMc);
else
    hResolverFunc = @i_defaultResolveExpression;
end
end


%%
function [xResult, nScope] = i_resolveInModelContext(sExpression, oMc)
try
    xResult = oMc.resolve(sExpression);
    nScope = 1;
catch
    xResult = [];
    nScope = 0;
end
end


%%
% INPUT
%   sExpresion (string)  the expression to be resolved
% OUTPUT
%   xResult    (xxx)     the result of the expression
%   nScope     (int)     0 -- expression cannot be resolved properly
%                        1 -- expression can be resolved in global base workpace
%
function [xResult, nScope] = i_defaultResolveExpression(sExpression)
try
    xResult = evalin('base', sExpression);
    nScope = 1;
catch
    xResult = [];
    nScope = 0;
end
end


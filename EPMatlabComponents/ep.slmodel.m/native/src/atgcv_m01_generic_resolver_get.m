function hResolverFunc = atgcv_m01_generic_resolver_get(xModelContext)
% Returns a generic resolver function that can evaluate either variable names or expression strings in model context.
%
% function hResolverFunc = atgcv_m01_generic_resolver_get(xModelContext)
%
%   INPUT               DESCRIPTION
%     xModelContext     (string/handle)   optional: the model context as string or handle
%                                         (note: if not provided or empty, the global workspace is taken as context)
%
%   OUTPUT              DESCRIPTION
%     hResolverFunc      (handle)         the function that can translate symbols or expressions in model context
%
%   ------------------------ Note -------------------------
%     The signature of the resolver function is the following
%
%     [xResult, nScope] = <resolver func>(sSomeString)
%
%      INPUT               DESCRIPTION
%        sSomeString       (string)       the variable name or expression to be evaluated
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
hSymbolResolverFunc = atgcv_m01_symbol_resolver_get(xModelContext);
hExpressionResolverFunc = atgcv_m01_expression_resolver_get(xModelContext);

hResolverFunc = @(sString) i_genericResolve(sString, hSymbolResolverFunc, hExpressionResolverFunc);
end


%%
function [xResolvedObj, nScope] = i_genericResolve(sString, hSymbolResolverFunc, hExpressionResolverFunc)
xResolvedObj = [];
nScope = 0;
if isempty(sString)
    return;
end

if isvarname(sString)
    [xResolvedObj, nScope] = feval(hSymbolResolverFunc, sString);
    if (nScope > 0)
        return;
    end
end

[xResolvedObj, nScope] = feval(hExpressionResolverFunc, sString);    
end
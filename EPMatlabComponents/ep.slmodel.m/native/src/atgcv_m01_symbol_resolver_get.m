function hResolverFunc = atgcv_m01_symbol_resolver_get(xModelContext)
% Returns a resolver function that can evaluate symbol names in model context.
%
% function hResolverFunc = atgcv_m01_symbol_resolver_get(xModelContext)
%
%   INPUT               DESCRIPTION
%     xModelContext     (string/handle)   optional: the model context as string or handle
%                                         (note: if not provided or empty, the global workspace is taken as context)
%
%   OUTPUT              DESCRIPTION
%     hResolverFunc      (handle)         the function that can translate symbols in model context
%
%   ------------------------ Note -------------------------
%     The signature of the resolver function is the following
%
%     [xResult, nScope] = <resolver func>(sSymbol)
%
%      INPUT               DESCRIPTION
%        sSymbol           (string)       the symbol to be evaluated
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
    hResolverFunc = @(sSymbol) oMc.getVariable(sSymbol);
else
    hResolverFunc = @i_defaultResolveSymbol;
end
end


%%
% INPUT
%   sSymbol (string)  some symbol used inside the model (SignalName, Type, Parameter, ...)
% OUTPUT
%   xValue  (xxx)     result of evaluating the symbol
%   nScope  (int)     0 -- symbol cannot be resolved properly
%                     1 -- symbol can be resolved in global base workpace
function [xValue, nScope] = i_defaultResolveSymbol(sSymbol)
bExist = evalin('base', sprintf('exist(''%s'', ''var'');', sSymbol));
if bExist
    xValue = evalin('base', sSymbol);
    nScope = 1;
else
    xValue = [];
    nScope = 0;
end
end


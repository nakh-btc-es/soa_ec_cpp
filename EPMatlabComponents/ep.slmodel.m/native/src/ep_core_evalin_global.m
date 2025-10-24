function varargout = ep_core_evalin_global(sModelName, sExpression)
% Evaluate an expression in model context on a global level (either in Data Dictionary or "base" workspace).
%
% function varargout = ep_core_evalin_global(sModelName, sExpression)
%
%   INPUT
%      sModelName      (string)       Name of an open/loaded model.
%                                     If invalid, exception is thrown.
%                                     If empty, the base workspace is used as context.
%      sExpression     (string)       Expression that shall be evaluated.
%
%   OUTPUT
%      varargout       (???)          Individual output that depends on the provided expression.
%
%
% $$$COPYRIGHT$$$-2017


%%
% Note: full DD API available for versions ML2015a and higher
%       hidden DD API available for versions ML2014a, ML2014b --> also try to read out DD here
try
    if i_isHighVersionML()
        [varargout{1:nargout}] = Simulink.data.evalinGlobal(sModelName, sExpression);
    else
        if i_isMediumVersionML()
            [varargout{1:nargout}] = evalinGlobalScope(sModelName, sExpression);
        else
            [varargout{1:nargout}] = i_evalinBase(sExpression);
        end
    end
catch oEx
    rethrow(oEx);
end
end


%%
function bIsHighVersionML = i_isHighVersionML()
persistent p_bIsHighVersionML;

if isempty(p_bIsHighVersionML)
    p_bIsHighVersionML = ~verLessThan('Matlab', '8.5');
end
bIsHighVersionML = p_bIsHighVersionML;
end


%%
function bIsMediumVersionML = i_isMediumVersionML()
persistent p_bIsMediumVersionML;

if isempty(p_bIsMediumVersionML)
    p_bIsMediumVersionML = ~verLessThan('Matlab', '8.3');
end
bIsMediumVersionML = p_bIsMediumVersionML;
end


%%
function varargout = i_evalinBase(sExpression)
[varargout{1:nargout}] = evalin('base', sExpression);
end


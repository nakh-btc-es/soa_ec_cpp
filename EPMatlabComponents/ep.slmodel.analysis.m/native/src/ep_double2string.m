function varargout = ep_double2string(bUseFloatString, varargin)
% Translates double values to strings.
%
% function varargout = ep_double2string(bUseFloatString, varargin)
%
%   INPUT               DESCRIPTION
%      bUseFloatString   (boolean)     *false*, if string is not allowed to have a floating point representation
%                                      (if the double is a real decimal, the value is treated with the command "fix")
%      varargin          (...)         arbitrary number of double values (may be empty, i.e. [] --> '')
%
%   INPUT               DESCRIPTION
%      varargout         (...)         strings corresponding to the provided double values
%


%%
n = numel(varargin);
varargout = cell(1, n);
for i = 1:n
    dValue = varargin{i};
    
    sValue = i_toString(dValue, bUseFloatString);
    if ~bUseFloatString
        if any(sValue == '.')
            sValue = i_toString(fix(dValue), bUseFloatString);
        end
    end
    varargout{i} = sValue;
end
end


%%
function sValue = i_toString(dVal, bUseFloatString)
if isempty(dVal)
    sValue = '';
else
    if bUseFloatString
        sValue = i_doubleToString(dVal);
    else
        sValue = i_otherToString(dVal);
    end
end
end


%%
function s = i_doubleToString(x)
s = sprintf('%.16e', x);
end


%%
function s = i_otherToString(x)
s = sprintf('%.17g', x);
if strcmp(s, '-0')
    s = '0';
end
end


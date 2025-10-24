function varargout = ep_core_feval(fun, varargin)
% Bridge for calling m scripts.
%
% varargout = ep_core_feval(fun, varargin)
%
%   INPUT
%    - fun            (string/func)   the function to be evaluated (as string or handle)
%    - varargin       (<...>)         the arguments passed to the evaluated function
%
%   OUTPUT
%    - varargout      (<...>)         the return values returned from the evaluated function
%
% $$$COPYRIGHT$$$-2016

[varargout{1:nargout}] = feval(fun, varargin{:});
end

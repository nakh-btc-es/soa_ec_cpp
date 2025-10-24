function varargout = sltu_use_caching(varargin)
% switch on local caching (can be used for Dev environment and should not be used for Jenkins)
%

if (nargin < 1)
    sUseCaching = getenv('EP_UT_USE_MODEL_CACHING');
    bUseCaching = ~isempty(sUseCaching) && any(strcmp(sUseCaching, {'1', 'on', 'true', 'yes'}));
    varargout{1} = bUseCaching;
else
    bUseCaching = varargin{1};
    if bUseCaching
        setenv('EP_UT_USE_MODEL_CACHING', '1');        
    else
        setenv('EP_UT_USE_MODEL_CACHING', '');
    end
end
end

function varargout = ut_currently_debugging(varargin)
persistent bDebugMode;

if isempty(bDebugMode)
    bDebugMode = false;
end

if (nargin > 0)
    bDebugMode = varargin{1};
    if bDebugMode
        if ~mislocked
            mlock;
        end
    else
        if mislocked
            munlock;
        end
    end
end

varargout{1} = bDebugMode;
end
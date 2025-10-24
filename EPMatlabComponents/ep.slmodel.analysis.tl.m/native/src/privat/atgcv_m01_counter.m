function varargout = atgcv_m01_counter(sCmd, varargin)
% storage of persistent counters
% sCmd --- add, get, set
%
% !note: "get" increases counter _after_ giving its value back
%
persistent stCount;
if isempty(stCount)
    stCount = struct();
end

switch lower(sCmd)
    case 'get'
        sCounterName = varargin{1};
        varargout{1} = stCount.(sCounterName);
        stCount.(sCounterName) = stCount.(sCounterName) + 1;
        
    case 'set'
        sCounterName = varargin{1};
        nInit = varargin{2};
        stCount.(sCounterName) = nInit;
        
    case 'add'
        sCounterName = varargin{1};
        if isfield(stCount, sCounterName)
            error('ATGCV:MOD_ANA:INTERNAL_ERROR', ...
                'Counter %s is already registered.', sCounterName);
        end
        if (length(varargin) > 1)
            nInit = varargin{2};
        else
            nInit = 1;
        end
        stCount.(sCounterName) = nInit;
        
    otherwise
        error('ATGCV:MOD_ANA:INTERNAL_ERROR', ...
            'Unknown command %s.', sCmd);
end
end        
        

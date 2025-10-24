function varargout = ep_ma_internal_property(sCmd, varargin)
% Access of internal properties. Mainly for UTs and Debugging workflows.
%
% function varargout = ep_ma_internal_property(sCmd, varargin)
%
%  this function can be used in two modes:
%
%  --- set mode -----------------------------------------
%      bExists = ep_ma_internal_property('set', <key>, <value>)
%
%   INPUT           DESCRIPTION
%     sKey              (string)      string used as key
%     sValue            (string)      any string used as value to be stored for the key
%       
%
%   OUTPUT          DESCRIPTION
%     bExists          (boolean)      flag indicating if the key was know before the set operation
%
%
%  --- get mode -----------------------------------------
%      [sValue, bExists] = ep_ma_internal_property('get', sKey, sDefaultValue)
%
%   INPUT           DESCRIPTION
%     sKey             (string)      string used as key
%     sDefaultValue    (string)      optional: any string used as default value if key is not found
%                                    (default == '')
%
%   OUTPUT          DESCRIPTION
%     sValue           (string)      value string found for key or the provided default key if available
%     bExists         (boolean)      flag indicating if key was found
%
%


%%
persistent p_mProps;
if isempty(p_mProps)
    p_mProps = containers.Map();
end


%%
if (nargin < 2)
    error('EP:ERROR:WRONG_USAGE', 'Wrong usage.');
end

switch lower(sCmd)
    case 'set'
        if (numel(varargin) ~= 2)
            error('EP:ERROR:WRONG_USAGE', 'Wrong usage.');
        end
        sKey = varargin{1};
        sVal = varargin{2};
        bExists = p_mProps.isKey(sKey);
        p_mProps(sKey) = sVal;
        
        varargout{1} = bExists;
        
    case 'get'
        nArgs = numel(varargin);
        switch nArgs
            case 1
                sKey = varargin{1};
                sDefaultVal = '';
                
            case 2
                sKey = varargin{1};
                sDefaultVal = varargin{2};
                
            otherwise
                error('EP:ERROR:WRONG_USAGE', 'Wrong usage.');
        end
        bExists = p_mProps.isKey(sKey);
        if bExists
            sVal = p_mProps(sKey);            
        else
            sVal = sDefaultVal;
        end
        
        varargout{1} = sVal;
        varargout{2} = bExists;
        
    otherwise
        error('EP:ERROR:WRONG_USAGE', 'Wrong usage.');
end
end


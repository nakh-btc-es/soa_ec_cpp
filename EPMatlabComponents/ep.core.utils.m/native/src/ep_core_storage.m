function varargout = ep_core_storage(sCmd, varargin)
% Stores arbitratry data persistently via keys.
%
%  function varagout = ep_core_storage(sCmd, varargin)
%
% ------------------------------------------------------------------------------------------------------
%  Note: Mainly a wrapper around a persistent containers.Map('KeyType', 'String', 'ValueType', 'any').
% ------------------------------------------------------------------------------------------------------
%
%  Usage: Adding data to storage.
%
%     xStorageKey = ep_core_storage('add', xData);
%
%  Usage: Retrieving data from storage.
%
%     xData = ep_core_storage('get', xStorageKey);
%
%  Usage: Retrieving all storage keys.
%
%     caxStorageKeys = ep_core_storage('keys');
%
%  Usage: Removing data from storage.
%
%     ep_core_storage('remove', xStorageKey);
%
%   
%
% $$$COPYRIGHT$$$-2017

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%%
persistent xMap;

if isempty(xMap)
    xMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    mlock;
end


%%
switch lower(sCmd)
    case 'add'
        xData = varargin{1};
        sKey = i_generateUniqueKey();
        xMap(sKey) = xData;
        varargout{1} = sKey;
        
    case 'get'
        sKey = varargin{1};
        if xMap.isKey(sKey)
            varargout{1} = xMap(sKey);
        else
            varargout{1} = [];
        end
        
    case 'remove'
        sKey = varargin{1};
        if xMap.isKey(sKey)
            xMap.remove(sKey);
        end        
        
    case 'keys'
        varargout{1} = xMap.keys;
    
    case 'clear'
        % internal usage when freeing memory is necessary by sacrificing stored data
        clear xMap;
        munlock;
        clear(mfilename);
        
    otherwise
        error('EP:CORE:UNKNOWN_COMMAND', 'Unknown command "%s".', sCmd);
end
end


%%
function sKey = i_generateUniqueKey()
if usejava('jvm')
    sKey = ['epc' char(java.util.UUID.randomUUID)];
else
    sKey = ['epc', num2str(feature('timing', 'cpucount'))];
end
end

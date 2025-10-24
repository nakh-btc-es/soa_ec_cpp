function varargout = ep_sl_bus_obj_store(sCmd, varargin)
% Persistent key-value store for bus objects and their corresponding signals.
%


%% init
persistent oBusNameObjMap;
persistent oBusNameSignalsMap;

if isempty(oBusNameObjMap)
    oBusNameObjMap = containers.Map();
    oBusNameSignalsMap = containers.Map();
end


%% main
switch lower(sCmd)
    case 'get'
        sBusName = varargin{1};
        oBusObj = varargin{2};
        
        varargout{1} = [];
        if oBusNameObjMap.isKey(sBusName)
            oStoredBusObj = oBusNameObjMap(sBusName);
            if isequal(oStoredBusObj, oBusObj)
                if (numel(varargin) > 2)
                    sRootName = varargin{3};
                    varargout{1} = i_adaptRootSignalName(oBusNameSignalsMap(sBusName), sRootName);
                else
                    varargout{1} = oBusNameSignalsMap(sBusName);
                end
            end
        end
        
    case 'set'
        sBusName = varargin{1};
        oBusObj = varargin{2};
        astSigs = varargin{3};
        
        oBusNameObjMap(sBusName) = oBusObj;
        oBusNameSignalsMap(sBusName) = astSigs;
        
    case 'all'
        varargout{1} = oBusNameObjMap.keys;
        
    otherwise
        error('ATGCV:INTERNAL:ERROR', 'Unknown command "%s".', sCmd);
end
end


%%
function astSigs = i_adaptRootSignalName(astSigs, sRootName)
if isempty(astSigs)
    return;
end

sMatcher = '^.*?\.'; % starting from beginning the first name characters before a dot (non-greedy evaluation)
sReplacement = [sRootName, '.'];

sFoundRoot = regexp(astSigs(1).sName, sMatcher, 'match', 'once');
if ~isempty(sFoundRoot) && strcmp(sFoundRoot, sReplacement)
    return;
end

for i = 1:numel(astSigs)
    astSigs(i).sName = regexprep(astSigs(i).sName, sMatcher, sReplacement);    
end
end


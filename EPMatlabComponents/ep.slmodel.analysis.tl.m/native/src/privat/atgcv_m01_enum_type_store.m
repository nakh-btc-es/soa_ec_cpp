function varargout = atgcv_m01_enum_type_store(sTypeName, astEnumElements)
% 
%


%%
persistent p_oTypeInfoMap;

if isempty(p_oTypeInfoMap)
    p_oTypeInfoMap = containers.Map;
end

% output mode
if (nargout > 0)
    % return all cached types
    varargout{1} = struct( ...
        'sName',           p_oTypeInfoMap.keys, ...
        'astEnumElements', p_oTypeInfoMap.values);
end

% input mode
if (nargin > 0)
    if ~p_oTypeInfoMap.isKey(sTypeName)
        p_oTypeInfoMap(sTypeName) = astEnumElements;
    end
end
end

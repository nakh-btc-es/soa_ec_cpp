function [sType, stTypeInfo] = ep_sl_export_type_eval(sType, mTypeInfoMap)
% Common functionality how types are treated during XML export.
%
% function [sType, stTypeInfo] = ep_sl_export_type_eval(sType, mTypeInfoMap)
%
%   INPUT               DESCRIPTION
%     sType              (string)      the signal/parameter type name
%     oTypeInfoMap       (map)         optional: map from types to type infos
%
%   OUTPUT              DESCRIPTION
%     sType              (string)      the type name to be used for the export
%     stTypeInfo         (struct)      infos for the type (as returned by ep_sl_type_info_get)
%

%%
if (nargin < 2)
    mTypeInfoMap = containers.Map();
end

if strcmp(sType, 'logical')
    sType = 'boolean'; % always translate logical type from ML into boolean type from SL
end

if mTypeInfoMap.isKey(sType)
    stTypeInfo = mTypeInfoMap(sType);
else
    stTypeInfo = ep_sl_type_info_get(sType);
    mTypeInfoMap(sType) = stTypeInfo; %#ok<NASGU> accepted side-effect: map variable provided as *reference*
end
if ~stTypeInfo.bIsValidType
    return;
end

if stTypeInfo.bIsEnum
    sType = stTypeInfo.sEvalType;
    return;
end

bIsFxpType = ~isempty(regexp(stTypeInfo.sEvalType, '^fixdt\(', 'once'));
if bIsFxpType
    sType = stTypeInfo.sEvalType;
    return;
end

sType = stTypeInfo.sBaseType;
end

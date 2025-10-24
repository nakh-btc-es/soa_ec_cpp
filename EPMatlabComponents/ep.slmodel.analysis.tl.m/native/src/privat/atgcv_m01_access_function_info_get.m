function stInfo = atgcv_m01_access_function_info_get(hAccessFunc)
% Get info from an access function DD handle.
%
% function stInfo = atgcv_m01_access_function_info_get(hAccessFunc)
%
%   INPUT               DESCRIPTION
%     hAccessFun          (DD handle)     DD handle for an "AccessFunction"
%
%   OUTPUT              DESCRIPTION
%     stAccessFuncs       (structs)       info from the AccessFunction node
%       .hAccessFunc          (DD handle)     the AccessFunction handle
%       .sMacroBody           (string)        the Macro body of the access function
%       .casVariableKindSpec  (strings)       spec to which variable kinds the access func shall be applied
%                                             (e.g. APPLY_TO_STRUCT, ...)
%       .sAccessFunctionKind  (string)        the kind of access (e.g. DIRECT, ADDRESS, READ_SINGLE_VALUE, ...)
%


%% default output
[bExist, hAccessFunc] = dsdd('Exist', hAccessFunc, 'objectKind', 'AccessFunction');
if ~bExist
    error('ATGCV:MODEL_ANA:INTERNAL_ERROR', 'Provided handle invalid.');
end

stInfo = struct( ...
    'hAccessFunc',         hAccessFunc, ...
    'sMacroBody',          '', ...
    'casVariableKindSpec', {{}}, ...
    'sAccessFunctionKind', '');
if isempty(hAccessFunc)
    return;
end

stDD = dsdd('GetAll', hAccessFunc);
casPropsDD = fieldnames(stDD);
for i = 1:numel(casPropsDD)
    sProp = casPropsDD{i};
    switch lower(sProp)
        case 'macrobody'
            stInfo.sMacroBody = stDD.(sProp);
            
        case 'variablekindspec'
            stInfo.casVariableKindSpec = stDD.(sProp);

        case 'accessfunctionkind'
            stInfo.sAccessFunctionKind = stDD.(sProp);            
    end
end
end




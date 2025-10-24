function stInfo = atgcv_m01_variable_type_get(stEnv, hVar, sMode)
% Get info about type and scaling of a variable.
%
% function stInfo = atgcv_m01_variable_type_get(stEnv, hVar, sMode)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)        environment struct
%     hVariable         (DD handle)     DD handle to "Variable" or
%                                       "InterfaceVariable"
%     sMode             (string)        if set to 'extended' function retrieves
%                                       also the Min/Max Info for the BaseType
%                                       (optional: default is 'short')
%   OUTPUT              DESCRIPTION
%     stInfo            (struct)       info about type of variable (see atgcv_m01_type_info_get)
%
%


%%
bWithExtendedInfo = false;
if ((nargin > 2) && strcmpi(sMode, 'extended'))
    bWithExtendedInfo = true;
end

hType = atgcv_mxx_dsdd(stEnv, 'GetType', hVar);
stInfo = atgcv_m01_type_info_get(stEnv, hType, bWithExtendedInfo);
end

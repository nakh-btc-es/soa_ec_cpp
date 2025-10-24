function stSettings = ep_ec_settings_merge(xEnv, stSettings, stNewSettings, casKnownIntermediateSettings)
% This function merges two sets of settings (stored in structures) by applying type consistency rules.
%
% Note: Old setting values are overridden by new values. However, if the value to set is not of the expected type,
% the setting is not applied.
%
% stSettings = ep_ec_settings_merge(xEnv, stSettings, stNewSettings, casKnownIntermediateSettings)
%
%   INPUT                               DESCRIPTION
%    - xEnv                                EPEnvironment object
%    - stSettings                          The structure containing all settings
%    - stNewSettings                       The structure containing settings to be overridden
%    - casKnownIntermediateSettings        Pre-defined fields for which the type consistency rules will be skipped.
%                                          Note: Only the leaf elements will be checked for correct type.
%
%  OUTPUT            DESCRIPTION
%    - stSettings                          The updated settings
%


%%
if (nargin < 4)
    casKnownIntermediateSettings = {};
end

sParentSetting = '';
stSettings = i_merge_settings(xEnv, stSettings, stNewSettings, casKnownIntermediateSettings, sParentSetting);
end

%%
function stSettings = i_merge_settings(xEnv, stSettings, stNewSettings, casKnownIntermediateSettings, sParentSetting)
casSettings = fieldnames(stNewSettings);
for k = 1:numel(casSettings)
    sSetting = casSettings{k};
    if isempty(sParentSetting)
        sNestedSetting = sSetting;
    else
        sNestedSetting = [sParentSetting, '.', sSetting];
    end
    if isfield(stSettings, sSetting)
        if i_is_intermediate_and_valid(sSetting, casKnownIntermediateSettings, stSettings, stNewSettings)
            stSettings.(sSetting) = i_merge_settings(xEnv, stSettings.(sSetting), ...
                stNewSettings.(sSetting), casKnownIntermediateSettings, sNestedSetting);
        else
            if ~isequal(stSettings.(sSetting), stNewSettings.(sSetting))
                [bSameType, xAdaptedUserValue] = i_check_and_adapt_type(stSettings.(sSetting), stNewSettings.(sSetting));
                if bSameType
                    stSettings.(sSetting) = xAdaptedUserValue;
                else
                    if ~isempty(xEnv)
                        sStr = sprintf( ...
                            ['Trying to set value type "%s" instead of "%s" for setting "%s". ', ...
                            'This change is invalid and will not be applied.'], ...
                            class(stNewSettings.(sSetting)), class(stSettings.(sSetting)), sNestedSetting);
                        xEnv.addMessage('EP:SLC:WARNING', 'msg', sStr);
                    end
                end
            end
        end
    else
        if ~isempty(xEnv)
            sStr = sprintf('Unknown setting "%s" found.', sNestedSetting);
            xEnv.addMessage('EP:SLC:WARNING', 'msg', sStr);
        end
    end
end
end

%%
function bIsIntermediateSetting = i_is_intermediate_and_valid(sSetting, casKnownIntermediateSettings, stSettings, stNewSettings)
bIsIntermediateSetting = false;
for i = 1:numel(casKnownIntermediateSettings)
    if strcmp(casKnownIntermediateSettings{i}, sSetting)
        bIsIntermediateSetting = true;
        break;
    end
end
% note: intermediate setting can only be treated as intermediate if the values for both setting-sets are stored as struct !!
bIsIntermediateSetting = bIsIntermediateSetting ...
    && isstruct(stSettings.(sSetting)) ...
    && isstruct(stNewSettings.(sSetting));
end

%%
function [bSameType, xUserValue] = i_check_and_adapt_type(xDefValue, xUserValue)
bSameType = false;

% 1. same type (normal case)
if isequal(class(xDefValue), class(xUserValue))
    bSameType = true;
    return;
end

% 2. xDefValue is a char
if ischar(xDefValue)
    if isempty(xUserValue)
        bSameType = true;
        xUserValue = ''; % 'x' - [] or {}  ->  ''
    else
        if iscell(xUserValue) && numel(xUserValue) == 1
            bSameType = true;
            xUserValue = xUserValue{1};  % 'x' - {'y'} -> 'y'
        else
            bSameType = false; %'x' - {'y', 'yy'} -> nok
        end
    end
    return;
end

% 3. xDefValue is a cell
if iscell(xDefValue)
    if isempty(xUserValue)
        bSameType = true;
        xUserValue = {};
    else
        if ischar(xUserValue)
            bSameType = true;
            xUserValue = {xUserValue};
        end
    end
    return;
end

% 4. defValue = [] - actually, should never happen!! but since underspecified, no type can be checked --> alow override
if isempty(xDefValue)
    bSameType = true;
    return;
end
end


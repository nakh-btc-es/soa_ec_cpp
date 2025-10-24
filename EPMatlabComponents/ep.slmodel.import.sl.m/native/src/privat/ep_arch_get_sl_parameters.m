function stResult = ep_arch_get_sl_parameters(xEnv, sModelName)
% Returns possible Simulink parameters used inside the provided model.
%
% function stResult = ep_arch_get_sl_parameters(xEnv, sModelName)
%
%  INPUT             DESCRIPTION
%  - xEnv            (Object)     Environment.
%  - sModelName      (Object)     The name of the model.
%
%  OUTPUT            DESCRIPTION
%  - stResult        (Struct)     The result of the parameters.
%      .casName      (cell array) Names of the variables
%      .casClass     (cell array) Classes of the variables
%      .casType      (cell array) Types of the variables
%


%%
astParameters = i_getParameters(xEnv, sModelName);
if isempty(astParameters)
    stResult = struct ( ...
        'casName',  [],...
        'casClass', [], ...
        'casType',  []);
else
    stResult = struct( ...
        'casName',  {{astParameters(:).sName}}, ...
        'casClass', {{astParameters(:).sStructureKind}}, ...
        'casType',  {{astParameters(:).sClass}});
end
end


%%
function astParameters = i_getParameters(xEnv, sModelName)
stResult = ep_model_params_get('Environment', xEnv, 'ModelContext', sModelName);
astParameters = arrayfun(@i_translateParam, stResult.astParams);
end


%%
function stParam = i_translateParam(stLegacyParam)
bIsSimulinkParam = ...
    ~i_isBuiltinType(stLegacyParam.sClass) && ~strcmp(stLegacyParam.sType, stLegacyParam.sClass);
if bIsSimulinkParam
    stParam = struct( ...
        'sName',          stLegacyParam.sName, ...
        'sClass',         stLegacyParam.sType, ...
        'sStructureKind', stLegacyParam.sClass);
else
    stParam = struct( ...
        'sName',          stLegacyParam.sName, ...
        'sClass',         stLegacyParam.sClass, ...
        'sStructureKind', i_getStructureKind(stLegacyParam));
end
end


%%
function sStructureKind = i_getStructureKind(stLegacyParam)
aiWidth = stLegacyParam.aiWidth;
if (aiWidth(1) == 1 && aiWidth(2) == 1)
    sClassKind = 'Simple';
elseif (aiWidth(1) > 1 && aiWidth(2) > 1)
    sClassKind = 'Matrix';
else
    sClassKind = 'Array';
end
sStructureKind = sprintf('%s (%dx%d)', sClassKind, aiWidth(1), aiWidth(2));
end


%%
function bIsBuiltIn = i_isBuiltinType(sCheckType)
persistent stTypes;

if isempty(stTypes)
    stTypes = struct(  ...
        'double',  true, ...
        'single',  true, ...
        'int8',    true, ...
        'uint8',   true, ...
        'int16',   true, ...
        'uint16',  true, ...
        'int32',   true, ...
        'uint32',  true, ...
        'boolean', true, ...
        'logical', true);
end
bIsBuiltIn = ~isempty(sCheckType) && ischar(sCheckType) && isfield(stTypes, sCheckType);
end

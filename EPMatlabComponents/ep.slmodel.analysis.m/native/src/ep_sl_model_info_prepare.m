function stSlModel = ep_sl_model_info_prepare(xEnv, stArgs)
% Analyses a pure SL model and returns a data structure describing it fully.
%
% function stSlModel = ep_sl_model_info_prepare(xEnv, stArgs)
%
%   INPUT               DESCRIPTION
%        ... TODO ...
%
%


%% debug options
if (nargin < 1)
    [xEnv, stArgs] = i_getDebugArgs();
end

%% main

stSlModel = i_analyseModel(xEnv, stArgs);
i_addVariantSubsystemWarnings(xEnv, stSlModel);
end


%%
function stSlModel = i_analyseModel(xEnv, stArgs)
clear ep_sl_type_info_get; % clear internal cache

stEnvLegacy = ep_core_legacy_env_get(xEnv);
stOpt = i_translateToLegacy(stArgs);
stSlModel = ep_sl_legacy_model_info_prepare(stEnvLegacy, stOpt);
stSlModel.astSlFunctions = ep_model_slfunctions_get(stArgs.Model);

stSlModel.astTypeInfos = ep_sl_type_info_get();
end


%%
function stLegacyArgs = i_translateToLegacy(stArgs)
stLegacyArgs = struct( ...
    'sModel',         stArgs.Model, ...
    'sCalMode',       'explicit', ...
    'sDispMode',      'all', ...
    'sDsmMode',       'all', ...
    'sAddModelInfo',  stArgs.AddModelInfoFile);
if ~strcmp(stArgs.ParameterHandling, 'ExplicitParam')
    stLegacyArgs.sCalMode = 'none';
end

if strcmp(stArgs.TestMode, 'BlackBox')
    stLegacyArgs.sDispMode = 'none';
end
if isfield(stArgs, 'ParamSearchFunc')
    stLegacyArgs.hParamSearchFunc = stArgs.ParamSearchFunc;
end
end


%%
function i_addVariantSubsystemWarnings(xEnv, stModel)
for i = 1:length(stModel.astSubsystems)
    sSubsysPath = stModel.astSubsystems(i).sPath;

    % check if parent subsystem is a variant subsystem if the current subsystem is the active one
    % (otherwise it would not be in the list)
    sParentSub = get_param(sSubsysPath, 'Parent');
    if isempty(sParentSub)
        continue;
    end
    
    sActiveVariant = i_getActiveVariant(sParentSub);
    if isempty(sActiveVariant)
        continue;
    end
        
    sCondition = sActiveVariant;
    if isvarname(sActiveVariant)
        oModelContext = EPModelContext.get(sParentSub);
        oActiveVariant = oModelContext.getVariable(sActiveVariant);
        if isa(oActiveVariant, 'Simulink.Variant')
            sCondition = oActiveVariant.Condition;
        end
    end
    xEnv.addMessage('EP:EPSLIMP:VARIANT_SUBSYSTEM_IMPORTED', 'subsystem', sSubsysPath, 'condition', sCondition);
end
end


%%
function sActiveVariant = i_getActiveVariant(sParentSub)
sActiveVariant = '';

stObjParams = get_param(sParentSub, 'ObjectParameters');
if (isfield(stObjParams, 'Variant') &&  strcmp('on', get_param(sParentSub, 'Variant')))
    bIsLowML = verLessThan('matlab', '9.6'); % ML < ML2019a
    if bIsLowML
        sAttribName = 'ActiveVariant';
        if isfield(stObjParams, sAttribName)
            sActiveVariant = get_param(sParentSub, sAttribName);
        end
    else
        sAttribName = 'CompiledActiveChoiceControl';
        try
            sParamValue = get_param(sParentSub, sAttribName);
        catch
            sParamValue = [];
        end
        if ~isempty(sParamValue)
            sActiveVariant = sParamValue;
        end
    end
    
end
end


%%
function [xEnv, stArgs] = i_getDebugArgs()
xEnv = EPEnvironment();

stArgs = struct( ...
    'Model',              bdroot(), ...
    'AddModelInfoFile',   '', ...
    'ParameterHandling',  'ExplicitParam', ...
    'TestMode',           'GreyBox', ...
    'oOnCleanupClearEnv', onCleanup(@() xEnv.clear()));
end

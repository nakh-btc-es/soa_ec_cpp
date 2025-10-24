function astSubsystems = ep_model_subsystems_get(varargin)
% Returns the Subsystems of a Simulink model. 
%
% function astSubsystems = ep_model_subsystems_get(varargin)
%
%   INPUT               DESCRIPTION
%       varargin           (key-values)   arbitrary number of key-value pairs
%
%  -------- KEY ---------- VALUE ---------------------------------------------------------------------------------------
%         Environment      (object)          EPEnvirionment object
%         ModelContext     (string/handle)   name/handle of a model or path/handle of a model block
%         SubsystemFilter  (handle)          Optional callback function for filtering subsystems. If not given, a default
%                                            filter will be used
%
%
%   OUTPUT              DESCRIPTION
%       astSubsystems      (array)           structs with following info:
%         .sName           (string)            name of the Local's block
%         .iParentID       (number)            ID number of the parent scope (might be empty for root subsystems)
%         .iID             (number)            ID number
%         .sClass          (string)            class of the subsystem block
%         .sSFClass        (string)            SF-class of the subsystem block
%         .sPath           (string)            real model path of the Local's block
%         .sVirtualPath    (string)            the virtual model path of the Local's block
%
%   REMARKS
%     Provided Model is assumed to be open.
%
%   <et_copyright>


%%
[stEnv, stOpt] = i_evalArgs(varargin{:});
astSubsystems = atgcv_m01_model_subsystems_get(stEnv, stOpt);
end


%%
function [stEnv, stOpt] = i_evalArgs(varargin)
stEnv = 0;
stOpt = struct();

caxKeyValues = varargin;
if (mod(length(caxKeyValues), 2) ~= 0)
    error('EP:MODEL_ANA:USAGE_ERROR', 'Number of key-values is inconsistent.');
end
for i = 1:2:length(caxKeyValues)
    sKey   = caxKeyValues{i};
    xValue = caxKeyValues{i + 1};
    
    switch lower(sKey)
        case 'environment'
            stEnv = ep_core_legacy_env_get(xValue);

        case 'modelcontext'
            stOpt.sModelContext = xValue;
            
        case 'subsystemfilter'
            stOpt.hSubsystemFilter = xValue;
        otherwise
            error('EP:MODEL_ANA:USAGE_ERROR', 'Unknown key "%s".', sKey);
    end
end
%default for wrapper use-case
stOpt.bUseRoot = false;
end

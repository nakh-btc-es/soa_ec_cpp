function stResult = ep_model_params_get(varargin)
% Returns the Parameters of a Simulink model. 
%
% function stResult = ep_model_params_get(varargin)
%
%   INPUT               DESCRIPTION
%       varargin           (key-values)   arbitrary number of key-value pairs
%
%  -------- KEY ---------- VALUE ---------------------------------------------------------------------------------------
%         Environment               (object)          EPEnvirionment object
%         ModelContext              (string/handle)   name/handle of a model or path/handle of a model block
%                                                     Note: it is assumed that the model is already loaded in memory
%         IncludeModelWorkspace     (boolean)         flag if model worspace parameters shall be considered
%                                                     (default is true for ML versions >= ML2017b, otherwise false)
%         Parameters                (strings)         white list of parameter names to be considered
%         SearchMethod              (string)          'compiled' | 'cached' (default=compiled) 
%
%
%   OUTPUT              DESCRIPTION
%       stResult              (struct)  the result struct
%         .astParams          (array)     structs with following info:
%           .sName            (string)      name of Parameter in workspace as used for EP 
%                                           (note: specifically for model workspace parameters the name of the model is 
%                                           prepended with a colon-char like this: "<model-name>:<raw-param-name>")
%           .sRawName         (string)      name of Parameter in workspace as used in model
%           .sSource          (string)      'base workspace' | '<name-of-SLDD>'
%           .sSourceType      (string)      'base workspace' | 'data dictionary' | 'model workspace'
%           .sSourceAccess    (string)      optional path information needed to access the paramter
%           .bIsModelArg      (boolean)     true, if the parameter is a model workspace parameter that is marked as model
%                                           argument also
%           .sSourceAccess    (string)      optional path information needed to access the paramter
%           .sClass           (string)      class of Parameter (default: double)
%           .sType            (string)      type of Parameter (default: double)
%           .aiWidth          (array)       parameter's dimensions
%           .astBlockInfo     (array)       structs with following info:
%             .sPath          (string)        model path of block
%             .sBlockType     (string)        type of block
%             .stUsage        (string)        struct with usages in Block as fieldnames
%                .(<Usage>)   (string)          expression in block where Variable is used
%         .casMissing         (strings)   all parameters that have bee provided as a whitelist but were not found
%                                         inside the model
%
%   REMARKS
%     Provided Model is assumed to be open.
%


%%
[stEnv, stOpt] = i_evalArgs(varargin{:});
[astParams, casMissing] = atgcv_m01_model_params_get(stEnv, stOpt);
stResult = struct( ...
    'astParams',  astParams, ...
    'casMissing', {casMissing});
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
            
        case 'includemodelworkspace'
            stOpt.bIncludeModelWS = xValue;
            
        case 'parameters'
            stOpt.casParamNames = xValue;
            
        case 'searchmethod'
            stOpt.SearchMethod = xValue;
            
        otherwise
            error('EP:MODEL_ANA:USAGE_ERROR', 'Unknown key "%s".', sKey);
    end
end
end

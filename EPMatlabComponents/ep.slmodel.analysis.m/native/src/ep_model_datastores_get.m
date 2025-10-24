function astDsms = ep_model_datastores_get(varargin)
% Returns the Datastores of a Simulink model.
%
% function astDsms = ep_model_datastores_get(varargin)
%
%   INPUT               DESCRIPTION
%       varargin           (key-values)   arbitrary number of key-value pairs
%
%  -------- KEY ---------- VALUE ---------------------------------------------------------------------------------------
%         Environment      (object)          EPEnvirionment object
%         ModelContext     (string/handle)   name/handle of a model or path/handle of a model block
%                                            Note: it is assumed that the model is already loaded in memory
%         SearchMethod     (string)          'compiled' | 'cached' (default=compiled) 
%
%
%   OUTPUT              DESCRIPTION
%       astDsms            (array)   structs with following info:
%         .sName           (string)    name of the DataStore
%         .sPath           (string)    path of the DataStoreMemory block (empty for global DataStores)
%         .sVirtualPath    (string)    virtual path of the DataStoreMemory block (empty for global DataStores)
%         .astUsingBlocks  (array)     structs with following info:
%            .sPath        (string)      path of the block using the DataStore
%            .sVirtualPath (string)      virtual path of the block using the DataStore
%            .sBlockType   (string)      type of the block using the DataStore
%            .bIsReader    (boolean)     true, if the block is a reader of the DataStore; otherwise false
%            .bIsWriter    (boolean)     true, if the block is a writer of the DataStore; otherwise false
%
%   REMARKS
%     Provided Model is assumed to be open.
%


%%
[stOpt, stEnv] = i_evalArgs(varargin{:});
astDsms = atgcv_m01_model_datastores_get(stEnv, stOpt);
end


%%
function [stOpt, stEnv] = i_evalArgs(varargin)
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
            
        case 'searchmethod'
            stOpt.SearchMethod = xValue;
            
        otherwise
            error('EP:MODEL_ANA:USAGE_ERROR', 'Unknown key "%s".', sKey);
    end
end

if ~isfield(stOpt, 'sModelContext')
    stOpt.sModelContext = bdroot;
end
end

function [stResult, oEx] = sltu_deviations_analyze(stTestData, varargin)
% Utility function to perform extraction and deviation analysis in one step.

oEx = [];

stArgs = i_evalArgs(stTestData, varargin{:});
try
    caxArgs = i_transformBackToKeyVals(stArgs);
    stResultDA = ep_deviations_analyze(caxArgs{:});
        
catch oEx
    % in case the caller is not expecting an exception, just rethrow it; otherwise return robustly
    if (nargout < 3)
        rethrow(oEx);
    else
        stResult = [];
        return;
    end
end

stResult = struct( ...
    'stResultDA', stResultDA, ...
    'sBlockOutGraphFile', stArgs.BlockOutGraphFile);
end


%%
function stArgs = i_evalArgs(stTestData, varargin)
casValidKeys = { ...
    'ModelFile', ...
    'InitScript', ...
    'ActivateMil', ...
    'InitModel', ...
    'ExtractionModelFile', ...
    'ExtractionModel', ...
    'ExtractionScript',...
    'ExtractionMessageFile', ...
    'DeviationSignalIds', ...
    'VectorPath', ...
    'BlockOutGraphFile', ...
    'MessageFile', ...
    'Progress'};

stArgs = ep_core_transform_args(varargin, casValidKeys);
stArgs = i_enhanceWithDefaults(stTestData, stArgs);
end


%%
function sFile = i_addPrefix(sFile, sPrefix)
[p, f, e] = fileparts(sFile);
sFile = fullfile(p, [sPrefix, f, e]);
end


%%
function stArgs = i_enhanceWithDefaults(stTestData, stArgs)
stDefaultArgs = struct( ...
    'ModelFile',                stTestData.sModelFile, ...
    'InitScript',               stTestData.sInitScriptFile, ...
    'ExtractionModelFile',      stTestData.sExtractionModelFile, ...
    'ExtractionMessageFile',    i_addPrefix(stTestData.sMessageFile, 'extr_'), ...
    'MessageFile',              stTestData.sMessageFile, ...
    'InitModel',                true, ...
    'ActivateMil',              false, ...
    'ExtractionModel',          '', ...
    'ExtractionScript',         '', ...
    'VectorPath',               stTestData.sTestRootData, ...
    'BlockOutGraphFile',        stTestData.sBlockOutGraphFile, ...
    'Progress',                 ep.core.ipc.matlab.server.progress.impl.ProgressImpl());

casDefaultArgNames = fieldnames(stDefaultArgs);
for i = 1:numel(casDefaultArgNames)
    sArgName = casDefaultArgNames{i};
    
    if ~isfield(stArgs, sArgName)
        stArgs.(sArgName) = stDefaultArgs.(sArgName);
    end
end
end


%%
function caxArgs = i_transformBackToKeyVals(stArgs)
casKeys = fieldnames(stArgs);
nKeys = numel(casKeys);

caxArgs = cell(1, nKeys);
for i = 1:numel(casKeys)
    sKey = casKeys{i};
    
    caxArgs{2*i - 1} = sKey;
    caxArgs{2*i} = stArgs.(sKey);    
end
end



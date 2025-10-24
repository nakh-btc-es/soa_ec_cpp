function xOnCleanupCloseModels = sltu_load_models(xEnv, varargin)
% Load model(s) via API for UnitTests. Note that _no_ explicit upgrade is done.
%
%  function xOnCleanupCloseModels = sltu_load_models(xEnv, varargin)
% 
% Two operating modes using varargin:
%
%   1) Opening just one Model
%         xOnCleanupCloseModels = sltu_load_models(xEnv, sModelFile, sInitFile, bIsTL)
%
%  
%   2) Opening multiple Models
%         xOnCleanupCloseModels = sltu_load_models(xEnv, caxArgs1, caxArgs2, ...)
%
%
%


%%
if (nargout < 1)
    error('SLTU:LOAD_MODELS:ERROR', ...
        'Function needs to return an output object for automatically closing the models (onClenaup mechanism).');
end

%% check operating mode and normalize
if iscell(varargin{1})
    ccaxArgs = varargin;
else
    ccaxArgs = {varargin};
end

nModels = length(ccaxArgs);

stEnv = ep_core_legacy_env_get(xEnv, false);
caxCloseModels = cell(1, nModels);
for i = 1:nModels
    caxArgs = ccaxArgs{i};    
    caxCloseModels{i} = i_openModel(stEnv, caxArgs{:});
end

if (nModels > 1)
    % use one single common onCleanupHandle instead of all individual cleanup handles
    xOnCleanupCloseModels = onCleanup(@() cellfun(@delete, caxCloseModels));
else
    xOnCleanupCloseModels = caxCloseModels{1};
end
end


%%
function xOnCleanupCloseModel = i_openModel(stEnv, sModelFile, sInitFile, bIsTL)
if (nargin < 4)
    bIsTL = true;
    if (nargin < 3)
        sInitFile = '';
    end
end
if isempty(sInitFile)
    casInitFiles = {};
else
    casInitFiles = {sInitFile};
end

% main
try
    bCheck = true;
    stOpen = atgcv_m_model_open(stEnv, sModelFile, casInitFiles, bIsTL, bCheck);
    xOnCleanupCloseModel = onCleanup(@() i_closeModel(stEnv, stOpen));

catch oEx
    MU_FAIL_FATAL(sprintf('Unexpected exception during opening: "%s".', oEx.message));
end
end


%%
function i_closeModel(stEnv, stOpen)
if sltu_currently_debugging()
    warning('UT:DEBUG', '%s: Currently in DEBUG mode: no cleanup done!', mfilename);
    return;
end
atgcv_m_model_close(stEnv, stOpen);
end

function xOnCleanupCloseModels = ut_open_model(xEnv, varargin)
% Open model(s) via API for ModelAnalysis UnitTests.
%
%  function xOnCleanupCloseModels = ut_open_model(xEnv, varargin)
% 
% Two operating modes using varargin:
%
%   1) Opening just one Model
%         xOnCleanupCloseModels = ut_open_model(xEnv, sModelFile, sInitFile, bIsTL)
%
%  
%   2) Opening multiple Models
%         xOnCleanupCloseModels = ut_open_model(xEnv, caxArgs1, caxArgs2, ...)
%
%
%

%% check operating mode and normalize
if iscell(varargin{1})
    ccaxArgs = varargin;
else
    ccaxArgs = {varargin};
end

nModels = length(ccaxArgs);
for i = 1:nModels
    caxArgs = ccaxArgs{i};
    i_upgradeModel(caxArgs{:});
end

% if no output argument expected, do not open the model at all (just use the upgrade functionality)
if (nargout < 1)
    return;
end

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
% Note: varargin arguments to be ignored
function i_upgradeModel(sModelFile, sInitFile, varargin)
if (nargin < 2)
    sInitFile = '';
end
try
    if isempty(sInitFile)
        ut_tu_test_model_adapt(sModelFile);
    else
        ut_tu_test_model_adapt(sModelFile, sInitFile);
    end
catch oEx
    MU_FAIL_FATAL(sprintf('Unexpected exception during upgrade: "%s".', oEx.message));
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
if ut_currently_debugging()
    warning('UT:DEBUG', '%s: Currently in DEBUG mode: no cleanup done!', mfilename);
    return;
end
atgcv_m_model_close(stEnv, stOpen);
end

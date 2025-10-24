function [bHookFound, varargout] = ep_core_eval_hook(sHookName, varargin)
%  Executes the hook function, if it is found, with the provided arguments.
%
%     function [bHookFound, varargout] = ep_core_eval_hook(sHookName, varargin)
%
%   INPUT               DESCRIPTION
%   - sHookName         (fixed string)      name of the hook function (without extension)
%   - varargin          (any)               arguments that are passed uninterpreted into the hook function
%
%   OUTPUT              DESCRIPTION
%   - bHookFound        (boolean)           flag, if a hook function has been found or not
%   - varargout         (any)               outputs that are returned uninterpreted from the hook function
%
%


%%
if ((nargin < 1) || ~isvarname(sHookName))
    error('EP:CORE:WRONG_USAGE', 'Expecting the name of the hook function as the first argument.');
end

sHookScript = i_findHookScript(sHookName);
bHookFound = ~isempty(sHookScript);

nVarArgsOut = nargout - 1;
if bHookFound
    xOnCleanupRestoreSearchPath = i_extendSearchPathIfNeeded(sHookScript); %#ok<NASGU> onCleanup object
    [varargout{1:nVarArgsOut}] = feval(sHookName, varargin{:});
else
    varargout = cell(1, nVarArgsOut);
end
end


%%
function xOnCleanupRestoreSearchPath = i_extendSearchPathIfNeeded(sHookScript)
xOnCleanupRestoreSearchPath = [];
[sDir, sCmd] = fileparts(sHookScript);
sCurrentScript = which(sCmd);
if (isempty(sCurrentScript) || ~strcmpi(sCurrentScript, sHookScript))
    addpath(sDir);
    rehash;
    xOnCleanupRestoreSearchPath = onCleanup(@() rmpath(sDir));
end
end


%%
function sHookScript = i_findHookScript(sHookName)
sHookScript = i_findFirstExecutableMatchingSpecInDirs(i_getHookDirs(), [sHookName, '.*']);
end


%%
function sExecutable = i_findFirstExecutableMatchingSpecInDirs(casDirs, sSpec)
casExecutableExtensions = {'.m', '.p', ['.', mexext()]};

sExecutable = '';
for k = 1:length(casDirs)
    sDir = casDirs{k};
    
    astFoundFiles = dir(fullfile(sDir, sSpec));
    for i = 1:length(astFoundFiles)
        stFile = astFoundFiles(i);
        
        if ~stFile.isdir
            [~, ~, sExt] = fileparts(stFile.name);
            if any(strcmp(sExt, casExecutableExtensions))
                sExecutable = fullfile(sDir, stFile.name);
                return;
            end
        end
    end
end
end


%%
function casHookDirs = i_getHookDirs()
casHookDirs = {};

sDynamicHookDir = i_getDynamicHookDir();
if ~isempty(sDynamicHookDir)
    casHookDirs{end + 1} = sDynamicHookDir;
end
casHookDirs{end + 1} = ep_core_path_get('EP_HOOKS');
end


%%
function sConfirmedDynamicHookDir = i_getDynamicHookDir()
sConfirmedDynamicHookDir = '';

sSpecifiedDynamicHookDir = getenv('EP_DYNAMIC_HOOK_DIR');
if isempty(sSpecifiedDynamicHookDir)
    return;
end

sSpecifiedDynamicHookDir = ep_core_canonical_path(sSpecifiedDynamicHookDir);
if isfolder(sSpecifiedDynamicHookDir)
    sConfirmedDynamicHookDir = sSpecifiedDynamicHookDir;
end
end

function varargout = ep_core_tl_get_config_path(sMode)
%  Extends the TL functionality "tl_get_config_path" with additional paths.
%
%  Note: Function can be used in two modes that are triggered by the input string.
%
%  ---------------------------------------------------------------------------------------------------------------------
%   Direct Mode: used by EP to replace the original "tl_get_config_path" with own extended version
%
%     xOnCleanupRemoveExtension = ep_core_tl_get_config_path('extend')
%
%   INPUT               DESCRIPTION
%   - sMode               (fixed string)    'extend'
%
%   OUTPUT              DESCRIPTION
%   - xOnCleanupRemoveExtension (obj)       onCleanup object that will revert the extension when cleared from workspace
%                                           NOTE: if the extension is not really needed, because there are no additional
%                                                 hook scripts, the object is empty ([])
%
%  ---------------------------------------------------------------------------------------------------------------------
%   Indirect Mode: used by TL to return the extended TL config paths
%
%     casPaths = ep_core_tl_get_config_path('default')
%
%   INPUT               DESCRIPTION
%   - sMode          (fixed string)    'default' (Note: string can also also be omitted from call)
%
%   OUTPUT              DESCRIPTION
%   - casPaths             (string)    all TL config as currently "seen" by the TL functionality
%
%
%
% $$$COPYRIGHT$$$-2017


%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%%
if (nargin < 1)
    sMode = 'default';
end

sCmd = 'tl_get_config_path';
if strcmpi(sMode, 'extend')
    if i_isExtensionNeeded()
        varargout{1} = i_extendConfigPaths(sCmd);
    else
        varargout{1} = [];
    end
else
    varargout{1} = i_getAllConfigPaths(sCmd);
end
end


%%
function xOnCleanupRestoreConfigPaths = i_extendConfigPaths(sCmd)
xOnCleanupRemoveStub = i_establishStub(sCmd);
xOnCleanupRestoreSearchPath = i_extendMatlabSearchPath(sCmd);

xOnCleanupRestoreConfigPaths = onCleanup(@() cellfun(@delete, {xOnCleanupRemoveStub, xOnCleanupRestoreSearchPath}));
end


%%
function xOnCleanupRestoreSearchPath = i_extendMatlabSearchPath(sCmd)
casExtendedPaths = i_getExtendedPaths();
cellfun(@addpath, casExtendedPaths);

xOnCleanupRestoreSearchPath = onCleanup(@() i_removeSearchPathsIfNotNeeded(casExtendedPaths, sCmd));
end


%%
function i_removeSearchPathsIfNotNeeded(casPaths, sCmd)
if ~i_isStubActive(sCmd)
    cellfun(@rmpath, casPaths);
end
end


%%
function bIsActive = i_isStubActive(sCmd)
sScript = which(sCmd);
bIsActive = i_isStubScript(sScript);
end


%%
function xOnCleanupRemoveStub = i_establishStub(sCmd)
sTmpDir = fullfile(EPEnvironment.getTempDirectory, 'btc_stub'); % unique dir with marker name
mkdir(sTmpDir);
i_writeCmdStubFile(fullfile(sTmpDir, [sCmd, '.m']));
addpath(sTmpDir);
rehash;
xOnCleanupRemoveStub = onCleanup(@() i_removeStub(sTmpDir));
end


%%
function i_writeCmdStubFile(sCmdFile)
sReplacementCmd = mfilename;

[~, sCmd] = fileparts(sCmdFile);
hFid = fopen(sCmdFile, 'wt');
if (hFid > 0)
    xOnCleanupClose = onCleanup(@() fclose(hFid));
    
    fprintf(hFid, 'function cfgPath = %s\n', sCmd);
    fprintf(hFid, '%% STUB: replacement by BTC used for extending the TL functionality\n\n');
    fprintf(hFid, 'cfgPath = %s();\n', sReplacementCmd);
    fprintf(hFid, 'end\n');
end
end


%%
function i_removeStub(sTmpDir)
rmpath(sTmpDir);
rehash;
rmdir(sTmpDir, 's');
end


%%
function casPaths = i_getAllConfigPaths(sCmd)
casScripts = which(sCmd, '-all');

bIsCalledFromStub = i_isCalledFromCmd(sCmd);
if bIsCalledFromStub
    sThisScript = casScripts{1};
    xOnCleanupRestore = i_temporarilyHideScriptFromMatlab(sThisScript); %#ok<NASGU> onCleanup object
    
    casScripts(1) = [];
end

bIsOrig = isempty(casScripts) || ~i_isStubScript(casScripts{1});
if bIsOrig
    casExtendedPaths = i_getExtendedPaths();
    if ~isempty(casScripts)
        casOrigPaths = feval(sCmd);
        if ~iscell(casOrigPaths)
            casOrigPaths = {casOrigPaths};
        end
    else
        casOrigPaths = i_getTlConfigDefaultPaths();
    end
    casPaths = [reshape(casExtendedPaths, [], 1); reshape(casOrigPaths, [], 1)];
else
    casPaths = feval(sCmd);
end
end


%%
function bIsStubScript = i_isStubScript(sScriptFile)
[~, sParentDirName] = fileparts(fileparts(sScriptFile));
bIsStubScript = strcmpi(sParentDirName, 'btc_stub');
end


%%
function casDefaultPaths = i_getTlConfigDefaultPaths()
sPwd = pwd;
casDefaultPaths = {sPwd; fullfile(sPwd, 'config')};
end


%%
function bHideTlConfigScript = i_isCalledFromCmd(sCmd)
bHideTlConfigScript = false;

astStack = dbstack;
for i = 1:length(astStack)
    if strcmp(sCmd, astStack(i).name)
        bHideTlConfigScript = true;
        return;
    end
end
end


%%
function casPaths = i_getExtendedPaths()
sTlHookPath = ep_core_path_get('TL_HOOKS');
if (~isempty(sTlHookPath) && exist(sTlHookPath, 'dir'))
    casPaths = {sTlHookPath};
else
    casPaths = {};
end
end


%%
function bIsNeeded = i_isExtensionNeeded()
bIsNeeded = ~isempty(i_getExtendedPaths());
end


%%
function xOnCleanupRestore = i_temporarilyHideScriptFromMatlab(sScriptFile)
[~, sCmd] = fileparts(sScriptFile);

sHiddenFile = [sScriptFile, '.hidden'];
movefile(sScriptFile, sHiddenFile);
clear(sCmd);
rehash;
xOnCleanupRestore = onCleanup(@() i_restoreHiddenFile(sHiddenFile, sScriptFile));
end


%%
function i_restoreHiddenFile(sHiddenFile, sOrigFile)
[~, sCmd] = fileparts(sOrigFile);

movefile(sHiddenFile, sOrigFile);
clear(sCmd);
rehash;
end

function ut_extend_tl_get_config_path
% Tests if the extending the TL config path is working as expected.
%
%  function ut_extend_tl_get_config_path()
%
%
% $$$COPYRIGHT$$$-2017

%%
if ~exist('dsdd', 'file')
    MU_MESSAGE('TEST SKIPPED: TL functionality is not available.');
    return;
end

%% prepare
xOnCleanupRemoveStubHookDir = i_createStubHookDirGet(); %#ok<NASGU> onCleanup object

sOrigMatlabPath = path;
MU_ASSERT_PATH_NOT_CHANGED = @() MU_ASSERT_TRUE(strcmpi(path, sOrigMatlabPath), 'Matlab path has changed!');


%% test
try
    i_setHookDir(''); % use-case: no valid hook dir found
    
    casOrigPathsBefore = i_getTlConfigPaths();    
    casExtendedPaths   = i_getExtendedPaths();
    casOrigPathsAfter  = i_getTlConfigPaths();    
    
    MU_ASSERT_TRUE(isequal(casOrigPathsBefore, casExtendedPaths), ...
        'Empty-string hook path: Original paths and extended paths shall be the same.')
    MU_ASSERT_TRUE(isequal(casOrigPathsAfter, casOrigPathsBefore), 'Extension shall be *temporary*.')
    
    feval(MU_ASSERT_PATH_NOT_CHANGED);
catch oEx
    MU_FAIL(sprintf('Unexpected error:\n%s', oEx.message));
end


%% test
try
    sDir = tempname(pwd);
    i_setHookDir(sDir); % use-case: non existing path
    
    casOrigPathsBefore = i_getTlConfigPaths();    
    casExtendedPaths   = i_getExtendedPaths();
    casOrigPathsAfter  = i_getTlConfigPaths();    
    
    MU_ASSERT_TRUE(isequal(casOrigPathsBefore, casExtendedPaths), ...
        'Non-existing hook path: Original paths and extended paths shall be the same.')
    MU_ASSERT_TRUE(isequal(casOrigPathsAfter, casOrigPathsBefore), 'Extension shall be *temporary*.')
    
    feval(MU_ASSERT_PATH_NOT_CHANGED);
catch oEx
    MU_FAIL(sprintf('Unexpected error:\n%s', oEx.message));
end


%% test
try
    sDir = tempname(pwd);
    mkdir(sDir);
    i_setHookDir(sDir); % use-case: existing path
    
    casOrigPathsBefore = i_getTlConfigPaths();    
    [casExtendedPaths, abOnSearchPath] = i_getExtendedPaths();
    casOrigPathsAfter  = i_getTlConfigPaths();    
    
    if (length(casOrigPathsBefore) < length(casExtendedPaths))
        MU_ASSERT_TRUE(strcmpi(casExtendedPaths{1}, sDir), ...
            'Existing hook path: First path shall be BTC extension.');
        MU_ASSERT_TRUE(abOnSearchPath(1), ...
            'Existing hook path: First path shall be on the Matlab search path.');
        MU_ASSERT_TRUE(isequal(casOrigPathsBefore, casExtendedPaths(2:end)), ...
            'Existing hook path: Original paths and rest of extended paths shall be the same.')
    else
        MU_FAIL('Extending with existing hook path was not successful.');
    end
    MU_ASSERT_TRUE(isequal(casOrigPathsAfter, casOrigPathsBefore), 'Extension shall be *temporary*.')
    
    feval(MU_ASSERT_PATH_NOT_CHANGED);
catch oEx
    MU_FAIL(sprintf('Unexpected error:\n%s', oEx.message));
end
end



%%
function [casPaths, abOnSearchPath] = i_getExtendedPaths()
xOnCleanupRevertExtension = ep_core_tl_get_config_path('extend'); %#ok<NASGU> onCleanup object
casPaths = i_getTlConfigPaths();

abOnSearchPath = cellfun(@i_assertOnMatlabSearchPath, casPaths);
end


%%
function bFound = i_assertOnMatlabSearchPath(sPath)
mlPath = [lower(path) pathsep lower(pwd) pathsep];
bFound = contains(mlPath, [lower(sPath) pathsep]);
end


%%
function casPaths = i_getTlConfigPaths()
if exist('tl_get_config_path', 'file')
    casPaths = tl_get_config_path();
else
    casPaths = reshape({pwd fullfile(pwd, 'config')}, [], 1);
end
end


%%
function i_setHookDir(varargin)
setenv('UT_EXTEND_TL_CONF_PATH', varargin{:});
end


%%
function xOnCleanupRemoveStub = i_createStubHookDirGet()
sTmpDir = tempname();
mkdir(sTmpDir);

sStubFile = fullfile(sTmpDir, 'ep_core_path_get.m');
i_writeFile(sStubFile, { ...
    'function sPath = ep_core_path_get(varargin)', ...
    'sPath = getenv(''UT_EXTEND_TL_CONF_PATH'');', ...
    'end'});
addpath(sTmpDir);
rehash;
xOnCleanupRemoveStub = onCleanup(@() i_removeStub(sStubFile));
end


%%
function i_writeFile(sFile, casLines)
hFid = fopen(sFile, 'wt');
if (hFid)
    xOnCleanupClose = onCleanup(@() fclose(hFid));
    
    for i = 1:length(casLines)
        fprintf(hFid, '%s\n', casLines{i});
    end
end
end


%%
function i_removeStub(sFile)
[sPath, sCmd] = fileparts(sFile);
clear(sCmd);
try
    rmpath(sPath);
    rehash;
    rmdir(sPath, 's');
    i_setHookDir();
catch oEx
    MU_FAIL(sprintf('Stub path was not removed correctly.\nError:\n%s', oEx.message));
end
end


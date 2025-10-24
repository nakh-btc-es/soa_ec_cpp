function ut_eval_hook
% Tests if evaluating hook functions is working as expected.
%
%  function ut_eval_hook
%
%
% $$$COPYRIGHT$$$-2017


%% prepare
sOrigMatlabPath = path;
MU_ASSERT_PATH_NOT_CHANGED = @() MU_ASSERT_TRUE(strcmpi(path, sOrigMatlabPath), 'Matlab path has changed!');

sTmpHookDir = fullfile(pwd, 'my_tmp_hook_dir');
xOnCleanupRemoveStub = i_createStubHookDirGet(sTmpHookDir); %#ok<NASGU>

%% test
try
    sNonExistingHook = 'ep_hook_some_unknown';
    
    ep_core_eval_hook(sNonExistingHook);
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
    ep_core_eval_hook(sNonExistingHook, 'arg');
    feval(MU_ASSERT_PATH_NOT_CHANGED);

    ep_core_eval_hook(sNonExistingHook, 'arg', [], 0.2, 'some other arg');
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
    
    [bHookFound, xOut] = ep_core_eval_hook(sNonExistingHook);
    MU_ASSERT_FALSE(bHookFound, 'Hook should not have been found.');
    MU_ASSERT_TRUE(isempty(xOut), 'Output of a non-existing hook shall be empty.');
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
    [bHookFound, xOut] = ep_core_eval_hook(sNonExistingHook, 'arg');
    MU_ASSERT_FALSE(bHookFound, 'Hook should not have been found.');
    MU_ASSERT_TRUE(isempty(xOut), 'Output of a non-existing hook shall be empty.');
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
    [bHookFound, xOut] = ep_core_eval_hook(sNonExistingHook, 'arg', [], 0.2, 'some other arg');
    MU_ASSERT_FALSE(bHookFound, 'Hook should not have been found.');
    MU_ASSERT_TRUE(isempty(xOut), 'Output of a non-existing hook shall be empty.');
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
    
    [bHookFound, xOut, xOtherOut] = ep_core_eval_hook(sNonExistingHook);
    MU_ASSERT_FALSE(bHookFound, 'Hook should not have been found.');
    MU_ASSERT_TRUE(isempty(xOut), 'Output of a non-existing hook shall be empty.');
    MU_ASSERT_TRUE(isempty(xOtherOut), 'Output of a non-existing hook shall be empty.');
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
    [bHookFound, xOut, xOtherOut] = ep_core_eval_hook(sNonExistingHook, 'arg');
    MU_ASSERT_FALSE(bHookFound, 'Hook should not have been found.');
    MU_ASSERT_TRUE(isempty(xOut), 'Output of a non-existing hook shall be empty.');
    MU_ASSERT_TRUE(isempty(xOtherOut), 'Output of a non-existing hook shall be empty.');
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
    [bHookFound, xOut, xOtherOut] = ep_core_eval_hook(sNonExistingHook, 'arg', [], 0.2, 'some other arg');
    MU_ASSERT_FALSE(bHookFound, 'Hook should not have been found.');
    MU_ASSERT_TRUE(isempty(xOut), 'Output of a non-existing hook shall be empty.');
    MU_ASSERT_TRUE(isempty(xOtherOut), 'Output of a non-existing hook shall be empty.');
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
catch oEx
    MU_FAIL(sprintf('Unexpected error:\n%s', oEx.message));
end


%% test
try
    sExistingHook = 'ep_hook_for_testing';
    i_createHookFcn(sTmpHookDir,  sExistingHook);
    
    MU_ASSERT_TRUE(isempty(which(sExistingHook)), 'Hook function shall not be directly visible in Matlab.');
    
    ep_core_eval_hook(sExistingHook);
    feval(MU_ASSERT_PATH_NOT_CHANGED);

    xIn1 = 'hello';
    ep_core_eval_hook(sExistingHook, xIn1);
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
    [bHookFound, xOut1] = ep_core_eval_hook(sExistingHook, xIn1);
    MU_ASSERT_TRUE(bHookFound, 'Hook should have been found.');
    MU_ASSERT_TRUE(isequal(xOut1, xIn1), 'Value returned by hook function is unexpected.');
    feval(MU_ASSERT_PATH_NOT_CHANGED);
    
catch oEx
    MU_FAIL(sprintf('Unexpected error:\n%s', oEx.message));
end


%% robustness
try
    ep_core_eval_hook();
    MU_FAIL('Missing exception for WRONG_USAGE.');

catch oEx
    MU_PASS(sprintf('Expected error:\n%s', oEx.message));
end


%% robustness
try
    ep_core_eval_hook([]);
    MU_FAIL('Missing exception for WRONG_USAGE.');

catch oEx
    MU_PASS(sprintf('Expected error:\n%s', oEx.message));
end


%% robustness
try
    ep_core_eval_hook(7.2);
    MU_FAIL('Missing exception for WRONG_USAGE.');

catch oEx
    MU_PASS(sprintf('Expected error:\n%s', oEx.message));
end
end



%%
function i_createHookFcn(sHookDir,  sHookName)
sHookFile = fullfile(sHookDir, [sHookName, '.m']);
i_writeFile(sHookFile, { ...
    sprintf('function varargout = %s(varargin)', sHookName), ...
    'nArgs = nargin;', ...
    'varargout = cell(1, nArgs);', ...
    'for i = 1:nArgs', ...
    '  varargout{i} = varargin{i};', ...
    'end', ...
    'end'})
end


%%
function xOnCleanupRemoveStub = i_createStubHookDirGet(sTmpHookDir)
if exist(sTmpHookDir, 'dir')
    rmdir(sTmpHookDir, 's');
end
mkdir(sTmpHookDir);

sStubFile = fullfile(pwd, 'ep_core_path_get.m');
i_writeFile(sStubFile, { ...
    'function sPath = ep_core_path_get(varargin)', ...
    sprintf('sPath = ''%s'';', sTmpHookDir), ...
    'end'});
xOnCleanupRemoveStub = onCleanup(@() i_removeStubAndDir(sStubFile, sTmpHookDir));
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
function i_removeStubAndDir(sStubFile, sDir)
[~, sCmd] = fileparts(sStubFile);
clear(sCmd);
try
    delete(sStubFile);
    rehash;
catch oEx
    MU_FAIL(sprintf('Stub file was not removed correctly.\nError:\n%s', oEx.message));
end
try
    rmdir(sDir, 's');
catch oEx
    MU_FAIL(sprintf('Directory was not removed correctly.\nError:\n%s', oEx.message));
end
end


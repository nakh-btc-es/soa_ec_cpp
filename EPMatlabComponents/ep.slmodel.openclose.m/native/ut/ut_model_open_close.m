function ut_model_open_close()
% Tests the delegation to the legacy component.
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%% clean up first
ep_tu_cleanup();

%% predefined values
sPwd      = pwd;
sTestRoot = fullfile(sPwd, 'tst_ut_model_open_close');
sEnvVar = 'UT_CHECK_EXTENSION_ESTABLISHED';

%% setup env for test
try
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    ep_tu_mkdir(sTestRoot);
    cd(sTestRoot);
    
    % Generate stubs for model_open and model_close
    xOnCleanupRemoveStub1 = i_createLegacyModelOpenStub();    %#ok<NASGU> onCleanup object
    xOnCleanupRemoveStub2 = i_createLegacyModelCloseStub();   %#ok<NASGU> onCleanup object
    xOnCleanupRemoveStub3 = i_createEpExtensionStub(sEnvVar); %#ok<NASGU> onCleanup object
    
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception during test env setup: "%s".', exception.message));
end


%% test open
try
    setenv(sEnvVar, '');
    
    xEnv = EPEnvironment();
    stInputArgs = struct('sModelFile', 'any.mdl');
    stModelHandle = util_ep_core_model_open(xEnv, stInputArgs);
catch exception
    MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end


%% test close
try
    ep_core_model_close(xEnv, stModelHandle);
    
    sVal = getenv(sEnvVar);
    MU_ASSERT_TRUE(strcmp(sVal, '1'), 'Extension hook was not triggered when opening/closing model.');
    
catch exception
    MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end
setenv(sEnvVar, '');


%% clean
try
    xEnv.clear();
    cd(sPwd);
    ep_tu_cleanup();
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
catch oEx
    warning('UT:BROKEN', '%s', oEx.message);
end
end



%%
function xOnCleanupRemoveStub = i_createEpExtensionStub(sEnvVar)
xOnCleanupRemoveStub = i_createStub('ep_core_tl_get_config_path', ...
    ['varargout{1} = onCleanup(@() setenv(''', sEnvVar, ''', ''1''));\n']);
end


%%
function xOnCleanupRemoveStub = i_createLegacyModelOpenStub()
xOnCleanupRemoveStub = i_createStub('atgcv_m_model_open', ...
    ['MU_ASSERT_TRUE(isstruct(varargin{1}), ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(strcmp(varargin{2}, ''any.mdl''), ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(isempty(varargin{3}), ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(varargin{4} == true, ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(varargin{5} == true, ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(isempty(varargin{6}), ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(varargin{7} == true, ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(varargin{8} == true, ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(varargin{9} == true, ''Env not correctly delegated.'');\n', ...
    'stReturn = struct(''bIsTL'', true);\n', ...
    'varargout{1} = stReturn;\n']);
end


%%
function xOnCleanupRemoveStub = i_createLegacyModelCloseStub()
xOnCleanupRemoveStub = i_createStub('atgcv_m_model_close', ...
    ['MU_ASSERT_TRUE(isstruct(varargin{1}), ''Env not correctly delegated.'');\n', ...
    'MU_ASSERT_TRUE(isstruct(varargin{2}), ''stModelHandle not correctly delegated.'');\n', ...
    'varargout{1} = true;\n']);
end


%%
function xOnCleanupRemoveStub = i_createStub(sStubName, sReplaceContent)
ep_tu_create_stub_function(sStubName, 'replace', sReplaceContent);
rehash;
xOnCleanupRemoveStub = onCleanup(@() i_removeSafely(fullfile(pwd, [sStubName, '.m'])));
end


%%
function i_removeSafely(sFile)
if exist(sFile, 'file')
    delete(sFile);
end
end



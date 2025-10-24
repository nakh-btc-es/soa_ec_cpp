function ut_model_handle()
% Tests the base functionality for handling additional resources for model open/close.
%
% $$$COPYRIGHT$$$-2017

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%% clean up first
ep_tu_cleanup();

%% predefined values
sPwd      = pwd;
sTestRoot = fullfile(sPwd, 'tst_ut_model_handle');
sEnvVar = 'UT_CHECK_EXTENSION_ESTABLISHED';

%% setup env for test
try
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    ep_tu_mkdir(sTestRoot);
    cd(sTestRoot);
    
    xOnCleanupRemoveStub = i_createEpExtensionStub(sEnvVar); %#ok<NASGU> onCleanup object
catch oEx
    MU_FAIL_FATAL(sprintf('Unexpected exception during test env setup:\n"%s".', oEx.message));
end


%% test for SL model
try
    stModelHandle = struct('bIsTL', true);
    
    setenv(sEnvVar, '');
    
    stModelHandle = ep_core_model_handle('allocate', stModelHandle);
    MU_ASSERT_TRUE(isfield(stModelHandle, 'xInternalCoreHandle') && ~isempty(stModelHandle.xInternalCoreHandle), ...
        'After allocating resources the internal core handle shall be added.');
    
    stModelHandle = ep_core_model_handle('free', stModelHandle);
    MU_ASSERT_TRUE(~isfield(stModelHandle, 'xInternalCoreHandle') || isempty(stModelHandle.xInternalCoreHandle), ...
        'After freeing the resources the internal core handle shall be empty.');
    
    sVal = getenv(sEnvVar);
    MU_ASSERT_TRUE(strcmp(sVal, '1'), 'Extension hook was not triggered when allocating/freeing resources.');
catch oEx
    MU_FAIL(sprintf('Unexpected exception:\n%s', oEx.message));
end
setenv(sEnvVar, '');


%% test for SL model
try
    stModelHandle = struct('bIsTL', false);
    
    stModelHandle = ep_core_model_handle('allocate', stModelHandle);
    MU_ASSERT_TRUE(isfield(stModelHandle, 'xInternalCoreHandle'), ...
        'After allocating resources the internal core handle shall be added.');
    
    stModelHandle = ep_core_model_handle('free', stModelHandle);
    MU_ASSERT_TRUE(~isfield(stModelHandle, 'xInternalCoreHandle') || isempty(stModelHandle.xInternalCoreHandle), ...
        'After freeing the resources the internal core handle shall be empty.');
catch oEx
    MU_FAIL(sprintf('Unexpected exception:\n%s', oEx.message));
end


%% robustness
try
    ep_core_model_handle('some_cmd');
    MU_FAIL('Shall throw exception when dealing with an unnown command.');
catch oEx
    MU_ASSERT_TRUE(strcmp(oEx.identifier, 'EP:CORE:UNKNOWN_COMMAND'), 'Unexpected exception.');
end


%% clean
try
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



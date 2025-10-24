function it_model_open_close_001()
% Tests the model open and close mechanism.
%
%  function it_model_open_close_001()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

%% clean up first
ep_tu_cleanup();


%% predefined values
sPwd            = pwd;
sTestData       = sltu_model_get('SimpleBurner', 'SL', true);
sDataPath       = sTestData.sTestDataPath;
sTestRoot       = fullfile(sPwd, 'tst_it_model_open_close_001');
sModelFile      = fullfile(sTestRoot, sTestData.sSlModel);
sInitScriptFile = fullfile(sTestRoot, sTestData.sSlInitScript);

[~, sModelName] = fileparts(sModelFile);

%% setup env for test
try 
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    copyfile(sDataPath, sTestRoot);
    cd(sTestRoot);
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', getReport(exception)));
end


%% test
try 
    MU_ASSERT_FALSE(i_isModelOpen(sModelName), ...
        'Pre-req: Before first opening of the model it should not be found among the open models.');
    
    xEnv = EPEnvironment();
    stInputArgsFirst = struct(...
        'sModelFile',            sModelFile, ...
        'caInitScripts',         {{sInitScriptFile}}, ...
        'bIsTL',                 false, ...
        'bCheck',                false, ...
        'bIgnoreInitScriptFail', false);
    stSlOpenFirst = ep_core_model_open(xEnv, stInputArgsFirst);
    MU_ASSERT_TRUE(i_isModelOpen(sModelName), ...
        'After first opening the model should be found among open models.');
    MU_ASSERT_FALSE(i_isModelDirty(sModelName), ...
        'After first opening model should not be in a dirty state.');
    
    % open the model a second time; now with checking active
    stInputArgsSecond = stInputArgsFirst;
    stInputArgsSecond.bCheck = true;
    stInputArgsSecond.bEnableBusObjectLabelMismatch = true;
    
    stSlOpenSecond = ep_core_model_open(xEnv, stInputArgsSecond);
    MU_ASSERT_TRUE(i_isModelOpen(sModelName), ...
        'After second opening the model should be still be open. Of course.');
    MU_ASSERT_FALSE(i_isModelDirty(sModelName), ...
        'After second opening and checking model should not be in a dirty state. (see EPDEV-62066)');
    
    ep_core_model_close(xEnv, stSlOpenSecond);
    MU_ASSERT_TRUE(i_isModelOpen(sModelName), ...
        'After reverting *second* opening the model should still be open.');
    MU_ASSERT_FALSE(i_isModelDirty(sModelName), ...
        'After reverting *second* opening the model should not be in a dirty state.');
    
    ep_core_model_close(xEnv, stSlOpenFirst);
    MU_ASSERT_FALSE(i_isModelOpen(sModelName), ...
        'After reverting *first* opening the model should not be open anymore.');
catch exception
    MU_FAIL(sprintf('Unexpected exception: "%s".', getReport(exception)));
end

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
function bIsDirty = i_isModelDirty(sModelName)
bIsDirty = strcmp('on', get_param(sModelName, 'Dirty'));
end


%%
function bIsOpen = i_isModelOpen(sModelName)
try
    bIsOpen = ~isempty(get_param(sModelName, 'handle'));
catch
    bIsOpen = false;
end
end

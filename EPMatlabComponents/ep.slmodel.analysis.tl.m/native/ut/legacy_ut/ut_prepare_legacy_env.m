function [xOnCleanupDoCleanup, stEnv] = ut_prepare_legacy_env(sDataDir, sTestRootDir)
% Prepare test environment for M01 UnitTests.
%
%


%% main
sPwd = pwd();
xOnCleanupDoCleanup = onCleanup(@() i_cleanup(sTestRootDir, sPwd));


% create root_dir for test and copy testdata
try
    if exist(sTestRootDir, 'file')
        rmdir(sTestRootDir, 's');
    end
    ut_m01_copyfile(sDataDir, sTestRootDir);
    cd(sTestRootDir);
    
    stEnv = ut_messenger_env_create(pwd);
    ut_messenger_reset(stEnv.hMessenger);
    
catch oEx
    MU_FAIL_FATAL( ...
        sprintf('Could not create root_dir for test!\n%s', oEx.message));
end
end



%%
function i_cleanup(sTestRoot, sPwd)
if ut_currently_debugging()
    warning('UT:DEBUG', '%s: Currently in DEBUG mode: no cleanup done!', mfilename);
    return;
end
cd(sPwd);
try
    clear mex;
    bdclose all;
    dsdd_free;
    if exist(sTestRoot, 'dir')
        rmdir(sTestRoot, 's');
    end
    close all force;
catch oEx
    warning('UT:M01', 'Cleanup failed:\n%s\n$s', oEx.identifier, oEx.message);
end
ut_cleanup();
end




function [xOnCleanupDoCleanup, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRootDir)
% Prepare test environment for ModelAnlysis UnitTests.
%
%

%% main
sPwd = pwd();
xEnv = EPEnvironment();
xOnCleanupDoCleanup = onCleanup(@() i_cleanup(sTestRootDir, sPwd, xEnv));

% create root_dir for test and copy testdata
try
    if exist(sTestRootDir, 'file')
        rmdir(sTestRootDir, 's');
    end
    ut_copyfile(sDataDir, sTestRootDir);
    cd(sTestRootDir);
    
    
    sResultDir = fullfile(pwd, 'ut_results');
    if exist(sResultDir, 'dir')
        rmdir(sResultDir, 's');
    end
    mkdir(sResultDir);
    
catch oEx
    MU_FAIL_FATAL(sprintf('Could not create root_dir for test!\n%s', oEx.message));
end
end



%%
function i_cleanup(sTestRoot, sPwd, xEnv)
if ut_currently_debugging()
    warning('UT:DEBUG', '%s: Currently in DEBUG mode: no cleanup done!', mfilename);
    return;
end
cd(sPwd);
try
    clear mex; %#ok<CLMEX>
    bdclose all;
    dsdd_free;
    if exist(sTestRoot, 'dir')
        rmdir(sTestRoot, 's');
    end
    close all force;
catch oEx
    warning('UT:ERROR', 'Cleanup failed:\n%s\n$s', oEx.identifier, oEx.message);
end
try
    xEnv.clear();
catch oEx
    warning('UT:ERROR', 'Cleanup failed:\n%s\n$s', oEx.identifier, oEx.message);
end
ut_cleanup();
end



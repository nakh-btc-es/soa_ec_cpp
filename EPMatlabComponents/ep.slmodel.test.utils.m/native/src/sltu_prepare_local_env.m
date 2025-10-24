function [xOnCleanupDoCleanup, xEnv, sResultDir] = sltu_prepare_local_env(sOrigDataDir, sTestRootDir)
% Prepare test environment for UT with copy of local data.
%
%

%%
if (nargout < 1)
    error('SLTU:ERROR:WRONG_USAGE', ...
        'Wrong usage of prepare function. Must never be called without accepting the cleanup object.');
end

%% main
sPwd = pwd();
xEnv = EPEnvironment();
xOnCleanupDoCleanup = onCleanup(@() i_cleanup(sTestRootDir, sPwd, xEnv));

% create root_dir for test and copy testdata
if exist(sTestRootDir, 'file')
    rmdir(sTestRootDir, 's');
end

sltu_copy_file(sOrigDataDir, sTestRootDir);

sResultDir = fullfile(pwd, 'ut_results');

if exist(sResultDir, 'dir')
    rmdir(sResultDir, 's');
end
mkdir(sResultDir);
end



%%
function i_cleanup(sTestRoot, sPwd, xEnv)
if sltu_currently_debugging()
    warning('SLTU:PREPARE_LOCAL_ENV:WARNING', '%s: Currently in DEBUG mode: no cleanup done!', mfilename);
    return;
end
cd(sPwd);
try
    sltu_clear_mex;
    bdclose all;
    if sltu_tl_available()
        dsdd_free;
    end
    if exist(sTestRoot, 'dir')
        rmdir(sTestRoot, 's');
    end
    close all force;
catch oEx
    warning('SLTU:PREPARE_LOCAL_ENV:ERROR', 'Cleanup failed:\n%s\n$s', oEx.identifier, oEx.message);
end
try
    xEnv.clear();
catch oEx
    warning('SLTU:PREPARE_LOCAL_ENV:ERROR', 'Cleanup failed:\n%s\n$s', oEx.identifier, oEx.message);
end
sltu_cleanup();
end



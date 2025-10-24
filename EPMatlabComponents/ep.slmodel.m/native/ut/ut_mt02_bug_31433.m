function ut_mt02_bug_31433()

sPwd = pwd();
sTestroot = fullfile(sPwd, 'bug_31433');
sDataroot = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tst', 'testdata', 'bug_31433');

% prepair testroot
try
    if exist(sTestroot, 'file')
        rmdir(sTestroot, 's');
    end
    mkdir(sTestroot);
    copyfile(sDataroot, sTestroot);
    cd(sTestroot);
catch
    stErr = atgcv_lasterror();
    MU_FAIL_FATAL(sprintf('prepair testroor failed: %s', stErr.message));
end

% modify dd file
try
    dsdd('Close', 'Save', 'off');
    dsdd('Open', 'File', fullfile(sTestroot, 'test3.dd'), 'Upgrade', 'on');
    dsdd('SetAccessRights', '//DD0', ...
        'access', 'rwr-', ...
        'TraverseMode', 'CurrentObjectAndSubTree');
catch
    stErr = atgcv_lasterror();
    MU_FAIL(sprintf('modify dd failed: %s', stErr.message));
end

% testmain
try
    stEnv = i_envCreate(sTestroot);
    ep_adapt_current_dd(stEnv);
catch
    stErr = atgcv_lasterror();
    MU_FAIL(sprintf('Unexpected exception: %s', stErr.message));
end

% clean up
try
    dsdd('Close', 'Save', 'off');
    cd(sPwd);
    if exist(sTestroot, 'file')
        rmdir(sTestroot, 's');
    end
catch
    MU_FAIL('remove testroot failed');
end

end

%% internal function
function stEnv = i_envCreate(sRootPath)
sTmpPath = fullfile(sRootPath, 'tmp');
sResPath = fullfile(sRootPath, 'res');
if exist(sTmpPath, 'dir')
    rmdir(sTmpPath, 's');
end
mkdir(sTmpPath);
if exist(sResPath, 'dir')
    rmdir(sResPath, 's');
end
mkdir(sResPath);

stEnv = struct( ...
    'sTmpPath',    sTmpPath, ...
    'sResultPath', sResPath, ...
    'hMessenger',  0);
end
function stEnv = ut_messenger_env_create(sRootPath)
% small helper for creating a default messenger environment
%
% function stEnv = ut_messenger_env_create(sRootPath)



%% setup env for test
try    
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
        'hMessenger',  EPEnvironment());
    
catch oEx
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', oEx.message));
end
end



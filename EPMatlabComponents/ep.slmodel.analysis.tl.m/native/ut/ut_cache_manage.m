function ut_cache_manage()
% reset the cache dir if date is expired
%

% Current Expire Date
sCacheDateExpire = '26-Apr-2019 08:00:00';


try
    sCacheDir = ut_cache_dir_get();
    if exist(sCacheDir, 'dir')
        [p, sDirName] = fileparts(sCacheDir);
        % asking for c:/a/b* to get info about "b" and not the content of "b"
        sSearch = fullfile(p, [sDirName, '*']);  
        stDir = dir(sSearch);
        if (length(stDir) > 1)
            for i = 1:length(stDir)
                if strcmpi(stDir(i).name, sDirName)
                    stDir = stDir(i);
                    break;
                end
            end
        end
        if (length(stDir) == 1)
            try
                if isfield(stDir, 'datenum')
                    nDatenumCache = stDir.datenum;
                else
                    nDatenumCache = datenum(stDir.date); 
                end
                nExpire = datenum(sCacheDateExpire);
                if (nDatenumCache < nExpire)
                    MU_MESSAGE('Current Cache is obsolete. Deleting it and creating new one.');
                    tu_rmdir(sCacheDir);
                    mkdir(sCacheDir);
                else
                    MU_MESSAGE('Current Cache is valid. Using it for testing.');
                end
            catch
                MU_FAIL('Status of current Cache unknown. Date check failed.');
            end
        else
            MU_FAIL('Status of current Cache unknown. Directory not found.');
        end
    else
        MU_MESSAGE('No Cache found. Creating new one.');
    end
catch oEx
    MU_FAIL(sprintf('Unexpected exception.\n\n%s', oEx.message));
    rethrow(oEx);
end
end



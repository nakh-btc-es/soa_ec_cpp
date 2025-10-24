function atgcv_api_copyfile(stEnv, sFileFrom, sFileTo)

%% avoid problems if source and target is the same or name differs only in case
if strcmpi(sFileFrom, sFileTo)
    return;
end

%% copy file; throw if failed
try
    sDir = fileparts(sFileTo);
    if ~isempty(sDir) && ~exist(sDir, 'dir')
        atgcv_api_mkdir(stEnv, sDir);
    end
    bSuccess = copyfile(sFileFrom, sFileTo, 'f');
catch
    bSuccess = false;
end
if ~bSuccess
    stErr = osc_messenger_add(stEnv, 'ATGCV:API:FILE_NOT_COPIED', ...
        'file_from', sFileFrom, 'file_to', sFileTo);
    osc_throw(stErr);
end
return;
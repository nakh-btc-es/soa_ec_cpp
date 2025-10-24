function atgcv_api_mkdir(stEnv, sDir)

%% create dir; throw if failed
try
    bSuccess = mkdir(sDir);
catch
    bSuccess = false;
end
if ~bSuccess
    stErr = osc_messenger_add(stEnv, 'ATGCV:API:DIR_NOT_CREATED', ...
        'dir', sDir);
    osc_throw(stErr);
end
return;


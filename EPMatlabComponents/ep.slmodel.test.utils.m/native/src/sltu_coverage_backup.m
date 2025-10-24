function sltu_coverage_backup(sCmd)
persistent p_bIsBackupActive;

if isempty(p_bIsBackupActive)
    mlock;
    p_bIsBackupActive = true;
end

% don't do anything if coverage handling is not needed
if (~p_bIsBackupActive || ~i_isCoverageMeasured())
    return;
end

switch lower(sCmd)
    case 'save'
        sBackupFile = i_getBackupFile();
        i_printInfoMsg('saving coverage to backup file');
        MC_save_data(sBackupFile);

    case 'load_and_delete'
        sBackupFile = i_getBackupFile();
        if exist(sBackupFile, 'file')
            i_printInfoMsg('restoring coverage from backup file');
            MC_clear();
            MC_add_data(sBackupFile);
            delete(sBackupFile);
        end

    case 'activate'
        p_bIsBackupActive = true;

    case 'deactivate'
        p_bIsBackupActive = false;

    case 'unlock'
        munlock;       

    otherwise
        error('UT:ERROR', 'Unkndown command: %s', sCmd);
end
end


%%
function i_printInfoMsg(sMsg)
fprintf('[INFO:%s:SLTU_COV_BACKUP] %s\n', datestr(now, 'HH:MM:SS'), sMsg);
end


%%
function bIsMeasured = i_isCoverageMeasured()
bIsMeasured = exist('MC_save_data', 'file');
end


%%
function sBackupFile = i_getBackupFile()
sBackupFile = fullfile(tempdir, 'UT_btc_coverage_backup.mat');
end

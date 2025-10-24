function [xOnCleanupDoCleanup, xEnv, sResultDir, stModelData] = ut_prepare_ats_env(sModelName, sModelSuite, sTestRootDir)
% Prepare test environment for ModelAnlysis UnitTests.
%
%

%% data
    stModelData = ep_ats_model_find('ModelName', sModelName, 'ModelSuite', sModelSuite, 'Upgrade', 'refresh');

if ~stModelData.bUpgradeSuccess
    error('EP:UT:ERROR', 'Model refresh was not successful.');
end

%% main
sPwd = pwd();
xEnv = EPEnvironment();
xOnCleanupDoCleanup = onCleanup(@() i_cleanup(sTestRootDir, sPwd, xEnv));

% create root_dir for test and copy testdata
try
    if exist(sTestRootDir, 'file')
        rmdir(sTestRootDir, 's');
    end
    
    ut_copyfile(stModelData.sRootPath, sTestRootDir);
    cd(sTestRootDir);
    stModelData = i_relocateRoot(stModelData, pwd);
    
    
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
function stModelData = i_relocateRoot(stModelData, sNewRootPath)
sOldRootPath = stModelData.sRootPath;
stModelData.sRootPath = sNewRootPath;

casFields = fieldnames(stModelData);
for i = 1:length(casFields)
    sField = casFields{i};
    
    if ~isempty(regexp(sField, 'File$', 'once'))
        sOldFile = stModelData.(sField);
        if ~isempty(sOldFile)
            stModelData.(sField) = i_relocateRootOfFile(sOldFile, sOldRootPath, sNewRootPath);
        end
    end
end
end


%%
function sFile = i_relocateRootOfFile(sFile, sOldRootPath, sNewRootPath)
sOldFile = sFile;
if (length(sFile) > length(sOldRootPath))
    sCurrentRoot = sFile(1:length(sOldRootPath));
    if ~strcmpi(sCurrentRoot, sOldRootPath)
        error('EP:UT:ERROR', 'File "%s" does not have "%s" as root path.', sFile, sOldRootPath);
    end
    sRelPath = sFile(length(sOldRootPath)+2:end);
    sFile = fullfile(sNewRootPath, sRelPath);
    
else
    if ~strcmpi(sFile, sOldRootPath)
        error('EP:UT:ERROR', 'File "%s" does not have "%s" as root path.', sFile, sOldRootPath);
    end
    sFile = sNewRootPath;
end
if (~exist(sFile, 'file') && exist(sOldFile, 'file'))
    error('EP:DEV:ERROR', 'File "%s" was not successfully relocated to "%s".', sOldFile, sNewRootPath);
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
    clear mex;
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



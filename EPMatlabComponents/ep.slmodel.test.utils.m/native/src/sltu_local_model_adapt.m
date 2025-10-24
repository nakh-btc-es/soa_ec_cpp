function sltu_local_model_adapt(varargin)
% wrapper for tu_test_model_adapt to use cached backup files instead of adapting to new ones
%


%%
casFiles = varargin;

sModelFile = casFiles{1};
if (length(casFiles) > 1)
    sInitScript = casFiles{2};
    if isempty(sInitScript)
        casFiles(2) = [];
    end
end
[sModelTestDir, sModelTestName] = i_getModelTestDir(sModelFile);
if isempty(sModelTestDir)
    error('SLTU:LOCAL_MODEL_ADAPT:ERROR', 'Model file "%s" seems to be outside of the test root directory.', sModelFile);
end

% check if caching is even activated
bUseCaching = sltu_use_caching();
sBackupDir = sltu_cache_dir_get();
if (bUseCaching && ~isempty(sBackupDir) && ~isempty(sModelTestDir))
    if ~exist(sBackupDir, 'dir')
        mkdir(sBackupDir);
    end
    
    [sPath, sModelName] = fileparts(sModelFile);
    sRelPath = strrep(sPath, sModelTestDir, '');
    if ~isempty(sRelPath) && (sRelPath(1) == filesep)
        sRelPath(1) = []; % remove the fileseparator from the beginning
    end
    
    sDirName = i_getUniqueDirName(sModelTestName, sModelName);

    % sometimes copy is hindered by open model mex files --> clear mex
    sltu_clear_mex;
        
    sModelBackupDir = fullfile(sBackupDir, sDirName);
    if exist(sModelBackupDir, 'dir')
        if i_isBackupStale(sModelBackupDir, casFiles, sRelPath)
            fprintf('\nRemoving stale backup data: %s.\n\n', sModelBackupDir);
            rmdir(sModelBackupDir, 's');
        else
            i_copyModelBackupDir(sModelBackupDir, sModelTestDir);
            return;
        end
    end    
    
    % do an upgrade and copy the data into the cache for next time
    % note copy the data only if the upgrade was successful!
    if ep_ats_test_model_adapt(casFiles{:})
        try
            copyfile(sModelTestDir, sModelBackupDir, 'f');
        catch oEx
            fprintf('Copying failed.\n%s\n\nRepeating after clearing artifacts.\n', oEx.message);
            i_removeArtifacts(sModelTestDir, true);
            copyfile(sModelTestDir, sModelBackupDir, 'f');            
        end
        fprintf('\nCopying testdata into cached backup dir: %s.\n\n', sModelBackupDir);
        try
            i_removeArtifacts(sModelBackupDir);
        catch
        end
    else
        MU_MESSAGE('SLTU:LOCAL_MODEL_ADAPT:ERROR: Model upgrade was not successful.');
    end
else
    % Backup functionality not available --> do only an upgrade without caching
    if ~tu_test_model_adapt(casFiles{:})
        MU_MESSAGE('SLTU:LOCAL_MODEL_ADAPT:ERROR: Model upgrade was not successful.');
    end
end
end    


%%
function sDirName = i_getUniqueDirName(sModelTestName, sModelName)
sDirName = i_shortenString([sModelTestName, '_', sModelName], 20);
end


%%
function sString = i_shortenString(sString, nMaxLen)
if (length(sString) > nMaxLen)
    sHashString = i_hashString(sString);
    if (length(sHashString) > nMaxLen)
        sString = sHashString(1:nMaxLen);
    else
        sString = sHashString;
    end
end
end


%%
function sString = i_hashString(sString)
if isunix
    md = java.security.MessageDigest.getInstance('MD5');
    hash = typecast(md.digest(uint8(sString)), 'uint8');
else
    jHasher = System.Security.Cryptography.HashAlgorithm.Create('MD5');
    hash = uint8(jHasher.ComputeHash(uint8(sString)));
end
sString = upper(reshape(dec2hex(hash), 1, []));
end


%%
function i_copyModelBackupDir(sModelBackupDir, sModelTestDir)
sMemPwd = pwd();
xOnCleanupReturn = onCleanup(@() cd(sMemPwd));

cd('..\..'); 
copyfile(fullfile(sModelBackupDir, '*'), sModelTestDir, 'f');
i_removeArtifacts(sModelTestDir);
fprintf('\nUsing cached backup dir: %s for testing.\n\n',  sModelBackupDir);
end


%%
function bIsStale = i_isBackupStale(sModelBackupDir, casFiles, sRelPath)
if (nargin < 3)
    sRelPath = '';
end
bIsStale = true;

[sLatestFile, dLatestDatenum] = i_getLatestFile(casFiles);

[~, sFile, sExt] = fileparts(sLatestFile);
if isempty(sRelPath)
    sFullFile = fullfile(sModelBackupDir, [sFile, sExt]);
else
    sFullFile = fullfile(sModelBackupDir, sRelPath, [sFile, sExt]);
end
if exist(sFullFile, 'file')
    stFile = dir(sFullFile);
    bIsStale = dLatestDatenum > stFile.datenum;
end
end


%%
function [sLatestFile, dLatestDatenum] = i_getLatestFile(casFiles)
sLatestFile = '';
dLatestDatenum = [];

for i = 1:length(casFiles)
    sFile = casFiles{i};
    stDir = dir(sFile);
    if isempty(sLatestFile)
        sLatestFile = sFile;
        dLatestDatenum = stDir.datenum;
    else
        if (stDir.datenum > dLatestDatenum)
            sLatestFile = sFile;
            dLatestDatenum = stDir.datenum;
        end
    end
end
end


%%
function [sModelTestDir, sModelTestName] = i_getModelTestDir(sModelFile)
sModelTestDir = '';
sModelTestName = '';

sDir = fileparts(sModelFile);
if ~isdir(sDir)
    return;
end

sTmpDir = sltu_tmp_env;
sRest   = strrep(sDir, sTmpDir, '');
sModelTestName = strtok(sRest, filesep());
sModelTestDir  = fullfile(sTmpDir, sModelTestName); 
end


%% remove recursively all slprj directories 
% (problems with different mex compilers and cached data -- inconsistencies)
function i_removeArtifacts(sCurrentDir, bDoTlCleanup)
if (nargin < 2)
    bDoTlCleanup = false;
end
astDir = dir(sCurrentDir);
for i = 1:length(astDir)
    sName = astDir(i).name;
    if astDir(i).isdir        
        if any(strcmp(sName, {'.', '..'}))
            continue;
        end
        
        sFull = fullfile(sCurrentDir, sName);        

        if strcmpi(sName, 'slprj')
            rmdir(sFull, 's');
        else
            i_removeArtifacts(sFull, bDoTlCleanup);
        end
    else
        [~, f, e] = fileparts(sName);
        if strcmpi(e, '.autosave')
            sFull = fullfile(sCurrentDir, sName);        
            sTarget = fullfile(sCurrentDir, f);
            sSrc    = sFull;
            movefile(sSrc, sTarget, 'f');
            continue;
        end
        
    end
end
if bDoTlCleanup
    i_evalTlClean(sCurrentDir);
end
end


%%
function i_evalTlClean(sDir)
sTlCleanBat = fullfile(sDir, 'tl_clean.bat');
if exist(sTlCleanBat, 'file')
    sPwd = pwd;
    xOnCleanupReturn = onCleanup(@() cd(sPwd));
    cd(sDir);
    try
        if verLessThan('tl', '5.2')
            dos('.\tl_clean.bat');
        else
            dos('.\tl_clean.bat all');
        end
    catch
    end
end
end



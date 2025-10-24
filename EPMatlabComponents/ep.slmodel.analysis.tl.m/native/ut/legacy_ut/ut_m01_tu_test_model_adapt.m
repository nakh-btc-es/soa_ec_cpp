function ut_m01_tu_test_model_adapt(varargin)
% wrapper for tu_test_model_adapt to use cached backup files instead
% of generating new ones
%


%%
casFiles = varargin;

sModelFile = casFiles{1};
sInitScriptName = '';
if (length(casFiles) > 1)
    sInitScript = casFiles{2};
    if ~isempty(sInitScript)
        [~, sInitScriptName] = fileparts(sInitScript);
    else
        casFiles(2) = [];
    end
end
[sModelTestDir, sModelTestName] = i_getModelTestDir(sModelFile);


sBackupDir = ut_m01_cache_dir_get();
if (~isempty(sBackupDir) && ~isempty(sModelTestDir))
    if ~exist(sBackupDir, 'dir')
        mkdir(sBackupDir);
    end
    
    [sPath, sModelName] = fileparts(sModelFile);
    sRelPath = strrep(sPath, sModelTestDir, '');
    if ~isempty(sRelPath) && ((sRelPath(1) == '\') || (sRelPath(1) == '/'))
        sRelPath(1) = []; % remove the fileseparator from the beginning
    end
    sDirName = [sModelTestName, '_', sModelName];
    if ~isempty(sInitScriptName)
        sDirName = [sDirName, '_', sInitScriptName];
    end
    % sometimes copy is hindered by open model mex files --> clear mex
    clear mex;
        
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
    if (tu_test_model_adapt(casFiles{:}))
        try
            copyfile(sModelTestDir, sModelBackupDir, 'f');
        catch oEx
            fprintf('Copying failed.\n%s\n\nRepeating after clearing artifacts.\n', oEx.message);
            i_removeArtifacts(sModelTestDir);
            copyfile(sModelTestDir, sModelBackupDir, 'f');            
        end
        fprintf('\nCopying testdata into cached backup dir: %s.\n\n', sModelBackupDir);
        try
            i_removeArtifacts(sModelBackupDir);
        catch
        end
    else
        MU_MESSAGE('TU_TEST_MODEL_ADAPT: Model upgrade was not successful.');
    end
else
    % Backup functionality not available --> do only an upgrade without caching
    if ~tu_test_model_adapt(casFiles{:})
        MU_MESSAGE('TU_TEST_MODEL_ADAPT: Model upgrade was not successful.');
    end
end
end    


%%
function i_copyModelBackupDir(sModelBackupDir, sModelTestDir)
sMemPwd = pwd();
xOnCleanupReturn = onCleanup(@() cd(sMemPwd));

cd('..\..'); 
ut_m01_copyfile(fullfile(sModelBackupDir, '*'), sModelTestDir, 'f');
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

sPattern = strrep(fullfile('x', 'tst', 'tmpdir'), '\', '\\');
sPattern = sPattern(2:end);
iFoundEnd = regexp(sDir, sPattern, 'end', 'once');
if (isempty(iFoundEnd) || iFoundEnd >= length(sDir))
    return;
end

sTmpDir = sDir(1:iFoundEnd);
sRest   = sDir(iFoundEnd + 1:end);
sModelTestName = strtok(sRest, filesep());
sModelTestDir  = fullfile(sTmpDir, sModelTestName); 
end


%% remove recursively all slprj directories 
% (problems with different mex compilers and cached data -- inconsistencies)
function i_removeArtifacts(sCurrentDir)
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
            i_removeArtifacts(sFull);
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
i_evalTlClean(sCurrentDir);
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



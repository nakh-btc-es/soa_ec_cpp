function atgcv_m46_copy_files(sTargetDir, casSrcDirs, casExts)
% Copies all files with specified extension(s) from the directories to the export directory.
%
% function atgcv_m46_copy_files(sTargetDir, casSrcDirs, casExts)
%
%   INPUT               DESCRIPTION
%   sExportDir           (string)    destination path
%   casPaths             (cell)      source path(s)
%   casExts              (cell)      file extension(s)
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
%   REFERENCE(S):
%     Design Document:
%        Section : M46
%        Download:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%


% check TargetDir
if ~exist(sTargetDir, 'dir')
    warning('ATGCV:WRONG_USAGE', 'Target directory "%s" not found.', sTargetDir);
    return;
end


% normalize inputs
if ischar(casSrcDirs)
    casSrcDirs = {casSrcDirs};
end
if ischar(casExts)
    casExts = {casExts};
end
if isempty(casSrcDirs) || isempty(casExts)
    return;
end


%% copy loop
nDirs = length(casSrcDirs);
for k = 1:nDirs
    sSrcDir = casSrcDirs{k};
    if exist(sSrcDir, 'dir')
        i_copyFilesFromTo(sTargetDir, sSrcDir, casExts);
    end
end
end


%%
function i_copyFilesFromTo(sTargetDir, sSrcDir, casExts)
if i_isSameDir(sTargetDir, sSrcDir)
    return;
end
nExts = length(casExts);
for k = 1:nExts
    sExt = casExts{k};
    
    sFileMatch = fullfile(sSrcDir, ['*', sExt]);
    astFiles = dir(sFileMatch);
    nFiles = length(astFiles);
    for i = 1:nFiles
        try
            copyfile(fullfile(sSrcDir, astFiles(i).name), sTargetDir, 'f');
        catch oEx
            warning('ATGCV:COPY_FAILED', ...
                'File "%s" could not be copied.\n%s', astFiles(i).name, ...
                oEx.message);
        end
    end
end
end


%%
function bIsSame = i_isSameDir(sDir1, sDir2)
sDirNorm1 = atgcv_canonical_path(sDir1);
sDirNorm2 = atgcv_canonical_path(sDir2);
bIsSame = strcmpi(sDirNorm1, sDirNorm2);
end


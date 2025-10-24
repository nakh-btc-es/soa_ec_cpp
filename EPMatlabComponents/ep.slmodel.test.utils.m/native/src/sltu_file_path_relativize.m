function sRelPath = sltu_file_path_relativize(sThisPath, sAnchorPath)
% return the relative path of this full path to an anchor path

sThisPath = i_checkAndGetCanonicalPath(sThisPath);
sAnchorPath = i_checkAndGetCanonicalPath(sAnchorPath);

sRelPath = i_relativize(sThisPath, sAnchorPath);
end


%%
function sCanonicalPath = i_checkAndGetCanonicalPath(sFilePath)
jFile = java.io.File(sFilePath);
if ~jFile.isAbsolute()
    error('USAGE:ERROR', 'File path "%s" is not absolute. Cannot compute rel path for it.', sFilePath);
end
sCanonicalPath = char(jFile.getCanonicalPath());
end


%%
function sRelPath = i_relativize(sThisPath, sAnchorPath)
jThisPath = java.nio.file.Paths.get('', sThisPath);
jOtherPath = java.nio.file.Paths.get('', sAnchorPath);

sRelPath = char(jOtherPath.relativize(jThisPath).toString());
end


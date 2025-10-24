function sltu_model_dir_copy(sDirFrom, sDirTo)
% Copies model files from one directory into another (gets created if not existing) and cleans up artefacts if found.
%

sltu_copyfile(sDirFrom, sDirTo);

% delete all cached files
delete(fullfile(sDirTo, '*.slxc'));

% delete the project directory
sProjectDir = fullfile(sDirTo, 'slprj');
if exist(sProjectDir, 'dir')
    rmdir(sProjectDir, 's');
end
end

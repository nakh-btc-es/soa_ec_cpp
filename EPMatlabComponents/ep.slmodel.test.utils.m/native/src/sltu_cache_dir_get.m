function sCacheDir = sltu_cache_dir_get(sCmd)
% returns the location of the cache dir (depends on current ML/TL version); if not existing, it is created
%

%%
persistent p_sCacheRootDir;
if isempty(p_sCacheRootDir)
    p_sCacheRootDir = sltu_tmpdir_get();
    mlock();
end

%%
if (nargin > 0)
    switch lower(sCmd)
        case 'unlock'
            munlock();
            return;
            
        otherwise
            error('SLTU:UNKNOWN_CMD', 'Unknown command "%s".', sCmd);
    end
end

sCacheDir = i_getCacheDir(p_sCacheRootDir);
if ~exist(sCacheDir, 'dir')
    try
        mkdir(sCacheDir);
    catch
        return;
    end
end
end



%%
function sCacheDir = i_getCacheDir(sRootDir)
sSubFolder = 'DEFAULT';

sCurrentModuleUtDir = fileparts(which('MU_pre_hook'));
if ~isempty(sCurrentModuleUtDir)
    % assuming UT folder to be EPMatlabComponents/<module_name>/native/ut
    [~, sModuleName] = fileparts(fileparts(fileparts(sCurrentModuleUtDir)));
    sModuleShort = regexprep(sModuleName, '.*?ep\.([^/\\]+).*', '$1');
    if (~isempty(sModuleShort) && (numel(sModuleShort) < numel(sCurrentModuleUtDir)))
        sSubFolder = strrep(sModuleShort, '.', '_');
    end
end
sCacheDir = fullfile(sRootDir, sSubFolder);
end

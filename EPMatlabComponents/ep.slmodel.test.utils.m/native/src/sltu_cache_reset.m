function varargout = sltu_cache_reset
% Resets the cache dir, i.e. removes it.

sCacheDir = sltu_cache_dir_get();
if exist(sCacheDir, 'dir')
    fprintf('\n[INFO] ... removing cache dir "%s".\n\n', sCacheDir);
    rmdir(sCacheDir, 's');
end
sCacheDir = sltu_cache_dir_get(); % creating a new cache dir by calling
if (nargout > 0)
    varargout{1} = sCacheDir;
end

sltu_context_tmpdir_get('reset');
end



function sCacheDir = ut_cache_reset
% Resets the cache dir, i.e. removes it.

sCacheDir = ut_cache_dir_get();
if exist(sCacheDir, 'dir')
    rmdir(sCacheDir, 's');
end
sCacheDir = ut_cache_dir_get(); % creating a new cache dir by calling
end



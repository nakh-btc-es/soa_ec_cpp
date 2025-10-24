function path = atgcv_env_bin_path()
path = char(ct.nativeaccess.ResourceServiceFactory.getInstance().getResourceAsFile([], 'x32').getAbsolutePath());
end

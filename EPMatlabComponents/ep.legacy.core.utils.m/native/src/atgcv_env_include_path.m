function path = atgcv_env_include_path()
path = char(ct.nativeaccess.ResourceServiceFactory.getInstance().getResourceAsFile([], 'include').getAbsolutePath());
end

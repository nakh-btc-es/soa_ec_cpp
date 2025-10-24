function xOnCleanupUninstall = ut_init_autosar(sVersion)
sUtilsRoot = fullfile(ut_local_testdata_dir_get(), 'AUTOSAR', sVersion);
if ~exist(sUtilsRoot, 'dir')
    error('UT:ERROR', 'AUTOSAR utilities version "%s" not found.', sVersion);
end

sAddPath = genpath(sUtilsRoot);
addpath(sAddPath);

xOnCleanupUninstall = onCleanup(@() rmpath(sAddPath));
end




function stInfo = ep_ec_codegen_info_get(oBuildInfo)
% Evaluating RTW.BuildInfo object.

stInfo = struct( ...
    'casFiles', {getFullFileList(oBuildInfo, 'source')}, ...
    'casHeaderFiles', {getFullFileList(oBuildInfo, 'include')}, ...
    'casIncludePaths', {i_getIncludePaths(oBuildInfo)});
end


%%
function casIncludePaths = i_getIncludePaths(oBuildInfo)
casIncludePaths = {};

sBuildRootDir = oBuildInfo.getLocalBuildDir;
casBuildIncludePaths = cellstr(oBuildInfo.getIncludePaths(true));

% for nested referenced models the list of include paths is incomplete (ML2016b)
% --> add also all build dirs as fallback include paths
casFallbackBuildDirs = cellstr(oBuildInfo.getBuildDirList);
casBuildIncludePaths = [casBuildIncludePaths, casFallbackBuildDirs];

% exclude directories in Matlab installation
for k = 1:numel(casBuildIncludePaths)
    sIncludePathCandidate = ep_core_canonical_path(casBuildIncludePaths{k}, sBuildRootDir);
    
    if exist(sIncludePathCandidate, 'dir')
        casIncludePaths{end + 1} = sIncludePathCandidate; %#ok<AGROW>
    end
end
casIncludePaths = unique(casIncludePaths, 'stable');
end

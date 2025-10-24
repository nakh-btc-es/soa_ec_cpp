function casIncludePaths = getCodegenIncludePaths(oEca)
oBuildInfo = oEca.getStoredBuildInfo();
if (oEca.bIsAdaptiveAutosar && verLessThan('matlab', '9.13'))
    casIncludePaths = i_getIncludePaths(oBuildInfo, i_getAdaptiveAutosarStubFolders(oBuildInfo));
else
    casIncludePaths = i_getIncludePaths(oBuildInfo);
end
end


%%
function casInclPaths = i_getAdaptiveAutosarStubFolders(oBuildInfo)
casInclPaths = {};

sBuildRootDir = oBuildInfo.getLocalBuildDir;
sCandidateAragenFolder = i_getCanonicalPath(fullfile(sBuildRootDir, 'stub', 'aragen'));
if exist(sCandidateAragenFolder, 'dir')
    casInclPaths{end + 1} = sCandidateAragenFolder;
end
end


%%
% TODO: move this internal function outside of Eca methods
function casIncludePaths = i_getIncludePaths(oBuildInfo, casAddInclPaths)
casIncludePaths = {};

if (nargin < 2)
    casAddInclPaths = {};
end

sBuildRootDir = oBuildInfo.getLocalBuildDir;
casBuildIncludePaths = cellstr(oBuildInfo.getIncludePaths(true));

% for nested referenced models the list of include paths is incomplete (ML2016b)
% --> add also all build dirs as fallback include paths
casFallbackBuildDirs = cellstr(oBuildInfo.getBuildDirList);
casBuildIncludePaths = [casBuildIncludePaths, casFallbackBuildDirs, casAddInclPaths];
for k = 1:numel(casBuildIncludePaths)
    sIncludePathCandidate = i_getCanonicalPath(casBuildIncludePaths{k}, sBuildRootDir);
    
    if exist(sIncludePathCandidate, 'dir')
        casIncludePaths{end + 1} = sIncludePathCandidate; %#ok<AGROW>
    end
end
casIncludePaths = unique(casIncludePaths, 'stable');
end


%%
function sPath = i_getCanonicalPath(varargin)
sPath = ep_core_feval('ep_core_canonical_path', varargin{:});
end

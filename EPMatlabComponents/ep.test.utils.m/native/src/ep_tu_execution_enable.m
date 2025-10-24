function ep_tu_execution_enable
% Executing this function enables running Matlab UTs directly inside the Matlab console.
%
%  function ep_tu_execution_enable
%
%   INPUT               DESCRIPTION
%     bWithLegacyUT        (boolean)   enable also the direct execution of Legacy UTs (default == false)
%


%%
sEPRepoDir = i_getEPRepositoryDir();
if ~exist(sEPRepoDir, 'dir')
    error('EP:DEV:ERROR', 'Cannot find Maven repository at expected location "%s".', sEPRepoDir);
end

%%
casNeededJarNames = { ...
    'ep.ats.models', ...
    'ep.ats.models.simple', ...
    'ep.ats.models.customer', ...
    'ep.ats.models.featuretest'};

casFoundJars = i_findJarFilesInRepository(sEPRepoDir, casNeededJarNames);
for i = 1:length(casFoundJars)
    sJarFile = casFoundJars{i};
    sJarName = casNeededJarNames{i};
    
    if ~isempty(sJarFile)
        fprintf('[INFO] Extending Java path with\n   %s\n\n', sJarFile);
        javaaddpath(sJarFile);
    else
        fprintf('[ERROR] Java module "%s" not found.\n\n', sJarName);
    end
end
end



%%
function sEPRepoDir = i_getEPRepositoryDir()
sEPRepoDir = fullfile(getenv('USERPROFILE'), '.m2', 'repository', 'btc_es');
end


%%
function casJars = i_findJarFilesInRepository(sRepoDir, casJarNames)
casJars = cellfun(@(sJarName) i_findJarInRepo(sRepoDir, sJarName), casJarNames, 'UniformOutput', false);
end



%%
function sJarFile = i_findJarInRepo(sRepoDir, sJarName)
sJarFile = '';

sJarRootDir = fullfile(sRepoDir, sJarName);
sSnapshotDir = i_findHighestVersionSnapshotDir(sJarRootDir);
if ~isempty(sSnapshotDir)
    sJarFile = fullfile(sJarRootDir, sSnapshotDir, [sJarName, '-', sSnapshotDir, '.jar']);
else
    fprintf('[ERROR] No SNAPSHOT directory found for "%s".\n\n', sJarName); 
end
end


%%
function sSnapshotDir = i_findHighestVersionSnapshotDir(sRootDir)
astFiles = dir(fullfile(sRootDir, '*SNAPSHOT'));

sHighestVer = '';
sSnapshotDir = '';
for i = 1:length(astFiles)
    stFile = astFiles(i);
    
    if stFile.isdir
        sVer = i_getVersionFromSnapshotDirName(stFile.name);
        if ~isempty(sHighestVer)
            if (ep_tu_version_compare(sHighestVer, sVer) <= 0)
                continue;
            end
        end
        sHighestVer = sVer;
        sSnapshotDir = stFile.name;
    end
end
end


%%
function sVer = i_getVersionFromSnapshotDirName(sDirName)
% note: assuming the following name pattern "xx.x.x-SNAPSHOT"
casFound = regexp(sDirName, '^(.*)-SNAPSHOT$', 'tokens', 'once');
if ~isempty(casFound)
    sVer = casFound{1};
else
    error('EP:DEV:ERROR', 'Directory name "%s" does not match expected pattern "xx.x.x-SNAPSHOT".', sDirName);
end
end













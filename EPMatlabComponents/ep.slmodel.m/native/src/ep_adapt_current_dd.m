function ep_adapt_current_dd(xEnv, bResetArtifactLocationsToDefault)
% Adapt current DD settings for internal CodeGeneration of ET.
%
% function ep_adapt_current_dd(xEnv, bResetArtifactLocationsToDefault)
%
%
%   INPUT               DESCRIPTION
%     xEnv                               (object)  environment
%     bResetArtifactLocationsToDefault   (bool)    flag for TL >= TL4.3 to reset DD settings to the default codegen
%                                                  locations (might have been changed by the user)
%                                                  (default == true)
%
%   OUTPUT              DESCRIPTION
%     -
%


%%
if (nargin < 2)
    bResetArtifactLocationsToDefault = true;
end

%% main
ahIncl = ep_dsdd(xEnv, 'Find', '/Config/DDIncludeFiles', 'ObjectKind', 'DDIncludeFile');
if ~isempty(ahIncl)
    i_reloadDdIncludes(xEnv, ahIncl);
    i_removeDdIncludes(xEnv, ahIncl);
end
if bResetArtifactLocationsToDefault
    atgcv_dd_remove_distributed_codegen_locations();
end
end


%%
function i_removeDdIncludes(xEnv, ahIncl)
nIncl = length(ahIncl);
for k = 1:nIncl
    hIncl = ahIncl(k);
    
    ep_dsdd(xEnv, 'SetAccessRights', hIncl, 'access', 'rwrw');
    hDd = ep_dsdd(xEnv, 'Delete', hIncl);  %#ok<NASGU> output needed for internal logic inside "ep_dsdd"
end
end


%%
% Note: For relative Paths the included DDs could not be loaded if the DD was
% opened while not in the in same dir as the main DD.
% For this use case try to reload the files manually with an abs. path.
function i_reloadDdIncludes(xEnv, ahIncl)
sMainPath = i_getDirOfMainDD();
if (isempty(sMainPath) || ~exist(sMainPath, 'dir'))
    % if the directory of the Main DD cannot be determined, it is not possible
    % to apply this function --> just be robust in this case
    return;
end

% TODO: find out if this setting or Rights is really necessary
dsdd('SetAccessRights', '//DD0', ...
    'access',           'rwrw', ...
    'TraverseMode',     'CurrentObjectAndSubTree');
nIncl = length(ahIncl);
for k = 1:nIncl
    hIncl = ahIncl(k);
    
    sDdInclFile = ep_dsdd(xEnv, 'GetFileName', hIncl);
    
    % 1) use only those paths that have no DD_MACROS (identfied by: %)
    if ~isempty(strfind(sDdInclFile, '%'))
        continue;
    end
    
    % 2) use only those paths that make sense when combined with the MainPath
    sFullFile = fullfile(sMainPath, sDdInclFile);
    if exist(sFullFile, 'file')
        sDdInnerPath = i_getDDPath(hIncl);
        if isempty(sDdInnerPath)
            % if no inner DD path is provided, use the dd loadincludefile command (TL >= TL3.5)
            % note: do not use ep_dsdd because error messages could be triggered that are not relevant to users
            if (ep_core_version_compare('tl3.5') >= 0)
                dsdd('LoadIncludedFile', hIncl, 'ignoreAutoLoad', 'on');
            end
        else
            ep_dsdd(xEnv, ...
                'Load',     sDdInnerPath, ...
                'file',     sFullFile, ...
                'readmode', 'OverWrite');
        end
    end
end
end


%%
function sMainPath = i_getDirOfMainDD()
sCurrDD = dsdd('GetDDAttribute', 0, 'fileName');
if ~isempty(sCurrDD)
    sMainPath = fileparts(sCurrDD);
else
    sMainPath = '';
end
end


%%
function sDDPath = i_getDDPath(hIncl)
[sOut, nErr] = dsdd('GetDDPath', hIncl);
if (nErr ~= 0)
    sDDPath = '';
else
    sDDPath = sOut;
end
end




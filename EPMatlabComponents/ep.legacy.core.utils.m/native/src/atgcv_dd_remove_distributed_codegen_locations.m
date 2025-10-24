function atgcv_dd_remove_distributed_codegen_locations()
% Remove customization of code generation output folders.
%
% function atgcv_dd_remove_distributed_codegen_locations()
%
%   INPUT
%      ---
%    
%   OUTPUT
%      ---
%
% Resets the default ProjectFolder and FolderStructure settings in '/Pool/ArtifactsLocation' and cleans up all
% 'ProjectFolder' and 'FolderStructure' objects in that section of the TargetLink DataDictionary. 
%
% This method just returns without any changes of the DataDictionary for TL versions earlier than TL 4.3.
%


%%
% not relevant for TL < TL4.3
if (atgcv_version_p_compare('TL4.3') < 0)
    return;
end


%%
% reset ProjectFolders
dsdd('ResetToDefault', '/Pool/ArtifactsLocation/ProjectFolders/TLPredefinedProjectFolder');
% remove non-default ProjectFolders
ahProjectFolder = dsdd('Find', '/Pool/ArtifactsLocation/ProjectFolders', 'ObjectKind', 'ProjectFolder');
for idx = 1:length(ahProjectFolder)
    if ~strcmp('TLPredefinedProjectFolder', dsdd('GetAttribute', ahProjectFolder(idx), 'name'))
        dsdd('Delete', ahProjectFolder(idx));
    end
end

%%
% reset FolderStructure
dsdd('ResetToDefault', '/Pool/ArtifactsLocation/ProjectFolders/TLPredefinedFolderStructure');
% remove non-default FolderStructures
ahProjectFolder = dsdd('Find', '/Pool/ArtifactsLocation/FolderStructures', 'ObjectKind', 'FolderStructure');
for idx = 1:length(ahProjectFolder)
    if ~strcmp('TLPredefinedFolderStructure', dsdd('GetAttribute', ahProjectFolder(idx), 'name'))
        dsdd('Delete', ahProjectFolder(idx));
    end
end
end

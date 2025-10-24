function astSubsystems = ep_sl_subsystems_filter(astSubsystems, abDoKeep)
% Reduces the number of subsystems in the provided SL subsystem hierarchy while preserving the tree property.
%
% function astSubsystems = ep_sl_subsystems_filter(astSubsystems, abDoKeep)
%
%   INPUT               DESCRIPTION
%     astSubsystems       (array)     SL subsystems with the important fields:
%                                         .iParentIdx    --> the index of the parent subsystem inside the provided array
%                                         .iID           --> the ID of the subsystem
%                                         .iParentID     --> the ID of the parent subsystem
%     abDoKeep            (array)     boolean values indicating whether to keep the subsystem 
%                                     (note: same size as the array of subsystems)
%
%   OUTPUT              DESCRIPTION
%     astSubsystems       (array)     reduced array of SL subsystems with adapted parent-child info
%


%%
if (numel(astSubsystems) ~= numel(abDoKeep))
    error('EP:INTERNAL:ERROR', 'Wrong usage. Both input arrays must have the same number of elements.');
end

%%
if all(abDoKeep)
    % taking a shortcut if all subsystems are to be kept
    return;
end

%% main idea:
% Build up parent-child hierarchy, but now only for the Elements to be kept.
% Strategy: 
% 1) add new Parent Idx for all kept Elements  -- get to the next highest kept Element when searching for new parent
% 2) then all unwanted Elements from the struct array

% Get the index of all kept Elements. This array is essentially the mapping between the old and the new hierarchy.
aiKeepIdx = find(abDoKeep); 
for i = 1:numel(astSubsystems)
    if abDoKeep(i)
        iParentIdx = astSubsystems(i).iParentIdx;
        
        % go the next highest ancestor to be kept; take care: no parent for (new) root elements
        while (~isempty(iParentIdx) && ~abDoKeep(iParentIdx))
            iParentIdx = astSubsystems(iParentIdx).iParentIdx;
        end
        if isempty(iParentIdx)
            % Element i has no Parent --> new root Element without ParentIdx
            astSubsystems(i).iParentIdx = []; 
            astSubsystems(i).iParentID  = [];
        else
            % new Parent index is the position inside the reduced array after the removal of all unwanted Elements
            iNewParentIdx = find(iParentIdx == aiKeepIdx);
            astSubsystems(i).iParentIdx = iNewParentIdx;
            astSubsystems(i).iParentID  = astSubsystems(iParentIdx).iID;
        end
    end
end
astSubsystems = astSubsystems(abDoKeep);

if isempty(astSubsystems)
    return;
end

if isfield(astSubsystems(1), 'aiChildIdx')
    astSubsystems = i_repairChildIdx(astSubsystems);
end
end


%% 
function astSubsystems = i_repairChildIdx(astSubsystems)
abIsToplevel = arrayfun(@i_isToplevel, astSubsystems);
iTop = find(abIsToplevel);
if (length(iTop) ~= 1)
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Could not find unique toplevel subsystem.');
end
% tmp set parent index of top from [] to -1 (cannot be found in algo)
iOrig = astSubsystems(iTop).iParentIdx;
astSubsystems(iTop).iParentIdx = -1;
aiParents = [astSubsystems(:).iParentIdx];
astSubsystems(iTop).iParentIdx = iOrig;

nSub = length(astSubsystems);
for i = 1:nSub
    astSubsystems(i).aiChildIdx = find(i == aiParents);
end
end


%%
function bIsToplevel = i_isToplevel(stSub)
bIsToplevel = isempty(stSub.iParentID);
end




function astElems = atgcv_m01_hierarchy_reduce(astElems, abDoKeep, sParentIdxField)
% Reduces the number of Elements to be kept inside the provided Hierarchy.
%
% function astElems = atgcv_m01_hierarchy_reduce(astElems, abDoKeep, sParentIdxField)
%
%   INPUT               DESCRIPTION
%     astElems            (array)     structs containing the Hierarchy info
%                  Note: Expected to have the following fields:
%          .('sParentIdxField')       the Index of the Parent Element inside
%                                     the struct-Array
%          .<...>                     other fields in structs are _ignored_
%     abDoKeep            (array)     array of boolean values with the same size
%                                     as astElems with the Info if the corresp.
%                                     Element shall be kept inside the Hierarchy
%     sParentIdxField     (string)    optional: name of the field containing the
%                                     ParentIdx info
%                                     (default == 'iParentIdx')
%
%   OUTPUT              DESCRIPTION
%     astElems            (array)     structs containing the reduced Hierarchy info
%


%% shortcut
if all(abDoKeep)
    return;
end

%% optional inputs
if (nargin < 3)
    sParentIdxField = 'iParentIdx';
end

%% main idea:
% Build up parent-child hierarchy, but now only for the Elements to be kept.
% Strategy: 
% 1) add new Parent Idx for all kept Elements
%    -- get to the next highest kept Element when searching for new parent
% 2) then all unwanted Elements from the struct array


% Get the index of all kept Elements. This array is essentially the mapping
% between the old and the new hierarchy.
aiKeepIdx = find(abDoKeep); 

for i = 1:length(astElems)
    if abDoKeep(i)
        iParentIdx = astElems(i).(sParentIdxField);
        
        % go the next highest ancestor to be kept
        % take care: no parent for (new) root elements
        while (~isempty(iParentIdx) && ~abDoKeep(iParentIdx))
            iParentIdx = astElems(iParentIdx).(sParentIdxField);
        end
        if isempty(iParentIdx)
            % Element i has no Parent --> new root Element without ParentIdx
            astElems(i).(sParentIdxField) = iParentIdx; 
        else
            % new Parent index is the position inside the reduced array after
            % the removal of all unwanted Elements
            iNewParentIdx = find(iParentIdx == aiKeepIdx);
            astElems(i).(sParentIdxField) = iNewParentIdx;
        end
    end
end
astElems = astElems(abDoKeep);
end

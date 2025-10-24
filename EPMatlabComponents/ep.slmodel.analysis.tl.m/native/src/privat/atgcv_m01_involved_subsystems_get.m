function ahSubs = atgcv_m01_involved_subsystems_get(stEnv, hTopSub)
% Returns all Subsystems that are involved in the context of the TL-Subsystem.
%
% function ahSubs = atgcv_m01_involved_subsystems_get(stEnv, hTopSub)
%
%   INPUT           DESCRIPTION
%     stEnv           (struct)    environment structure
%     hTopSub         (handle)    DD handle of the toplevel TL subsystem
%                                 (DD->Subsystems->"TopLevelName")
%
%   OUTPUT          DESCRIPTION
%       ahSubs         (array)    DD handles of all involved Subsystems
%                                 (always including the TL Subsystem itself)
%

%%
casSubs = atgcv_mxx_dd_subsystem_tree_get(stEnv, dsdd('GetAttribute', hTopSub, 'name'));
nSubs = length(casSubs);
ahSubs = zeros(1, nSubs);
for i = 1:nSubs
    [bExist, hSub] = dsdd('Exist', ['/Subsystems/' casSubs{i}]);
    if bExist
        ahSubs(i) = hSub;
    end
end

% remove all Subs that do not exist (left as init value zero)
ahSubs(ahSubs == 0) = [];
end




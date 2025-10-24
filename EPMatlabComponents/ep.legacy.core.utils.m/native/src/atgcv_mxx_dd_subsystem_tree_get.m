function casSubTree = atgcv_mxx_dd_subsystem_tree_get(stEnv, sTopSub)
% Returns all Subsystems that are involved in the context of the TL-Subsystem.
%
% function casSubTree = atgcv_mxx_dd_subsystem_tree_get(stEnv, sTopSub)
%
%   INPUT           DESCRIPTION
%     stEnv           (struct)    environment structure
%     sTopSub         (string)    Name of a toplevel TL Subsystem
%                                 (DD->Subsystems->"TopLevelName")
%
%   OUTPUT          DESCRIPTION
%     casSubTree      (array)     names of all involved TL Subsystems
%                                 (always including the toplevel TL Subsystem itself)
%


%% main
% recursively retrieve the subsystem hierarchy
casSubTree = i_getSubsysTree(stEnv, sTopSub);
end


%%
function casCgUnits = i_getCgUnits(astSystemHierarchy)
if isempty(astSystemHierarchy)
    casCgUnits = {};
else
    if isfield(astSystemHierarchy(1), 'cgUnitName')
        casCgUnits = {astSystemHierarchy(:).cgUnitName};
    else
        % TL version below TL4.1
        casCgUnits = {astSystemHierarchy(:).name};
    end
end
end

%%
% recursive function
function casSubTree = i_getSubsysTree(stEnv, sSub)
casSubTree = {};

[bExist, hSub] = dsdd('Exist', ['/Subsystems/' sSub]);
if ~bExist
    stErr = osc_messenger_add(stEnv, 'ATGCV:CODE_GEN:MISSING_CODEGEN_INFO', 'tl_subsystem', sSub);
    osc_throw(stErr);
end
astSystemHierarchy = i_getTlSystemHierarchy(stEnv, hSub);
if ~isempty(astSystemHierarchy)
    iFound  = find(strcmp(sSub, i_getCgUnits(astSystemHierarchy)));
    if ~isempty(iFound)
        % we have a real toplevel sub with its own subtree --> add toplevel and apply function recursively on children
        casSubTree{end + 1} = sSub;

        aiChildren = astSystemHierarchy(iFound).children;
        if ~isempty(aiChildren)
            casChildren = unique(i_getCgUnits(astSystemHierarchy(aiChildren)), 'stable');
            for i = 1:length(casChildren)
                casSubTree = [casSubTree, i_getSubsysTree(stEnv, casChildren{i})]; %#ok<AGROW>
            end
        end
    else
        % DEAD CODE: actually should never happen, but just to be sure, add the subsystem itself
        casSubTree{end + 1} = sSub;
    end
end
end


%%
function astSystemHierarchy = i_getTlSystemHierarchy(stEnv, hSub)
astSystemHierarchy = [];

hSubsysInfo = atgcv_mxx_dsdd(stEnv, 'GetSubsystemInfo', hSub);
if (numel(hSubsysInfo) > 1)
    hSubsysInfo = hSubsysInfo(1);
end
if dsdd('Exist', hSubsysInfo, 'property', 'SystemHierarchy')
    sHierarchStructString = atgcv_mxx_dsdd(stEnv, 'Get', hSubsysInfo, 'SystemHierarchy');
    
elseif dsdd('Exist', hSubsysInfo, 'property', 'IncrementalSystemsHierarchy')
    sHierarchStructString = atgcv_mxx_dsdd(stEnv, 'GetIncrementalSystemsHierarchy', hSubsysInfo);
    
else
    sHierarchStructString = '';
end
if ~isempty(sHierarchStructString)
    astSystemHierarchy = eval(sHierarchStructString);
end
end



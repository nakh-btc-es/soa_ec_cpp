function stStateflow = atgcv_m01_sfblock_blockvars_get(stEnv, hBlock)
% returns all relevant block variables from a Stateflow block
%


%%
stStateflow = struct( ...
    'stInputs',    struct(), ...
    'stOutputs',   struct(), ...
    'stBlockVars', struct());

sBlockType = dsdd('GetBlockType', hBlock);
if strcmpi(sBlockType, 'Stateflow')
    hSfNodes = atgcv_mxx_dsdd(stEnv, 'GetStateflowNodes', hBlock);
    if ~isempty(hSfNodes)
        stStateflow.stInputs = i_getBlockVarsOfKind(stEnv, hSfNodes, 'Inputs');
        stStateflow.stOutputs = i_getBlockVarsOfKind(stEnv, hSfNodes, 'Outputs');
        stStateflow.stBlockVars = i_getBlockVarsOfKind(stEnv, hSfNodes, 'BlockVariables');
    end
end
end


%%
function stBlockVars = i_getBlockVarsOfKind(stEnv, hSfNodes, sKind)
[bExist, hKindGroup] = dsdd('Exist', sKind, 'Parent', hSfNodes);
if bExist
    stBlockVars = atgcv_mxx_dsdd(stEnv, 'GetAll', hKindGroup);
else
    stBlockVars = struct();
end
end
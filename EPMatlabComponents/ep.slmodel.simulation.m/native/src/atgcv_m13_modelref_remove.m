function [casNewSubsystemPaths, casRefModels] = atgcv_m13_modelref_remove(stEnv, hSub)
% Resolves all model references in the Subsystem (breaking the reference link).
%
% function [casNewSubsystemPaths, casRefModels] = atgcv_m13_modelref_remove(stEnv, hSub)
%
% INPUTS             DESCRIPTION
%   stEnv            (struct)    Environment structure
%   hSub             (handle)    Simulink/TargetLink subsystem
%
%
% OUTPUTS:
%   casNewSubsystemPaths  (strings)  path of all new subsystem blocks that were replaced for the original model
%                                    reference blocks
%   casRefModels          (strings)  model names that the corresponding model ref blocks were referencing
%

%%
casNewSubsystemPaths = {};
casRefModels = {};
ahAllModelRefs = ep_find_system(hSub,...
    'LookUnderMasks', 'on', ...
    'FollowLinks',    'off', ...
    'BlockType',      'ModelReference');

if isempty(ahAllModelRefs)
    return;
end

bSetSampleTimeToInheritForFctCallTriggers = true; % does this make sense?

nBreakCnt = numel(ahAllModelRefs);
casNewSubsystemPaths = cell(1, nBreakCnt);
casRefModels = cell(1, nBreakCnt);
for i = 1:nBreakCnt
    [sNewSubsystemPath, sRefModelName] = ...
        atgcv_m13_modelref_replace(stEnv, ahAllModelRefs(i), bSetSampleTimeToInheritForFctCallTriggers);
    casNewSubsystemPaths{i} = sNewSubsystemPath;
    casRefModels{i} = sRefModelName;
end
end

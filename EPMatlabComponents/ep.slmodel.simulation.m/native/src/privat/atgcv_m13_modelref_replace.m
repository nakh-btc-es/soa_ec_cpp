function [sNewSubsystemPath, sRefModelName] = atgcv_m13_modelref_replace(stEnv, hModelRef, bSetSampleTimeToInheritForFctCallTriggers)
% Replacing ModelReference with Subsystem having the same contents.
%
% function [sNewSubsystemPath, sRefModelName] = ...
%               atgcv_m13_modelref_replace(stEnv, hModelRef, bSetSampleTimeToInheritForFctCallTriggers)
%
% INPUTS             DESCRIPTION
%   stEnv            (struct)    Environment structure
%   hModelRef        (handle)    ModelReference block
%   bSetSampleTimeToInheritForFctCallTriggers  (boolean)  true, when the root function-call trigger ports 
%                                                   have to be assigned to -1 inheriting the sample-time value
%
% OUTPUTS:
%   sNewSubsystemPath (string)   model path to the subsystem that has replaced the original model reference block
%   sRefModelName     (string)   name of the model that the replaced model reference block has referenced
%


%%
[bSuccess, sNewSubsystemPath, sRefModelName] = ...
    i_modelRefToSubsystem(stEnv, hModelRef, bSetSampleTimeToInheritForFctCallTriggers);
if ~bSuccess
    sModelRef = getfullname(hModelRef);
    stErr = osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:MODELREF_DISABLED_FAILED', ...
        'block', sModelRef);
    osc_throw(stErr);
end
end


%%
function [bSuccess, sNewSubsystemPath, sModelName] = ...
    i_modelRefToSubsystem(stEnv, hModelRefBlock, bSetSampleTimeToInheritForFctCallInports)
bSuccess = false;
sNewSubsystemPath = '';
sModelName = '';
try
    sModelName = get_param(hModelRefBlock, 'ModelName');
    hReferencingMdl = bdroot(hModelRefBlock);
    hReferencedMdl  = get_param(sModelName, 'handle');
    
    sOriginalName = get_param(hModelRefBlock, 'Name');
    sOriginalModelRefBlock = getfullname(hModelRefBlock);
    [sActiveVariantSubsystem, hVarSub] = i_checkIfRefModelIsAnActiveVariant(hModelRefBlock);
    
    
    % create subsystem with name
    sTmpName = 'btc_dummy';
    sTempFullname = sprintf('%s_%s', sOriginalModelRefBlock, sTmpName);
    add_block('built-in/SubSystem', sTempFullname, 'MakeNameUnique', 'on');
    
    Simulink.BlockDiagram.copyContentsToSubSystem(sModelName, sTempFullname);
    
    % set for the root function-call trigger ports the sample time to -1
    if bSetSampleTimeToInheritForFctCallInports
        i_setSampleTimeToInheritForFctCallInports(sTempFullname);
    end
    % store the initial position
    sOrigBlockPos = get_param(sOriginalModelRefBlock, 'Position');
    
    % copy necessary properties like block priority EP-1589
    set_param(sTempFullname, 'Priority', get_param(hModelRefBlock, 'Priority'));
    
    % delete the model reference block
    delete_block(sOriginalModelRefBlock);
    
    % place the block in the original position - all lines are now connected
    set_param(sTempFullname, 'Position', sOrigBlockPos);
    
    % rename the subsystem block that is the substitute of the model reference block
    set_param(sTempFullname, 'Name', sOriginalName);
    % Note: after the renaming sOriginalModelRefBlock is referring to the replacement subsystem
    sNewSubsystemPath = sOriginalModelRefBlock;
    
    % mark the replacement sub and enhance it with the original model info
    ep_sim_modelref_replacement('mark', sNewSubsystemPath, sModelName);    
    
    % activate the variant after the replacement again
    if ~isempty(sActiveVariantSubsystem)
        set_param(sNewSubsystemPath, 'VariantControl', sActiveVariantSubsystem);
        
        if ~i_isWrapperVariantSub(hVarSub)
            % Fixes EP-1621
            set_param(sNewSubsystemPath, 'TreatAsAtomicUnit', 'on');
        end
    end
    
    % copy model workspace from former referenced model into the model where the subsystem resides
    atgcv_m13_mdlbase_copy(hReferencedMdl, hReferencingMdl);
    
    % transfer SF data from the original referenced model into the referencing model
    % do this only for versions <ML2022a because model data structure has changed
    if verLessThan('matlab', '9.12')
        bOverwrite = false;
        atgcv_m13_sfdata_transfer(stEnv, hReferencedMdl, hReferencingMdl, bOverwrite);
    end
    
    bSuccess = true;
    
catch oEx %#ok
end
end


%%
function [sActiveVariantSubsystem, hVarSub] = i_checkIfRefModelIsAnActiveVariant(hBlock)
% Default for return values
sActiveVariantSubsystem = '';
hVarSub = [];

sParent = get(hBlock, 'Parent');
if ~isempty(sParent)
    hParent = get_param(sParent, 'Handle');
    if strcmp(get(hParent, 'Type'), 'block') && strcmp(get(hParent, 'Variant'), 'on')
        if ep_core_version_compare('ML9.6') >= 0
            sActiveVariantSubsystem = get(hParent, 'CompiledActiveChoiceControl');
        else
            sActiveVariantSubsystem = get(hParent, 'ActiveVariant');
        end
        hVarSub = hParent;
    end
end
end


%%
% Hack solution for C-S AUTOSAR wrapper use case (EPDEV-50118)
% TODO: replace with better one where issues with *global* SL-Functions are handled more generically
function bIsWrapperVarSub = i_isWrapperVariantSub(xVariantSub)
bIsWrapperVarSub = i_containsVariant(xVariantSub, 'orig') && i_containsVariant(xVariantSub, 'dummy');
end


%%
function bContainsVariant = i_containsVariant(xVariantSub, sVariantControl)
bContainsVariant = ~isempty(ep_find_system(xVariantSub, ...
    'SearchDepth',   1, ...
    'Variants',      'AllVariants', ...
    'VariantControl', sVariantControl));
end


%%
function  i_setSampleTimeToInheritForFctCallInports(sSub)
casInports = ep_find_system(sSub, ...
    'LookUnderMasks', 'on', ...
    'FollowLinks',    'on', ...
    'SearchDepth',    1, ...
    'BlockType',      'Inport');
for j = 1:numel(casInports)
    if strcmp(get_param(casInports{j}, 'OutputFunctionCall'), 'on')
        if ~strcmp(get_param(casInports{j}, 'SampleTime'), '-1')
            set_param(casInports{j}, 'SampleTime', '-1')
        end
    end
end
end

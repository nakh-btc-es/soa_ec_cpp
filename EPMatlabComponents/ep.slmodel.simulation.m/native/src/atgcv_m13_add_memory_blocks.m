function atgcv_m13_add_memory_blocks(stEnv, sDestMdl, sSubsystem, nUsage)
% add used data store memory blocks to the extraction model
%
% function atgcv_m13_add_memory_blocks(stEnv, sDestMdl, sSubsystem, nUsage)
%
%   INPUTS               DESCRIPTION
%     stEnv              (struct)     Environment structure
%     sDestMdl           (string)     Extraction Model Name
%     sSubsystem         (string)     Subsystem name.
%     nUsage             (integer)    1, if we handle a TargetLink model
%                                     2, if we handle a Simulink model
%                                        stored in result path.
%
%   OUTPUT               DESCRIPTION
%     -                     -
%   REMARKS
%
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%


% (1) get all data storage memory blocks from the hSrcMdl,
% which are resides above the subsytem 'sSubsystem'
% It is assumed that the list of memory blocks is sorted by path
% The longer paths are first and later occurences of the same
% DataStoreName are shadowed by the earlier (deeper path) once
sParent = get_param( sSubsystem, 'Parent');
casMemoryBlocks = atgcv_m13_memory_blocks_get(sParent);

% (2) check whether for each memory data storage unit
% a reading or writting access in the subsystem 'sSubsystem'
% add the subsystems below exists
% If yes, add the memory storage data unit in the destination
% model.
casDSMNames = cell(0);
for i=1:length( casMemoryBlocks )
    sMemoryBlock = casMemoryBlocks{i};
    sDSMName = get_param( sMemoryBlock, 'DataStoreName' );
    
    if any(ismember(casDSMNames, sDSMName))
        % skip DSM for already existing block
        continue;
    else
        casDSMNames{end+1} = sDSMName;
    end
    
    % add the sMemoryBlock to the destination model 'hDestMdl'
    % Get name of the memory block
    sDestName = get_param( sMemoryBlock, 'Name' );
    
    bTLMemoryBlock = strcmp( ...
        get_param( sMemoryBlock, 'MaskType' ),'TL_DataStoreMemory');
    
    if( nUsage == 1 && bTLMemoryBlock )
        sBlock = char( ep_find_system(sDestMdl, ...
            'LookUnderMasks','on','Tag','MIL Subsystem') );
        hBlock = atgcv_m13_add_block(sMemoryBlock, sBlock, sDestName);
        atgcv_m13_copy_mask_info(stEnv, hBlock, sMemoryBlock );
    else
        hBlock = atgcv_m13_add_block(sMemoryBlock, sDestMdl, sDestName);
        atgcv_m13_copy_mask_info(stEnv, hBlock, sMemoryBlock );
    end
    nGap = atgcv_m13_offset;
    nWidth = 50;
    y1 = 200 + ((nWidth+nGap) * i);
    arPosition = [y1, 10, (y1+50), 40];
    set_param(hBlock,'position',arPosition);
end
end
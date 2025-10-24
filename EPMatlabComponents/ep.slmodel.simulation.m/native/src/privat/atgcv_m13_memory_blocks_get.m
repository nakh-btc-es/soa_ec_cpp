function casMemoryBlocks = atgcv_m13_memory_blocks_get(sSubsystem)

%**************************************************************************
% returns all data memory TargetLink/Simulink blocks, which are supper
% subsystems of the given 'sSubsystem' Subsystem
%**************************************************************************

casMemoryBlocks = cell(0);
if( ~isempty( sSubsystem ) )
    
    % Simulink and TagetLink blocks
    casBlocks = ep_find_system( sSubsystem,...
        'FollowLinks', 'on', ...
        'SearchDepth',1, ...
        'BlockType', 'DataStoreMemory');
    
    sParent = get_param( sSubsystem, 'Parent');
    
    casParentBlocks = atgcv_m13_memory_blocks_get( sParent );
        
    for i=1:length( casBlocks )
        casMemoryBlocks{end+1} = casBlocks{i}; %#ok
    end
    for i=1:length( casParentBlocks )
        casMemoryBlocks{end+1} = casParentBlocks{i}; %#ok
    end
end
end

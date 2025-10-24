function atgcv_m13_add_addfile_blocks(sDestMdl, sSubsystem, nUsage)
% add used AddFile blocks to the extraction model
%
% function atgcv_m13_add_addfile_blocks(sDestMdl, sSubsystem, nUsage)
%
%   INPUTS               DESCRIPTION
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

% (1) get all data storage AddFile blocks from the hSrcMdl,
% which are resides above the subsytem 'sSubsystem'
sParent = get_param( sSubsystem, 'Parent');
casAddFileBlocks = i_get_addfile_blocks(sParent, nUsage);
sBlock = char(ep_find_system(sDestMdl, 'LookUnderMasks', 'on', 'Tag', 'MIL Subsystem'));

% (2) add blocks to the extraction model
for i=1:length( casAddFileBlocks )
    sAddFileBlock = casAddFileBlocks{i};
    sDestName = get_param( sAddFileBlock, 'Name' );
    sName = ['btc','_',sDestName,'_',num2str(i)];
    hBlock = atgcv_m13_add_block(sAddFileBlock, sBlock, sName);
    
    nGap = atgcv_m13_offset;
    nWidth = 50;
    y1 = 100 + ((nWidth+nGap) * i);
    arPosition = [600, y1, 700, (y1+50)];
    set_param(hBlock,'position',arPosition);
end
end



%%
% returns all data memory TargetLink/Simulink blocks, which are parent subsystems of the given 'sSubsystem' Subsystem
function casAddFileBlocks = i_get_addfile_blocks(sSubsystem, nUsage)
casAddFileBlocks = cell(0);
if( ~isempty( sSubsystem ) )
    if( nUsage == 1 )
        % TagetLink model
        casAddFileBlocks = ep_find_system( sSubsystem,...
            'LookUnderMasks', 'on', ...
            'FollowLinks',    'on', ...
            'SearchDepth',    1, ...
            'MaskType',       'TL_AddFile');
    elseif( nUsage == 2 )
        % Simulink model
        % not supported yet (maybe there is no SL-Block)
    end
    sParent = get_param( sSubsystem, 'Parent');

    casTempBlocks = i_get_addfile_blocks( sParent, nUsage );

    for i=1:length( casTempBlocks )
        casAddFileBlocks{end+1} = casTempBlocks{i};
    end
end
end

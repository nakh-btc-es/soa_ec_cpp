function atgcv_m13_copyfcn_remove( hBlock )
% Removes all copyfcn of the block and its subsystems. 
%
% function atgcv_m13_copyfcn_remove( hBlock )
%
% INPUTS             DESCRIPTION
%   hBlock           (handle)     Simulink block.
%   
%
% OUTPUTS:
%

%%
try
    sLinkStatus = get_param(hBlock, 'LinkStatus');
    if any(strcmpi(sLinkStatus, {'resolved', 'implicit', 'unresolved'}))
        return;
    end
    if ~isempty(get_param(hBlock, 'CopyFcn'))
        set_param(hBlock, 'CopyFcn', '');
    end
    if ~isempty(get_param(hBlock, 'DestroyFcn'))
        set_param(hBlock, 'DestroyFcn', '');
    end
catch oEx
    return;
end

aoSubsystems = ep_find_system(hBlock,...
    'FollowLinks', 'on', ...
    'BlockType',   'SubSystem');

nLength = length( aoSubsystems );
for i = 1:nLength
    hSubsystem = aoSubsystems(i);
    try
        sLinkStatus = get_param(hSubsystem, 'LinkStatus');
        if any(strcmpi(sLinkStatus, {'resolved', 'implicit', 'unresolved'}))
            continue;
        end
    catch oEx
        continue;
    end
    
    try
        if(~isempty( get_param(hSubsystem, 'CopyFcn' ) ) )
            set_param( hSubsystem, 'CopyFcn', '');
        end
        if(~isempty( get_param(hSubsystem, 'DestroyFcn' ) ) )
            set_param( hSubsystem, 'DestroyFcn', '');
        end
        if(~isempty( get_param(hSubsystem, 'NameChangeFcn' ) ) )
            set_param( hSubsystem, 'NameChangeFcn','');
        end
        if(~isempty( get_param(hSubsystem, 'StartFcn' ) ) )
            set_param( hSubsystem, 'StartFcn', '');
        end
        if(~isempty( get_param(hSubsystem, 'StopFcn' ) ) )
            set_param( hSubsystem, 'StopFcn', '');
        end
    catch oEx
        disp('');
    end
end
end

function caxSubsystem = atgcv_m13_subsystem_children_get_all( xSubsystem )
% Returns all children subsystems of a given subsystem (recursive)
%
% function caxSubsystem = atgcv_m13_subsystem_children_get_all( xSubsystem )
%
%   INPUTS               DESCRIPTION
%     xSubsystem         (handle)     XML node subsystem.
%
%   OUTPUT               DESCRIPTION
%     -                     -
%
%   REMARKS
%     Per default, all parameters auf simulink Blocks are declared to Tunable
%
%  REFERENCE(S):
%     Design Document:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

caxSubsystem = {};
ahScopes = ep_em_entity_find( xSubsystem, 'child::Scope');
for i = 1:length( ahScopes )
    xFindSubsystem = ahScopes{i};   
    
    caxSubsystem{end+1} = xFindSubsystem;
    
    % and check all children of xFindSubsystem
    caxSubsystem = horzcat( caxSubsystem, ...
        atgcv_m13_subsystem_children_get_all( xFindSubsystem ) );
end

%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************
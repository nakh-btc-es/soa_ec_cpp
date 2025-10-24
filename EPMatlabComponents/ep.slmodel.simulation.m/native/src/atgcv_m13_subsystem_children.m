function caxSubsystem = atgcv_m13_subsystem_children( xSubsystem )
% Returns all children subsystems of a given subsystem (recursive)
%
% function caxSubsystem = atgcv_m13_subsystem_children( xSubsystem )
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

caxSubsystem = ep_em_entity_find( xSubsystem, 'child::Scope');


%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************
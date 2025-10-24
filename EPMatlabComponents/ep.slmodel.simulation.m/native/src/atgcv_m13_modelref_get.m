function sModelRefPath = atgcv_m13_modelref_get( xSubsystem, bTLModel )
%
% function sModelRefPath = atgcv_m13_modelref_get( xSubsystem, bTLModel )
%
% INPUTS             DESCRIPTION
%  
%   
%
% OUTPUTS:
%

%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2008
%
%%

sModelRefPath = '';
% check if parent subsystem is defined
% get the TL/SL Model Reference path

xModelReference = ep_em_entity_find_first( xSubsystem, 'child::Model' );

if( ~isempty( xModelReference ) )
    sModelRefPath = ep_em_entity_attribute_get( xSubsystem, 'physicalPath');
end


%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************

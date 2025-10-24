function [bIsBusPort,bIsSimple] = atgcv_m13_isbusport( xPort )
% Checks if a port is a bus port.
%
% Parameters:
%    xPort           (handle)    Port of the model analysis.
%                                (see ModelAnalysis.dtd)
%
% Output:
%    bIsBusPort      (boolean)   Return true, when port is a bus port.
%    bIsSimple       (boolean)   Retrun true, when port is a simple port. 
% AUTHOR(S):
%   Remmer.Wilts@osc-es.de
% $$$COPYRIGHT$$$-2006
%
%%

sCompositeSig = ep_em_entity_attribute_get(...
    xPort, 'compositeSig');

if( isempty( sCompositeSig ) )
    bIsBusPort = false;
    bIsSimple = true;
else
    switch(sCompositeSig)
        case 'mux'
            bIsBusPort = false;
            bIsSimple = false;
        case 'bus'
            bIsBusPort = true;
            bIsSimple = false;
        case 'pseudo_bus'
            bIsBusPort = true;
            bIsSimple = false;
        otherwise
            bIsBusPort = false;
            bIsSimple = true;
    end
end

%**************************************************************************
% END OF FILE
%**************************************************************************

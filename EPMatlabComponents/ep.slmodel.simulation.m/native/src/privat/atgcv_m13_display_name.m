function sName = atgcv_m13_display_name(xIfName)
% Returns the display name of an xIfName (ModelAnalysis.xml)
% 
% function 
%
%   INPUT               DESCRIPTION
%       xIfName          (xml node)   IfName node (see ModelAnalysis.dtd)
%       
%   OUTPUT              DESCRIPTION
%       sName            (string)     Display name 
%
%   REMARKS
%
%   REFERENCE(S):
%     Design Document: 
%        Section : M13
%        Download:
%        
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

% note only the first value is used
sName = strrep( ep_em_entity_attribute_get( xIfName, 'displayName'),...
    char(10), ' ');
  
%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

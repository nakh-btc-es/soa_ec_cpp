function sValue = ep_em_entity_attribute_get(oEntity, sAttName)
% Returns the value of the given attribute name of an entity.
%
% function sValue = ep_em_entity_attribute_get(oEntity, sAttName)
%
%   INPUT               DESCRIPTION
%     oEntity           (object)   Entity object
%     sAttName          (string)   Attribute name
%   OUTPUT              DESCRIPTION
%     sValue            (char)     Attribute value  
%   REMARKS
%     
%
%   (c) 2007-2010 by OSC Embedded Systems AG, Germany


%% intertnal
%
%   REFERENCE(S):
%     EP5 Document:
%        Download: ...
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

%% Check parameters

sValue =  mxx_xmltree('get_attribute', oEntity, sAttName);
if( isempty(sValue) )
    sValue = '';
end







%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

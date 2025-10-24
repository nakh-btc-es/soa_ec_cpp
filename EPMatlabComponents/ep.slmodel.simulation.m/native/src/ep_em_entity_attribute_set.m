function ep_em_entity_attribute_set(oEntity, sAttName, sValue)
% Sets an attribute for an entity with the given parameter.
%
% function ep_em_entity_attribute_set(oEntity, sAttName, sValue)
%
%   INPUT               DESCRIPTION
%     oEntity           (object)   Entity object
%     sAttName          (string)   Attribute name  
%     sValue            (char)     Attribute value
%   OUTPUT              DESCRIPTION
%
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

try
    if( isempty(sValue) )
        sValue = '';
    end
    mxx_xmltree('set_attribute', oEntity, sAttName, sValue);
catch
    stError = atgcv_lasterror;
    error( 'ATGCV:API:ATTRIBUTE_SETTING_FAILED', stError.message );
end

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

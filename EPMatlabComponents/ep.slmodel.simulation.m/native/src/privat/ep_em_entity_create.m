function oEntity = ep_em_entity_create(oParent, sEntityTypeName, bPersistency)
% Creates an entity with the given parameter.
%
% function oEntity = ep_em_entity_create(oParent, sEntityTypeName, bPersistency)
%
%   INPUT               DESCRIPTION
%     oParent           (object)    Entity object    
%     sEntityTypeName   (string)    Entity type name
%     bPersistency     [false|true] Optional (default: true)] boolean
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


if( nargin < 3 )
    bPersistency = true;
end

try
    oEntity = mxx_xmltree('add_node', oParent, sEntityTypeName);
catch
    stError = atgcv_lasterror;
    error( 'ATGCV:API:ENTITY_CREATION_FAILED', stError.message );
end


%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

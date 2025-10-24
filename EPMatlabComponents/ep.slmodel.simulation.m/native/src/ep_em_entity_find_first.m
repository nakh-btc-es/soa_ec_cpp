function oObject = ep_em_entity_find_first(oEntity, sXPath)
% Find with an sXPath enities in the data structure.
%
% function caoObject = ep_em_entity_find(oEntity, sXPath)
%
%   INPUT               DESCRIPTION
%     oEntity           (object)    Entity object    
%     sXPath            (string)    Path string to find entities
%   OUTPUT              DESCRIPTION
%     caoObject        (cell array) Cell array of found entities, 
%                                   references and links.
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

stEnv = 0; % default env=0
atgcv_api_argcheck(stEnv, 'sXPath', sXPath, ...
    {'class', 'char'}, 'not_empty');

oObject = [];
caoEntity = ep_em_entity_find(oEntity, sXPath);
if ~isempty(caoEntity)
    oObject = caoEntity{1};
end

return;


%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

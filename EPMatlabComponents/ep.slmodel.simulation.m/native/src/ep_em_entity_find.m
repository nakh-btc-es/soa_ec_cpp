function caoObject = ep_em_entity_find(oEntity, sXPath)
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


%%
stEnv = 0;
atgcv_api_argcheck(stEnv, 'sXPath', sXPath, {'class', 'char'}, 'not_empty');

caoObject = cell(0);
try
    ahObject = mxx_xmltree('get_nodes', oEntity, sXPath);
    nLength = length(ahObject);
    for i=1:nLength
        caoObject{i} = ahObject(i);
    end
catch
    stErr = lasterror;
    sMsg = sprintf( 'Failed xPath expression "%s". (%s)', sXPath, stErr.message );
    error( 'ATGCV:API:ENTITY_FIND_FAILED', sMsg );
end
end

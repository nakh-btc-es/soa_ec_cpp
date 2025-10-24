function atgcv_m46_tlclass_settings( hPort, cahSources )
% Special handling for ports, this function sets the
% the TL variable class for sources objects, which are not 
% specified.
% For more information see BTS/12112
% 
% function atgcv_m46_tlclass_settings( hPort, cahSources )
%
%   INPUT               DESCRIPTION
%       hPort            (handle)     TargetLink Port
%       cahSources     (cell array)   Cell array of Source Handles
%       
%   OUTPUT              DESCRIPTION
%      
%   REMARKS
%
%   REFERENCE(S):
%     Design Document: 
%        Section : M46
%        Download:
%        
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

for i = 1 : length ( cahSources )
    hSource = cahSources{i};
    
    % check if hSource is a TL block
    if( ~ds_isa( hSource, 'tlblock') )
        continue;
    end
    
   
    % check if source block is a const-Block (first only const blocks are
    % considered)
    sBlockType = get( hSource, 'BlockType' );
    if( strcmp( sBlockType, 'Constant' ) )
        % now we have a TL constant block

        % check if the Class of the constant block is 'default'
        sClass = tl_get( hSource ,'output.class');

        if( strcmp( sClass, 'default' ) )
            % we have found, now we have to set the same values like the hPort
            sPortClass = tl_get( hPort,'output.class');

            nDim = tl_get( hPort,'output.width');
            anLsb =  tl_get( hPort,'output.lsb');
            anOffset = tl_get( hPort, 'output.offset');
            sType = tl_get( hPort, 'output.type' );
            sScaling = tl_get( hPort, 'output.scaling' );

            if( ~strcmp( sPortClass, 'default' ) )
                tl_set( hSource,'output.class', sPortClass);
                tl_set( hSource,'output.type', sType );
                tl_set( hSource,'output.width',nDim);
                tl_set( hSource,'output.arb', 1 );
                tl_set( hSource,'output.lsb', anLsb );
                tl_set( hSource,'output.offset', anOffset );
                tl_set( hSource,'output.scaling', sScaling );
            else
                aoClasses = dsdd('find','//DD0/Pool/VariableClasses',...
                    'objectkind','VariableClass',...
                    'property',{'Name','Storage','Value','default'});
                if( ~isempty( aoClasses ) )
                    oClass = aoClasses(1);
                    sPortClass = dsdd('GetAttribute',oClass,'name');
                    tl_set( hSource,'output.class', sPortClass);
                    tl_set( hSource,'output.scaling', sScaling );
                    tl_set( hSource,'output.type', sType );
                    tl_set( hSource,'output.width',nDim);
                    tl_set( hSource,'output.arb', 1 );
                    tl_set( hSource,'output.lsb', anLsb );
                    tl_set( hSource,'output.offset', anOffset );
                end
            end
        end
    end
end

%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************




%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

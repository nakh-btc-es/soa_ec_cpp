function sPath = atgcv_m13_find_mask_var(hBlock,sSFVarName)
%
% function sPath = atgcv_m13_find_mask_var(sBlock,sSFVarName)
%
%   INPUTS               DESCRIPTION
%
%
%   OUTPUT               DESCRIPTION
%     -                     -
%
%   
%%

sPath = '';
if( isempty( hBlock ) )
    return
end
hParent = get_param(hBlock,'Parent');
if( isempty( hParent ) )
    return
end
stRes = get_param(hBlock,'DialogParameters');
if( isempty( stRes ) )
    sPath = atgcv_m13_find_mask_var(hParent,sSFVarName);
else
    casFieldName = fieldnames(stRes);
    for i = 1:length( casFieldName )
        sName = casFieldName{i};
        if( strcmp( sName , sSFVarName) )
            sPath = get_param( hBock, 'Path');
            return;
        end
    end    
    sPath = atgcv_m13_find_mask_var(hParent,sSFVarName);
end

%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************

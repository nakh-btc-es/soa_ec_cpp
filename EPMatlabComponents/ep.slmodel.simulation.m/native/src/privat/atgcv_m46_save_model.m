function atgcv_m46_save_model(sModelName, bCloseSaveDD)
% 
% function atgcv_m46_save_model(sModelName, bCloseSaveDD)
%
%   INPUT               DESCRIPTION
%       sModel          (string) Model name of the simulink model
%       bCloseSaveDD    (boolean) Save DD
%   OUTPUT              DESCRIPTION
%     
%   REMARKS
%
%   REFERENCE(S):
%     Design Document: 
%        Section : M13
%        Download:
%        http://pcosc29/dp2004/Download.aspx?ID=1cd1982c-9a3f-4a8d-a155-ce05bc5d84a6
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

if atgcv_use_tl
    % close model without DD requester
    sBatchMode = ds_error_get('BatchMode');
    ds_error_set('BatchMode','on');
end

if( ~atgcv_debug_status )
    sWarn = warning;
    warning off all;
end

save_system(sModelName, [], 'OverwriteIfChangedOnDisk', true);
if( bCloseSaveDD )
    if atgcv_use_tl
        dsdd('Close','Save','on');
    end
end

if( ~atgcv_debug_status )
    warning( sWarn );
end

if atgcv_use_tl
    ds_error_set('BatchMode',sBatchMode);
end

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
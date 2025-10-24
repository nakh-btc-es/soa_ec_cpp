function stError = atgcv_m46_tl_msg_eval(stEnv)
%
% function stError = atgcv_m46_tl_msg_eval(stEnv)
%
%   INPUT               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%     .sResultPath       (string)    Result directory for outputs
%                                    the execution of the extraction model.
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


stError = '';
% Report all kink of warnings and errors
tl_batch_mode = tl_error_get('batchmode');
tl_error_set('batchmode', 'on');

astRes = ds_error_get('AllMessages');
if(~isempty(astRes) )
    for i=1:length(astRes)
        
        stRes = astRes(i);
        if( isstruct( stRes ) )
            if( isfield( stRes, 'msg' ) )
                sMsg = stRes.msg;
            else
                sMsg = 'No exception message defined. Please refer to Matlab console output.';
            end
            msgtype = '';
            if( isfield( stRes, 'type') )
                msgtype = stRes.type;
            end
            switch msgtype
                case {'note', 'advice'}
                    osc_messenger_add(stEnv,...
                        'ATGCV:MDEBUG_ENV:DS_MSGDLG_NOTE', ...
                        'tlmsg', sMsg);
                case 'warning'
                    osc_messenger_add(stEnv,...
                        'ATGCV:MDEBUG_ENV:DS_MSGDLG_WARNING', ...
                        'tlmsg', sMsg);
                case {'error', 'fatal'}
                    stError = osc_messenger_add(stEnv,...
                        'ATGCV:MDEBUG_ENV:DS_MSGDLG_ERROR', ...
                        'tlmsg', sMsg);
                otherwise
                    % should be dead code! just for robustness
                    stError = osc_messenger_add(stEnv,...
                        'ATGCV:MDEBUG_ENV:DS_MSGDLG_ERROR', ...
                        'tlmsg', sMsg);
            end
            
        end
    end
end

ds_msgdlg('Clear');
ds_msgdlg('Close');
tl_error_set('batchmode', tl_batch_mode);


%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

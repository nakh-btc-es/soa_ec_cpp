function atgcv_exec_transfer_msglog(stEnv, sMsgLogFile)
% Transfer the message log file to the current error message system.
%
% function atgcv_exec_transfer_msglog(stEnv, sMsgLogFile)
%
%   INPUT              DESCRIPTION
%     stEnv              (struct)  Environment structure with a component
%                                  ".hMessenger"
%     sMsgLogFile        (string)  Message log files.
%
%   OUTPUT             DESCRIPTION
%
%   REFERENCE(S):
%     ---
%
%   RELATED MODULES:
%     ---
%
%   AUTHOR(S):
%     Remmer Wilts
%     Alex Hornstein (fix für BTS/7424)
% $$$COPYRIGHT$$$-2005
%%




hMessenger = 0;

if( ~isempty( stEnv ) )
    if( isfield( stEnv  ,'hMessenger' ) )
        hMessenger = stEnv.hMessenger;
    end
end
if isnumeric(hMessenger)
    hMessenger = atgcv_m_messenger( hMessenger, 'get_global');
end

oFile = java.io.File(sMsgLogFile);
oException = com.btc.et.messenger.MessengerUtils.transfer_msglog(hMessenger, oFile);

if( ~isempty( oException ) )
    stError.identifier = char(oException.getID());
    stError.message = char(oException.getMessage());
    oHint = oException.getHint();
	if( ~isempty(oHint) )
		stError.hint = char(oHint);
	end
    stError.stEnv = stEnv;
    stError.entity = oException.getEntity();
    osc_throw(stError);
end

%**************************************************************************
% END OF FILE
%**************************************************************************

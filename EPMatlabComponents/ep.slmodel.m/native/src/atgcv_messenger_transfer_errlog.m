function atgcv_messenger_transfer_errlog( stEnv , sErrorLogFile )
%  Add errlog messages into messenger.
%
%  function atgcv_messenger_transfer_errlog( stEnv , sErrorLogFile )
%
%   PARAMETER(S)          DESCRIPTION
%    stEnv                (struct)
%    sErrorLogFile        (string)     parsed xml structure from a errorlog
%
%   OUTPUT
%
%   REMARKS
%
%   REFERENCE(S):
%     Design Document:
%        Section : M18
%        Download:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%
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

oFile = java.io.File(sErrorLogFile);
com.btc.et.messenger.MessengerUtils.transfer_errlog(hMessenger, oFile);



%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************


function atgcv_m_messenger_delete(hMessenger, sErrorId, sMsg, sDate)
%  Removes the message which maps on the given parameters from the messenger.
%
%  function atgcv_m_messenger_delete(hMessenger, sErrorId, sMsg, sDate)
%
%   INPUT              DESCRIPTION
%    hMessenger        (handle)    EmbeddedTester messenger handle to use
% 
%    sErrorId          (string)    The symbolic error identifier which has
%                                  to be searched. It has to 
%                                  consists of two parts, separated by a 
%                                  double colon, like Matlab's error 
%                                  identifiers.
%                                  '<Tool>:STD:###' identifies default
%                                  messages.
%    sMsg             (string)     The message which should be deleted.
%    sDate            (string)     Date-String of the message.
%                                  Format: 'yyyy-mm-dd HH:MM:SS'
%                                  see: datestr( now, 'yyyy-mm-dd HH:MM:SS' )
%
%   OUTPUT                  DESCRIPTION
%     
%
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
% %



% Deactivated, because the current function is only used for legacy unit tests.
% atgcv_api_argcheck(0, 'sDate', sDate, {'date', 'yyyy-mm-dd HH:MM:SS'});

atgcv_m_messenger( hMessenger, 'delete', sErrorId, sMsg, sDate);

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

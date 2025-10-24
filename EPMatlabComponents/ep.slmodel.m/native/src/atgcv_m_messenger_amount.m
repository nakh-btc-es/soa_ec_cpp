function nNumber = atgcv_m_messenger_amount( hMessenger, sDate )
%  Return the amount of messages within current the messenger.
%
%  function atgcv_m_messenger_reset( hMessenger, sDate )
%
%   PARAMETER(S)    DESCRIPTION
%
%   INPUT               DESCRIPTION
%   hMessenger     (integer)    messenger Identifier Messenger to use
%   sDate          (string)    (Optional) Format: 'yyyy-mm-dd HH:MM:SS'
%                               see: datestr( now, 'yyyy-mm-dd HH:MM:SS' )
%                               Only messages with newer or equal timestamps 
%                               than the given timestamp 'sDate' will be 
%                               taken into account.
%
%   OUTPUT              DESCRIPTION
%   nNumber        (integer)    The number of messages in the current 
%                               messenger.
%
%
% AUTHOR(S):
%   Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%  
%%


if( isequal( nargin , 2 ) )
    if( isempty( sDate ) )
        error('The parameter "sDate" is empty.');
    end
    
% Deactivated, because the current function is only used for legacy unit tests.
% atgcv_api_argcheck(0, 'sDate', sDate, {'date', 'yyyy-mm-dd HH:MM:SS'});
    
    nNumber = atgcv_m_messenger( hMessenger,'number', sDate );
else    
    nNumber = atgcv_m_messenger( hMessenger,'number' );
end

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

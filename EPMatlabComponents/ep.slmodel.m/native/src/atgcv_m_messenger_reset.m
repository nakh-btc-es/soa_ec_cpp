function atgcv_m_messenger_reset( hMessenger, sDate )
%  Reset internal data structure of the messenger module.
%
%  function atgcv_m_messenger_reset( hMessenger, sDate )
%
%   PARAMETER(S)    DESCRIPTION
%
%   hMessenger     (integer)    messenger Identifier Messenger to use
%   sDate          (string)     (Optional) Format: 'yyyy-mm-dd HH:MM:SS'
%                               see: datestr( now, 'yyyy-mm-dd HH:MM:SS' )
%                               Messages with newer or equal timestamps 
%                               than the given timestamp 'sDate' will be 
%                               removed.
%
%  Reset messenger module. Module suitable for unit tests.
%
% AUTHOR(S):
%   Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%  
%%

error('ERROR:DEPRACTED', 'Script "%s" is deprecated and shall never be called.', mfilename);


if( isequal( nargin , 2 ) )
    
    % Deactivated, because the current function is only used for legacy unit tests.
    % atgcv_api_argcheck(0, 'sDate', sDate, {'date', 'yyyy-mm-dd HH:MM:SS'});
    atgcv_m_messenger( hMessenger,'reset', sDate );
else
    atgcv_m_messenger( hMessenger,'reset' );
end

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

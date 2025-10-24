function atgcv_m_messenger_save(hMessenger, sFile, sDate )
%  Write a report xml file.
%
%  function atgcv_m_messenger_save(hMessenger, sFile, sDate )
%
%  Writes the collected messages to the specified file.
%
%   PARAMETER(S)    DESCRIPTION
%   hMessenger     (integer) messenger Identifier Messenger to use
%   sFile          (string)  full path to output XML file (with extension).
%   sDate          (string)  (Optional) Format: 'yyyy-mm-dd HH:MM:SS'
%                            see: datestr( now, 'yyyy-mm-dd HH:MM:SS' )
%                            All messages with an older timestamp will 
%                            not be saved in the given file.
%
%   OUTPUT
%
%   REFERENCE(S):
%     Design Document: 
%        Section : M18
%        Download:
%        http://pcosc29/dp2004/Download.aspx?ID=1cd1982c-9a3f-4a8d-a155-ce05bc5d84a6
%
%   RELATED MODULES:
%     -
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%  

%%
error('ERROR:DEPRACTED', 'Script "%s" is deprecated and shall never be called.', mfilename);

if( isequal( nargin, 3 ) )
    % Deactivated, because the current function is only used for legacy unit tests.
    % atgcv_api_argcheck(0, 'sDate', sDate, {'date', 'yyyy-mm-dd HH:MM:SS'});
    atgcv_m_messenger( hMessenger, 'save', sFile, sDate );
else
    atgcv_m_messenger( hMessenger, 'save', sFile );
end


%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

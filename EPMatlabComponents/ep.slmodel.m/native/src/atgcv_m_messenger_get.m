function bPresent = atgcv_m_messenger_get(sStatus)
%  Get the current status of the messenger.
%
%  function atgcv_m_messenger_get()
%
%   INPUT                   DESCRIPTION
%     sStatus  (string)     (error|warning|note)
%
%   OUTPUT                  DESCRIPTION
%     bPresent (numerical)  status exists==1, otherwise 0
%
%   REMARKS
%     Functions delivers a 1 if the sStatus (error|warning|note) exists in the message stack.
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
%     Hilger Steenblock
% $$$COPYRIGHT$$$-2005
%
%   $Revision: 14794 $ Last modified: $Date: 2007-02-15 12:05:55 +0100 (Do, 15 Feb 2007) $ $Author: hilger $



if ~any( strcmpi( sStatus,{'error','warning','note'} )  )
     error( 'ATGCV:API:ERROR', 'Unkown command: %s!', sStatus );
end
hMessenger = 0;
bPresent = atgcv_m_messenger( hMessenger, 'status', sStatus);

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

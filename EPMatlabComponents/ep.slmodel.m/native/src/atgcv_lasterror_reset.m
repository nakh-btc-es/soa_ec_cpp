function [stError] = atgcv_lasterror_reset()
% Reset the ATG/CV-error contents to a 'No Error' state, returns old contents
%
% function [stError] = atgcv_lasterror_reset()
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%     stError
%     .identifier        (string) Message Identifier that was stored
%     .message           (string) Message that was stored
%
%   REMARKS
%     
%
%   <et_copyright>


%% internal 
%
%   REFERENCE(S):
%     EP5-Document
%        $ModuleDirectory/m/doc/DocumentName.odt
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Jens Wilken
% $$$COPYRIGHT$$$
%
%   $Revision: 35187 $
%   Last modified: $Date: 2008-03-31 09:25:17 +0200 (Mo, 31 Mrz 2008) $ 
%   $Author: ahornste $
%%

% initializing outputs:

stError = osc_lasterror_reset;

return;

%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                         
%                                                                         
%******************************************************************************


%**************************************************************************
% END OF FILE                                                             
%**************************************************************************

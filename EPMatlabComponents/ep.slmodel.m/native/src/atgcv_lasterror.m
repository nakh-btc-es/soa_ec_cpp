function [stError] = atgcv_lasterror()
% Give the last stored ATG/CV error
%
% function [stError] = atgcv_lasterror()
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%     stError
%     .identifier        (string) Message Identifier, '' if none
%     .message           (string) Message text, '' if none
%
%   THROWS
%
%   EXAMPLE
%       atgcv_lasterror   retrieve the last error
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
% $$$COPYRIGHT$$$-2005
%
%   $Revision: 35187 $
%   Last modified: $Date: 2008-03-31 09:25:17 +0200 (Mo, 31 Mrz 2008) $ 
%   $Author: ahornste $
%%

% initializing outputs:

stError = osc_lasterror;

return;
%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                         
%                                                                         
%******************************************************************************


%******************************************************************************
% END OF FILE                                                             
%******************************************************************************

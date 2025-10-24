function [stError] = osc_lasterror_reset()
% Reset the osc-error contents to a 'No Error' state, returns old contents
%
% function [stError] = osc_lasterror_reset()
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%     stError
%     .identifier        (string) Message Identifier that was stored
%     .message           (string) Message that was stored
%
%   THROWS
%
%   EXAMPLE
%
%   REMARKS
%     
%
%   (c) 2006 by OSC Embedded Systems AG, Germany


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
%   $Revision: 10980 $
%   Last modified: $Date: 2006-11-22 11:29:23 +0100 (Mi, 22 Nov 2006) $ 
%   $Author: jensw $
%%

% initializing outputs:

stError = osc_global_error;
osc_global_error(struct('message', '', 'identifier', ''));

return;

%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                         
%                                                                         
%******************************************************************************


%******************************************************************************
% END OF FILE                                                             
%******************************************************************************

function [sString] = osc_stack_to_string(stStack)
% Convert a Stacktrace fom dbstack to a single string
%
% function [sString] = osc_stack_to_string(stStack)
%
%   A stacktrace is an Array of Structs consisting of
%       .file (string)  Filename
%       .name (string)  Name of Script / Function
%       .line (integer) Line where dbstack was called
%
%   INPUT               DESCRIPTION
%       stStack            (ar struct) Array of structs as declared above
%
%   OUTPUT              DESCRIPTION
%       sString             (string) Structures converted to a single string
%
%
%   THROWS
%
%   EXAMPLE
%       {'file', 'func.m', 'name', 'i_func1', 'line', 50}
%       {'file', 'func.m', 'name', 'func', 'line', 3},
%       becomes
%       '[func.m:i_func1:50]\[func.m:func:3]'
%       where the first struct / substring in []-brackets is the error position.
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
%   $Revision: 11008 $
%   Last modified: $Date: 2006-11-22 18:08:40 +0100 (Mi, 22 Nov 2006) $ 
%   $Author: jensw $
%%

% initializing outputs:
if ( length(stStack) == 1 )
    sString = '';
else
    sString = sprintf('[%s:%s:%d]', ...
                       stStack(2).file, ...
                       stStack(2).name, ...
                       stStack(2).line);
end;
for ( i = 3:length(stStack) )
    sString = [ sString, ...
        sprintf('\\[%s:%s:%d]', ...
                stStack(i).file, ...
                stStack(i).name, ...
                stStack(i).line)];
end;

%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                         
%                                                                         
%******************************************************************************


%******************************************************************************
% END OF FILE                                                             
%******************************************************************************

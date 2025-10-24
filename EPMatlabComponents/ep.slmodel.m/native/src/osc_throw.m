function osc_throw( stError )
% Raise a ML-Exception with the given error, registers the error as osc-error
%
% function osc_throw(stError)
%
%   See ML 'rethrow' for more information.
%
%   INPUT               DESCRIPTION
%     stError            (struct)
%       .message         (string) Error Message
%       .identifier      (string) Error identifier
%       <.fields>        User defined fields
%   OR
%     identifier         (string) Identifier string
%     message            (string) Message string
%
%   OUTPUT              DESCRIPTION
%
%   THROWS
%           Itself
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
%   $Revision: 14577 $
%   Last modified: $Date: 2007-02-09 15:52:09 +0100 (Fr, 09 Feb 2007) $ 
%   $Author: jensw $
%%

if ( ~isfield(stError, 'stEnv') )
    stEnv = 0;
else
    stEnv = stError.stEnv;
end

if isa(stError, 'MException')
    stError = struct( ...
        'message',    stError.message, ...
        'identifier', stError.identifier, ...
        'stack',      stError.stack);
end

stStack = dbstack;
sStack = osc_stack_to_string(stStack);

if isstruct(stError) && ~isfield(stError, 'stack')
    stError.stack = stStack;
end

if (~isfield(stError, 'strStack'))
    stError.strStack = sStack;
    if( atgcv_debug_status )
        % Add Stacktrace in string-encoded form to the messenger
        osc_messenger_add(stEnv, 'OSC:STD:CALLSTACK', 'trace', sStack);
    end
end

osc_global_error(stError);
rethrow(stError);
end



function [stError] = osc_lasterror()
% Give the last stored OSC-error
%
% function [stError] = osc_lasterror()
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
%       osc_lasterror   retrieve the last error
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
%   $Revision: 26940 $
%   Last modified: $Date: 2007-09-25 15:50:00 +0200 (Di, 25 Sep 2007) $ 
%   $Author: ahornste $
%%

% initializing outputs:

stError = lasterror;
stOSCErr = osc_global_error;
%% Matlab error IDs will always be different, so when lasterror has the same ID
%% as OSC-error I return the OSC-Error because it is enriched with additional
%% data like a trace stack. The additional dta is lost when the error structure
%% is given to lasterror and read back.
if ( isempty(stOSCErr))
    return; %% No previous OSCError exists
end;
if ( strcmp(stError.identifier, stOSCErr.identifier) == 1 )
    if (isfield(stError, 'stack') && isfield(stOSCErr, 'stack'))
        if ( length(stError.stack) ~= length(stOSCErr.stack))
            return; % Use ML lasterror, stack sizes differ
        else
            % Compare stacks, use ML-lasterror when differert
            for idx=1:length(stError.stack)
                stErrStack = stError.stack(idx);
                stOscStack = stOSCErr.stack(idx);
                if (stErrStack.line ~= stOscStack.line)
                    return;
                end;
                if (strcmp(stErrStack.file, stOscStack.file)==0)
                    return; % m-script name differs
                end;
                if (strcmp(stErrStack.name, stOscStack.name)==0)
                    return; % function name differs
                end;
            end;
        end;
        stError = stOSCErr; % BTC has same stack as ML, use OSC
    else
        stError = stOSCErr;
    end;
end;

return;
%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                         
%                                                                         
%******************************************************************************


%******************************************************************************
% END OF FILE                                                             
%******************************************************************************

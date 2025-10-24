function result = ep_core_mdf(sCommand)
% MDF libary utility.
%
% function sMdfDialect = ep_core_mdf(sCommand)
%
%   OUTPUT              DESCRIPTION
%   - sCommand           (string)  Command.
%
%   USAGE
%   
%   - result = ep_core_mdf('GetPreferredDialect')
%     Get the preferred MDF dialect (string).
%
%   - result = ep_core_mdf('GetFixedPointBaseValueEnabled');
%     Returns true iff base integer values instead of floating point values 
%     should be stored for fixed-point values (boolean).  
%
%%

switch sCommand
    case 'GetPreferredDialect'
        result = i_GetPreferredDialect();
    case 'GetFixedPointBaseValueEnabled'
        result = i_GetFixedPointBaseValueEnabled();
    otherwise
        error('EP:CORE:MDF', ['Unknown command ', sCommand]); 
end

end


%% GetPreferredDialect
function sMdfDialect = i_GetPreferredDialect()
    sMdfDialect = 'EP2.9';
end

%% GetFixedPointBaseValueEnabled
function bFixedPointBaseValueEnabled = i_GetFixedPointBaseValueEnabled()

    sMdfDialect = i_GetPreferredDialect();
    bFixedPointBaseValueEnabled = strcmp(sMdfDialect, 'EP2.9'); 
end


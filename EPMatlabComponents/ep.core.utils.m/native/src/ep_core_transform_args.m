function stArgs = ep_core_transform_args(casKeyValue, casAllowedKeys)
% This function transforms key-values into a struct.
%
% function stArgs = ep_core_transform_args(casKeyValue, casAllowedKeys)
%
%  INPUT              DESCRIPTION
%  - casKeyValue         (cell)   list with string-keys and xxx-values
%                                 (Keys need to usable as field-names of structs;
%                                 othewise an exception is issued.)
%
%  - casAllowedKeys     (cell)    optional: list with all valid key-names
%                                 (if not provided _all_ keys are allowed)
%  OUTPUT            DESCRIPTION
%  - stArgs              (struct)  structure of arguments
%

%%
bDoValidCheck = true;
if (nargin < 2)
    casAllowedKeys = {};
    bDoValidCheck = false;
end


%% check if every key has a value
nLen = length(casKeyValue);
if (mod(nLen, 2) ~= 0) 
    error('EP:API:INCONSISTENT_KEY_VALUES', ...
        'Inconsistent number of key-value pairs. Not every key has a corresponding value.');
end

%% loop over all key-values 
stArgs = struct();
for i = 1:2:nLen
    sKey   = casKeyValue{i};
    xValue = casKeyValue{i+1};
   
    if (isempty(sKey) || ~ischar(sKey))
        error('EP:API:INCONSISTENT_KEY', 'Keys need to be non-empty strings.');
    end
    
    if bDoValidCheck
        if ~any(strcmp(sKey, casAllowedKeys))
            error('EP:API:KEY_NOT_ALLOWED', 'Key "%s" not allowed.', sKey);
        end
    end
    
    if isfield(stArgs, sKey)
        error('EP:API:MULTIPLE_KEY', 'Multiple usage of same key "%s".', sKey);
    end
    
    try
        stArgs.(sKey) = xValue;
        
    catch oEx
        oMainEx = MException('EP:API:KEY_NOT_SUPPORTED', 'Key "%s" not supported.', sKey);
        oMainEx = oMainEx.addCause(oEx);
        throw(oMainEx);
    end
end
end
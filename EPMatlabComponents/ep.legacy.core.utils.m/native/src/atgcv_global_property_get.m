function [sValue, bExist] = atgcv_global_property_get(sKey, sDefaultValue)
% Returns a value of the given key. Throws an exception when key is
% not available int the global data structure.
%
% function sValue = atgcv_global_property_get(sKey)
%
%   INPUT               DESCRIPTION
%   sKey                (string)   The key for which the value is returned.
%   sDefaultValue       (string)   The default value in case the key does not exist.
%
%   OUTPUT              DESCRIPTION
%   sValue              (string)   The value which belongs to the key.
%   bExist              (bool)     The flag to indicate wether the key does exist.
%
%   REMARK
%   The global data structure is user dependent.
%   A non existent key in the global data structure leads to an exception if the second output argument bExist
%   is not requested.
%
%  <et_copyright>

%% Internal
%   REFERENCE(S):
%     Design Document:
%
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2009
%
%%

%% check parameters
try
    sValue = atgcv_global_property_state(sKey);
    bExist = true;
catch oEx
    if ((nargin < 2) && (nargout < 2))
        rethrow(oEx);
    end
    bExist = false;
    if (nargin > 1)
        sValue = sDefaultValue;
    else
        sValue = [];
    end
end
end

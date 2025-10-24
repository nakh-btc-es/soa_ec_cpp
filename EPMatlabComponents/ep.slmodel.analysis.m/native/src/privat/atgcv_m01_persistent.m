function xOut = atgcv_m01_persistent(sKey, xValue)
% Persistent key-value store.
%
%
%   <et_copyright>


persistent stRegistry;

if isempty(stRegistry)
    stRegistry = struct( ...
        'iBusStrictLevel', []);
end
if ~isfield(stRegistry, sKey)
    error('INTERNAL:ERROR', 'Key "%s" is not supported.', sKey);
end
   
xOut = stRegistry.(sKey);
if (nargin > 1)
    stRegistry.(sKey) = xValue;
end
end


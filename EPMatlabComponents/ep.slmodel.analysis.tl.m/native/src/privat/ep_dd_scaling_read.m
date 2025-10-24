function stInfo = ep_dd_scaling_read(xScaling)
% Returns properties of a DD scaling object. Currently, only TAB_VERB types are supported!
%
%  function stInfo = ep_dd_scaling_read(xScaling)
%
%   INPUT           DESCRIPTION
%     xScaling          (handle/path) DD handle (or DD path to) of Scaling
%
%   OUTPUT          DESCRIPTION
%     stInfo            (struct)      struct with following info
%       .sName            (string)      name of the scaling definition
%       .sConversionType  (string)      type of conversion introduced by this scaling
%       .astTabValue      (array)       structs with the following info (non-empty only for conversion type == 'TAB_VERB')
%         .sName            (string)      name of the table element
%         .xValue           (xxxx)        value of the table element
%
%


%%
stInfo = struct( ...
    'sName', '', ...
    'sConversionType', '', ...
    'astTabValues',    []);

[bExist, hScaling] = dsdd('Exist', xScaling);
if ~bExist
    return;
end

% accept object kind InterfaceVariable but get handle of the corresponding variable if possible
sObjectKind = dsdd('GetAttribute', hScaling, 'objectKind');
if ~strcmpi(sObjectKind, 'Scaling')
    return;
end

stInfo.sName = dsdd('GetAttribute', hScaling, 'Name');
stInfo.sConversionType = dsdd('GetConversionType', hScaling);
if strcmp(stInfo.sConversionType, 'TAB_VERB')
    stInfo.astTabValues = i_readConversionTable(hScaling);
end
end


%%
function astTabValues = i_readConversionTable(hScaling)
casNames = dsdd('GetConversionStrings', hScaling);
axValues = dsdd('GetConversionTable', hScaling);

if (isempty(casNames) || (numel(casNames) ~= numel(axValues)))
    astTabValues = [];
else
    astTabValues = struct( ...
        'sName',  reshape(casNames, 1, []), ...
        'xValue', reshape(num2cell(axValues), 1, []));
end
end


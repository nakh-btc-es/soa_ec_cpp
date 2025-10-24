function hVar = ep_dd_variable_normalize(xVar)
% Return a "normalized" version of the provided variable: InterfaceVariables are replaced by the corresponding Variable.
%
%  function hVar = ep_dd_variable_normalize(xDdVar)
%
%   INPUT           DESCRIPTION
%     xVar              (handle/path) DD handle (or DD path to) of Variable or InterfaceVariable
%
%   OUTPUT          DESCRIPTION
%     hVar              (handle)      the DD handle of the (corresponding) Variable
%
%

%%
[bExist, hVar] = dsdd('Exist', xVar);
if ~bExist
    hVar = [];
    return;
end

% accept object kind InterfaceVariable but get handle of the corresponding variable if possible
sObjectKind = dsdd('GetAttribute', hVar, 'objectKind');
if strcmpi(sObjectKind, 'InterfaceVariable')
    hVar = i_getVariableOfInterface(hVar);
else
    if ~strcmpi(sObjectKind, 'Variable')
        error('EP:DD:ILLEGAL_ARGUMENT', 'Expected DD kind "Variable" instead of "%s".', sObjectKind);
    end
end
end


%%
function hVar = i_getVariableOfInterface(hInterfaceVar)

% Variable is non-optional but can be empty
hVar = dsdd('GetVariable', hInterfaceVar);

% if Variable is empty, try to get it through BlockVariable
if (isempty(hVar) && dsdd('Exist', hInterfaceVar, 'Property', 'BlockVariable'))
    hBlockVar = dsdd('GetBlockVariable', hInterfaceVar);
    if dsdd('Exist', hBlockVar, 'Property', 'VariableRef')
        hVar = dsdd('GetVariableRef', hBlockVar);
    end
end

% if Variable is still empty, use the original InterfaceVariable
if isempty(hVar)
    hVar = hInterfaceVar;
end
end


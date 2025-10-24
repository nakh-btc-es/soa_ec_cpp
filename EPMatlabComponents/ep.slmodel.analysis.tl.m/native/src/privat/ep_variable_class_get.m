function stInfo = ep_variable_class_get(hVar)
% Returns Class info of Variable or InsterfaceVariable DD object.
%
% function stInfo = ep_variable_class_get(hVar)
%
%   INPUT               DESCRIPTION
%     hVar              (handle)       DD handle to "Variable" or "InterfaceVariable"
%
%   OUTPUT                   DESCRIPTION
%     stInfo                    (struct)       info structure
%       .hClass                     (handle)      DD handle of corresponding VariableClass (might be empty if not found)
%       .sScope                     (string)      scope, e.g. 'global', 'local', 'struct_component', ...
%       .sStorage                   (string)      storage, e.g. 'extern', 'static', ... 
%       .bIsMacro                   (boolean)     is realized as Macro or not
%       .bIsConst                   (boolean)     is constant or not
%       .stAccess                   (struct)      additional info about access to variable
%          .bIsElementAccessFunc        (boolean)    flag, if variable is represented as an access function that
%                                                    accesses a part of another variable (e.g. ArrayOfStruct)
%                                                    (TODO: very specialized info that needs to be adapted sometime)
%


%%
hVar = i_normalizeVariable(hVar);

hClass = [];
if ~isempty(hVar)
    hClass = dsdd('GetClass', hVar);
end
hClass = i_normalizeClass(hClass);
stInfo = i_getInfoClass(hClass);
stInfo.stAccess = i_getAccessInfo(hVar);
end


%%
% note: handle case where hClass == 'default' <-- the default class is always present as string; never as handle!
function hClass = i_normalizeClass(hClass)
if ischar(hClass)
    [~, hClass] = dsdd('Exist', hClass);
end
end


%%
% requirement: expecting hClass to be a valid handle or empty (i.e. 'default' is not allowed)
function stInfo = i_getInfoClass(hClass)
stInfo = struct( ...
    'hClass',       [], ...
    'sScope',       '', ...
    'sStorage',     '', ...
    'bIsMacro',     false, ...
    'bIsConst',     false);

if isempty(hClass)
    return;
end

stInfo.hClass   = hClass;
stInfo.sScope   = dsdd('GetScope', hClass);
stInfo.sStorage = dsdd('GetStorage', hClass);
stInfo.bIsMacro = logical(dsdd('GetMacro', hClass));
stInfo.bIsConst = logical(dsdd('GetConst', hClass));
end


%%
% requirement: expecting hClass to be a valid handle or empty (i.e. 'default' is not allowed)
function stInfo = i_getAccessInfo(hVar)
stInfo = struct( ...
    'bIsElementAccessFunc', false);

if isempty(hVar)
    return;
end

ahAccessFuncs = i_getAccessFuncRefs(hVar);
for i = 1:numel(ahAccessFuncs)
    stAccessFunc = atgcv_m01_access_function_info_get(ahAccessFuncs(i));
    if strcmp(stAccessFunc.sAccessFunctionKind, 'DIRECT')
        stInfo.bIsElementAccessFunc = i_isAccessingElementInMacro(stAccessFunc.sMacroBody);
        if stInfo.bIsElementAccessFunc
            break;
        end
    end
end
end


%%
% note: currently not discriminating between read and write access
function ahAccessFuncs = i_getAccessFuncRefs(hVar)
ahAccessFuncs = [];

casAccessFncRefKinds = {'ReadAccessFcnRef', 'WriteAccessFcnRef'};
for i = 1:length(casAccessFncRefKinds)
    sRefKind = casAccessFncRefKinds{i};
    sGetRefTargetCmd = ['Get', sRefKind, 'Target']; % e.g. GetReadAccessFcnRefTarget
    
    
    aiIdx = dsdd('GetAutoRenamePropertyIndices', hVar, sRefKind);
    for k = 1:numel(aiIdx)
        hFunc = dsdd(sGetRefTargetCmd, hVar, aiIdx(k));
        if dsdd('Exist', hFunc, 'Property', 'AccessFunctionRef')
            hAccessFunc = dsdd('GetAccessFunctionRefTarget', hFunc);
            if ~isempty(hAccessFunc)
                ahAccessFuncs(end + 1) = hAccessFunc; %#ok<AGROW>
            end
        end        
    end
end
if (numel(ahAccessFuncs) > 1)
    ahAccessFuncs = unique(ahAccessFuncs);
end
end


%%
function bIsAccessingElem = i_isAccessingElementInMacro(sMacroBody)
bIsAccessingElem = ~isempty(regexp(sMacroBody, '\[\s*\d+\s*\]', 'once'));
end


%%
function hVar = i_normalizeVariable(xVar)
[bExist, hVar] = dsdd('Exist', xVar);
if ~bExist
    error('EP:MODEL_ANA:INTERNAL_ERROR', 'Provided handle invalid.');
end

% class info can only be gained from a true variable; if we have an InterfaceVariable, try to access the referenced
% variable from it
sKind = dsdd('GetAttribute', hVar, 'objectKind');
if strcmpi(sKind, 'InterfaceVariable')
    if dsdd('Exist', hVar, 'property', {'name', 'Variable'})
        hVar = dsdd('GetVariable', hVar);
    else
        hVar = [];
    end
end
end


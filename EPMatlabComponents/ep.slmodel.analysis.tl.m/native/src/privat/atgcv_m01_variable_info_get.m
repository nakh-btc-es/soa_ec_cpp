function stInfo = atgcv_m01_variable_info_get(stEnv, hVar, bWithDetailedProperties)
% Get info about variable.
%
% function stInfo = atgcv_m01_variable_info_get(stEnv, hVar, bWithProperties)
%
%   INPUT             DESCRIPTION
%     stEnv                      (struct)       environment struct
%     hVar                       (handle)       DD handle to "Variable" or "InterfaceVariable"
%     bWithDetailedProperties    (boolean)      optional: get detailed properties of the variable, including individual 
%                                               ones of sub-elements, e.g. for arrays
%                                               (default: true)
%
%   OUTPUT            DESCRIPTION
%     stInfo            (struct)       data struct with following info 
%       .hVar             (handle)       DD handle of variable
%       .sModuleName      (string)       name of C-file in which variable is defined (known)
%       .stVarType        (struct)       return value of "atgcv_m01_variable_type_get"
%       .stVarClass       (struct)       return value of "atgcv_m01_variable_class_get"
%       .hRootVar         (handle)       DD handle of root variable
%                                        (differes only from hVar if it is a Struct component)
%       .stRootType       (struct)       return value of "atgcv_m01_variable_type_get"
%       .stRootClass      (struct)       return value of "atgcv_m01_variable_class_get"
%       .sRootName        (string)       name of root variable
%       .sAccessPath      (string)       C-access-path from root_var to var
%       .aiWidth          (array)        array of integers describing the width of the variable: 
%                                          scalar --> empty, vector --> m,  matrix --> [m,n]
%       .astProp          (array)        return value of "atgcv_m01_variable_properties_get"
%

%%
if (nargin < 3)
    bWithDetailedProperties = true;
end

%% init struct
stInfo = struct( ...
    'hVar',         [], ...
    'sModuleName',  '', ...
    'stVarType',    [], ...
    'stVarClass',   [], ...
    'hRootVar',     [], ...
    'stRootType',   [], ...
    'stRootClass',  [], ...
    'sRootName',    '', ...
    'sAccessPath',  '', ...
    'aiWidth',      [], ...
    'astProp',      [], ...
    'oTypeMap',     []);

%% check and adapt input
hVar = i_getVariable(stEnv, hVar);

%% get info
stInfo.hVar        = hVar;
stInfo.sModuleName = i_getModuleName(stEnv, hVar);
stInfo.stVarType   = atgcv_m01_variable_type_get(stEnv, hVar, 'extended');
stInfo.stVarClass  = atgcv_m01_variable_class_get(stEnv, hVar);
stInfo.hRootVar    = i_getRootVar(stEnv, hVar);

if (stInfo.hRootVar ~= hVar)
    stInfo.stRootType  = atgcv_m01_variable_type_get(stEnv, stInfo.hRootVar);
    stInfo.stRootClass = atgcv_m01_variable_class_get(stEnv, stInfo.hRootVar);
else
    stInfo.stRootType  = stInfo.stVarType;
    stInfo.stRootClass = stInfo.stVarClass;
end

stInfo.sRootName   = i_getCleanVarName(atgcv_mxx_dsdd(stEnv, 'GetAttribute', stInfo.hRootVar, 'name'));
stInfo.sAccessPath = i_getAccessPath(stEnv, stInfo.hRootVar, stInfo.hVar);
stInfo.aiWidth     = i_getVarWidth(stEnv, hVar);

if bWithDetailedProperties
    [stInfo.astProp, stInfo.oTypeMap] = i_getVariableProperties(stEnv, hVar, stInfo.stVarType);
end
end



%%
function hVar = i_getVariable(stEnv, xVar)
% check that provided handle exists and transform DD-path to handle
[bExist, hVar] = dsdd('Exist', xVar);
if ~bExist
    error('ATGCV:MODEL_ANA:INTERNAL_ERROR', 'Provided handle invalid.');
end
sVarKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'ObjectKind');
if strcmpi(sVarKind, 'InterfaceVariable')
    hOrigVar = hVar;
    if dsdd('Exist', hVar, 'property', {'name', 'Variable'})
        hVar = atgcv_mxx_dsdd(stEnv, 'GetVariable', hVar);
    end
    if isempty(hVar)
        hVar = hOrigVar;
    end
end
end


%%
% essentially for struct_vars in interface
function hRootVar = i_getRootVar(stEnv, hVar)
sPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
sRootPath = regexprep(sPath, '(.*Variables/.*?)(/Components.*)', '$1');
hRootVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', sRootPath, 'hDDObject');
end


%%
% note: function only suited for variables that are components in structs
function sAccessPath = i_getAccessPath(stEnv, hRootVar, hVar)
sAccessPath = '';

% shortcut for root variables
if (hRootVar == hVar)
    return;
end

sRootPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hRootVar, 'path');
sPath     = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
if isempty(strfind(sPath, sRootPath))
    % root_path not part of var_path is unexpected! 
    % maybe issue a warning here
    return;
end

casPathParts = {};
hObj = hVar;
while (hObj ~= hRootVar) 
    sName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'name');
    casPathParts{end + 1} = sName; %#ok<AGROW>
    
    % Components or Components(#\d+)
    hObj      = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'hDDParent');
    sCompName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'name');
    
    % parent var
    hObj = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'hDDParent');
    if dsdd('Exist', hObj, 'property', {'name', 'Width'})
        nWidth = atgcv_mxx_dsdd(stEnv, 'GetWidth', hObj);
    else
        nWidth = [];
    end
    
    % special treatment for StructPtr
    if i_hasPointerType(stEnv, hObj)
        casPathParts{end + 1} = '->'; %#ok<AGROW>
    else
        casPathParts{end + 1} = '.'; %#ok<AGROW>
    end
    
    % special treatment for StructArrays
    if ~isempty(nWidth)
        casIdx = regexp(sCompName, '\(#(\d+)\)', 'tokens', 'once');
        if isempty(casIdx)
            casPathParts{end + 1} = '[0]'; %#ok<AGROW>
        else
            nIdx = str2double(casIdx{1}) - 1;
            casPathParts{end + 1} = ['[', num2str(nIdx), ']']; %#ok<AGROW>
        end
    end
end
% when concatenating reverse the order since we entered parts from leaf to root
sAccessPath = strjoin(casPathParts(end:-1:1), ''); 
end


%%
function bHasPointerType = i_hasPointerType(stEnv, hVar)
hType = atgcv_mxx_dsdd(stEnv, 'GetType', hVar);
sBaseType = atgcv_mxx_dsdd(stEnv, 'GetBaseType', hType);
bHasPointerType = strcmpi(sBaseType, 'Pointer');
end


%%
function aiWidth = i_getVarWidth(stEnv, hVar)
if dsdd('Exist', hVar, 'property', {'name', 'Width'})
    aiWidth = atgcv_mxx_dsdd(stEnv, 'GetWidth', hVar);
else
    aiWidth = [];
end
end


%%
function dFloatValue = i_computeFloatValue(iIntValue, dLsb, dOffset)
dFloatValue = iIntValue*dLsb + dOffset;
end


%%
function [astProp, oTypeMap] = i_getVariableProperties(stEnv, hMainVar, stMainType)
oTypeMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
oTypeMap(hMainVar) = stMainType;

astProp = atgcv_m01_variable_properties_get(stEnv, hMainVar);

% get min and max either from user_def or compute it ourselves
for i = 1:length(astProp)
    hSubVar = astProp(i).hVar;
    
    if oTypeMap.isKey(hSubVar)
        stType = oTypeMap(hSubVar);
    else
        stType = atgcv_m01_variable_type_get(stEnv, hSubVar, 'extended');
        oTypeMap(hSubVar) = stType;
    end
    
    if ~isempty(astProp(i).dUserMin)
        astProp(i).dMin = astProp(i).dUserMin;
    else
        if stType.bIsFloat
            astProp(i).dMin = stType.dMin;
        else
            astProp(i).dMin = i_computeFloatValue(stType.dMin, astProp(i).dLsb, astProp(i).dOffset);
        end
    end
    if ~isempty(astProp(i).dUserMax)
        astProp(i).dMax = astProp(i).dUserMax;
    else
        if stType.bIsFloat
            astProp(i).dMax = stType.dMax;
        else
            astProp(i).dMax = i_computeFloatValue(stType.dMax, astProp(i).dLsb, astProp(i).dOffset);
        end
    end
end
end


%%
function sModuleName = i_getModuleName(stEnv, hVar)
sModuleName = '';

sPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
iFind = regexp(sPath, '/Variables/', 'once');
if isempty(iFind)
    return;
end

sModulePath = sPath(1:iFind-1);

% if we are here, module is valid and we have to look for its C-code file name
hModuleInfo = atgcv_mxx_dsdd(stEnv, 'GetModuleInfo', sModulePath);
ahFileInfo  = atgcv_mxx_dsdd(stEnv, 'Find', hModuleInfo, 'objectKind', 'FileInfo', 'property', {'name', 'FileType'});
nFiles = length(ahFileInfo);
for i = 1:nFiles
    hFileInfo = ahFileInfo(i);
    sFileKind = atgcv_mxx_dsdd(stEnv, 'GetFileKind', hFileInfo);
    if strcmpi(sFileKind, 'SourceFile')
        sModuleName = atgcv_mxx_dsdd(stEnv, 'GetFileName', hFileInfo);
        break;
    end
end
end


%%
% note: remove the (#<%d>) post-fix from the variable name
function sVarName = i_getCleanVarName(sVarName)
sVarName = regexprep(sVarName, '\(#\d+\)$', '');
end

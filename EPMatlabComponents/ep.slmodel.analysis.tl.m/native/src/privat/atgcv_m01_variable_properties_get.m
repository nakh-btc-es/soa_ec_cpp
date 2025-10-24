function astInfo = atgcv_m01_variable_properties_get(stEnv, hVariable, sRootAccess)
% Get info about the elements of a variable.
%
% function astInfo = atgcv_m01_variable_properties_get(stEnv, hVariable, sRootAccess)
%
%   INPUT               DESCRIPTION
%     stEnv              (struct)       environment struct
%     hVariable          (DD handle)    DD handle to "Variable" or "InterfaceVariable"
%     sRootAccess        (string)       optional: string that is prepended to the computed access path
%
%   OUTPUT              DESCRIPTION
%     astInfo            (array)        array of structs with following info
%       .hVar             (handle)       DD handle of the variable
%       .dInitValue       (double)       init value of element (if any)
%       .sAccessPath      (string)       access path for elements: [0], [1], ...
%       .nIndex1          (integer)      first index (non-empty for arrays and matrices)
%       .nIndex1          (integer)      second index (non-empty for matrices)
%       .dLsb             (double)       LSB of variable as double  (e.g. 0.5, 0.25, ...)
%       .dOffset          (double)       offset of variable as double
%       .dUserMin         (double)       min value of variable (defined by user)
%       .dUserMax         (double)       max value of variable (defined by user)
%       .sUnit            (string)       unit for variable
%

%%
hVariable = ep_dd_variable_normalize(hVariable);
if isempty(hVariable)
    return;
end
if (nargin < 3)
    sRootAccess = '';
end
    

%%
ahCompVars = i_getComponentVariables(hVariable);
bIsStruct = ~isempty(ahCompVars);
if bIsStruct
    astInfo = repmat(i_getInitInfo(hVariable, ''), 1, 0);
    for i = 1:numel(ahCompVars)
        hCompVar = ahCompVars(i);
        
        sCompVarName = dsdd('GetAttribute', hCompVar, 'Name');
        sParentAccess = [sRootAccess, '.', sCompVarName];
        astInfo = [astInfo, atgcv_m01_variable_properties_get(stEnv, hCompVar, sParentAccess)]; %#ok<AGROW>
    end
else
    astInfo = i_getProperties(stEnv, hVariable, sRootAccess);
end
end


%%
function stInfo = i_getInitInfo(hVar, sUnit)
stInfo = struct( ...
    'hVar',         hVar, ...
    'dInitValue',   [], ...
    'sAccessPath',  '', ...
    'nIndex1',      [], ...
    'nIndex2',      [], ...
    'dLsb',         [], ...
    'dOffset',      [], ...
    'dUserMin',     [], ...
    'dUserMax',     [], ...
    'sUnit',        sUnit);
end


%%
function astInfo = i_getProperties(stEnv, hVariable, sRootAccess)
% get common info
% ! init value: scalar/vector/matrix property
adInitValue = i_getInitValue(stEnv, hVariable);

% lsb/offset: scalar/vector properties
% unit: scalar property
[adLsb, adOffset, sUnit] = i_getLsbOffsetUnit(stEnv, hVariable);

% min/max: scalar/vector properties
[adMin, adMax] = i_getMinMax(stEnv, hVariable);


%% different approach for scalars / vectors / matrices
if dsdd('Exist', hVariable, 'Property', 'Width')
    anWidth = atgcv_mxx_dsdd(stEnv, 'GetWidth', hVariable);
else
    anWidth = [];
end

% 1) shortcut for scalars
stInitInfo = i_getInitInfo(hVariable, sUnit);
if isempty(anWidth)
    astInfo = stInitInfo;
    astInfo.dInitValue  = i_extractScalar(adInitValue, 1);
    astInfo.sAccessPath = sRootAccess;
    astInfo.dLsb        = i_extractScalar(adLsb, 1);
    astInfo.dOffset     = i_extractScalar(adOffset, 1);
    astInfo.dUserMin    = i_extractScalar(adMin, 1);
    astInfo.dUserMax    = i_extractScalar(adMax, 1);
    return;
end

% 2) vector/matrix approach
nElements = prod(anWidth);
astInfo = repmat(stInitInfo, 1, nElements);

if (length(anWidth) == 1)
    for i = 1:anWidth
        astInfo(i).dInitValue  = i_extractScalar(adInitValue, i);
        astInfo(i).sAccessPath = sprintf('%s[%i]', sRootAccess, (i - 1));
        astInfo(i).nIndex1     = i;
        astInfo(i).dLsb        = i_extractScalar(adLsb, i);
        astInfo(i).dOffset     = i_extractScalar(adOffset, i);
        astInfo(i).dUserMin    = i_extractScalar(adMin, i);
        astInfo(i).dUserMax    = i_extractScalar(adMax, i);
    end
else
    k = 0;
    
    % gather in col-first approach similar to Matlab: inner loop i, outer loop j
    for j = 1:anWidth(2)
        for i = 1:anWidth(1)
            k = k + 1;
            astInfo(k).dInitValue  = i_extractScalar(adInitValue, i, j);
            astInfo(k).sAccessPath = sprintf('%s[%i][%i]', sRootAccess, (i - 1), (j - 1));
            astInfo(k).nIndex1     = i;
            astInfo(k).nIndex2     = j;
            astInfo(k).dLsb        = i_extractScalar(adLsb, i, j);
            astInfo(k).dOffset     = i_extractScalar(adOffset, i, j);
            astInfo(k).dUserMin    = i_extractScalar(adMin, i, j);
            astInfo(k).dUserMax    = i_extractScalar(adMax, i, j);
        end
    end
end
end


%%
function xScalarVal = i_extractScalar(xVal, i, j)
if isempty(xVal)
    xScalarVal = [];
else
    if isscalar(xVal)
        xScalarVal = xVal;
    else
        if (nargin < 3)
            xScalarVal = xVal(i);
        else
            xScalarVal = xVal(i, j);
        end
    end
end
end


%%
function adInitValue = i_getInitValue(stEnv, hVar)
adInitValue = [];
if dsdd('Exist', hVar, 'Property', 'Value')
    adInitValue = atgcv_mxx_dsdd(stEnv, 'GetValue', hVar);
end
end


%%
function [dMin, dMax] = i_getMinMax(stEnv, hVar)
if dsdd('Exist', hVar, 'Property', 'Min')
    dMin = atgcv_mxx_dsdd(stEnv, 'GetMin', hVar);
else
    dMin = [];
end
if dsdd('Exist', hVar, 'Property', 'Max')
    dMax = atgcv_mxx_dsdd(stEnv, 'GetMax', hVar);
else
    dMax = [];
end
end


%%
function sUnit = i_getUnit(stEnv, hScaling, hVar)   
sUnit = '';

% try via unit reference
hUnitRef = i_getUnitRefFromScaling(stEnv, hScaling);
if ~isempty(hUnitRef)
    % use try-catch for inconsistent DD info (see BTS/26898)
    try
        % recursively find the unit
        while true
            hUnit = hUnitRef;
            if dsdd('Exist', hUnit, 'Property', 'UnitRefTarget')
                hUnitRef = atgcv_mxx_dsdd(stEnv, 'GetUnitRefTarget', hUnit);
            else
                break;
            end
        end
        sUnit = atgcv_mxx_dsdd(stEnv, 'GetDisplayString', hUnit);
    catch
    end
end

% if still empty, try to get unit directly
if (isempty(sUnit) && dsdd('Exist', hScaling, 'property', 'Unit'))
    try
        sUnit = dsdd('GetUnit', hScaling);
    catch
        sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'Name');
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', ...
            'msg', sprintf('Inconsistency in DataDictionary: Could not read out Unit for Variable "%s".', sVarName));
    end
end
end


%%
function hUnitRef = i_getUnitRefFromScaling(stEnv, hScaling)
hUnitRef = [];
if dsdd('Exist', hScaling, 'property', 'UnitRef')
    hUnitRef = atgcv_mxx_dsdd(stEnv, 'GetUnitRef', hScaling);
    if ~isempty(hUnitRef)
        % catch DD-inconsistency: we get the name instead of the handle
        if ischar(hUnitRef)
            hUnitRef = atgcv_mxx_dsdd(stEnv, ...
                'Find',         '/Config/Units', ...
                'objectKind',   'Unit', ...
                'name',         hUnitRef);
        end
    end
end
end


%%
function [dLsb, dOffset, sUnit] = i_getLsbOffsetUnit(stEnv, hVar)
hScaling = atgcv_mxx_dsdd(stEnv, 'GetScaling', hVar);

% workaround for DD inconsistency: sometimes the returned scaling is not a handle but a string
if ischar(hScaling)
    hScaling = atgcv_mxx_dsdd(stEnv, 'Find', '/Pool/Scalings', 'objectKind', 'Scaling', 'name', hScaling);
end

if ~isempty(hScaling)
    dLsb     = atgcv_mxx_dsdd(stEnv, 'GetLSB',     hScaling);
    dOffset  = atgcv_mxx_dsdd(stEnv, 'GetOffset',  hScaling);
    sUnit    = i_getUnit(stEnv, hScaling, hVar);
else
    dLsb     = [];
    dOffset  = [];
    sUnit    = '';
end
end


%%
function ahCompVars = i_getComponentVariables(hVar)
ahCompVars = [];

hComponents = dsdd('GetComponents', hVar);
if ~isempty(hComponents)
    ahCompVars = dsdd('GetChildren', hComponents);
end
end

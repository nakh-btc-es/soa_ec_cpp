function astLocals = atgcv_m01_sfchart_locals_info_get(stEnv, sChartPath)
% Get interface info of provided block in compiled mode.
% 
%   ... TODO
%
%   REMARKS
%     Note: Assuming the function is called with the model being set to "compiled" mode already.
%
%   <et_copyright>


%%
astSfLocalInfos = atgcv_m01_sf_data_info_get(sChartPath, {'Scope', 'Local'});

% Note: for now filter out nested locals because of limitation in MIL
astSfLocalInfos(arrayfun(@i_isNestedData, astSfLocalInfos)) = [];

if isempty(astSfLocalInfos)
    astLocals = [];
    return;
end

hResolverFunc = atgcv_m01_generic_resolver_get(sChartPath);
astLocals = arrayfun(@(x) i_getLocalAsPortInfo(stEnv, x, hResolverFunc), astSfLocalInfos);
end


%%
function bIsNested = i_isNestedData(stSfData)
bIsNested = ~isempty(stSfData.sRelPath);
end


%%
function stPortInfo = i_getLocalAsPortInfo(stEnv, stSfLocal, hResolverFunc)
stPortInfo = struct( ...
    'iNumber',         -1, ...
    'sSfName',         stSfLocal.sName, ...
    'sSfRelPath',      stSfLocal.sRelPath, ...
    'sPath',           stSfLocal.hSfBlock.Path, ...
    'aiDim',           [], ...
    'iWidth',          [], ...
    'sOutMin',         '', ...
    'sOutMax',         '', ...
    'sSigKind',        'simple', ...
    'sBusType',        'NOT_BUS', ...
    'sBusObj',         '', ...
    'astSignals',      [], ...
    'bIsInfoComplete', true);

stTypeInfo = ep_sl_type_info_get(stSfLocal.hSfData.CompiledType, hResolverFunc);
stSigInfo = i_getSigInfoFromSfData(stSfLocal.hSfData, stTypeInfo);

stPortInfo.aiDim = stSigInfo.aiDim;
if stTypeInfo.bIsBus
    stPortInfo.sSigKind = 'bus';
    
    [astSigs, sBusObj] = i_getBusSignalsFromSfData(stEnv, stSfLocal.hSfData, hResolverFunc);
    if isempty(astSigs)
        stPortInfo.bIsInfoComplete = false;
    else
        stPortInfo.iWidth = i_countSignals(astSigs);
        stPortInfo.sBusType = 'NON_VIRTUAL_BUS'; % TODO: check if this makes sense
        stPortInfo.sBusObj = sBusObj;
        stPortInfo.astSignals = astSigs;
    end
else
    stPortInfo.iWidth = stSigInfo.iWidth;
    stPortInfo.astSignals = stSigInfo;
end
end


%%
function stSigInfo = i_getSigInfoFromSfData(hSfData, stTypeInfo)

sCompiledSize = hSfData.CompiledSize;
if ~isempty(sCompiledSize)
    aiSize = eval(sCompiledSize);
else
    aiSize = 1;
end
nDim = numel(aiSize);

stSigInfo = struct( ...
    'sName',      hSfData.Name, ...
    'sType',      stTypeInfo.sEvalType, ...
    'sUserType',  stTypeInfo.sType, ...
    'sMin',       hSfData.Props.Range.Minimum, ...
    'sMax',       hSfData.Props.Range.Maximum, ...
    'xDesignMin', [], ...
    'xDesignMax', [], ...
    'iWidth',     prod(aiSize), ...
    'aiDim',      [nDim, reshape(aiSize(:), 1, [])]);
end


%%
function [astSigs, sBusObjName] = i_getBusSignalsFromSfData(stEnv, hSfData, hResolverFunc)
astSigs = [];

% first check if the bus object candidate is a real bus object
sBusObjName = hSfData.Props.Type.BusObject;
if isempty(sBusObjName)
    return;
end
oBus = i_evalBusTypeAsBusObject(sBusObjName, hResolverFunc);
if isempty(oBus)
    return;
end

sRootSigName = hSfData.Name;
astSigs = atgcv_m01_bus_obj_store('get', sBusObjName, oBus, sRootSigName);
if isempty(astSigs)
    astSigs = atgcv_m01_bus_object_signal_info_get(stEnv, oBus, sRootSigName, hResolverFunc);
    atgcv_m01_bus_obj_store('set', sBusObjName, oBus, astSigs);
end
end


%%
function oBus = i_evalBusTypeAsBusObject(sBusName, hResolverFunc)
oBus = [];
if isempty(sBusName)
    return;
end
try
    [xResolvedBus, nScope] = feval(hResolverFunc, sBusName);
    if (nScope > 0)
        oBus = xResolvedBus;
    end
catch  %#ok<CTCH>
end
end


%%
function stPortInfo = i_getPortInfo(stEnv, hPort)
stPortInfo = struct( ...
    'iNumber',         get_param(hPort, 'PortNumber'), ...
    'sPath',           '', ...
    'aiDim',           [], ...
    'iWidth',          [], ...
    'sOutMin',         '', ...
    'sOutMax',         '', ...
    'sSigKind',        '', ...
    'sBusType',        '', ...
    'sBusObj',         '', ...
    'astSignals',      [], ...
    'bIsInfoComplete', false);

[stInfo, sErrMsg] = atgcv_m01_port_signal_info_get(stEnv, hPort); 
if (isempty(stInfo) || isempty(stInfo.astSigs))
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sErrMsg);
    return;
end

stInfo.astSigs = i_addDesignMinMax(stInfo.astSigs, stInfo.xDesignMin, stInfo.xDesignMax);

stPortInfo.bIsInfoComplete = true;
stPortInfo.aiDim           = stInfo.aiDim;
stPortInfo.iWidth          = i_countSignals(stInfo.astSigs);
stPortInfo.sSigKind        = stInfo.sSigKind;
stPortInfo.sBusType        = stInfo.sBusType;
stPortInfo.sBusObj         = stInfo.sBusObj;
stPortInfo.astSignals      = stInfo.astSigs;

% for "outport" get Min/Max from block
if strcmpi(get_param(hPort, 'PortType'), 'outport')
    hBlock = get_param(hPort, 'Parent');
    [stPortInfo.sOutMin, stPortInfo.sOutMax] = i_getBlockOutMinMax(hBlock, sprintf('%i', stPortInfo.iNumber));
    
    % Note: for Simulink, use port-defined Min/Max values for ML versions lower than ML2011b
    %       Reason: for higher ML versions, the info is better read out from CompiledPortDesignMin/-Max
    if atgcv_verLessThan('ML7.13')    
        sMin = i_getDoubleValueInBlockContext(stPortInfo.sOutMin, hBlock);
        sMax = i_getDoubleValueInBlockContext(stPortInfo.sOutMax, hBlock);
    else
        sMin = '';
        sMax = '';
    end
    if (~isempty(sMin) || ~isempty(sMax))
        for k = 1:length(stPortInfo.astSignals)
            stPortInfo.astSignals(k).sMin = sMin;
            stPortInfo.astSignals(k).sMax = sMax;
        end
    end
end
end


%%
% Note: PortBlocks are only "Inport" and "Outport"; nothing else!
function stPortInfo = i_getInfoFromPortBlock(stEnv, hPortBlock, oSfInterfaceMap)
stInnerPortHandles = get_param(hPortBlock, 'PortHandles');

% Note: an  InPort has an inner outport
%       an OutPort has an inner inport
hPort = stInnerPortHandles.Outport;
if isempty(hPort)
    % Block is an OutPort
    hPort = stInnerPortHandles.Inport;
end

[stInfo, sErrMsg] = atgcv_m01_port_signal_info_get(stEnv, hPort);
if (isempty(stInfo) || isempty(stInfo.astSigs))
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sErrMsg);
    stPortInfo = struct( ...
        'iNumber',         str2double(get_param(hPortBlock, 'Port')), ...
        'sPath',           getfullname(hPortBlock), ...
        'aiDim',           [], ...
        'iWidth',          [], ...
        'sOutMin',         '', ...
        'sOutMax',         '', ...
        'sSigKind',        '', ...
        'sBusType',        '', ...
        'sBusObj',         '', ...
        'astSignals',      [], ...
        'bIsInfoComplete', false);
    return;
end

stInfo.astSigs = i_addDesignMinMax(stInfo.astSigs, stInfo.xDesignMin, stInfo.xDesignMax);

stPortInfo = struct( ...
    'iNumber',         str2double(get_param(hPortBlock, 'Port')), ...
    'sPath',           getfullname(hPortBlock), ...
    'aiDim',           stInfo.aiDim, ...
    'iWidth',          i_countSignals(stInfo.astSigs), ...
    'sOutMin',         '', ...
    'sOutMax',         '', ...
    'sSigKind',        stInfo.sSigKind, ...
    'sBusType',        stInfo.sBusType, ...
    'sBusObj',         stInfo.sBusObj, ...
    'astSignals',      stInfo.astSigs, ...
    'bIsInfoComplete', true);

oSfData = oSfInterfaceMap(stPortInfo.sPath);
[dMin, dMax] = i_getMinMax(oSfData, hPortBlock);
stPortInfo.sOutMin = i_getFiniteDoubleValueAsString(dMin);
stPortInfo.sOutMax = i_getFiniteDoubleValueAsString(dMax);

% Note: for Stateflow, always use the port-defined Min/Max values
sMin = stPortInfo.sOutMin;
sMax = stPortInfo.sOutMax;


if (~isempty(sMin) || ~isempty(sMax))
    for k = 1:length(stPortInfo.astSignals)
        stPortInfo.astSignals(k).sMin = sMin;
        stPortInfo.astSignals(k).sMax = sMax;
    end
end
end

%%
function [dMin, dMax] = i_getMinMax(oSfData, hPortBlock)
if verLessThan('matlab', '9.13')
    dMin = oSfData.ParsedInfo.Range.Minimum;
    dMax = oSfData.ParsedInfo.Range.Maximum;
else
    dMin = i_robustSlResolve(oSfData.Props.Range.Minimum, hPortBlock);
    dMax = i_robustSlResolve(oSfData.Props.Range.Maximum, hPortBlock);
end
end

%%
function dVal = i_robustSlResolve(sExpression, hPortBlock)
if ~isempty(sExpression)
    dVal = slResolve(sExpression, hPortBlock);
else
    dVal = [];
end
end

%%
function astSignals = i_addDesignMinMax(astSignals, xDesignMin, xDesignMax)
astSignals = i_addDesignValue(astSignals, xDesignMin, 'xDesignMin');
astSignals = i_addDesignValue(astSignals, xDesignMax, 'xDesignMax');
end


%%
function astSignals = i_addDesignValue(astSignals, xDesignValue, sField)
if isstruct(xDesignValue)
    for i = 1:length(astSignals)
        casNameParts = regexp(astSignals(i).sName, '\.', 'split');
        if (numel(casNameParts) < 2)
            xSubDesignValue = [];
        else
            xSubDesignValue = i_accessDeepStruct(xDesignValue, casNameParts(2:end));
        end        
        astSignals(i) = i_addDesignValue(astSignals(i), xSubDesignValue, sField);
    end
    
elseif iscell(xDesignValue)
    for i = 1:length(astSignals)
        astSignals(i).(sField) = xDesignValue;
    end
    
else
    for i = 1:length(astSignals)
        astSignals(i).(sField) = xDesignValue;
    end
end
end


%%
function xValue = i_accessDeepStruct(stStruct, casNameParts)
xValue = [];
for i = 1:numel(casNameParts)
    if isstruct(stStruct) && isfield(stStruct, casNameParts{i})
        stStruct = stStruct.(casNameParts{i});
    else
        return;
    end
end
xValue = stStruct;
end


%%
function sValue = i_getFiniteDoubleValueAsString(dValue)
if (~isempty(dValue) && isfinite(dValue))
    sValue = sprintf('%.16e', dValue);
else
    sValue = '';
end
end


%%
% Note: xBlock can be a block handle or a block path
function sValue = i_getDoubleValueInBlockContext(sExpression, xBlock)
sValue = '';
if isempty(sExpression)
    return;
end
stInfo = atgcv_m01_expression_info_get(sExpression, xBlock);
if (stInfo.bIsValid && isfinite(stInfo.xValue))
    sValue = sprintf('%.16e', stInfo.xValue);
end
end


%%
function sString = i_getParamNumString(hBlock, sParam)
try
    sString = strtrim(get_param(hBlock, sParam));
    sString = regexprep(sString, '\[\s*\]', '');
catch %#ok<CTCH>
    sString = '';
end
end


%%
function [sOutMin, sOutMax] = i_getBlockOutMinMax(hBlock, sPort)
sOutMin = '';
sOutMax = '';

% Note: currently not able to support any port except port '1'
if ~strcmp(sPort, '1')
    return;
end
sOutMin = i_getParamNumString(hBlock, 'OutMin');
sOutMax = i_getParamNumString(hBlock, 'OutMax');
end


%%
function nSigs = i_countSignals(astSignals)
if ~isempty(astSignals)
    nSigs = sum([astSignals(:).iWidth]);
else
    nSigs = 0;
end
end


%%
function ahBlocks = i_getInnerBlocks(hParent, sBlockType)
ahBlocks = ep_find_system(hParent, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'SearchDepth',    1, ...
    'BlockType',      sBlockType);
ahBlocks = reshape(ahBlocks, 1, []);
end

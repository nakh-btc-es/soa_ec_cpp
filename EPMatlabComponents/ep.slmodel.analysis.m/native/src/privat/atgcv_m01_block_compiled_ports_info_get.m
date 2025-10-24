function [astInports, astOutports, bUseInnerView] = atgcv_m01_block_compiled_ports_info_get(stEnv, sBlockPath, bLookIntoSubsystems)
% Get interface info of provided block in compiled mode.
%
% function [astInports, astOutports, bUseInnerView] = atgcv_m01_block_compiled_ports_info_get(stEnv, sBlockPath, bLookIntoSubsystems)
%
%   INPUT               DESCRIPTION
%     stEnv              (struct)      error messenger environment
%     sBlockPath         (string)      full paths to model block
%     bLookIntoSubsystems  (bool)      optional flag that the "inner view" is to be used for subsystems, i.e.
%                                      (1) a subsystem is *not* treated as a block but as a container AND
%                                      (2) instead the child port blocks of the subystem on the lower level are analyzed
%                                      [default == true]
%
%   OUTPUT              DESCRIPTION
%      astInports         (array)      structs with following fields: 
%       .iNumber            (int)        number of port
%       .sPath           (string)        path of port
%       .aiDim              (int)        'CompiledPortDimensions' of Port
%       .iWidth             (int)        width of the main Signal
%       .sOutMin         (string)        'Min' as defined for the Port
%       .sOutMax         (string)        'Max' as defined for the Port
%      [.sSigKind        (string)]       !deprecated! -- 'simple' | 'bus'
%                                           --> replaced by sBusType and sBusObj
%      .sBusType         (string)        'NOT_BUS' | 'VIRTUAL_BUS' | 'NON_VIRTUAL_BUS'
%      .sBusObj          (string)        name of corresponding Bus object (if available)
%       .astSignal       (string)        structs with te following fields:
%         .sName         (string)          name of subsignal
%         .sType         (string)          type of subsignal
%         .iWidth       (integer)          width of subsignal
%
%       .bIsInfoComplete   (bool)        flat that info is complete
%
%      astOutports        (array)       ... same struct as astInports
%
%      bUseInnerView       (bool)       flag if the inner or outer view was used
%
%   REMARKS
%     Note: Assuming the function is called with the model being set to
%     "compiled" mode already.
%
%   <et_copyright>


%%
if (nargin < 3)
    bLookIntoSubsystems = true; % as default look inside (user) subsystems
end
hBlock = get_param(sBlockPath, 'handle');

[bUseInnerView, bIsSfChart] = i_isInnerViewRequired(hBlock, bLookIntoSubsystems);
if bUseInnerView
    % handle as Subsystem with "inner" view via interfaces of inner Port-blocks
    ahInBlocks  = i_getInnerBlocks(hBlock, 'Inport');
    ahOutBlocks = i_getInnerBlocks(hBlock, 'Outport');
    
    if bIsSfChart
        oSfInterfaceMap = i_getSfChartInterfaceAsMap(hBlock);
    else
        oSfInterfaceMap = containers.Map;
    end
    
    astInports  = arrayfun(@(x) i_getInfoFromPortBlock(stEnv, x, oSfInterfaceMap), ahInBlocks);
    astOutports = arrayfun(@(x) i_getInfoFromPortBlock(stEnv, x, oSfInterfaceMap), ahOutBlocks);
else
    % handle as block with "outer" view directly via Block interface
    stPortHandles = get_param(hBlock, 'PortHandles');    
    
    astInports  = arrayfun(@(x) i_getPortInfo(stEnv, x), stPortHandles.Inport);
    astOutports = arrayfun(@(x) i_getPortInfo(stEnv, x), stPortHandles.Outport);    
end
end



%%
function [bUseInnerView, bIsSfChart] = i_isInnerViewRequired(hBlock, bLookIntoSubsystems)
bIsSfChart = false;

% for root level blocks (i.e. models) only the *inner view* is possible
if i_isRootLevel(hBlock)
    bUseInnerView = true;
    return;
end

% for SF-Charts only the *inner view* is currently supported
if atgcv_sl_block_isa(hBlock, 'Stateflow')
    bIsSfChart    = true;
    bUseInnerView = true;
    return;
end

% *inner view* only for user subsystems and only if requested
bUseInnerView = bLookIntoSubsystems && i_isUserSubsystem(hBlock);
end


%%
function oSfInterfaceMap = i_getSfChartInterfaceAsMap(hChartBlock)
oSfInterfaceMap = containers.Map;

oSfRoot  = sfroot;
oSfChart = oSfRoot.find( ...
    '-isa', 'Stateflow.Chart', ...
    'Path',  getfullname(hChartBlock));
if isempty(oSfChart)
    return;
end

casIfScopes = {'Input', 'Output'};
for i = 1:length(casIfScopes)
    aoSfData = oSfChart.find ( ...
        '-isa', 'Stateflow.Data', ...
        'Scope', casIfScopes{i});
    
    for k = 1:length(aoSfData)
        sFullPath = [aoSfData(k).Path, '/', aoSfData(k).Name];
        oSfInterfaceMap(sFullPath) = aoSfData(k);
    end
end
end


%%
% UserSubsystem == every Subsystem that is not a predefined Simlink block
function bIsUserSub = i_isUserSubsystem(hBlock)
bIsUserSub = strcmpi(get_param(hBlock, 'BlockType'), 'SubSystem') && ~i_isPredfinedSimulinkBlock(hBlock);
end


%%
% RootLevel == hBlock is actually the model (i.e. bdroot)
function bIsRootLevel = i_isRootLevel(hBlock)
bIsRootLevel = isempty(get_param(hBlock, 'Parent'));
end


%%
function stPortInfo = i_getPortInfo(stEnv, hPort)
stPortInfo = struct( ...
    'iNumber',         get_param(hPort, 'PortNumber'), ...
    'sSfName',         '', ...
    'sSfRelPath',      '', ...
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

if (~isempty(oSfInterfaceMap) && oSfInterfaceMap.isKey(stPortInfo.sPath))
    oSfData = oSfInterfaceMap(stPortInfo.sPath);
    [dMin, dMax] = i_getMinMax(oSfData, hPortBlock);
    stPortInfo.sOutMin = i_getFiniteDoubleValueAsString(dMin);
    stPortInfo.sOutMax = i_getFiniteDoubleValueAsString(dMax);
    
    % Note: for Stateflow, always use the port-defined Min/Max values
    sMin = stPortInfo.sOutMin;
    sMax = stPortInfo.sOutMax;
else
    stPortInfo.sOutMin = i_getParamNumString(hPortBlock, 'OutMin');
    stPortInfo.sOutMax = i_getParamNumString(hPortBlock, 'OutMax');
    
    % Note: for Simulink, use port-defined Min/Max values for ML versions lower than ML2011b
    %       Reason: for higher ML versions, the info is better read out from CompiledPortDesignMin/-Max
    if atgcv_verLessThan('ML7.13')    
        sMin = i_getDoubleValueInBlockContext(stPortInfo.sOutMin, hPortBlock);
        sMax = i_getDoubleValueInBlockContext(stPortInfo.sOutMax, hPortBlock);
    else
        sMin = '';
        sMax = '';
    end
end

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
function bIsPredefSL = i_isPredfinedSimulinkBlock(hBlock)
bIsPredefSL = false;
try
    if strcmpi(get_param(hBlock, 'Mask'), 'on') 
        sRefBlock = get_param(hBlock, 'ReferenceBlock');
        if (~isempty(sRefBlock) && strncmpi(sRefBlock, 'simulink', 8))
            bIsPredefSL = true;
        end
    end
catch %#ok<CTCH>
    % just ignore for now
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
ahBlocks = find_system(hParent, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'SearchDepth',    1, ...
    'BlockType',      sBlockType);
ahBlocks = reshape(ahBlocks, 1, []);
end

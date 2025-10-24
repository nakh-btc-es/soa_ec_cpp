function [astInports, astOutports, bUseInnerView] = ep_sl_block_compiled_ports_info_get(stEnv, sBlockPath, bLookIntoSubsystems)
% Get interface info of provided block in compiled mode.
%
% function [astInports, astOutports, bUseInnerView] = ep_sl_block_compiled_ports_info_get(stEnv, sBlockPath, bLookIntoSubsystems)
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
%       .sSfName         (string)        only for SF Chart interfaces: SF data name
%       .sSfRelPath      (string)        only for SF Chart interfaces: relative path for nested SF data
%       .sPath           (string)        path of port
%       .oSig            (object)        ep_sl.Signal object with full info about the signal
%       .bIsInfoComplete   (bool)        flag telling if info is complete and trustworthy
%
%      astOutports        (array)       ... same struct as astInports
%
%      bUseInnerView       (bool)       flag if the inner or outer view was used
%
%   REMARKS
%     Note: Assuming the function is called with the model being set to "compiled" mode already.
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
    
    astInports  = arrayfun(@(x) i_getInfoFromIOBlock(stEnv, x, oSfInterfaceMap), ahInBlocks);
    astOutports = arrayfun(@(x) i_getInfoFromIOBlock(stEnv, x, oSfInterfaceMap), ahOutBlocks);
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
    'oSig',            i_getSignalFromPort(stEnv, hPort), ...
    'bIsInfoComplete', false);

if ~stPortInfo.oSig.isValid()
    sErrMsg = sprintf('Signal for Port "%s" could not be analyzed properly.', i_getPortDisplayName(hPort));
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sErrMsg);
end
stPortInfo.bIsInfoComplete = true;
end


%%
function oSig = i_getSignalFromPort(stEnv, hPort)
try
    oSig = ep_sl_signal_from_port_get(hPort);
catch oEx %#ok<NASGU>
    warning('EP:INTERNAL:USING_FALLBACK_SIGNAL_ANALYSIS', ...
        'Using fallback analysis for port "%s".', i_getPortDisplayName(hPort));
    oSig = i_useLegacyFallbackForSignal(stEnv, hPort);
end
end


%%
function oSig = i_useLegacyFallbackForSignal(stEnv, hPort)
[stInfo, sErrMsg] = atgcv_m01_port_signal_info_get(stEnv, hPort);
if isempty(sErrMsg)
    oSig = ep_sl_signal_from_legacy_signal_info_get(stInfo.astSigs);
    xDesignMin = get_param(hPort, 'CompiledPortDesignMin');
    xDesignMax = get_param(hPort, 'CompiledPortDesignMax');
    
    oSig = oSig.setDesignMinMax(xDesignMin, xDesignMax);
else
    oSig = ep_sl.Signal;
end
end


%%
function sDispName = i_getPortDisplayName(hPort)
sDispName = sprintf('%s (%s:%d)', getfullname(hPort), get_param(hPort, 'PortType'), get_param(hPort, 'PortNumber'));
end


%%
% Note: PortBlocks are only "Inport" and "Outport"; nothing else!
function stPortInfo = i_getInfoFromIOBlock(stEnv, hPortBlock, oSfInterfaceMap)
stInnerPortHandles = get_param(hPortBlock, 'PortHandles');

% Note: an  InPort has an inner outport
%       an OutPort has an inner inport
hPort = stInnerPortHandles.Outport;
bIsOutport = isempty(hPort);
if bIsOutport
    % Block is an OutPort
    hPort = stInnerPortHandles.Inport;
end

stPortInfo = struct( ...
    'iNumber',         str2double(get_param(hPortBlock, 'Port')), ...
    'sSfName',         '', ...
    'sSfRelPath',      '', ...
    'sPath',           getfullname(hPortBlock), ...
    'oSig',            i_getSignalFromPort(stEnv, hPort), ...
    'bIsInfoComplete', false);

if ~stPortInfo.oSig.isValid()
    sErrMsg = sprintf('Signal for Port "%s" could not be analyzed properly.', i_getPortDisplayName(hPort));
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sErrMsg);
end

if (~isempty(oSfInterfaceMap) && oSfInterfaceMap.isKey(stPortInfo.sPath))
    % Note: for Stateflow, always use the port-defined Min/Max values
    
    oSfData = oSfInterfaceMap(stPortInfo.sPath);
    [dMin, dMax] = i_getMinMax(oSfData, hPortBlock);
    sMin = i_getFiniteDoubleValueAsString(dMin);
    sMax = i_getFiniteDoubleValueAsString(dMax);
    stPortInfo.oSig = stPortInfo.oSig.setLeafMinMax(sMin, sMax);
else
    % special case: for root-level Outports the signal name can be directly specified inside the block
    % Note: Only possible for ML >= ML2016b.
    if (bIsOutport && i_isOnRootLevel(hPortBlock))
        sSigNameFromPort = get_param(hPortBlock, 'SignalName');
        if ~isempty(sSigNameFromPort)
            stPortInfo.oSig.sName_ = sSigNameFromPort;
        end
    end
end

stPortInfo.bIsInfoComplete = true;
end


%%
function bIsOnRootLevel = i_isOnRootLevel(hBlock)
bIsOnRootLevel = i_isRootLevel(get_param(hBlock, 'Parent'));
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
function ahBlocks = i_getInnerBlocks(hParent, sBlockType)
ahBlocks = find_system(hParent, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'SearchDepth',    1, ...
    'BlockType',      sBlockType);
ahBlocks = reshape(ahBlocks, 1, []);
end

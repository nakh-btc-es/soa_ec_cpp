function [stInfo, sErrMsg] = atgcv_m01_port_signal_info_get(stEnv, hPort, sForceName)
% Get info on Signal running through provided BlockPort.
%
% function stInfo = atgcv_m01_port_signal_info_get(stEnv, hPort)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)       environment struct
%     hPort             (string)       Port handle of a Block in model
%
%   OUTPUT              DESCRIPTION
%     stInfo             (struct)      info data:
%      .aiDim            (array)       dimensions info of main signal 
%                                      (== CompiledPortDimensions)
%      [.sSigKind        (string)]     !deprecated! -- 'simple' | 'bus'
%                                      --> replaced by sBusType and sBusObj
%      .sBusType         (string)      'NOT_BUS' | 'VIRTUAL_BUS' | 'NON_VIRTUAL_BUS'
%      .sBusObj          (string)      name of corresponding Bus object (if available)
%      .astSigs          (array)       structs with following info 
%        .sName          (string)      name of subsignal
%        .sUserType      (string)      type of subsignal (might be an alias)
%        .sType          (string)      base type of subsignal (builtin or fixed-point-type)
%        .iWidth         (integer)     width of subsignal
%        .sMin           (string)      Min constraint of signal if available
%        .sMax           (string)      Max constraint of signal if available
%        .aiDim          (array)       integers representing dimension
%
%   REMARK:
%     Note: The readout depends on the corresponding model being in "compiled" mode and 
%     on the BusStrictMode being active.
%


%%
if isempty(hPort)
    sErrMsg = 'Empty Port provided.';
    stInfo = i_getInitInfo();
    return;
end

%%
hBlock = i_getParentBlock(hPort);
% NOTE: if something went wrong, hBlock is empty! be prepared for this!


%%
[stSigInfo, stPortInfo] = i_getPortSigInfo(hPort, hBlock);
if (nargin > 2)
    stSigInfo.sName = sForceName;
end
[stInfo, sErrMsg] = i_getMainInfo(stEnv, stPortInfo, stSigInfo, hPort, hBlock);
end


%%
function stInfo = i_getInitInfo()
stInfo = struct( ...
    'xDesignMin', [], ...
    'xDesignMax', [], ...
    'astSigs',    [], ...
    'aiDim',      [], ...
    'sSigKind',   '', ...
    'sBusType',   '', ...
    'sBusObj',    '');
end


%%
function [stInfo, sErrMsg] = i_getMainInfo(stEnv, stPortInfo, stSigInfo, hPort, hBlock)
stInfo = i_getInitInfo();
sErrMsg = '';

stInfo.sBusType = stPortInfo.sBusType;
if stPortInfo.bIsBus
    [stInfo, bIsValid] = i_addBusInfo(stEnv, stInfo, stPortInfo, stSigInfo, hPort, hBlock);
    if ~bIsValid
        sErrMsg = sprintf('Bus signal for Port "%s" could not be analyzed properly.', i_getPortDisplayName(hPort));
        stInfo = i_getInitInfo();
        return;
    end
    
else
    % workaround/hack for special case: "auto" should be replaced by the most 
    % often used type: "double"
    if strcmp(stSigInfo.sType, 'auto')
        stSigInfo.sType = 'double';
    end
    stInfo.astSigs  = stSigInfo;
    stInfo.sSigKind = 'simple';   
end
stInfo.aiDim = get_param(hPort, 'CompiledPortDimensions');

stInfo.xDesignMin = stPortInfo.DesignMin;
stInfo.xDesignMax = stPortInfo.DesignMax;
end


%%
function sDispName = i_getPortDisplayName(hPort)
sDispName = sprintf('%s (%s:%d)', getfullname(hPort), get_param(hPort, 'PortType'), get_param(hPort, 'PortNumber'));
end


%%
function [stInfo, bIsValid] = i_addBusInfo(stEnv, stInfo, stPortInfo, stSigInfo, hPort, hBlock)
bIsValid = true;

stInfo.sSigKind = 'bus';

% 1) if we have a BusObject, use it
if ~isempty(stPortInfo.sBusObj)
    stInfo.sBusObj = stPortInfo.sBusObj;
    oBus = i_evalBusToBusObject(stPortInfo.sBusObj, i_getResolver(hPort, hBlock));
    
    if ~isempty(oBus)
        astSigs = atgcv_m01_bus_obj_store('get', stPortInfo.sBusObj, oBus, stSigInfo.sName);
        if isempty(astSigs)
            astSigs = atgcv_m01_bus_object_signal_info_get(stEnv, oBus, stSigInfo.sName, i_getResolver(hPort, hBlock));
            atgcv_m01_bus_obj_store('set', stPortInfo.sBusObj, oBus, astSigs);
        end
    
        if ~isempty(astSigs)
            stInfo.astSigs = astSigs;
            return;
        end
    end
end

% 2) get info from Signal Hierarchy
stInfo.astSigs = i_resolvePortSignalHierarchy(stEnv, hPort, hBlock, stSigInfo.sName);
iEffectivePortWidth = i_getEffectivePortWidth(hPort);
if i_isSubSigInfoConsistent(stInfo.astSigs, iEffectivePortWidth)
    return;
end

% 3) here we try to do backpropagation and apply this function to each found block
%    --> but only if we have consistent info from Simulink
if i_isPortValid(hPort)
    stBackpropInfo = i_getSigInfoByBackprop(stEnv, hBlock, hPort);
    if (isstruct(stBackpropInfo) ...
        && ~isempty(stBackpropInfo.astSigs) ...
        && i_isSubSigInfoConsistent(stBackpropInfo.astSigs, iEffectivePortWidth))
        stInfo = stBackpropInfo;
        return;
    end
end

% 4) here we refer to the "legacy" way for non-BusStrictMode
if (~isempty(hBlock) &&  i_isPortValid(hPort))
    stInfo.astSigs = i_getLegacySigInfoNonStrict(stEnv, hBlock, hPort);
end
bIsValid = i_isSubSigInfoConsistent(stInfo.astSigs, iEffectivePortWidth);
end


%%
function bIsValid = i_isPortValid(hPortHandle)
aiDim = get_param(hPortHandle, 'CompiledPortDimensions');
bIsValid = ~isempty(aiDim);
end


%%
% Note: Function is optimized for Bus signals! It can handle non-bus signals but only *inefficiently* as a fallback.
function iWidth = i_getEffectivePortWidth(hPortHandle)
try
    stBusStruct = Simulink.Bus.createMATLABStruct(hPortHandle);
    if ~isempty(stBusStruct)
        iWidth = i_getNumLeafElements(stBusStruct);
        return;
    end
catch
end

% fallback: non-bus signal
iWidth = get_param(hPortHandle, 'CompiledPortWidth');
end


%%
% recursive function that counts the number of leaf elements of a struct
% Note: two special cases
%       1) a struct without any fields has zero leaf elements
%       2) a non-struct variable is considered a leaf element
function nLeafs = i_getNumLeafElements(xVariable)
if isstruct(xVariable)
    nLeafs = 0;
    
    casFieldnames = fieldnames(xVariable);
    for i = 1:numel(casFieldnames)
        nLeafs = nLeafs + i_getNumLeafElements(xVariable.(casFieldnames{i}));
    end
else
    nLeafs = numel(xVariable);
end
end


%%
function bIsConsistent = i_isSubSigInfoConsistent(astSigs, iExpectedWidth)
bIsConsistent = false;
if isempty(astSigs)
    % cornercase: no sub signals
    if (iExpectedWidth == 0)
        bIsConsistent = true;
    end
    return;
end

% Info is inconsistent if expected total width does not meet expectation
iSigWidth = sum([astSigs(:).iWidth]);
if (iSigWidth ~= iExpectedWidth)
    return;
end

% Type "auto" or "" is also a sign of inconsistent Info
casTypes = {astSigs(:).sType};
if (any(cellfun(@isempty, casTypes)) || any(strcmp('auto', casTypes)))
    return;
end

% if we are here, all consistency checks were successful
bIsConsistent = true;
end


%%
function astSigs = i_getLegacySigInfoNonStrict(stEnv, hBlock, hPort)
astSigs = [];
if ~isempty(hBlock)
    sPort = sprintf('%d', get_param(hPort, 'PortNumber'));
    if strcmpi(get_param(hPort, 'PortType'), 'outport')
        stSrc = struct( ...
            'hBlock', hBlock, ...
            'sPort',  sPort);
        [stInfo, bIsValid] = atgcv_m01_signal_info_get(stEnv, stSrc, true);
    else
        stDest = struct( ...
            'hBlock', hBlock, ...
            'sPort',  sPort);
        [stInfo, bIsValid] = atgcv_m01_signal_info_get(stEnv, stDest);
    end
    if bIsValid
        astSigs = stInfo.astSigs;
    end
end
end


%%
function stInfo = i_getSigInfoByBackprop(stEnv, hBlock, hPort)
stInfo = [];
if isempty(hBlock)
    return;
end

sPort = sprintf('%d', get_param(hPort, 'PortNumber'));
if strcmpi(get_param(hPort, 'PortType'), 'outport')
    stSrc = struct( ...
        'hBlock', hBlock, ...
        'sPort',  sPort);
    
    bForceDestName = false;
    [stSrc, stDest] = atgcv_m01_dest_src_find(stEnv, stSrc, true);
    if isempty(stDest)
        stDest = i_getBusDest(stSrc);
        if isempty(stDest)
            return;
        end
        bForceDestName = true;
    end
    try
        stPortHandles = get_param(stDest.hBlock, 'PortHandles');
        hPort = stPortHandles.Inport(str2double(stDest.sPort));
        if bForceDestName
            stInfo = atgcv_m01_port_signal_info_get(stEnv, hPort, stDest.sSigName);
        else
            stInfo = atgcv_m01_port_signal_info_get(stEnv, hPort);
        end
    catch
    end
else
    stDest = struct( ...
        'hBlock', hBlock, ...
        'sPort',  sPort);
    
    stSrc = atgcv_m01_dest_src_find(stEnv, stDest);
    if isempty(stSrc)
        return;
    end
    try
        stPortHandles = get_param(stSrc.hBlock, 'PortHandles');
        hPort = stPortHandles.Outport(str2double(stSrc.sPort));
        stInfo = atgcv_m01_port_signal_info_get(stEnv, hPort);
    catch
    end
end
end


%%
function [stDest, astCheckDest] = i_getBusDest(stSrc)
astCheckDest = [];
switch lower(get_param(stSrc.hBlock, 'BlockType'))
    case {'signalspecification', 'zeroorderhold', 'ratetransition', 'unitdelay', 'memory', 'signalconversion'}
        stDest = i_getDefaultDest(stSrc);
    case 'merge'
        [stDest, astCheckDest] = i_getMultiInportDest(stSrc);
    case 'switch'
        % second input is the switch_signal, so do not use it
        [stDest, astCheckDest] = i_getMultiInportDest(stSrc, '2');
    case 'multiportswitch'
        % first input is the swich_signal, so do not use it
        [stDest, astCheckDest] = i_getMultiInportDest(stSrc, '1');
    otherwise
        % assume invalid block: i.e. a block that is _not_ bus-capable
        stDest = [];
end
end


%%
function [stDest, astCheckDest] = i_getMultiInportDest(stSrc, sForbiddenPort)
if (nargin < 2)
    sForbiddenPort = '';
end
astPortCon = get_param(stSrc.hBlock, 'PortConnectivity');
abIsValid = true(size(astPortCon));
for i = 1:length(astPortCon)
    abIsValid(i) = (~isempty(astPortCon(i).SrcBlock) && ...
        ~isletter(astPortCon(i).Type(1)) && ...
        ~strcmp(astPortCon(i).Type, sForbiddenPort));
end
astPortCon = astPortCon(abIsValid); % only the allowed inports
if ~isempty(astPortCon)
    % use the first connection as dest
    stDest = stSrc;
    stDest.sPort = astPortCon(1).Type;
    astPortCon(1) = [];
    
    % use the rest for checking
    if ~isempty(astPortCon)
        astCheckDest = repmat(stDest, 1, length(astPortCon));
        for i = 1:length(astPortCon)
            astCheckDest(i).sPort = astPortCon(i).Type;
        end
    else
        astCheckDest = [];
    end
else
    stDest = [];
    astCheckDest = [];
end
end


%%
% just use the first (or provided) inport of the block as new dest
function stDest = i_getDefaultDest(stSrc)
stDest = stSrc;
stDest.sPort = '1';
end


%%
function bIsPropag = i_isPropagatingBlock(hBlock)
casPropagBlocks = { ...
    'Inport', ...
    'Outport', ...
    'SubSystem', ...
    'From', ...
    'Goto'};
bIsPropag = any(strcmpi(get_param(hBlock, 'BlockType'), casPropagBlocks));
end


%%
function bCanPropagateName = i_canPropagateNameBlock(hBlock)
bCanPropagateName = strcmpi(get_param(hBlock, 'BlockType'), 'BusSelector');
bCanPropagateName = bCanPropagateName || i_isPropagatingBlock(hBlock);
end


%%
function sBusObjectName = i_getBusObjectNameFromBlock(hBlock)
sBusObjectName = '';
if strcmpi(get_param(hBlock, 'UseBusObject'), 'on')
    sBusObjectName = get_param(hBlock, 'BusObject');
end
end


%%
function oBus = i_evalBusToBusObject(xBus, hResolverFunction)
oBus = [];
if isempty(xBus)
    return;
end
if ischar(xBus)
    try
        [xResolvedBus, nScope] = feval(hResolverFunction, xBus);
        if (nScope > 0)
            xBus = xResolvedBus;
        end
    catch  %#ok<CTCH>
    end
end
if isa(xBus, 'Simulink.Bus')
    oBus = xBus;
end
end


%%
function stSigInfo = i_getInitSigInfo()
stSigInfo = struct( ...
    'sName',      '', ...
    'sType',      '', ...
    'sUserType',  '', ...
    'sMin',       '', ...
    'sMax',       '', ...
    'xDesignMin', [], ...
    'xDesignMax', [], ...
    'iWidth',     [], ...
    'aiDim',      []);
end


%%
function stPortInfo = i_getInitPortInfo()
stPortInfo = struct( ...
    'DesignMin', [], ...
    'DesignMax', [], ...
    'sBusType',  '', ...
    'sBusObj',   '', ...      
    'bIsBus',    false);
end


%%
function sName = i_getPortSigName(hPort, hBlock)
sName = i_getCleanName(get_param(hPort, 'Name'));
if isempty(sName)
    if strcmpi(get_param(hPort, 'PortType'), 'outport')
        if ~isempty(hBlock) && i_canPropagateNameBlock(hBlock)
            sName = i_getPropagatedSignalRootName(hPort);
        end
    else
        hLine = get_param(hPort, 'Line');
        if (hLine > 0)
            hSrcBlock = get_param(hLine, 'SrcBlockHandle');
            % negative hSrcBlock means an _unconnected_ line
            if ((hSrcBlock > 0) && i_canPropagateNameBlock(hSrcBlock))
                hSrcPort = get_param(hLine, 'SrcPortHandle');
                sName = i_getPropagatedSignalRootName(hSrcPort);
            end
        end
    end
end
end


%%
function [stSigInfo, stPortInfo] = i_getPortSigInfo(hPort, hBlock)
stSigInfo = i_getInitSigInfo();
stPortInfo = i_getInitPortInfo();

stSigInfo.sName = i_getPortSigName(hPort, hBlock);

hResolverFunc = i_getResolver(hPort, hBlock);

stSigInfo.sUserType = get_param(hPort, 'CompiledPortDataType');
[stSigInfo.sType, bIsValidType] = i_evaluateType(stSigInfo.sUserType, hResolverFunc);
stSigInfo.iWidth = get_param(hPort, 'CompiledPortWidth');
stSigInfo.aiDim  = get_param(hPort, 'CompiledPortDimensions');

stPortInfo.bIsBus   = get_param(hPort, 'CompiledPortBusMode');
stPortInfo.sBusType = get_param(hPort, 'CompiledBusType');
if (stPortInfo.bIsBus && ~isempty(hBlock))
    stPortInfo.sBusObj = i_tryToGetBusObjectName(hPort, hBlock);
    
elseif ~bIsValidType
    stPortInfo.sBusObj = i_tryToGetBusObjectNameFromType(stSigInfo.sUserType, hResolverFunc);    
    if ~isempty(stPortInfo.sBusObj)
        stPortInfo.bIsBus = true;
        stPortInfo.sBusType = 'NON_VIRTUAL_BUS'; % TODO: check if this makes sense
    end
end

stPortInfo.DesignMin = get_param(hPort, 'CompiledPortDesignMin');
stPortInfo.DesignMax = get_param(hPort, 'CompiledPortDesignMax');
end


%%
function hResolverFunc = i_getResolver(hPortHandle, hBlock)
if (isempty(hBlock) && ~isempty(hPortHandle))
    hBlock = i_getContextBlock(hPortHandle);
end

if isempty(hBlock)
    hResolverFunc = atgcv_m01_generic_resolver_get();
else
    hResolverFunc = atgcv_m01_generic_resolver_get(hBlock);
end
end


%%
function hBlock = i_getContextBlock(hPortHandle)
hBlock = i_getParentBlock(hPortHandle);
if isempty(hBlock)
    hBlock = i_getModelBlock(hPortHandle);
end
end


%%
function hBlock = i_getModelBlock(hPortHandle)
hBlock = [];
try %#ok<TRYNC>
    hBlock = bdroot(hPortHandle);
end
if isempty(hBlock)
    try %#ok<TRYNC>
        hBlock = get_param(regexprep(getfullname(hPortHandle), '/.*$', ''), 'handle');
    end
end
end


%%
function hBlock = i_getParentBlock(hPortHandle)
hBlock = [];
try
    sParentBlock = get_param(hPortHandle, 'Parent'); 
    hBlock = get_param(sParentBlock, 'Handle');
catch oEx
    % Note: sometimes SL is behaving in a weird way by providing the path to the
    %       Parent Block but also saying that the path is invalid!
    % --> UT in com.btc.model_analysis.m: 'Matrix.SL11'
    % --> QA model WABCO-2 ASM (ML2010bSP2, TL3.3) is displaying this behavior
end
end


%%
function bIsValid = i_isPortHandleValid(hPort)
bIsValid = ~isempty(i_getParentBlock(hPort));
end


%%
function sBusObjectName = i_tryToGetBusObjectName(hPort, hBlock)
sBusObjectName = i_getBusObjectNameFromPort(hPort);
if ~isempty(sBusObjectName)
    return;
end

% try all blocks that can specify a BusObject
if ~isempty(hBlock)
    sBlockType = get_param(hBlock, 'BlockType');
    if any(strcmp(sBlockType, {'Inport', 'Outport'}))
        sBusObjectName = i_getBusObjectNameFromBlock(hBlock);
    elseif strcmpi(sBlockType, 'BusCreator')
        if strcmpi(get_param(hPort, 'PortType'), 'outport')
            sBusObjectName = i_getBusObjectNameFromBlock(hBlock);
        end
    end
end
end


%%
function sBusObjectName = i_getBusObjectNameFromPort(hPort)
sBusObjectName = '';

try
    stSignalHierarchy = get_param(hPort, 'SignalHierarchy');
    if ~isempty(stSignalHierarchy.BusObject)
        sBusObjectName = stSignalHierarchy.BusObject;
    end
catch %#ok<CTCH>
end
if isempty(sBusObjectName)
    try
        stBusStruct = get_param(hPort, 'BusStruct');
        if ~isempty(stBusStruct)
            if isfield(stBusStruct, 'busObjectName')
                sBusObjectName = stBusStruct.busObjectName;
            end
        end
    catch %#ok<CTCH>
    end
end
end


%%
% try to determine the Name:
% - sometimes we get an empty SignalName from hierarchy but the Port is
%   nevertheless propagating a name
% - however, the propagated Name is not always the right one, since it could
%   also be the name of one of the child elements
% --> try to use a heuristic that is right most of the time
function sName = i_getPropagatedSignalRootName(hPort)
% 1) check hierarchy root name
[sName, bIsValid] = i_getNameFromSignalHierarchy(hPort);
if (bIsValid && ~isempty(sName))
    return;
end

% 2) hierarch name turned out to be invalid or empty, try to use 
%    propagated name(s)
sName = i_getPropagatedName(hPort);
end


%%
function sPropagName = i_getPropagatedName(hPort)
sPropagName = '';
% first check, if the Port is valid --> otherwise just return an empty name
if ~i_isPortHandleValid(hPort)
    return;
end

% Note: the propagated name could be really the name of the root signal or the
% name of the child elements --> try to differentiate here and just return
% something if it is probably the root name

% 1) if the propagated name has a "comma" --> name of the child elements --> do not use it!
sPropagName = get_param(hPort, 'PropagatedSignals');
if any(sPropagName == ',')
    sPropagName = '';
else
    % 2) the name has no commas but could still be a child name if the signal has only one child --> check this
    sPropagName = i_getCleanName(sPropagName);
    if ~isempty(sPropagName)
        casNames = i_getChildNames(hPort);
        if ((length(casNames) == 1) && strcmp(sPropagName, casNames{1}))
            % just one child element with same name
            % --> most proably the propagated name is referring to child
            % --> do not use it
            sPropagName = '';
        end
    end
end
end


%%
function casNames = i_getChildNames(hPort)
casNames = {};
try
    stSignalHierarchy = get_param(hPort, 'SignalHierarchy');
    if ~isempty(stSignalHierarchy)
        if ~isempty(stSignalHierarchy.Children)
            casNames = {stSignalHierarchy.Children(:).SignalName};
        end
    end
catch %#ok<CTCH>
end
end


%%
function [sName, bIsValid] = i_getNameFromSignalHierarchy(hPort)
sName = '';
bIsValid = false;
try
    sType = get_param(hPort, 'CompiledBusType');
    if strcmpi(sType, 'NOT_BUS')
        return;
    end
    stSignalHierarchy = get_param(hPort, 'SignalHierarchy');
    if ~isempty(stSignalHierarchy)
        sName = stSignalHierarchy.SignalName;
        bIsValid = true;
    end
catch %#ok<CTCH>
end
end


% %%
% function casBlocks = i_getBusCapableBlocks()
% casBlocks = { ...
%     'BusAssignment', ...
%     'BusCreator', ...
%     'BusSelector', ...
%     'From', ...
%     'Goto', ...
%     'Inport', ...
%     'Memory', ...
%     'Merge', ...
%     'MultiportSwitch', ...
%     'Outport', ...
%     'RateTransition', ...
%     'SignalConversion', ...
%     'Switch', ...
%     'UnitDelay', ...
%     'ZeroOrderHold'};
% end



%%
function astSigs = i_resolvePortSignalHierarchy(stEnv, hPortHandle, hBlock, sName, sType)
if (nargin < 5)
    sType = get_param(hPortHandle, 'CompiledPortDataType');
    if (nargin < 4)
        % TODO: ???? is this the right approach to get the name ????
        sName = get_param(hPortHandle, 'SignalNameFromLabel');
    end
end
stSignalHierarchy = get_param(hPortHandle, 'SignalHierarchy');
if isempty(stSignalHierarchy)
    astSigs = repmat(i_getInitSigInfo(), 1, 0);
    return;
end

% take a shortcut if we have a BusObject at the root level
if ~isempty(stSignalHierarchy.BusObject)
    astSigs = ...
        atgcv_m01_bus_object_signal_info_get(stEnv, stSignalHierarchy.BusObject, sName, i_getResolver(hPortHandle, []));
    return;
end

if strcmp(sType, 'auto')
    stBusStruct = get_param(hPortHandle, 'BusStruct');
    if ~isempty(stBusStruct)
        astSigs = atgcv_m01_bus_struct_resolve(stEnv, stBusStruct.signals, sName);
        if isempty(astSigs)
            astSigs = i_fallbackForBusStructPorts(stEnv, hBlock, hPortHandle, sName);
        end
        if ~isempty(astSigs)
            return;
        end
    end
end

stSignalHierarchy.SignalName = sName;
astSigs = i_resolveSignalHierarchy(stEnv, stSignalHierarchy, i_getResolver(hPortHandle, []));
if isempty(astSigs)
    return;
end

nSigs = length(astSigs);
for i = 1:nSigs
    if isempty(astSigs(i).sType)
        astSigs(i).sType = sType;
    end
end

caiDims = i_getIndividualSignalDimensions(hPortHandle);
if (nSigs == length(caiDims))
    for k = 1:nSigs
        astSigs(k).aiDim = caiDims{k};
        if (length(astSigs(k).aiDim) < 3)
            % simple sig
            astSigs(k).iWidth = prod(astSigs(k).aiDim);
        else
            astSigs(k).iWidth = prod(astSigs(k).aiDim(2:end));
        end
    end
end
end


%%
function astSigs = i_fallbackForBusStructPorts(stEnv, hBlock, hPortHandle, sName)
astSigs = [];
if isempty(hBlock)
    return;
end
if (strcmpi(get_param(hBlock, 'BlockType'), 'BusCreator') && strcmpi(get_param(hPortHandle, 'PortType'), 'outport'))
    astSigs = i_fallbackForBusCreatorOutport(stEnv, hBlock, sName);
end
end


%%
function astSigs = i_fallbackForBusCreatorOutport(stEnv, hBlock, sName)
astSigs = [];

stPortHandles = get_param(hBlock, 'PortHandles');
for i = 1:length(stPortHandles.Inport)
    stInfo = atgcv_m01_port_signal_info_get(stEnv, stPortHandles.Inport(i));
    if ~isempty(stInfo.astSigs)
        for k = 1:numel(stInfo.astSigs)
            % Note: if the root input signal has no name, replace it with the default one "signal<#InputIdx>"
            if (stInfo.astSigs(k).sName(1) == '.')
                stInfo.astSigs(k).sName = [sprintf('signal%d', i), stInfo.astSigs(k).sName];
            end
        end
        if isempty(astSigs)
            astSigs = stInfo.astSigs;
        else
            astSigs = [astSigs, stInfo.astSigs]; %#ok<AGROW>
        end
    else
        astSigs = [];
        return;
    end
end
for i = 1:numel(astSigs)
    astSigs(i).sName = [sName, '.', astSigs(i).sName]; %#ok<AGROW>
end
end


%%
function astSigs = i_resolveSignalHierarchy(stEnv, stSignalHierarchy, hResolverFunc)
if ~isempty(stSignalHierarchy.BusObject)
    astSigs = atgcv_m01_bus_object_signal_info_get(stEnv, ...
        stSignalHierarchy.BusObject, stSignalHierarchy.SignalName, hResolverFunc);
else
    if isempty(stSignalHierarchy.Children)
        astSigs = i_getInitSigInfo();
        astSigs.sName = stSignalHierarchy.SignalName;
    else
        sRootName = stSignalHierarchy.SignalName;
        stChild = stSignalHierarchy.Children(1); 
        
        stChild.SignalName = [sRootName, '.', stChild.SignalName];
        astSigs = i_resolveSignalHierarchy(stEnv, stChild, hResolverFunc);
        for i = 2:length(stSignalHierarchy.Children)
            stChild = stSignalHierarchy.Children(i); 
            stChild.SignalName = [sRootName, '.', stChild.SignalName];
            astSigs = [astSigs, i_resolveSignalHierarchy(stEnv, stChild, hResolverFunc)]; %#ok<AGROW>
        end
    end
end
end


%%
function caiDims = i_getIndividualSignalDimensions(hBlockPort)
caiDims = {};

aiDims = get_param(hBlockPort, 'CompiledPortDimensions');
if isempty(aiDims)
    return;
end

if (aiDims(1) == -2)
    nSigs = aiDims(2);
    aiDims = aiDims(3:end);
    caiDims = cell(1, nSigs);
    
    bSuccess = true;
    iIdx = 1;
    for i = 1:nSigs
        if (iIdx > length(aiDims))
            bSuccess = false;
            break;
        end
        try
            nDims = aiDims(iIdx);
            caiDims{i} = aiDims(iIdx:iIdx+nDims);
            iIdx = iIdx + nDims +1;
        catch oEx %#ok<NASGU>
            bSuccess = false;
            break;
        end
    end
    if ~bSuccess
        caiDims = {};
    end
else
    caiDims = {aiDims};
end
end


%%
function sName = i_getCleanName(sName)
sName = regexprep(sName, '^<(.*)>$', '$1');
end


%% 
function [sEvalType, bIsValidType] = i_evaluateType(sType, hResolverFunc)
bIsValidType = false;
sEvalType = sType;
if ~strcmp(sType, 'auto')
    stTypeInfo = ep_sl_type_info_get(sType, hResolverFunc);
    if stTypeInfo.bIsValidType
        sEvalType = stTypeInfo.sEvalType;
        bIsValidType = true;
    end
end
end


%%
function sBusObj = i_tryToGetBusObjectNameFromType(sUserType, hResolverFunc)
sBusObj = '';

sUserType = regexprep(sUserType, '^Bus:\s*', '');
try
    oBusObj = feval(hResolverFunc, sUserType);
    if isa(oBusObj, 'Simulink.Bus')
        sBusObj = sUserType;
    end
catch
end
end


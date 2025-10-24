function oSig = ep_sl_signal_from_port_get(hPort)
% Get info on Signal running through provided BlockPort.
%
% function oSig = ep_sl_signal_from_port_get(hPort)
%
%   INPUT               DESCRIPTION
%     hPort             (string)       Port handle of a Block in model
%
%   OUTPUT              DESCRIPTION
%     oSig              (object )      ep_sl.Signal object
%
%   REMARK:
%     Note: The readout depends on the corresponding model being in "compiled" mode and 
%     on the BusStrictMode being active.
%


%%
if verLessThan('matlab', '9.12')   
    oPort = handle(hPort);
else
    oPort = findobj(hPort);
end

if ~isa(oPort, 'Simulink.Port')
    error('EP:SL:USAGE_ERROR', 'Function requires a valid port handle.');
end

%%
hBlock = i_getParentBlock(hPort);
% NOTE: if something went wrong, hBlock is empty! be prepared for this!

oSig = ep_sl.Signal;

oSig.sName_ = ep_sl_signal_name_from_port_get(hPort);

hResolverFunc = i_getResolver(hPort, hBlock);
sCompiledType = get_param(hPort, 'CompiledPortDataType');
oSig.stTypeInfo_ = ep_sl_type_info_get(sCompiledType, hResolverFunc);

oSig.aiDim_ = get_param(hPort, 'CompiledPortDimensions');

bIsBus = i_isBusModeActive(hPort) || oSig.stTypeInfo_.bIsBus;

if ~verLessThan('matlab', '9.6')
    if strcmp(get_param(hPort, 'CompiledMessageMode'), 'on')
        oSig = oSig.setMessage(true);
    end
else
    % for ML < ML2019a assume automatically false, since message signals were not supported by SL
    oSig = oSig.setMessage(false);
end

if bIsBus
    sBusType = get_param(hPort, 'CompiledBusType');
    if strcmp(sBusType, 'NOT_BUS')
        % note: for unconnected ports that provide/consume a signal referencing a Bus-Signal (Simulink.Signal)
        % it can happen that the compiled bus type is "NOT_BUS" 
        % --> this leads to incosistencies later during analysis
        % --> adapt here to a non-virtual bus type
        sBusType = 'NON_VIRTUAL_BUS';
    end
    if strcmp(sBusType, 'VIRTUAL_BUS')
        % note: for virtual buses the dimensions needs to start with a negative dimension number "-2"
        % <-- in Simulink this is sometimes not fullfilled
        % in such a case normalize the dimension to be scalar; otherwise it will be interpreted as array-of-buses
        bIsBuggyDimForVirtual = oSig.aiDim_(1) > 0;
        if bIsBuggyDimForVirtual
            oSig.aiDim_ = [1 1];
        end
    end    
    oSig.sBusType_ = sBusType;
    sBusObj = i_tryToGetBusObjectName(hPort, hBlock);
    if isempty(sBusObj)
        sBusObj = i_tryToGetBusObjectNameFromType(sCompiledType, hResolverFunc);    
    end
    oSig.sBusObj_ = sBusObj;
end

if bIsBus
    oSig.aoSubSignals_ = i_getSubSignals(oSig, hPort, hBlock);
end

if get_param(hPort, 'CompiledPortDimensionsMode')    
    oSig = oSig.setVariableSize(true);
end

xDesignMin = get_param(hPort, 'CompiledPortDesignMin');
xDesignMax = get_param(hPort, 'CompiledPortDesignMax');

oSig = oSig.setDesignMinMax(xDesignMin, xDesignMax);
end


%%
function bIsBusModeActive = i_isBusModeActive(hPort)
% note: for ports that are inactive the mode can be -1 
%       ==> do not use the value directly as boolean but check for a positive number indicating an active bus mode
bIsBusModeActive = (get_param(hPort, 'CompiledPortBusMode') > 0);
end


%%
function aoSigs = i_getSubSignals(oSig, hPort, hBlock, bDoTracing)
if (nargin < 4)
    bDoTracing = true;
end

% 1) if we have a BusObject, use it
sBusObj = oSig.sBusObj_;
if ~isempty(sBusObj)
    hResolverFunc = i_getResolver(hPort, hBlock);
    oBusSig = ep_sl_signal_from_bus_object_get(sBusObj, hResolverFunc);
    aoSigs = oBusSig.aoSubSignals_;
    if ~isempty(aoSigs)
        return;
    end
end

% 2) get info from BusStruct or Signal Hierarchy
aoSigs = i_tryResolvingPortSignalHierarchy(hPort, hBlock, oSig.getType());
if i_isSignalArrayValid(aoSigs)
    return;
end

% 3) try via tracing (more of a workaround)
if bDoTracing
    aoSigs = i_getSubSignalsByTracing(oSig, hPort);
    if i_isSignalArrayValid(aoSigs)
        return;
    end
end

% 4) try via prototype (results in the least possible information but still enough for MIL in EP)
aoSigs = i_getSignalsFromPrototype(hPort);
if i_isSignalArrayValid(aoSigs)
    return;
end

error('INTERNAL:ERROR', 'Signal detections for port "%s" failed.', getfullname(hPort));
end


%%
function aoSigs = i_getSignalsFromPrototype(hPort)
aoSigs = [];
try
    stBusStruct = Simulink.Bus.createMATLABStruct(hPort);
    if ~isempty(stBusStruct)
        oSig = ep_sl_signal_from_value_prototype_get(stBusStruct);
        if oSig.isValid()
            aoSigs = oSig.aoSubSignals_;
        end
    end
catch
end
end


%%
function aoSigs = i_getSubSignalsByTracing(oSig, hPort)
aoSigs = [];

hPort = ep_sl_port_src_dst_trace(hPort);
if ~isempty(hPort)
    hBlock = i_getParentBlock(hPort);
    oSig.sBusObj_ = i_tryToGetBusObjectName(hPort, hBlock);
    
    bDoTracing = false; % note: avoid tracing back and forth the signal line endlessly
    aoSigs = i_getSubSignals(oSig, hPort, hBlock, bDoTracing);
end
end


%%
function hCounterPort = i_getCounterPort(hPort)
hCounterPort = ep_sl_port_src_dst_trace(hPort);
end


%%
function stBusStruct = i_getBusStruct(hPort)
try
    stBusStruct = get_param(hPort, 'BusStruct');
catch
    stBusStruct = [];
end
if isempty(stBusStruct)
    hCounterPort = i_getCounterPort(hPort);
    if ~isempty(hCounterPort)
        try
            stBusStruct = get_param(hCounterPort, 'BusStruct');
        catch
            stBusStruct = [];
        end
    end
end
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
function sBusObjectName = i_getBusObjectNameFromBlock(hBlock)
sBusObjectName = '';
if strcmpi(get_param(hBlock, 'UseBusObject'), 'on')
    sBusObjectName = get_param(hBlock, 'BusObject');
end
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
catch oEx %#ok<NASGU>
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
function aoSigs = i_tryResolvingPortSignalHierarchy(hPortHandle, hBlock, sType)
aoSigs = [];
hProtoSigRepairFunc = [];

aiMainDim = get_param(hPortHandle, 'CompiledPortDimensions');
stBusStruct = i_getBusStruct(hPortHandle);
if ~isempty(stBusStruct)
    aoSigs = ep_sl_signal_from_bus_struct_get(stBusStruct.signals, i_getResolver(hPortHandle, hBlock));
    if i_isSignalArrayValid(aoSigs)
        return;
    end
    aiMainDim = i_tryImprovingDimensionInfo(aiMainDim, stBusStruct.src);
    
    if ~isempty(aoSigs)
        if isempty(hProtoSigRepairFunc)
            hProtoSigRepairFunc = i_getRepairWithPrototypeFunc(hPortHandle, aiMainDim);
        end
        aoSigs = feval(hProtoSigRepairFunc, aoSigs);
        if i_isSignalArrayValid(aoSigs)
            return;
        end
    end
end


% now try with the signal hierarchy
aoSigs = i_getSignalsFromSignalHiearachy(hPortHandle, hBlock);
if isempty(aoSigs)
    % worst case: no signal information at all --> just give up here
    return;
end
if i_isSignalArrayValid(aoSigs)
    % best case: full signal information --> we are finished
    return;
end

% note: if we are here, we have signals with incomplete info; 
%       signals gained from hierarchy ususally do not have any type or dimension info ...

% i) ... ---> try repairing with type and dimension info
aoSigs = i_repairWithTypeAndDimensionInfo(aoSigs, sType, aiMainDim);
if i_isSignalArrayValid(aoSigs)
    return;
end

% ii) ... ---> try repairing with prototype info
if isempty(hProtoSigRepairFunc)
    hProtoSigRepairFunc = i_getRepairWithPrototypeFunc(hPortHandle, aiMainDim);
end
aoSigs = feval(hProtoSigRepairFunc, aoSigs);
end


%%
function aoSigs = i_getSignalsFromSignalHiearachy(hPortHandle, hBlock)
aoSigs = [];

stSignalHierarchy = get_param(hPortHandle, 'SignalHierarchy');
if isempty(stSignalHierarchy)
    return;
end

% take a shortcut if we have a BusObject at the root level
if ~isempty(stSignalHierarchy.BusObject)
    oSig = ep_sl_signal_from_bus_object_get(stSignalHierarchy.BusObject, i_getResolver(hPortHandle, hBlock));
    aoSigs = oSig.aoSubSignals_;
else
    aoSigs = i_resolveSignalHierarchy(stSignalHierarchy, i_getResolver(hPortHandle, hBlock));
end
end


%%
function bIsValid = i_isSignalArrayValid(aoSigs)
bIsValid = (~isempty(aoSigs) && all(arrayfun(@(o) o.isValid, aoSigs)));
end


%%
function aoSigs = i_repairWithPrototypeInfo(aoSigs, aoSigsFromProto)
nSigs = numel(aoSigsFromProto);
if ((nSigs < 1) || (nSigs ~= numel(aoSigs)))
    return;
end

abIsValid = arrayfun(@(o) o.isValid, aoSigs);
if all(abIsValid)
    % nothing to be repaired, since everyhing is valid
    return;
end

% note: repair only if at least one of the signals is valid; otherwise we do not get much benefit from repairing
if any(abIsValid)
    nSigs = numel(aoSigsFromProto);
    if (nSigs == numel(aoSigs))
        for i = 1:nSigs
            if (~aoSigs(i).isValid && aoSigsFromProto(i).isValid)
                aoSigs(i) = aoSigsFromProto(i);
            end
        end
    end
end
end


%%
function aoSigs = i_repairWithTypeAndDimensionInfo(aoSigs, sType, aiMainDim)
bIsInfoComplete = ~strcmp(sType, 'auto') && (aiMainDim(1) < 0);
if bIsInfoComplete
    nMainLeafs = aiMainDim(2);
    nFoundLeafs = sum(arrayfun(@numLeafSignals, aoSigs));
    if (nMainLeafs == nFoundLeafs)
        caiLeafDims = i_splitLeafDimensions(aiMainDim);
        castLeafTypes = repmat({ep_sl_type_info_get(sType)}, 1, nFoundLeafs);
        
        iAttribIdx = 1;
        for i = 1:numel(aoSigs)
            nLeafs = aoSigs(i).numLeafSignals();
            aoSigs(i) = i_applyMissingLeafSigAttributes( ...
                aoSigs(i), ...
                caiLeafDims(iAttribIdx:iAttribIdx + nLeafs - 1), ...
                castLeafTypes(iAttribIdx:iAttribIdx + nLeafs - 1));
            
            iAttribIdx = iAttribIdx + nLeafs;
        end
    end
end
end


%%
function hProtoSigRepairFunc = i_getRepairWithPrototypeFunc(hPortHandle, aiMainDim)
aoSigsFromProto = i_getSignalsFromPrototype(hPortHandle);

% note: dimensions evaluated from prototypes are missing a distinction between: array, col-array, row-array
% --> try to improve this by using the main signal dimensions
aoSigsFromProto = i_overwriteDimensionInfo(aoSigsFromProto, aiMainDim);

hProtoSigRepairFunc = @(aoSigs) i_repairWithPrototypeInfo(aoSigs, aoSigsFromProto);
end


%%
function aiDim = i_tryImprovingDimensionInfo(aiDim, hSrcBlock)
if (aiDim(1) < 0)
    return; % everything is fine if we have a "normal" virtual bus demension starting with the negative number "-2"
end

% we can improve the dimension if the source block is a BusCreator:
if strcmp(get_param(hSrcBlock, 'BlockType'), 'BusCreator')
    stDims = get_param(hSrcBlock, 'CompiledPortDimensions');
    if (stDims.Outport(1) < 0)
        aiDim = stDims.Outport;
    else
        stPortHandles = get_param(hSrcBlock, 'PortHandles');
        nInports = numel(stPortHandles.Inport);
        aiDim = [-2, nInports, stDims.Inport];
    end
end
end


%%
function oSig = i_applyMissingLeafSigAttributes(oSig, caiLeafDims, castLeafTypes)
if oSig.isLeaf()
    if ~oSig.isValid()
        oSig.aiDim_ = caiLeafDims{1};
        oSig.stTypeInfo_ = castLeafTypes{1};
    end
else
    % note: do the assingment of dimension only if the info is not complete
    if ~oSig.isValid()
        iAttribIdx = 1;
        for i = 1:numel(oSig.aoSubSignals_)
            nLeafs = oSig.aoSubSignals_(i).numLeafSignals();
            oSig.aoSubSignals_(i) = i_applyMissingLeafSigAttributes( ...
                oSig.aoSubSignals_(i), ...
                caiLeafDims(iAttribIdx:iAttribIdx + nLeafs - 1), ...
                castLeafTypes(iAttribIdx:iAttribIdx + nLeafs - 1));

            iAttribIdx = iAttribIdx + nLeafs;
        end
    end
end
end


%%
function aoSigs = i_overwriteDimensionInfo(aoSigs, aiMainDim)
bIsInfoComplete = (aiMainDim(1) < 0);
if bIsInfoComplete
    nMainLeafs = aiMainDim(2);
    nFoundLeafs = sum(arrayfun(@numLeafSignals, aoSigs));
    if (nMainLeafs == nFoundLeafs)
        caiLeafDims = i_splitLeafDimensions(aiMainDim);
        
        iAttribIdx = 1;
        for i = 1:numel(aoSigs)
            nLeafs = aoSigs(i).numLeafSignals();
            aoSigs(i) = i_overwriteLeafSigDimensions( ...
                aoSigs(i), ...
                caiLeafDims(iAttribIdx:iAttribIdx + nLeafs - 1));
            
            iAttribIdx = iAttribIdx + nLeafs;
        end
    end
end
end


%%
function oSig = i_overwriteLeafSigDimensions(oSig, caiLeafDims)
if oSig.isLeaf()
    oSig.aiDim_ = caiLeafDims{1};
else
    iAttribIdx = 1;
    for i = 1:numel(oSig.aoSubSignals_)
        nLeafs = oSig.aoSubSignals_(i).numLeafSignals();
        oSig.aoSubSignals_(i) = i_overwriteLeafSigDimensions( ...
            oSig.aoSubSignals_(i), ...
            caiLeafDims(iAttribIdx:iAttribIdx + nLeafs - 1));
        
        iAttribIdx = iAttribIdx + nLeafs;
    end
end
end


%%
function caiDims = i_splitLeafDimensions(aiDim)
if (aiDim(1) ~= -2)
    error('EP:SL:INTERNAL_ERROR', 'Usage error: Function can only handle virtual bus dimensions.');
end
nDims = aiDim(2);
caiDims = cell(1, nDims);

iLeafIdx = 1;
nArrayLen = numel(aiDim);
k = 3;
while (k < nArrayLen)
    iLeafDims = aiDim(k);
    caiDims{iLeafIdx} = aiDim(k:k + iLeafDims);
    
    k = k + iLeafDims + 1;
    iLeafIdx = iLeafIdx + 1;
end
end


%%
function aoSigs = i_resolveSignalHierarchy(stSignalHierarchy, hResolverFunc)
if ~isempty(stSignalHierarchy.BusObject)
    oSig = ep_sl_signal_from_bus_object_get(stSignalHierarchy.BusObject, hResolverFunc);
    aoSigs = oSig.aoSubSignals_;
    
else
    caoSubSigs = arrayfun(@(st) i_getChildSignal(st, hResolverFunc), stSignalHierarchy.Children, 'uni', false);
    aoSigs = i_cell2mat(caoSubSigs);
end
end


%%
function oSig = i_getChildSignal(stSignalHierarchy, hResolverFunc)
if ~isempty(stSignalHierarchy.BusObject)
    oSig = ep_sl_signal_from_bus_object_get(stSignalHierarchy.BusObject, hResolverFunc);
else
    bIsBus = ~isempty(stSignalHierarchy.Children);
    if bIsBus
        oSig = ep_sl.Signal.getTypelessBus();
        oSig.sBusType_ = 'VIRTUAL_BUS';
        oSig.aoSubSignals_ = i_resolveSignalHierarchy(stSignalHierarchy, hResolverFunc);
    else
        oSig = ep_sl.Signal;
    end
end
oSig.sName_ = stSignalHierarchy.SignalName;
end


%%
function axElem = i_cell2mat(caxElem)
if isempty(caxElem)
    axElem = [];
else
    nElem = numel(caxElem);
    axElem = caxElem{1};
    axElem = repmat(axElem, 1, nElem); 
    for i = 2:nElem
        axElem(i) = caxElem{i};
    end
end
end


%%
function sBusObj = i_tryToGetBusObjectNameFromType(sUserType, hResolverFunc)
sBusObj = '';

if strcmp(sUserType, 'auto')
    return;
end

sUserType = regexprep(sUserType, '^Bus:\s*', '');
try
    oBusObj = feval(hResolverFunc, sUserType);
    if isa(oBusObj, 'Simulink.Bus')
        sBusObj = sUserType;
    end
catch
end
end


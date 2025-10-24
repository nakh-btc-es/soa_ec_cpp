function [oSig, oStateSig] = ep_datastore_signal_info_get(stOpts)
% Returns info about the signal type/structure of the provided DataStore.
%
% function [oSig, oStateSig] = ep_datastore_signal_info_get(stOpts)
%
%   INPUT               DESCRIPTION
%       stOpts             (struct)    the options:
%         .sName           (string)         for global DataStores name of the Simulink.Signal object
%         .sPath           (string)         for local DataStores the block path to the DataStoreMemory block
%         .sModelContext   (string)         the model context (only needed for global DataStores)
%
%   OUTPUT              DESCRIPTION
%       oSig               (object)    ep_sl.Signal containing info about the DataStore signal 
%       oStateSig          (object)    original Simulink.Signal representing the state of the DataStore
%
%   <et_copyright>


%% main
if (nargin < 1)
    stOpts = struct();
end
stOpts = i_checkSetOptions(stOpts);
[stInfo, oStateSig] = i_getSignalInfo(stOpts);

if i_isOptionSet(stOpts, 'sModelContext')
    hResolverFunc = atgcv_m01_generic_resolver_get(stOpts.sModelContext);
else
    hResolverFunc = atgcv_m01_generic_resolver_get(stOpts.sPath);
end
oSig = i_adaptToSig(stInfo, hResolverFunc);
end


%%
function [stInfo, oStateSig] = i_getSignalInfo(stOpts)
if i_isOptionSet(stOpts, 'sPath')
    [stInfo, oStateSig] = i_getSignalInfoFromBlock(stOpts.sPath);
else
    [stInfo, oStateSig] = i_getSignalInfoFromSignalObject(stOpts.sName, stOpts.sModelContext);
end
end


%%
function [stInfo, oStateSig] = i_getSignalInfoFromBlock(sBlockPath)

% following strategy for all information pieces: 
%  1) try to read out info from a resolving Simulink.Signal if possible
%  2) then add all missing info from info specified directly inside the block
%
sDataStoreName = get_param(sBlockPath, 'DataStoreName');
[stSigObj, oStateSig] = i_getResolvingSignalInfo(sBlockPath);
if i_isTypeValidOrBus(stSigObj.stTypeInfo)
    stTypeInfo = stSigObj.stTypeInfo;
else
    hResolverFunc = atgcv_m01_generic_resolver_get(sBlockPath);
    sDataType = get_param(sBlockPath, 'OutDataTypeStr');
    stTypeInfo = ep_sl_type_info_get(sDataType, hResolverFunc);
    oStateSig = i_getBlockStateSignal(sBlockPath);
end

hExprResolverFunc = atgcv_m01_expression_resolver_get(sBlockPath);
if ~isempty(stSigObj.xInitValue)
    xInitValue = stSigObj.xInitValue;
else
    sInitValue = get_param(sBlockPath, 'InitialValue');
    xInitValue = i_evalExpression(sInitValue, hExprResolverFunc);
end

if ~isempty(stSigObj.aiDimensions)
    aiDimensions = stSigObj.aiDimensions;
else
    aiDimensions = i_getDimensions(sBlockPath, hExprResolverFunc, size(xInitValue));
end

[dMin, dMax] = i_getMinMax(sBlockPath, hExprResolverFunc);
dMin = i_findFirstNonEmpty(dMin, stSigObj.dMin);
dMax = i_findFirstNonEmpty(dMax, stSigObj.dMax);

stInfo = i_createSignalInfo( ...
    sDataStoreName, ...
    stTypeInfo, ...
    xInitValue, ...
    aiDimensions, ...
    dMin, ...
    dMax);
end


%%
function xVal = i_findFirstNonEmpty(varargin)
for i = 1:nargin
    xVal = varargin{i};
    if ~isempty(xVal)
        return;
    end
end

% in case nothing is found, ensure a well-defined [] as return value instead of '' for example
xVal = [];
end


%%
function bIsValid = i_isTypeValidOrBus(stTypeInfo)
bIsValid = ~isempty(stTypeInfo) && (stTypeInfo.bIsValidType || stTypeInfo.bIsBus);
end


%%
function [stInfo, oStateSig] = i_getResolvingSignalInfo(sBlockPath)
if i_isStateResolvingToSignal(sBlockPath)
    sSigName  = get_param(sBlockPath, 'DataStoreName');
    [stInfo, oStateSig] = i_getSignalInfoFromSignalObject(sSigName, sBlockPath, i_interpretAsOneDimArray(sBlockPath));
else
    stInfo    = i_getUnsupportedSignalInfo();
    oStateSig = [];
end
end


%%
function oStateSig = i_getBlockStateSignal(sBlockPath)
try
    oStateSig = get_param(sBlockPath, 'StateSignalObject');
catch
    oStateSig = [];
end
end


%%
function bIsResolving = i_isStateResolvingToSignal(sBlockPath)
bIsResolving = strcmpi(get_param(sBlockPath, 'StateMustResolveToSignalObject'), 'on');
end


%%
function bOneDimArray = i_interpretAsOneDimArray(sBlockPath)
bOneDimArray = strcmpi(get_param(sBlockPath, 'VectorParams1D'), 'on');
end


%%
function [dMin, dMax] = i_getMinMax(sBlockPath, hResolverFunc)
dMin = i_evalExpression(get_param(sBlockPath, 'OutMin'), hResolverFunc);
dMax = i_evalExpression(get_param(sBlockPath, 'OutMax'), hResolverFunc);
end


%%
function aiDimensions = i_getDimensions(sBlockPath, hResolverFunc, aiInitValueSize)
try
    aiDimensions = i_evalExpression(get_param(sBlockPath, 'Dimensions'), hResolverFunc);
catch %#ok<CTCH>
    aiDimensions = [];
end
if (isempty(aiDimensions) || any(aiDimensions < 0))
    aiDimensions = aiInitValueSize;
end
if (i_interpretAsOneDimArray(sBlockPath) && i_isArrayDimensions(aiDimensions))
    aiDimensions = prod(aiDimensions);
end
end


%%
function [xResult, bIsValid] = i_evalExpression(sExpression, hResolverFunc)
if isempty(sExpression)
    xResult  = [];
    bIsValid = true;
else
    try
        xResult = feval(hResolverFunc, sExpression);    
        bIsValid = true;
    catch %#ok<CTCH>
        xResult  = [];
        bIsValid = false;
    end
end
end


%%
function [stInfo, oStateSig] = i_getSignalInfoFromSignalObject(sSignalName, xModelContext, bInterpretAsOneDimArrayBlockSpec)
% note: 1D-Interpretation can be free or specified by using block
if (nargin < 3)
    bInterpretAsOneDimArray = []; % free interpretation
else
    bInterpretAsOneDimArray = bInterpretAsOneDimArrayBlockSpec; % specified by using block
end

hResolverFunc = atgcv_m01_generic_resolver_get(xModelContext);
oStateSig = feval(hResolverFunc, sSignalName);
if (isempty(oStateSig) || ~isa(oStateSig, 'Simulink.Signal'))
    stInfo    = i_getUnsupportedSignalInfo();
    oStateSig = [];
else
    stTypeInfo = ep_sl_type_info_get(oStateSig.DataType, hResolverFunc);
    
    hExprResolverFunc = atgcv_m01_expression_resolver_get(xModelContext);
    [xInitValue, aiDimensions, bDimInherited] = i_getInitValAndDimension(oStateSig, hExprResolverFunc);
    if isempty(bInterpretAsOneDimArray)
        % note: if the 1D-Interpretation is not specified by block, the 1D-interpretation is specified as follows:
        % 1) Signal.Object is having an epxlicit dimension --> 1D-interpretation is *not* active
        % 2) Signal.Object with inertited dimension "-1" --> 1D-interpretation is active
        bInterpretAsOneDimArray = bDimInherited;
    end
    
    if (bInterpretAsOneDimArray && i_isArrayDimensions(aiDimensions))
        aiDimensions = prod(aiDimensions);
    end
    
    stInfo = i_createSignalInfo( ...
        sSignalName, ...
        stTypeInfo, ...
        xInitValue, ...
        aiDimensions, ...
        i_getFiniteOrEmpty(oStateSig.Min), ...
        i_getFiniteOrEmpty(oStateSig.Max));
end
end


%%
% Note: mainly for filtering out infinite values: -Inf and Inf
function dVal = i_getFiniteOrEmpty(dVal)
if (~isempty(dVal) && ~isfinite(dVal))
    dVal = [];
end 
end


%%
function bIsArrayDim = i_isArrayDimensions(aiDimensions)
bIsArrayDim = (numel(aiDimensions) == 2) && any(aiDimensions == 1);
end


%%
function [xInitVal, aiDimensions, bDimInherited] = i_getInitValAndDimension(oSignal, hExprResolverFunc)
bDimInherited = false;
if isempty(oSignal.InitialValue)
    xInitVal = [];
    bIsValValid = false;
else
    sInitVal = oSignal.InitialValue;
    [xInitVal, bIsValValid] = i_evalExpression(sInitVal, hExprResolverFunc);
end
aiDimensions = oSignal.Dimensions;
if any(aiDimensions < 0)
    bDimInherited = true;
    if bIsValValid
        aiDimensions = size(xInitVal);
    else
        aiDimensions = [];
    end
end
end


%%
function stInfo = i_getUnsupportedSignalInfo(stTypeInfo)
if (nargin < 1)
    stTypeInfo = [];
end
stInfo = i_createSignalInfo( ...
    '', ...
    stTypeInfo, ...
    [], ...
    [], ...
    [], ...
    []);
stInfo.bIsSupported = false; % Note: set explicitly to "not supported"
end


%%
function stInfo = i_createSignalInfo(sName, stTypeInfo, xInitValue, aiDimensions, dMin, dMax)
stInfo = struct( ...
    'sName',        sName, ...
    'bIsSupported', i_isTypeValidOrBus(stTypeInfo), ...
    'stTypeInfo',   stTypeInfo, ...
    'xInitValue',   xInitValue, ...
    'aiDimensions', aiDimensions, ...
    'dMin',         dMin, ...
    'dMax',         dMax);
end


%%
function stOpts = i_checkSetOptions(stOpts)
bIsGlobal = i_isOptionSet(stOpts, 'sName') && ~i_isOptionSet(stOpts, 'sPath');
if bIsGlobal
    if ~i_isOptionSet(stOpts, 'sModelContext')
        stOpts.sModelContext = bdroot(gcb);
    end
else
    if ~i_isOptionSet(stOpts, 'sPath')
        stOpts.sPath = gcb;
    end
    if ~i_isDataStoreMemoryBlock(stOpts.sPath)
        error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Provided block "%s" is not a DataStoreMemory block.', stOpts.sPath);
    end
end
end


%%
function bIsSet = i_isOptionSet(stOpts, sOptionName)
bIsSet = isfield(stOpts, sOptionName) && ~isempty(stOpts.(sOptionName));
end


%%
function bIsDSM = i_isDataStoreMemoryBlock(sPath)
try
    bIsDSM = strcmpi(get_param(sPath, 'BlockType'), 'DataStoreMemory');
catch oEx
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Provided block "%s" is invalid.\n%s', sPath, oEx.message);
end
end


%%
function oSig = i_adaptToSig(stDsmSignalInfo, hResolverFunc)
if ~stDsmSignalInfo.bIsSupported
    oSig = i_createInvalidSig();
    return;
end

if stDsmSignalInfo.stTypeInfo.bIsBus
    sBusObj = stDsmSignalInfo.stTypeInfo.sType;
    oSig = ep_sl_signal_from_bus_object_get(sBusObj, hResolverFunc);
else
    oSig = ep_sl.Signal;
    oSig.stTypeInfo_ = stDsmSignalInfo.stTypeInfo;
    oSig.sBusType_   = 'NOT_BUS';
end

% attributes from the DataStore
oSig.sName_      = stDsmSignalInfo.sName;
oSig.aiDim_      = i_translateDimensions(stDsmSignalInfo.aiDimensions);
oSig.xDesignMin_ = stDsmSignalInfo.dMin;
oSig.xDesignMax_ = stDsmSignalInfo.dMax;

oSig = oSig.setInitValue(stDsmSignalInfo.xInitValue);
end


%%
% translate Simulink.Signal "dimensions" to CompiledPortDimensions:
% trafo for 2-dim: [x, y] --> [2 x y] and trafo for 1-dim: [x] --> [1 x]
function aiCompiledDim = i_translateDimensions(aiDimensions)
nDim = numel(aiDimensions);
aiCompiledDim = [nDim, reshape(aiDimensions(:), 1, [])];

% special case: treat 1x1 matrix always as scalar
if isequal(aiCompiledDim, [2 1 1])
    aiCompiledDim = [1 1];
end
end


%%
function oSig = i_createInvalidSig()
oSig = ep_sl.Signal;
end

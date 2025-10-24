classdef Signal
    % Class representing a signal inside a Simulink model.
    properties
        sName_         = '';
        aiDim_         = [];
        iIndexOffset_  = 0;
        xInitValue_    = [];
        sMin_          = '';
        sMax_          = '';
        xDesignMin_    = [];
        xDesignMax_    = [];
        stTypeInfo_    = [];
        bHasVarSize_   = false;
        bIsMessage_    = false;
        sBusType_      = 'NOT_BUS';
        sBusObj_       = '';
        aoSubSignals_  = [];
    end
    
    methods (Static = true)
        function oObj = getTypelessBus()
            oObj = ep_sl.Signal();
            oObj.aiDim_ = [1 1];
            oObj.stTypeInfo_ = i_getTypeInfoBus('');
            oObj.sBusType_ = 'VIRTUAL_BUS';
        end
        
        function oObj = getTypedBus(sBusObjName)
            oObj = ep_sl.Signal();
            oObj.aiDim_ = [1 1];
            oObj.stTypeInfo_ = i_getTypeInfoBus(sBusObjName);
            oObj.sBusType_ = 'VIRTUAL_BUS';
        end
    end
    
    methods
        %%
        % function returning if a signal is of variable size
        function bResult = hasVariableSize(oSig)
            bResult = oSig.bHasVarSize_;
        end
        
        %%
        % function to set var-size status
        function oSig = setVariableSize(oSig, bFlag)
            oSig.bHasVarSize_ = bFlag;
        end
        
        %%
        % function returning if a signal is a message signal
        function bResult = isMessage(oSig)
            bResult = oSig.bIsMessage_;
        end
        
        %%
        function oSig = setInitValue(oSig, xInitValue)
            oSig = i_setInitValue(oSig, xInitValue);
        end
        
        %%
        % function to set message status
        function oSig = setMessage(oSig, bFlag)
            oSig.bIsMessage_ = bFlag;
        end
        
        %%
        % recursive function returning the number of leafs for bus signals (note: #leafs == 1 for nun-bus signals)
        function nLeafs = numLeafSignals(oObj)
            if oObj.isLeaf()
                nLeafs = 1;
            else
                nLeafs = sum(arrayfun(@numLeafSignals, oObj.aoSubSignals_));
            end
        end
        
        %%
        % returns flag if signal is valid or non-valid (i.e. a dummy signal)
        function bIsValid = isValid(oObj)
            bIsValid = ~isempty(oObj.stTypeInfo_);
            if ~bIsValid || oObj.isLeaf()
                return;
            end
            bIsValid = all(arrayfun(@(o) isValid(o), oObj.aoSubSignals_));
        end
        
        %%
        % returns flag if signal has a valid type
        function bHasValidType = hasValidType(oObj)
            if isempty(oObj.stTypeInfo_)
                bHasValidType = false;
            else
                if isLeaf(oObj)
                    bHasValidType = oObj.stTypeInfo_.bIsValidType;
                else
                    bHasValidType = all(arrayfun(@hasValidType, getSubSignals(oObj)));
                end
            end
        end
        
        %%
        % returns the effective type of the signal
        function sType = getType(oObj)
            if oObj.stTypeInfo_.bIsValidType
                sType = oObj.stTypeInfo_.sEvalType;
            else
                sType = oObj.stTypeInfo_.sType;
            end
        end
        
        %%
        function stInfo = getFixedPointInfo(oObj)
            stInfo = i_getFixedPointInfo(oObj.stTypeInfo_);
        end
        
        %%
        function stInfo = getEnumInfo(oObj)
            stInfo = i_getEnumInfo(oObj.stTypeInfo_);
        end
        
        %%
        % returns the width of the main signal (note: for buses the width of the *root* signal)
        function nWidth = getWidth(oObj)
            aiDim = getDim(oObj);
            nWidth = prod(aiDim(2:end));
        end
        
        %%
        % returns the flat width of the signal, i.e. the number of flat scalar signals contained within
        function nWidth = getFlatWidth(oObj)
            nWidth = getWidth(oObj); % main sig width
            if isBus(oObj)
                aiSubWidths = arrayfun(@getFlatWidth, oObj.aoSubSignals_);
                nWidth = nWidth*sum(aiSubWidths);
            end
        end
        
        %%
        function aiDim = getDim(oObj)
            aiDim = oObj.aiDim_;
            if ~isempty(aiDim)
                if ((aiDim(1) < 0 || all(aiDim(2:end) == 1) || strcmp(oObj.sBusType_, 'VIRTUAL_BUS')))
                    aiDim = [1 1];
                end
            end
        end
        
        %%
        function [sMin, sMax] = getEffectiveMinMax(oObj)
            [sMin, sMax] = i_getEffectiveMinMax(oObj);
        end
        
        %%
        function sName = getName(oObj)
            sName = oObj.sName_;
        end
        
        %%
        function sBusObjName = getBusObjectName(oObj)
            sBusObjName = oObj.sBusObj_;
        end
        
        %%
        function sBusType = getBusType(oObj)
            sBusType = oObj.sBusType_;
        end
        
        %%
        function aoSubSignals = getSubSignals(oObj)
            aoSubSignals = oObj.aoSubSignals_;
        end
        
        %%
        function aoLeafSignals = getLeafSignals(oObj, bWithFieldNames)
            if (nargin < 2)
                bWithFieldNames = false;
            end
            if bWithFieldNames
                aoLeafSignals = i_getAdaptedLeafSignals(oObj);
            else
                aoLeafSignals = i_getLeafSignals(oObj);
            end
        end
        
        %%
        function bIsBus = isBus(oObj)
            bIsBus = ~strcmp(oObj.sBusType_, 'NOT_BUS');
        end
        
        %%
        function bIsBus = isVirtualBus(oObj)
            bIsBus = strcmp(oObj.sBusType_, 'VIRTUAL_BUS');
        end
        
        %%
        function bContainsAoB = containsArrayOfBuses(oObj)
            bContainsAoB = false;
            if isBus(oObj)
                if (getWidth(oObj) > 1)
                    bContainsAoB = true;
                else
                    bContainsAoB = any(arrayfun(@containsArrayOfBuses, getSubSignals(oObj)));
                end
            end
        end
        
        %%
        function bIsScalar = isScalar(oObj)
            bIsScalar = isequal(getDim(oObj), [1 1]);
        end
        
        %%
        function bIsLeaf = isLeaf(oObj)
            bIsLeaf = isempty(oObj.aoSubSignals_);
        end
        
        %%
        function bIsUniform = isUniform(oObj)
            bIsUniform = isBus(oObj) || isempty(oObj.xInitValue_);
        end
        
        %%
        % recursive function that sets the index offset for the signal
        % note: for composite signals only the leaf sub-signals are changed
        function oObj = setLeafIndexOffset(oObj, iIdxOffset)
            if isLeaf(oObj)
                oObj.iIndexOffset_ = iIdxOffset;
            else
                for i = 1:numel(oObj.aoSubSignals_)
                    oObj.aoSubSignals_(i) = setLeafIndexOffset(oObj.aoSubSignals_(i), iIdxOffset);
                end
            end
        end
        
        %%
        % recursive function that sets the min/max values for the signal
        % note: for composite signals only the leaf sub-signals are changed
        function oObj = setLeafMinMax(oObj, sMin, sMax)
            if isLeaf(oObj)
                oObj.sMin_ = sMin;
                oObj.sMax_ = sMax;
            else
                for i = 1:numel(oObj.aoSubSignals_)
                    oObj.aoSubSignals_(i) = setLeafMinMax(oObj.aoSubSignals_(i), sMin, sMax);
                end
            end
        end
        
        %%
        % recursive function that sets the design min/max for the signal
        function oObj = setDesignMinMax(oObj, xDesignMin, xDesignMax)
            oObj = i_setDesignMinMax(oObj, xDesignMin, xDesignMax);
        end
        
        %%
        function astSigs = getLegacySignalInfos(oObj)
            if isValid(oObj)
                astSigs = i_getLegacySignalInfos(oObj);
            else
                astSigs = [];
            end
        end
        
        %%
        function stRes = getSignalAsStruct(oSig)
            stRes = struct(...
                'sName', oSig.sName_, ...
                'aiDim', oSig.aiDim_, ...
                'iIndexOffset', oSig.iIndexOffset_, ...
                'xInitValue', oSig.xInitValue_, ...
                'sMin', oSig.sMin_, ...
                'sMax', oSig.sMax_, ...
                'xDesignMin', oSig.xDesignMin_, ...
                'xDesignMax', oSig.xDesignMax_, ...
                'stTypeInfo', oSig.stTypeInfo_, ...
                'bHasVarSize', oSig.bHasVarSize_, ...
                'bIsMessage', oSig.bIsMessage_, ...
                'sBusType', oSig.sBusType_, ...
                'sBusObj', oSig.sBusObj_, ...
                'aoSubSignals', oSig.aoSubSignals_);
        end
    end
end


%%
function oSig = i_setInitValue(oSig, xInitValue)
if (isscalar(xInitValue) && ~oSig.isScalar())
    aiDim = oSig.getDim();
    nRows = aiDim(2);
    if (aiDim(1) == 1)
        nCols = 1;
    else
        nCols = aiDim(3);
    end
    xInitValue = repmat(xInitValue, nRows, nCols);
end
oSig.xInitValue_ = xInitValue;
if (oSig.isBus() && isstruct(xInitValue))
    for i = 1:numel(oSig.aoSubSignals_)
        sSubSigName = oSig.aoSubSignals_(i).getName();
        if isfield(xInitValue, sSubSigName)
            oSig.aoSubSignals_(i) = oSig.aoSubSignals_(i).setInitValue(xInitValue.(sSubSigName));
        end
    end
end
end


%%
function stTypeInfo = i_getTypeInfoBus(sTypeName)
stTypeInfo = ep_core_feval('ep_sl_type_info_get', '');
stTypeInfo.bIsBus = true;
if ((nargin > 0) && ~isempty(sTypeName))
    stTypeInfo.sType = sTypeName;
end
end


%%
function [sMin, sMax] = i_getEffectiveMinMax(oSig)
if oSig.hasValidType()
    [oTypeMin, oTypeMax] = i_getFxpTypeMinMax(oSig.stTypeInfo_);
    [oMin, oMax] = i_getSigMinMax(oSig, oTypeMin, oTypeMax);
    
    sMin = oMin.toString();
    sMax = oMax.toString();
else
    sMin = '';
    sMax = '';
end
end


%%
function [oTypeMin, oTypeMax] = i_getFxpTypeMinMax(stTypeInfo)
bIsFxpPoint = stTypeInfo.bIsFxp;
if bIsFxpPoint
    oTypeMin = stTypeInfo.oRepresentMin;
    oTypeMax = stTypeInfo.oRepresentMax;
else
    oTypeMin = ep_sl.Value([]);
    oTypeMax = ep_sl.Value([]);
end
end


%%
function stFxpInfo = i_getFixedPointInfo(stTypeInfo)
stFxpInfo = struct( ...
    'bIsFxp',  false, ...
    'dLSB',    [], ...
    'dOffset', []);

if (stTypeInfo.bIsValidType && stTypeInfo.bIsFxp)
    stFxpInfo.bIsFxp  = true;
    stFxpInfo.dLSB    = stTypeInfo.dLsb;
    stFxpInfo.dOffset = stTypeInfo.dOffset;
end
end


%%
function stEnumInfo = i_getEnumInfo(stTypeInfo)
stEnumInfo = struct( ...
    'bIsEnum',   false, ...
    'sBaseType', '');

if (stTypeInfo.bIsValidType && stTypeInfo.bIsEnum)
    stEnumInfo.bIsEnum = true;
    stEnumInfo.sBaseType = stTypeInfo.sBaseType;
end
end


%%
function [oHighestMin, oLowestMax] = i_getSigMinMax(oSig, oTypeMin, oTypeMax)
[oDesignMin, oDesignMax] = i_getDesignMinMax(oSig);
[oPortMin, oPortMax] = i_getExplicitMinMax(oSig);

% get the *highest* possible min value for Min, and the *lowest* possible max value for Max
oHighestMin = i_getValidMax(oDesignMin, oPortMin, oTypeMin);
oLowestMax  = i_getValidMin(oDesignMax, oPortMax, oTypeMax);
end


%%
function [oDesignMin, oDesignMax] = i_getDesignMinMax(oSig)
if i_hasFloatType(oSig)
    oDesignMin = ep_sl.Value(i_getDoubleValForDesignMinMaxValue(oSig.xDesignMin_));
    oDesignMax = ep_sl.Value(i_getDoubleValForDesignMinMaxValue(oSig.xDesignMax_));
else
    oDesignMin = ep_sl.Value(i_getIntegerValForDesignMinMaxValue(oSig.xDesignMin_));
    oDesignMax = ep_sl.Value(i_getIntegerValForDesignMinMaxValue(oSig.xDesignMax_));
end
end


%%
function bHasFloatType = i_hasFloatType(oSig)
bHasFloatType = oSig.stTypeInfo_.bIsFloat || oSig.stTypeInfo_.bIsFxp; % assuming the validity of type was ensured before
end


%%
function [oMin, oMax] = i_getExplicitMinMax(oSig)
if isempty(oSig.sMin_)
    oMin = ep_sl.Value([]);
else
    oMin = ep_sl.Value(oSig.sMin_);
end
if isempty(oSig.sMax_)
    oMax = ep_sl.Value([]);
else
    oMax = ep_sl.Value(oSig.sMax_);
end
end


%%
function oMaxVal = i_getValidMax(varargin)
caoVals = varargin;
abIsValid = cellfun(@(o) ~o.isnan(), caoVals);
caoVals = caoVals(abIsValid);

if isempty(caoVals)
    oMaxVal = ep_sl.Value([]);
else
    oMaxVal = caoVals{1};
    for i = 2:numel(caoVals)
        oNextVal = caoVals{i};
        if (oNextVal.compareTo(oMaxVal) > 0)
            oMaxVal = oNextVal;
        end
    end
end
end


%%
function oMinVal = i_getValidMin(varargin)
caoVals = varargin;
abIsValid = cellfun(@(o) ~o.isnan(), caoVals);
caoVals = caoVals(abIsValid);

if isempty(caoVals)
    oMinVal = ep_sl.Value([]);
else
    oMinVal = caoVals{1};
    for i = 2:numel(caoVals)
        oNextVal = caoVals{i};
        if (oNextVal.compareTo(oMinVal) < 0)
            oMinVal = oNextVal;
        end
    end
end
end


%%
% note: input can be a double value or a cell array of doubles
% --> in the first case just retun the input value
% --> in the second case remove the first non-empty element of the cell array or an empty double if none is found
function dVal = i_getDoubleValForDesignMinMaxValue(xVal)
if iscell(xVal)
    abIsEmptyElem = cellfun('isempty', xVal);
    if all(abIsEmptyElem)
        dVal = [];
    else
        xVal = xVal(~abIsEmptyElem);
        dVal = xVal{1};
    end
else
    dVal = xVal;
end
end


%%
% note: input can be a double value or a cell array of doubles
% --> in the first case just retun the input value
% --> in the second case remove the first non-empty element of the cell array or an empty double if none is found
function iVal = i_getIntegerValForDesignMinMaxValue(xVal)
dVal = i_getDoubleValForDesignMinMaxValue(xVal);
if isempty(dVal)
    iVal = [];
else
    iVal = int64(round(dVal));
end
end


%%
function astSigs = i_getLegacySignalInfos(oSig)
aoSigs = i_getAdaptedLeafSignals(oSig);
try
    astSigs = arrayfun(@i_transformToLegacyInfo, aoSigs);
catch oEx
    rethrow(oEx);
end
end


%%
function stSigInfo = i_transformToLegacyInfo(oSig)
stSigInfo = struct( ...
    'sName',      oSig.sName_, ...
    'sUserType',  oSig.stTypeInfo_.sType, ...
    'sType',      oSig.getType(), ...
    'sMin',       oSig.sMin_, ...
    'sMax',       oSig.sMax_, ...
    'xDesignMin', [], ... % see below
    'xDesignMax', [], ... % see below
    'iWidth',     oSig.getWidth(), ...
    'aiDim',      oSig.getDim());

% both design min/max can be cell --> cannot be used in "struct()" constructor directly without special handling
stSigInfo.xDesignMin = oSig.xDesignMin_;
stSigInfo.xDesignMax = oSig.xDesignMax_;
end


%%
function aoSigs = i_getLeafSignals(oSig)
if oSig.isLeaf()
    aoSigs = oSig;
else
    aoSigs = [];
    
    aoSubSigs = oSig.aoSubSignals_;
    for i = 1:numel(aoSubSigs)
        if isempty(aoSigs)
            aoSigs = i_getLeafSignals(aoSubSigs(i));
        else
            aoSigs = [aoSigs, i_getLeafSignals(aoSubSigs(i))]; %#ok<AGROW>
        end
    end
end
end


%%
function aoSigs = i_getAdaptedLeafSignals(oSig)
if oSig.isLeaf()
    aoSigs = oSig;
else
    aoSigs = [];
    
    aoSubSigs = oSig.aoSubSignals_;
    for i = 1:numel(aoSubSigs)
        aoSubSigs(i).sName_ = [oSig.sName_, '.', aoSubSigs(i).sName_];
        
        if isempty(aoSigs)
            aoSigs = i_getAdaptedLeafSignals(aoSubSigs(i));
        else
            aoSigs = [aoSigs, i_getAdaptedLeafSignals(aoSubSigs(i))]; %#ok<AGROW>
        end
    end
end
end


%%
function oSig = i_setDesignMinMax(oSig, xDesignMin, xDesignMax)
oSig.xDesignMin_ = xDesignMin;
oSig.xDesignMax_ = xDesignMax;
if ~isLeaf(oSig)
    for i = 1:numel(oSig.aoSubSignals_)
        sSubName = oSig.aoSubSignals_(i).sName_;
        xSubDesignMin = i_extractSubValue(xDesignMin, sSubName);
        xSubDesignMax = i_extractSubValue(xDesignMax, sSubName);
        
        oSig.aoSubSignals_(i) = i_setDesignMinMax(oSig.aoSubSignals_(i), xSubDesignMin, xSubDesignMax);
    end
end
end


%%
function xSubValue = i_extractSubValue(xValue, sFieldName)
if isstruct(xValue)
    if isfield(xValue, sFieldName)
        xSubValue = xValue.(sFieldName);
    else
        xSubValue = [];
    end
else
    xSubValue = xValue; % for all non-struct values, value and sub-value are the same
end
end

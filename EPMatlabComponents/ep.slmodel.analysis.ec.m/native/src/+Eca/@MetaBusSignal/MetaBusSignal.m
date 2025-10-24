classdef MetaBusSignal
    
    properties (SetAccess = immutable)
        casSignalParts_ = {};
        caaiSignalPartDims_ = {};
        oSigSL_ = [];
        bIsPartOfBusObject_ = false;
    end
    
    %%
    % static constructor
    methods (Static = true)
        function oObj = createMetaBusSignal(oSigSL, sSignalName)
            if (nargin < 2)
                oObj = Eca.MetaBusSignal(oSigSL);
            else
                oObj = Eca.MetaBusSignal(oSigSL, {sSignalName});
            end
        end
    end
    
    %%
    methods        
        %%
        function sSignalName = signalName(oObj)
            i_assertSingle(oObj);
            sSignalName = oObj.casSignalParts_{end};
        end
        
        %%
        function sSignalName = topBusSignalName(oObj)
            i_assertSingle(oObj);
            sSignalName = oObj.casSignalParts_{1};
        end
        
        %%
        function sSignalPath = modelSignalPath(oObj)
            i_assertSingle(oObj);
            sSignalPath = ['.', strjoin(oObj.casSignalParts_, '.')];
        end
        
        %%
        function sAccess = codeVariableAccess(oObj)
            i_assertSingle(oObj);
            if (numel(oObj.casSignalParts_) < 2)
                sAccess = '';
            else
                sAccess = ['.', strjoin(oObj.casSignalParts_(2:end), '.')];
            end
        end
        
        %%
        % TODO: Legacy name should be renamed to isPartOfBusObject
        function bIsPartOfBusObj = iBusObjElement(oObj)
            bIsPartOfBusObj = oObj.bIsPartOfBusObject_;
        end
        
        %%
        function sType = getDataType(oObj)
            i_assertSingle(oObj);
            sType = oObj.oSigSL_.getType();
        end
        
        %%
        function aiDim = getDimension(oObj)
            i_assertSingle(oObj);
            aiDim = oObj.oSigSL_.getDim();
            aiDim = aiDim(2:end); % note: remove the number-of-dims at beginning and return the plain size values
        end
        
        %%
        function [sMin, sMax] = getMinMax(oObj)
            [sMin, sMax] = oObj.oSigSL_.getEffectiveMinMax();
        end
        
        %%
        function bIsBus = isBus(oObj)
            i_assertSingle(oObj);
            bIsBus = oObj.oSigSL_.isBus;
        end
        
        %%
        function bIsBus = isBusSignal(oObj)
            i_assertSingle(oObj);
            bIsBus = isBus(oObj) || (numel(oObj.casSignalParts_) > 1);
        end
        
        %%
        function bIsBus = isRootSignal(oObj)
            i_assertSingle(oObj);
            bIsBus = numel(oObj.casSignalParts_) < 2;
        end
        
        %%
        function bIsAoB = isArrayOfBusSignal(oObj)
            i_assertSingle(oObj);
            bIsAoB = i_isArrayOfBusSignal(oObj);
        end
        
        %%
        function [casSigParts, caaiPartWidth] = getModelSigParts(oObj)
            i_assertSingle(oObj);
            casSigParts =  [{''}, cellfun(@i_getCleanSignalName, oObj.casSignalParts_, 'uni', false)];
            
            if (nargout > 1)
                caaiPartWidth = [{[]}, cellfun(@i_translateToWidth, oObj.caaiSignalPartDims_, 'uni', false)];
            end
        end
        
        %%
        function [casSigParts, caaiPartWidth] = getCodeSigParts(oObj, casCustomSigParts)
            i_assertSingle(oObj);
            
            if (nargin < 2)
                casCustomSigParts = {};
            end
            casSigParts = cellfun(@i_getCleanSignalName, oObj.casSignalParts_, 'uni', false);
            
            nMatchingDepth = find(strcmp(casSigParts{1}, casCustomSigParts), 1, 'first');            
            if isempty(nMatchingDepth)
                nMatchingDepth = 1;
            end
            nCustomPrefixTokens = nMatchingDepth - 1;
            if (nCustomPrefixTokens > 0)
                casSigParts = [casCustomSigParts(1:nCustomPrefixTokens), casSigParts];
            end
            casSigParts{1} = '';
            
            if (nargout > 1)
                caaiPartWidth = cellfun(@i_translateToWidth, oObj.caaiSignalPartDims_, 'uni', false);
                if (nCustomPrefixTokens > 0)
                    caaiPartWidth = [repmat({[]}, 1, nCustomPrefixTokens), caaiPartWidth];
                end
            end
        end
        
        %%
        function aoFlatSigs = getFlatSignals(oObj)
            aoFlatSigs = i_getFlatSignals(oObj);
        end

        %%
        function oObjCopy = copyWithDifferentRootName(oObj, sNewRootName)
            sNewSignalParts = oObj.casSignalParts_;
            sNewSignalParts{1} = sNewRootName;

            oObjCopy = Eca.MetaBusSignal(oObj.oSigSL_, sNewSignalParts, oObj.caaiSignalPartDims_, oObj.bIsPartOfBusObject_);
        end
    end
    
    %%
    methods (Access = private)
        % internal constructor
        function oObj = MetaBusSignal(oSigSL, casSignalParts, caaiSignalPartDims, bIsPartOfBusObj)
            if isempty(oSigSL)
                error('INTERNAL:ERROR', 'Cannot construct a meta bus signal without an SL signal object.');
            end
            if (nargin < 4)
                bIsPartOfBusObj = false; % if info is not enforced from the outside, assume "false" as default
            end
            
            oObj.oSigSL_ = oSigSL;
            oObj.bIsPartOfBusObject_ = bIsPartOfBusObj || ~isempty(oSigSL.getBusObjectName());
            
            if ((nargin < 2) || isempty(casSignalParts))
                casSignalParts = {oSigSL.getName()};
            end
            oObj.casSignalParts_ = casSignalParts;
            
            if ((nargin < 3) || isempty(caaiSignalPartDims))
                caaiSignalPartDims = {oSigSL.getDim()};
            end
            oObj.caaiSignalPartDims_ = caaiSignalPartDims;
        end
    end
end


%%
function aiWidth = i_translateToWidth(aiDim)
if (isempty(aiDim) || isequal(aiDim, [1 1]))
    aiWidth = [];
else
    aiWidth = aiDim(2:end);
end
end


%%
function sSignalName = i_getCleanSignalName(sSignalName)
if isempty(regexp(sSignalName, '<signal1>', 'once'))
    sSignalName = regexprep(sSignalName, '[<,>]', '');
end
end


%%
function bIsAoB = i_isArrayOfBusSignal(oObj)
bIsAoB = false;
if ~isempty(oObj.oSigSL_)
    if (numel(oObj.caaiSignalPartDims_) > 1)
        bHasScalarAccess = all(cellfun(@(x) isequal(x, [1 1]), oObj.caaiSignalPartDims_(1:end - 1)));
    else
        bHasScalarAccess = true;
    end
    bIsAoB = ~bHasScalarAccess || oObj.oSigSL_.containsArrayOfBuses();
end
end


%%
function i_assertSingle(oObj)
if (numel(oObj) > 1)
    error('ERROR:INVALID_ARRAY_USAGE', 'Method defined only for scalar objects.');
end
end


%%
function oMetaSubSig = i_slToMetaSubSig(oSubSigSL, casParentSignalParts, caadParentSignalPartDims, bParentPartOfBusObject)
casSignalParts = [casParentSignalParts, {oSubSigSL.getName()}];
caaiSignalPartDims = [caadParentSignalPartDims, {oSubSigSL.getDim()}];
oMetaSubSig = Eca.MetaBusSignal(oSubSigSL, casSignalParts, caaiSignalPartDims, bParentPartOfBusObject);
end


%%
% recursive function that returns all bus-leaf-signals as a flat array of signals
function aoFlatSigs = i_getFlatSignals(oObj)
i_assertSingle(oObj);
if ~isBus(oObj)
    aoFlatSigs = oObj;
else
    aoFlatSigs = [];
    
    aoSubSignalsSL = oObj.oSigSL_.getSubSignals();
    nSigs = numel(aoSubSignalsSL);
    for i = 1:nSigs
        oMetaSubSig = i_slToMetaSubSig( ...
            aoSubSignalsSL(i), oObj.casSignalParts_, oObj.caaiSignalPartDims_, oObj.bIsPartOfBusObject_);
        aoFlatSigs = [aoFlatSigs, i_getFlatSignals(oMetaSubSig)]; %#ok<AGROW>
    end
end
end

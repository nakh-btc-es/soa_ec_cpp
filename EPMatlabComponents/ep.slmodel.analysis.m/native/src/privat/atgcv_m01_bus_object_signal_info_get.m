function astSigs = atgcv_m01_bus_object_signal_info_get(stEnv, oBusObject, sRootName, hResolverFunc)
% Get info on dest/src signal of block.
%
% function astSigs = atgcv_m01_bus_object_signal_info_get(stEnv, oBusObject, sRootName, hResolverFunc)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)         environment struct
%     oBusObject        (string|object)  either the name of or the Simulink.Bus
%                                        object itself
%                                        (if name, it is assumed that the object
%                                        exists in the Base workspace)
%     sRootName         (string)         name of the root signal (empty if not provided)
%     hResolverFunc     (handle)         function for resolving symbols in model
%
%   OUTPUT              DESCRIPTION
%      astSigs           (array)         structs with following info: 
%        .sName          (string)        name of subsignal
%        .sUserType      (string)        type of subsignal (might be an alias)
%        .sType          (string)        base type of subsignal (builtin or fixed-point-type)
%        .iWidth         (integer)       width of subsignal
%        .sMin           (string)        Min constraint of signal if available
%        .sMax           (string)        Max constraint of signal if available
%        .aiDim          (array)         integers representing dimension
%
%   REMARKS
% 
%
%   <et_copyright>


%% input check
if (nargin < 3)
    sRootName = '';
end
if (nargin < 4)
    hResolverFunc = atgcv_m01_generic_resolver_get();
end

if ischar(oBusObject)
    oBusObject = i_getBusObject(oBusObject, hResolverFunc);
end

if isa(oBusObject, 'Simulink.Bus')
    astSigs = i_getElementSignals(stEnv, oBusObject.Elements, sRootName, hResolverFunc);
else
    astSigs = [];
end
end


%%
function oBusObj = i_getBusObject(sObjectName, hResolverFunc)
oBusObj = [];

[xMaybeBusObj, nScope] = feval(hResolverFunc, sObjectName);
if (nScope > 0)
    bIsBus = isa(xMaybeBusObj, 'Simulink.Bus');
    if bIsBus
        oBusObj = xMaybeBusObj;
    end
end
end


%%
function stSigInfo = i_getInitSigInfo()
stSigInfo = struct( ...
    'sName',      '', ...
    'sUserType',  '', ...
    'sType',      '', ...
    'sMin',       '', ...
    'sMax',       '', ...
    'xDesignMin', [], ...
    'xDesignMax', [], ...
    'iWidth',     [], ...
    'aiDim',      []);
end


%%
function astSigs = i_getElementSignals(stEnv, aoBusElements, sRootName, hResolverFunc)
astSigs = repmat(i_getInitSigInfo(), 0, 0);

nElem = length(aoBusElements);
for i = 1:nElem
    sDataType = i_evaluateType(aoBusElements(i).DataType);    
    stTypeInfo = ep_sl_type_info_get(sDataType, hResolverFunc);
    
    oSubBus = [];
    if ~stTypeInfo.bIsValidType
        oSubBus = i_getBusObject(sDataType, hResolverFunc);
    end
    if ~isempty(oSubBus)
        sSubRootName = [sRootName, '.', aoBusElements(i).Name];
        astSubSigs = i_getElementSignals(stEnv, oSubBus.Elements, sSubRootName, hResolverFunc);
        astSigs = [astSigs, astSubSigs]; %#ok<AGROW>
    else
        aiDim = i_transformElemDimToCompiledDim(aoBusElements(i).Dimensions);
        
        % Note: Bus Dimensions behave differently from CompiledPortDimensions
        %       --> try to transform them accordingly
        if (length(aiDim) > 1)
            if (length(aiDim) > 2)
                % usual CompiledPortDimensions array is structured as
                % [<number_of_dims>, <dim1>, <dim2>, ...]
                iWidth = prod(aiDim(2:end));
            else
                iWidth = prod(aiDim(1:end));                
            end
        else
            iWidth = aiDim;
        end
        astSigs(end + 1) = struct( ...
            'sName',      [sRootName, '.', aoBusElements(i).Name], ...
            'sUserType',  sDataType, ...
            'sType',      stTypeInfo.sEvalType, ...
            'sMin',       '', ...
            'sMax',       '', ...
            'xDesignMin', [], ...
            'xDesignMax', [], ...
            'iWidth',     iWidth, ...
            'aiDim',      aiDim); %#ok<AGROW>
    end
end
end


%%
% Note: Bus Dimensions behave differently from CompiledPortDimensions
%       --> try to transform them accordingly
function aiDim = i_transformElemDimToCompiledDim(aiElemDim)
aiDim = [length(aiElemDim), aiElemDim];
end

        
%%
function sEvalType = i_evaluateType(sType)
if ~isempty(regexp(sType, '^Bus:\s*', 'once'))
    sType = sType(6:end);
end
sEvalType = sType;
end


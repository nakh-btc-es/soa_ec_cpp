function oSig = ep_sl_param_signal_adapt(stParameter, mTypeInfoMap)
% Adaptor for parameter info struct.
%
% function oSig = ep_sl_param_signal_adapt(stParameter, mTypeInfoMap)
%
%   INPUT               DESCRIPTION
%     stParameter        (struct)      info data for parameters:
%      .aiWidth          (array)       dimensions in simple notation: 1-dim -> [x], d-dim -> [x, y]
%      .sType            (string)      parameter value type
%      .xValue           (arbitrary)   parameter value (size and type depend on the specific parameter)
%      .sMin             (string)      min value as string
%      .sMax             (string)      max value as string
%
%     oTypeInfoMap       (map)         optional: map from types to type infos
%
%   OUTPUT              DESCRIPTION
%     oSig               (object)      ep_sl.Signal object
%

%%
if (nargin < 2)
    mTypeInfoMap = containers.Map();
end

% currently only non-bus typed parameters supported
sBusType = 'NOT_BUS';
bIsComplete = true;

oSig = i_createRootSigObj( ...
    i_widthToCompiledDim(stParameter.aiWidth), ...
    sBusType, ...
    '', ...
    bIsComplete);
if ~bIsComplete
    return;
end

if strcmp(sBusType, 'NOT_BUS')
    [~, stTypeInfo] = ep_sl_export_type_eval(stParameter.sType, mTypeInfoMap);
    if ~stTypeInfo.bIsValidType
        return;
    end
    oSig.stTypeInfo_ = stTypeInfo;
    oSig.xInitValue_ = stParameter.xValue;
    oSig.sMin_       = stParameter.sMin;
    oSig.sMax_       = stParameter.sMax;
else
    error('BUS_SUPPORT:MISSING', 'Bus-typed parameters not supported yet!');
end
end


%%
% translate Simulink.Parameter "dimensions" to CompiledPortDimensions:
function aiCompiledDim = i_widthToCompiledDim(aiWidth)
if all(aiWidth == 1)
    aiCompiledDim = [1 1];
else
    if any(aiWidth == 1)
        aiCompiledDim = [1, prod(aiWidth)];
    else
        aiCompiledDim = [2, reshape(aiWidth(:), 1, [])];
    end
end
end


%%
function oSig = i_createRootSigObj(aiDim, sBusType, sBusObj, bIsComplete)
oSig = ep_sl.Signal;
if ~bIsComplete
    return;
end
oSig.aiDim_    = aiDim;
oSig.sBusType_ = sBusType;
oSig.sBusObj_  = sBusObj;
end

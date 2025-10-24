function [stCheckInputs, stCheckOutputs] = atgcv_m01_compiled_interface_check(stCompInterface)
% Check if the compiled interface of a Subsystem is supported by EPP.
%
% function stCheck = atgcv_m01_compiled_interface_check(stCompInterface)
%
%   INPUT               DESCRIPTION
%     stCompInterface   (struct)    as returned by "atgcv_m01_compiled_info_get"
%
%   OUTPUT              DESCRIPTION
%     stCheck           (struct)    info about non-supported interfaces
%       .astInvalidPorts (struct)     all ports with an invalid signal type
%          ....
%       .astMatrixPorts  (string)     all ports with Matrix signal dimension
%          ....
%

%%
[stCheckInputs, stCheckOutputs] = i_evalCompInterface(stCompInterface);
end


%%
function [stEvalIn, stEvalOut] = i_evalCompInterface(stCompInterface)
hResolverFunc = atgcv_m01_generic_resolver_get(stCompInterface.sRootModel);

stEvalIn  = i_getPortsEvaluation(stCompInterface.astInports, hResolverFunc);
stEvalOut = i_getPortsEvaluation(stCompInterface.astOutports, hResolverFunc);
end



%%
function stEval = i_getPortsEvaluation(astPorts, hResolverFunc)
if isempty(astPorts)
    stEval = struct( ...
        'astInvalidPorts', astPorts, ...
        'astUnsupportedPorts', astPorts, ...
        'astHighDimPorts', astPorts,...
        'astArrayOfBuses', astPorts);
else
    astPortSignalEvals = i_evalPortSignals(astPorts, hResolverFunc);
    astPortEvals = i_evalPorts(astPorts);
    
    stEval = struct( ...
        'astInvalidPorts', astPorts([astPortSignalEvals(:).bHasInvalidSigs]), ...
        'astUnsupportedPorts', astPorts([astPortSignalEvals(:).bHasUnsupportedSigs]), ...
        'astHighDimPorts', astPorts([astPortSignalEvals(:).bHasHighDimSigs]),...
        'astArrayOfBuses', astPorts([astPortEvals(:).bHasArrayOfBuses]));
end
end


%%
function astPortSignalEvals = i_evalPortSignals(astPorts, hResolverFunc)
nPorts = length(astPorts);
astPortSignalEvals = repmat(struct( ...
    'bHasInvalidSigs', false, ...
    'bHasUnsupportedSigs', false, ...
    'bHasHighDimSigs', false), 1, nPorts);

for i = 1:nPorts
    if isempty(astPorts(i).astSignals)
        continue;
    end
    
    astSigEvals = arrayfun(@(stSignal) i_evalSignal(stSignal, hResolverFunc), astPorts(i).astSignals);
    astPortSignalEvals(i).bHasInvalidSigs = any(~[astSigEvals(:).bHasValidType]);
    astPortSignalEvals(i).bHasUnsupportedSigs = any(~[astSigEvals(:).bHasSupportedType]);
    astPortSignalEvals(i).bHasHighDimSigs = any([astSigEvals(:).bHasHighDim]);
end
end


%%
function astPortEvals = i_evalPorts(astPorts)
astPortEvals = arrayfun(@(stPort) i_evalPortDim(stPort), astPorts);
end


%%
function stEval = i_evalSignal(stSignal, hResolverFunc)
stTypeInfo = ep_sl_type_info_get(stSignal.sType, hResolverFunc);
bIsValidType = stTypeInfo.bIsValidType || stTypeInfo.bIsBus;

% note: a little bit of a strange logic here
% a data type is supported if
% (1) it has an invalid type OR
% (2) it has a valid type that is actually supported
% ==> this means that *all* invalid types are automatically supported
stEval = struct( ...
    'bHasValidType',     bIsValidType, ...
    'bHasSupportedType', ~bIsValidType || i_isValidTypeSupported(stTypeInfo.sBaseType), ...
    'bHasHighDim',       i_isHighDimSignal(stSignal));
end


%%
function bIsSupported = i_isValidTypeSupported(sBaseType)
bIsSupported = ~any(strcmp(sBaseType, {'int64', 'uint64'}));
end


%%
function stEval = i_evalPortDim(stPort)
stEval = struct( ...
    'bHasArrayOfBuses', i_hasArrayOfBusses(stPort));
end


%%
% Note:
%  1) the Dim of array-valued signals has the format:
%     aiDim = [<widthDim1>]
%  2) the Dim of matrix-valued signals has the format:
%     aiDim = [<#numDim> <widthDim1> <widthDim2> <widthDim3> ...]
function bIsHighDim = i_isHighDimSignal(stSignal)
nDim = 1;
if (length(stSignal.aiDim) > 2)
    nDim = stSignal.aiDim(1);
    
    % Note: matrix-valued signals of Dim=2 and width 1x1 never do any harm
    %         --> accept them as non-matrix signals
    if ((nDim == 2) && (prod(stSignal.aiDim(2:end)) == 1))
        nDim = 1;
    end
end
bIsHighDim = (nDim > 2);
end


%%
function bHasArrayOfBuses = i_hasArrayOfBusses(stPort)
bHasArrayOfBuses = false;
if any(strcmp(stPort.sBusType, {'VIRTUAL_BUS', 'NOT_BUS'}))
    return;
end

bHasArrayOfBuses = (prod(stPort.aiDim(2:end)) > 1);
end

function stCheck = ep_sl_compiled_interface_check(stCompInterface)
% Check if the compiled interface of a Subsystem is supported by EPP.
%
% function stCheck = ep_sl_compiled_interface_check(stCompInterface)
%
%   INPUT               DESCRIPTION
%     stCompInterface   (struct)    as returned by "ep_sl_compiled_info_get"
%
%   OUTPUT              DESCRIPTION
%     stCheck           (struct)    info about non-supported interfaces
%       .astInvalidPorts (struct)     all ports with an invalid signal type
%          ....
%       .astMatrixPorts  (string)     all ports with Matrix signal dimension
%          ....
%

%%
stCheck = i_evalCompInterface(stCompInterface);
end


%%
function stEval = i_evalCompInterface(stCompInterface)
astPorts = [stCompInterface.astInports, stCompInterface.astOutports];
if isempty(astPorts)
    stEval = struct( ...
        'astInvalidPorts',     astPorts, ...
        'astVarSize',          astPorts, ...
        'astUnsupportedPorts', astPorts, ...
        'astHighDimPorts',     astPorts, ...
        'astArrayOfBuses',     astPorts, ...
        'astInvalidMessages',  astPorts);
else
    astPortSignalEvals = arrayfun(@i_evalPortSignal, astPorts);
    astPortEvals = i_evalPorts(astPorts);
    
    stEval = struct( ...
        'astInvalidPorts',     astPorts([astPortSignalEvals(:).bHasInvalidSigs]), ...
        'astVarSize',          astPorts([astPortSignalEvals(:).bHasVariableSize]), ...
        'astUnsupportedPorts', astPorts([astPortSignalEvals(:).bHasUnsupportedSigs]), ...
        'astHighDimPorts',     astPorts([astPortSignalEvals(:).bHasHighDimSigs]),...
        'astArrayOfBuses',     astPorts([astPortEvals(:).bHasArrayOfBuses]), ...
        'astInvalidMessages',  astPorts([astPortSignalEvals(:).bHasInvalidMessages]));
end
end


%%
function stPortSignalEval = i_evalPortSignal(stPort)
if ~stPort.oSig.isValid()
    stPortSignalEval = struct( ...
        'bHasInvalidSigs',     false, ...
        'bHasVariableSize',    false, ...
        'bHasUnsupportedSigs', false, ...
        'bHasInvalidMessages', false, ...
        'bHasHighDimSigs',     false);
else
    stPortSignalEval = i_evalSignal(stPort.oSig);
end
end


%%
function astPortEvals = i_evalPorts(astPorts)
astPortEvals = arrayfun(@(stPort) i_evalPortDim(stPort), astPorts);
end


%%
function stEval = i_evalSignal(oSig)
bHasValidSigs    = oSig.hasValidType();
bHasVariableSize = oSig.hasVariableSize(); 
stEval = struct( ...
    'bHasInvalidSigs',     ~bHasValidSigs, ...
    'bHasVariableSize',    bHasVariableSize, ...
    'bHasUnsupportedSigs', bHasValidSigs && ~i_hasSupportedLeafBaseTypes(oSig), ...
    'bHasInvalidMessages', i_hasInvalidMessages(oSig), ...
    'bHasHighDimSigs',     i_hasHighDimSignals(oSig));
end


%%
function bIsSupported = i_hasSupportedLeafBaseTypes(oSig)
aoLeafSigs = oSig.getLeafSignals();
casLeafTypes = arrayfun(@(o) o.getType(), aoLeafSigs, 'uni', false);

oTypes = ep_sl.Types.getInstance();
bIsSupported = all(cellfun(@(sType) oTypes.isSupported(sType), casLeafTypes));
end


%%
function bHasHighDimSigs = i_hasHighDimSignals(oSig)
bHasHighDimSigs = i_isHighDim(oSig.getDim());
if (~bHasHighDimSigs && ~oSig.isLeaf())
    bHasHighDimSigs = any(arrayfun(@i_hasHighDimSignals, oSig.getSubSignals()));
end
end


%%
function bInvalidMessages = i_hasInvalidMessages(oSig)
    bInvalidMessages = oSig.isMessage && oSig.isVirtualBus;
end


%%
function bIsHighDim = i_isHighDim(aiDims)
bIsHighDim = ~isempty(aiDims) && (aiDims(1) > 2);
end


%%
function stEval = i_evalPortDim(stPort)
stEval = struct( ...
    'bHasArrayOfBuses', i_hasArrayOfBusses(stPort));
end


%%
function bHasArrayOfBuses = i_hasArrayOfBusses(stPort)
bHasArrayOfBuses = stPort.oSig.isBus && (stPort.oSig.getWidth > 1);
end

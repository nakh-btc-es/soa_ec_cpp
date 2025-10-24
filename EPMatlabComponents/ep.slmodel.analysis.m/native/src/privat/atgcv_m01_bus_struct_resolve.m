function astSigs = atgcv_m01_bus_struct_resolve(stEnv, astBusStruct, sRootName)
% Transform a bus struct (get_param(..., 'BusStruct') into an array of signal information.
%
% function [astSigs, abIsValid] = atgcv_m01_bus_struct_resolve(stEnv, astBusStruct, sRootName)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)       environment struct
%     astBusStruct      (string)       bus struct (array) as returned by the SL function
%                                      get_param(<block or port handle>, 'BusStruct')
%     sRootName         (string)       an optional root signal name that is prepended to the names of the signals
%
%   OUTPUT              DESCRIPTION
%      astSigs          (array)       structs with following info 
%        .sName          (string)      name of subsignal
%        .sUserType      (string)      type of subsignal (might be an alias)
%        .sType          (string)      base type of subsignal (builtin or fixed-point-type)
%        .iWidth         (integer)     width of subsignal
%        .sMin           (string)      Min constraint of signal if available
%        .sMax           (string)      Max constraint of signal if available
%        .aiDim          (array)       integers representing dimension
%
%   REMARK:
%     Note that the readout depends on the corresponding model being in "compiled" mode and 
%     on the BusStrictMode being active.
%     Note that the result weill be returned as an empty array [] if the evaluation fails completely.
%
%   <et_copyright>


%%
if (nargin < 3)
    casAddArgs = {};
else
    casAddArgs = {sRootName};
end

astSigs = [];
if ~i_canBeResolved(astBusStruct)
    return;
end

for i = 1:numel(astBusStruct)
    stBus = astBusStruct(i);  
    
    [hSrcPort, bIsValid] = i_getBlockPortHandle(stBus.src, stBus.srcPort);
    if bIsValid
        stInfo = atgcv_m01_port_signal_info_get(stEnv, hSrcPort, stBus.name);    
        astCompSigs = i_filterBusSignals(stInfo.astSigs, stBus, casAddArgs{:});        
    elseif ~isempty(stBus.signals)
        astCompSigs = atgcv_m01_bus_struct_resolve(stEnv, stBus.signals, stBus.name);
    else
        astCompSigs = [];
    end

    if isempty(astCompSigs)
        % if one set of the components signals are empty, there is some error somewhere
        % --> exit with an empty result to indicate an internal failure
        astSigs = [];
        return;
    end
    
    if isempty(astSigs)
        astSigs = astCompSigs;
    else
        astSigs = [astSigs, astCompSigs]; %#ok<AGROW>
    end
end
end


%%
function bCanBeResolved = i_canBeResolved(astBusStruct)
bCanBeResolved = false;
for i = 1:numel(astBusStruct)
    stBus = astBusStruct(i);
    
    [~, bIsValid] = i_getBlockPortHandle(stBus.src, stBus.srcPort);
    if ~bIsValid && isempty(stBus.signals)
        return;
    end
end
bCanBeResolved = true;
end


%%
function astSigs = i_filterBusSignals(astSigs, stBus, sRootName)
casLeafSigs = i_getLeafSignalNames(stBus);
abSelect = false(size(astSigs));
for i = 1:numel(astSigs)
    sSigName = astSigs(i).sName;
    
    sMatchingLeafName = i_findMatchingLeafName(casLeafSigs, sSigName);
    if ~isempty(sMatchingLeafName)
        abSelect(i) = true;
        
        if (nargin < 3)
            astSigs(i).sName = sMatchingLeafName;
        else
            astSigs(i).sName = [sRootName, '.', sMatchingLeafName];
        end
    end
end
astSigs = astSigs(abSelect);
astSigs = i_filterOutDuplicates(astSigs);
end


%%
function astSigs = i_filterOutDuplicates(astSigs)
if (numel(astSigs) < 2)
    return;
end

xKnownNames = containers.Map;
abSelect = true(size(astSigs));
for i = 1:numel(astSigs)
    sSigName = astSigs(i).sName;
    if xKnownNames.isKey(sSigName)
        abSelect(i) = false;
    else
        xKnownNames(sSigName) = true;
    end
end
astSigs = astSigs(abSelect);
end


%%
function sMatchingLeafName = i_findMatchingLeafName(casLeafSigs, sSigName)
for i = 1:numel(casLeafSigs)
    sPattern = [regexptranslate('escape', casLeafSigs{i}), '$'];
    if ~isempty(regexp(sSigName, sPattern, 'once'))
        sMatchingLeafName = casLeafSigs{i};
        return;
    end
end
sMatchingLeafName = [];
end


%%
function casLeafSigs = i_getLeafSignalNames(stBus, sRootName)
if (nargin < 2)
    sName = stBus.name;
else
    sName = [sRootName, '.', stBus.name];
end
if isempty(stBus.signals)
    casLeafSigs = {sName};
else
    ccasLeafSigs = arrayfun(@(stSig) i_getLeafSignalNames(stSig, sName), stBus.signals, 'UniformOutput', false);
    casLeafSigs = horzcat(ccasLeafSigs{:});
end
end


%%
function [hPort, bIsValid] = i_getBlockPortHandle(hBlock, iPort)
stPortHandles = get_param(hBlock, 'PortHandles');
if (iPort > 0)
    hPort = stPortHandles.Outport(iPort);
 else 
    hPort = stPortHandles.Inport(abs(iPort));
end
aiDim = get_param(hPort, 'CompiledPortDimensions');
bIsValid = ~isempty(aiDim);
end

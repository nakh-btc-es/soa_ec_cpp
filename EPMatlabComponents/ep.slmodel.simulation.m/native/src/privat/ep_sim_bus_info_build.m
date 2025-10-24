function astBusInfo = ep_sim_bus_info_build(casNames, casTypes, casDims)
% Combines divers data from flat signal represenation into a hierarchical info about bus signals.
%
%  function astBusInfo = ep_sim_bus_info_build(casNames, casTypes, casDims)
%
%     INPUT
%   casNames        (cell)     flat names of leaf signals, i.e. full-path-signal-name for buses with signal separators
%                              example: 'a.b.c'
%   casTypes        (cell)     types of the leaf signals
%   casDims         (cell)     dimensions of the the leaf signals
%
%     OUTPUT
%   astBusInfo      (array)    structured info about the contained bus signals
%     .sBusElemName      (string)   name of the bus element
%     .bIsBus            (boolean)  flag if the signal is a bus and has info about sub-signals attached
%     .sType             (string)   type of the signal (note: non-empty only for the leaf elements)
%     .sDim              (string)   dimension of the signal (note: non-empty only for the leaf elements)
%     .astBusInfo        (array)    structs recursively following the same pattern ...
%                                   (note: non-empty only for bus elements and empty for leaf elements)
%



%%
nSigs = numel(casNames);
if (nSigs < 1)
    astBusInfo = [];
    return;
end

% just for debugging fill dims and types with some nonsense
if (nargin < 3)
    casDims = repmat({'<dim>'}, 1, nSigs);
end
if (nargin < 2)
    casTypes = repmat({'<type>'}, 1, nSigs);
end

astFlatSigs = i_createFlatSigsInfo(casNames, casTypes, casDims);

astNestedSigs = ep_flat_to_nested_signals(astFlatSigs);

astBusInfo = i_nestedSigsToBusInfo(astNestedSigs);
end


%%
function astFlatSigs = i_createFlatSigsInfo(casNames, casTypes, casDims)
astFlatSigs = struct( ...
    'sName', casNames, ...
    'stInfo', []);
astInfo = struct( ...
    'sType', casTypes, ...
    'sDim',  casDims);
for i = 1:numel(astFlatSigs)
    astFlatSigs(i).stInfo = astInfo(i);
end
end


%%
function astBusInfo = i_nestedSigsToBusInfo(astNestedSigs)
astBusInfo = arrayfun(@i_createBusInfo, astNestedSigs);
end


%%
function stBusInfo = i_createBusInfo(stNestedSig)
if isempty(stNestedSig.stInfo)
    sType = '';
    sDim  = '';
else
    sType = stNestedSig.stInfo.sType;
    sDim  = stNestedSig.stInfo.sDim;
end

stBusInfo = struct( ...
    'sBusElemName', stNestedSig.sName, ...
    'bIsBus',       ~isempty(stNestedSig.astSubSigs), ...
    'sType',        sType, ...
    'sDim',         sDim, ...
    'astBusInfo',   i_nestedSigsToBusInfo(stNestedSig.astSubSigs));
end


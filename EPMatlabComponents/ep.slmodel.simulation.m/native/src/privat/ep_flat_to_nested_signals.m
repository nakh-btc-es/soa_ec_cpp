function astNestedSigs = ep_flat_to_nested_signals(astFlatSigs)
% Transforms flat signal information into hierarchical structured signal information.
%
%  function astNestedSigs = ep_flat_to_nested_signals(astFlatSigs)
%
% INPUT
%  astFlagSigs
%       .sName   (string)   name of the flat signal (can contain signal separators for bus signals, e.g. 'a.b.c')
%       .stInfo  (struct)   some arbitrary info for the signal
%
% OUTPUT
%  astNestedSigs
%       .sName       (string)   name of the nested signal (does not contain any signal separators)
%       .stInfo      (struct)   some arbitrary info for the signal (empty for non-leaf signals)
%       .astSubSigs  (struct)   structs containing info for the sub-signals (empty for leaf elements) 
%
%


%%
astNestedSigs = repmat(i_createNewNestedSig(''), 1, 0);

nSigs = numel(astFlatSigs);
if (nSigs < 1)
    return;
end

for i = 1:nSigs
    stFlatSig = astFlatSigs(i);
    
    if i_isLeafSig(stFlatSig.sName)
        astNestedSigs(end + 1) = i_convertFlatToNestedSig(stFlatSig); %#ok<AGROW>
        
    else
        [sRootSig, sRemainderSig] = i_splitSigName(stFlatSig.sName);
        
        % check if we already have a nested signal with the same root name and use it when found
        iRootSigIdx = [];
        for k = numel(astNestedSigs):-1:1 % note: look in reverse order because similar names are next to each other
            if strcmp(astNestedSigs(k).sName, sRootSig)
                iRootSigIdx = k;
                break;
            end
        end
        % if we do not have any root signal with the same name, create one
        if isempty(iRootSigIdx)
            astNestedSigs(end + 1) = i_createNewNestedSig(sRootSig); %#ok<AGROW>
            iRootSigIdx = numel(astNestedSigs);
        end
        
        % replace full signal name with the remainder name and add the flat signal as sub-signal to root signal
        stFlatSig.sName = sRemainderSig;
        
        if isempty(astNestedSigs(iRootSigIdx).astSubSigs)
            astNestedSigs(iRootSigIdx).astSubSigs = stFlatSig;
        else
            astNestedSigs(iRootSigIdx).astSubSigs(end + 1) = stFlatSig;
        end
    end
end

% note: the attached sub-signals still have the flat-signal structure and need to be made nested by calling this
% function recursively --> this goes deeper and deeper until there are only leaf-signals left as sub-signals
for i = 1:numel(astNestedSigs)
    if ~isempty(astNestedSigs(i).astSubSigs)
        astNestedSigs(i).astSubSigs = ep_flat_to_nested_signals(astNestedSigs(i).astSubSigs);
    end
end
end


%%
function [sRootSig, sRemainderSig] = i_splitSigName(sSigName)
casSigParts = regexp(sSigName, '\.', 'split', 'once');

sRootSig = casSigParts{1};
if (numel(casSigParts) > 1)
    sRemainderSig = casSigParts{2};
else
    sRemainderSig = '';
end
end


%%
function stNestedSig = i_convertFlatToNestedSig(stFlatSig)
stNestedSig = stFlatSig;
stNestedSig.astSubSigs = []; % add a field containing the nested child elements
end


%%
function stNestedSig = i_createNewNestedSig(sRootSig)
stNestedSig = struct( ...
    'sName',      sRootSig, ...
    'stInfo',     [], ...
    'astSubSigs', []);
end


%%
function bIsLeaf = i_isLeafSig(sSigName)
bIsLeaf = all(sSigName ~= '.'); % note: leaf signal names do not contain any signal separator '.'
end

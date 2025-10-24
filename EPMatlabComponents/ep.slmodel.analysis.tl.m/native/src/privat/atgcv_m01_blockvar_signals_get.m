function astSignals = atgcv_m01_blockvar_signals_get(stEnv, hBlockVar, bWithVarInfo)
% Get info about the LeafSignals represented by a DD BlockVariable.
%
% function astSignals = atgcv_m01_blockvar_signals_get(stEnv, hBlockVar, bWithVarInfo)
%
%   INPUT               DESCRIPTION
%     stEnv              (struct)   error messenger environment
%     hBlockVar          (handle)   DD handle of block variable
%     iPort              (integer)  port number of output port
%                                   (optional: if not given, _all_ output signals of all output ports are returned)
%     bWithVarInfo       (boolean)  return additional info about ref variable (optional: default = true)
%
%   OUTPUT              DESCRIPTION
%      stSignal          (struct)   with the following fields
%        .hBlockVar      (handle)     DD handle of output BlockVariable
%        .sSignalName    (string)     signal name of output BlockVariable
%        .hVariableRef   (handle)     reference to variable in C-code
%        .iWidth         (integer)    width of the Signal
%        .aiElements     (integer)    array of non-neg integer C-Indexes  referring to the C-Variable
%                                     (usually used for "slices", i.e. may be empty if the Variable is a 
%                                     Scalar or if all elements of the Variable are used)
%        .aiSigElements  (integer)    array of non-neg integer ML-Indexes referring to the MIL Signal
%                                     (usually used for "slices", i.e. may be empty if all of the Signal elements
%                                     are described by the Variable)
%                                     (for the 1st Dimension)
%        .aiSigElements2  (integer)   similar to aiSigElements (for the 2nd Dimension)
%        .bIsDummyVar    (boolean)    if TRUE, the signal is a dummy variable
%        .bIsMacro       (boolean)    if TRUE, the signal is represented by a C-Macro
%        .bIsRDI         (boolean)    If true, the signal is a RDI interface
%        .stVarInfo      (struct)     info about ref variable (only non-empty if bWithVarInfo == true)
%        .astInstanceSigs (array)     of structs with the same fields as the main "stSignal"
%               ...                   
%                                     [used since TL4.0 for multiple instances of the same MIL Signal as
%                                     different C-Code Variables]
%


%%
hBlockVar = i_checkNormalizeBlockVarHandle(stEnv, hBlockVar);
if (nargin < 3)
    bWithVarInfo = true;
end
astSignals = i_getAllSignals(stEnv, hBlockVar, bWithVarInfo);
end


%%
function astSignals = i_getAllSignals(stEnv, hBlockVar, bWithVarInfo)
ahChildBlockVars = atgcv_mxx_dsdd(stEnv, 'GetChildren', hBlockVar, 'objectKind', 'BlockVariable');

% BUS SIGNAL
if i_isBusRelation(hBlockVar, ahChildBlockVars)
    hFunc = @(x) i_getAllSignals(stEnv, x, bWithVarInfo);
    astSignals = cell2mat(arrayfun(hFunc, ahChildBlockVars, 'UniformOutput', false));
    return;
end

% ARRAY SIGNAL composed of multiple variables
if i_isComposedArrayRelation(hBlockVar, ahChildBlockVars)
    hFunc = @(x) i_getLeafSignal(stEnv, x, bWithVarInfo);
    astSignals = cell2mat(arrayfun(hFunc, ahChildBlockVars, 'UniformOutput', false));
    astSignals = i_makeComposedArrayAdaptions(stEnv, hBlockVar, astSignals);
else
    % LEAF SIGNAL (possibly with multiple instances)
    astSignals = i_getLeafSignal(stEnv, hBlockVar, bWithVarInfo);
end

% REFILL and REORDER if without InstanceSignals
if ~any(arrayfun(@i_hasInstanceSignals, astSignals))
    astSignals = i_reorderAndFillGaps(stEnv, hBlockVar, astSignals);
end
end


%%
function bHasInstancesSigs = i_hasInstanceSignals(stSignal)
bHasInstancesSigs = ~isempty(stSignal.astInstanceSigs);
end


%%
function astSignals = i_makeComposedArrayAdaptions(stEnv, hBlockVar, astSignals)
aiElemNums = arrayfun(@i_getNumSignalElements, astSignals);

aiWidth = i_getWidth(stEnv, hBlockVar);
if isempty(aiWidth)
    % for TL < 4.0 the root element may not have a width
    % in this case just add the number of all elements (assumption: no matrix valued width used here!)    
    aiWidth = sum(aiElemNums);
end
 
% also provide fake SignalElements to be more similar to TL4.0 and higher
%  --> take care that index starts with zero!
nOffset = 1;
iIdx1 = 1;
for i = 1:length(astSignals)
    astSignals(i).iRootWidth = aiWidth;

    iIdx2 = iIdx1 + aiElemNums(i) - 1;
    if (isempty(astSignals(i).aiSigElements) && isempty(astSignals(i).aiSigElements2))
        astSignals(i).aiSigElements = (iIdx1:iIdx2) - nOffset;
    end
    iIdx1 = iIdx2 + 1;
end
end


%%
function astSignals = i_reorderAndFillGaps(stEnv, hBlockVar, astSignals)
aiWidth = i_getWidth(stEnv, hBlockVar);
if isempty(aiWidth)
    return;
end
% iLength = prod(aiWidth);
% if (iLength < 2) || ...
%         (iLength <= sum(arrayfun(@i_getNumSignalElements, astSignals)))
%     return;
% end

hFunc = @(x) i_findRepresentedSubSignals(x, aiWidth);
caiIdxFound = arrayfun(hFunc, astSignals, 'UniformOutput', false);

if ~i_areDisjointIntegerSets(caiIdxFound)
    error('ATGCV:MOD_ANA:UNSUPPORTED_MAPPING', ...
        'Mapping between SIL variable and MIL signal in Block "%s" is inconsistent.', dsdd_get_block_path(hBlockVar));
end

% INNER GAPS: gaps inside the Variable Signals
% check if any of the Variables represents non-sequential signal elements
% e.g. Variable X with width=2 can represent elements 1 and 3 (leaving out 2)
bHasInnerGaps = false;
bHasOneToManyMapping = false;
for i = 1:length(caiIdxFound)
    aiIdxFound = caiIdxFound{i};
    
    bHasInnerGaps = ~i_isSortedWithoutGaps(aiIdxFound);
    if bHasInnerGaps
        break;
    end
    
    iWidthMIL = length(aiIdxFound);
    iWidthSIL = i_getNumVarElements(astSignals(i));
    if (iWidthMIL ~= iWidthSIL)
        % currently only 1:N Mapping supported
        if (iWidthSIL == 1)
            bHasOneToManyMapping = true;
        else
            error('ATGCV:MOD_ANA:UNSUPPORTED_MAPPING', 'Mapping between SIL variable and MIL signal is not supported.');
        end
    end
end

% if there are inner gaps, break everything up element-wise and reorder if needed 
%  --> this way is the brute force method to remove all inner gaps and just to
%      have outer gaps (more efficient but more complicated is to group 
%      sequential variable elements --> TODO)
if (bHasInnerGaps || bHasOneToManyMapping)
    castSplitSignals = cell(1, length(astSignals));
    for i = 1:length(astSignals)
        aiIdxFound = caiIdxFound{i};
        nElems = length(aiIdxFound);
        astSplitSignals = repmat(astSignals(i), 1, nElems);
        [caiSplitElems, caiSplitElems2] = i_splitVarElements(astSignals(i));
        if (length(caiSplitElems) < nElems)
            % NOTE: the following replication strategy makes only sense for 
            %       a 1:N Mapping
            caiSplitElems  = repmat(caiSplitElems(1), 1, nElems);
            caiSplitElems2 = repmat(caiSplitElems2(1), 1, nElems);
        end
        for k = 1:nElems
            iRepresentedIdx = aiIdxFound(k);
            [aiSigElems, aiSigElems2] = ...
                i_trafoIdxToSigElems(iRepresentedIdx, aiWidth);
            astSplitSignals(k).iWidth = 1;
            astSplitSignals(k).aiSigElements  = aiSigElems;
            astSplitSignals(k).aiSigElements2 = aiSigElems2;
            
            astSplitSignals(k).aiElements = caiSplitElems{k};
            astSplitSignals(k).aiElements2 = caiSplitElems2{k};
        end
        castSplitSignals{i} = astSplitSignals;
    end
    astSignals = cell2mat(castSplitSignals);
    aiSplitIdxFound = cell2mat(caiIdxFound);    
    caiIdxFound = arrayfun(@(x) x, aiSplitIdxFound, 'UniformOutput', false);
end

% OUTER GAPS: gaps _between_ the variables
% now there are only "outer" gaps, 
% e.g. Variable X represents element 1 and Variable Y represents element 3
aiIdxFound = cell2mat(caiIdxFound);
aiIdxMissing = 1:prod(aiWidth);
aiIdxMissing(aiIdxFound) = [];
if ~isempty(aiIdxMissing)
    % if there are DummyVariables, the width is potentially not
    % adapted yet --> do this now
    for i = 1:length(astSignals)
        astSignals(i).iWidth = i_getWidthSignalElements(astSignals(i));
    end
    
    for i = 1:length(aiIdxMissing)
        [aiSigElems, aiSigElems2] = i_trafoIdxToSigElems(aiIdxMissing(i), aiWidth);
        astSignals(end + 1) = ...
            i_getDummyVar(stEnv, hBlockVar, aiWidth, aiSigElems, aiSigElems2); %#ok<AGROW>
        caiIdxFound{end + 1} = aiIdxMissing(i); %#ok<AGROW>
    end
end

% REORDERING
aiGroupMaxIdx = cellfun(@max, caiIdxFound);
[~, aiSortedIdx] = sort(aiGroupMaxIdx);
astSignals = astSignals(aiSortedIdx);
end


%%
function bAreDisjoint = i_areDisjointIntegerSets(caiArrays)
if (length(caiArrays) < 2)
    bAreDisjoint = true;
else
    aiArrays = cell2mat(caiArrays);
    bAreDisjoint = length(aiArrays) == length(unique(aiArrays));
end
end


%%
% provided with an integer array, checks if the integers are sequential (+1)
% Examples for arrays that are sorted AND without gaps: [3, 4, 5], [], [1], [-3, -2], ...
% Examples for arrays that are unsorted OR have gaps:[4, 6, 5], [1, -1], [3, 5, 6], ...
function bSuccess = i_isSortedWithoutGaps(aiArray)
if (length(aiArray) < 2)
    % array with less than two elements is always sorted and without gaps
    bSuccess = true;
else
    aiDiff = aiArray(2:end) - aiArray(1:end-1);
    bSuccess = all(aiDiff == 1);
end
end


%%
function [caiSplitElems, caiSplitElems2] = i_splitVarElements(stSignal)
caiSplitElems  = {[]};
caiSplitElems2 = {[]};

[aiElems, aiElems2] = i_getSignalVarElements(stSignal);
if ~isempty(aiElems)
    caiSplitCol = arrayfun(@(x) x, aiElems, 'UniformOutput', false);
    iWidth1 = length(caiSplitCol);
    
    if isempty(aiElems2)
        caiSplitElems  = caiSplitCol;
        caiSplitElems2 = repmat({[]}, 1, iWidth1);
    else               
        caiSplitRow = arrayfun(@(x) x, aiElems2, 'UniformOutput', false);
        
        iCol = length(caiSplitCol);
        iRow = length(caiSplitRow);
        
        caiSplitElems  = reshape(repmat(caiSplitCol, 1, iRow), 1, []);
        caiSplitElems2 = reshape(repmat(caiSplitRow, iCol, 1), 1, []);
    end    
end
end


%%
function iNum = i_getNumVarElements(stSignal)
[aiElem, aiElem2] = i_getSignalVarElements(stSignal);

iWidth1 = 1;
if ~isempty(aiElem)
    iWidth1 = length(aiElem);
end
iWidth2 = 1;
if ~isempty(aiElem2)
    iWidth2 = length(aiElem2);
end
iNum = iWidth1*iWidth2;
end


%%
function [aiVarElements, aiVarElements2] = i_getSignalVarElements(stSignal)
aiWidth = [];
if ~isempty(stSignal.stVarInfo)
    aiWidth = stSignal.stVarInfo.aiWidth;
end
aiVarElements  = stSignal.aiElements;
aiVarElements2 = stSignal.aiElements2;
if isempty(aiVarElements)
    if ~isempty(aiWidth)
        if (length(aiWidth) < 2)
            aiVarElements = 0:(aiWidth - 1);
        else
            aiVarElements  = 0:(aiWidth(1) - 1);
            aiVarElements2 = 0:(aiWidth(2) - 1);
        end
    end
else
    if any(aiVarElements < 0)
        if ~isempty(aiWidth)
            aiVarElements = 0:(aiWidth(1) - 1);
        end
    end
    if any(aiVarElements2 < 0)
        if ~isempty(aiWidth)
            aiVarElements2 = 0:(aiWidth(2) - 1);
        end
    end
end
end


%%
function [aiSigElems, aiSigElems2] = i_trafoIdxToSigElems(iIdx, aiWidth)
if (length(aiWidth) > 1)
    [iX, iY] = ind2sub(aiWidth, iIdx);
    aiSigElems  = iX - 1;
    aiSigElems2 = iY - 1;
else
    aiSigElems = iIdx - 1;
    aiSigElems2 = [];
end
end


%%
function aiIdxFound = i_findRepresentedSubSignals(stSignal, aiWidth)
if isempty(stSignal.aiSigElements)
    aiIdxFound = 1:prod(aiWidth);
    return;
end

aiSigElem = stSignal.aiSigElements;
if any(aiSigElem < 0)
    aiSigElem = 1:aiWidth(1);
else
    aiSigElem = aiSigElem + 1; % compensate for DD starting with zero offset
end

if isempty(stSignal.aiSigElements2)
    aiIdxFound = aiSigElem;
    return;
end

aiSigElem2 = stSignal.aiSigElements2;
if any(aiSigElem2 < 0)
    aiSigElem2 = 1:aiWidth(2);
else
    aiSigElem2 = aiSigElem2 + 1; % compensate for DD starting with zero offset
end

nFound = length(aiSigElem) * length(aiSigElem2);
aiIdxFound = zeros(1, nFound);
iIdx = 1;
for i = 1:length(aiSigElem2)
    for k = 1:length(aiSigElem)
        aiIdxFound(iIdx) = sub2ind(aiWidth, aiSigElem(k), aiSigElem2(i));
        iIdx = iIdx + 1;
    end
end
end


%%
function iNum = i_getNumSignalElements(stSignal)
iNum = prod(i_getWidthSignalElements(stSignal));
end


%%
function aiWidth = i_getWidthSignalElements(stSignal)
if isempty(stSignal.aiSigElements)
    if isempty(stSignal.iWidth)
        % scalar signals do not have a width --> return 1 in this case
        aiWidth = 1;
    else
        aiWidth = stSignal.iWidth;
    end
else
    % Note: property SignalElements == -1 indicates _all_ elements of the
    %       particular dimension; otherwise SignalElements starts with zero
    if any(stSignal.aiSigElements < 0)
        iWidth1 = stSignal.iWidth(1);
    else
        iWidth1 = length(stSignal.aiSigElements);
    end
    if isempty(stSignal.aiSigElements2)
        aiWidth = iWidth1;
    else
        if any(stSignal.aiSigElements2 < 0)
            iWidth2 = stSignal.iWidth(2);
        else
            iWidth2 = length(stSignal.aiSigElements2);
        end
        aiWidth = [iWidth1, iWidth2];
    end
end
end


%%
function stSignal = i_getInitSignalInfo(stEnv, hBlockVar)
aiWidth = i_getWidth(stEnv, hBlockVar);
stSignal = struct( ...
    'hBlockVar',        hBlockVar, ...
    'sSignalName',      i_getFullSignalName(stEnv, hBlockVar), ...
    'hVariableRef',     [], ...
    'iRootWidth',       aiWidth, ...
    'iWidth',           aiWidth, ...
    'aiElements',       [], ...
    'aiElements2',      [], ...
    'aiSigElements',    [], ...
    'aiSigElements2',   [], ...
    'bIsDummyVar',      false, ...
    'bIsMacro',         false, ...
    'bIsRDI',           false, ...
    'stVarInfo',        [], ...
    'astInstanceSigs',  []);
end


%%
function stSignal = i_getDummyVar(stEnv, hBlockVar, aiWidth, aiSigElems, aiSigElems2)
stSignal = i_getInitSignalInfo(stEnv, hBlockVar);
stSignal.iRootWidth = aiWidth;
stSignal.iWidth = 1;
stSignal.aiSigElements = aiSigElems;
stSignal.aiSigElements2 = aiSigElems2;
stSignal.bIsDummyVar = true;
end


%%
function stSignal = i_getLeafSignal(stEnv, hBlockVar, bWithVarInfo)
stSignal = i_getInitSignalInfo(stEnv, hBlockVar);

ahChildBlockVars = atgcv_mxx_dsdd(stEnv, 'GetChildren', hBlockVar, 'objectKind', 'BlockVariable');
if isempty(ahChildBlockVars)
    hVariableRef = [];
    
    % first try the RDI reference (otherwise we maybe find the VariableRef first)
    if ~atgcv_verLessThan('TL3.4')
        if dsdd('Exist', hBlockVar, 'property', {'name', 'ReplaceableDataItemRef'})
            stSignal.bIsRDI = true;
            
            hRDITarget = atgcv_mxx_dsdd(stEnv, 'GetReplaceableDataItemRefTarget', hBlockVar);
            if ~isempty(hRDITarget)
                hVariableRef = atgcv_mxx_dsdd(stEnv, 'GetMacroVariableRefTarget', hRDITarget);
            end
        end
    end
    
    % try to get variable reference
    hBlockVarSource = [];
    if isempty(hVariableRef)
        [hVariableRef, hBlockVarSource] = i_getVariableRef(stEnv, hBlockVar);
    end

    if ~isempty(hVariableRef)
        % only accept macros that are extern or connected to RDIs
        [bIsMacro, bIsExternMacro] = i_checkMacro(stEnv, hVariableRef);
        if (~bIsMacro || bIsExternMacro || stSignal.bIsRDI)
            stSignal.bIsMacro     = bIsMacro;
            stSignal.hVariableRef = hVariableRef;

            if bWithVarInfo
                stSignal.stVarInfo = atgcv_m01_variable_info_get(stEnv, stSignal.hVariableRef);
            end
        end
    end

    % if there is no VariableRef, we have a Dummy Variable
    if isempty(stSignal.hVariableRef)
        stSignal.bIsDummyVar = true;
    end
    [stSignal.aiElements, stSignal.aiElements2] = i_getVariableElements(stEnv, hBlockVar);
    if (isempty(stSignal.aiElements)  && ~isempty(hBlockVarSource) && (hBlockVarSource ~= hBlockVar))
        [stSignal.aiElements, stSignal.aiElements2] = i_getVariableElements(stEnv, hBlockVarSource);
    end
    [stSignal.aiSigElements, stSignal.aiSigElements2] = i_getSignalElements(stEnv, hBlockVar);
    
else
    % BlockVariables with Child BlockVariables that are not CompoundSignals were introduced in TL4.0.
    % --> They need to be treated specially since the Child BlockVariables
    %     do not represent any Signal from the MIL level. Instead, they are
    %     _instances_ of the Parent BlockVariable.
    %
    ahChildBlockVars = i_makeUnique(ahChildBlockVars);
    stSignal.astInstanceSigs = cell2mat(arrayfun( ...
        @(x) atgcv_m01_blockvar_signals_get(stEnv, x, bWithVarInfo), ahChildBlockVars, 'UniformOutput', false));
end
end


%%
function aiWidth = i_getWidth(stEnv, hBlockVar)
if dsdd('Exist', hBlockVar, 'Property', {'Name', 'Width'})
    aiWidth = atgcv_mxx_dsdd(stEnv, 'GetWidth', hBlockVar);
else
    aiWidth = [];
end
end


%%
function ahDdObjects = i_makeUnique(ahDdObjects)
if (length(ahDdObjects) < 2)
    return;
end

% Get the properties that define our understanding of uniqueness.
% Since the struct-values could be different, use a cell-array as output.
castProps = arrayfun(@(x) (dsdd('GetAll', x)), ahDdObjects, 'UniformOutput', false);

abSelect = false(size(ahDdObjects));
for i = 1:length(ahDdObjects)
    if ~any(abSelect)
        % if no Objects have been selected yet, every Object is
        % automatically unique
        abSelect(i) = true;
        continue;
    end
    
    % Set A of selected Props: Properties of the already seleted Objects
    castSelectedProps = castProps(abSelect);
    
    % Prop B: Property of the Object to be tested
    stProp = castProps{i};
    
    % Compare Prop B with every Prop in A
    abIsEqual = cellfun(@(x) (isequal(stProp, x)), castSelectedProps);
    
    % If there is no Match, Object is unique and can be selected.
    if all(~abIsEqual)
        abSelect(i) = true;
    end
end
ahDdObjects = ahDdObjects(abSelect);
end


%%
function [hVariableRef, hBlockVar] = i_getVariableRef(stEnv, hBlockVar)
hVariableRef = [];
if dsdd('Exist', hBlockVar, 'property', {'name', 'VariableRef'})
    hVariableRef = atgcv_mxx_dsdd(stEnv, 'GetVariableRef', hBlockVar);
end
if isempty(hVariableRef)
    hVariableRef = i_tryVariantRef(stEnv, hBlockVar);
end
if isempty(hVariableRef)
    hVariableRef = i_tryAutosarRef(stEnv, hBlockVar);
end
if (isempty(hVariableRef) && ~atgcv_verLessThan('TL4.0'))
    if dsdd('Exist', hBlockVar, 'property', {'name', 'BlockVariableRef'})
        hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', hBlockVar, -1);
        if ~isempty(hSrcBlockVar)
            [hVariableRef, hBlockVar] = i_getVariableRef(stEnv, hSrcBlockVar);
        end
    end
end
end


%%
function bIsArray = i_isComposedArrayRelation(hBlockVar, ahChildBlockVars)
bIsArray = false;
if isempty(ahChildBlockVars)
    % no children, no composed array
    return;
end

if atgcv_verLessThan('TL4.0')
    % for older TL versions a Parent block var with children always
    % represents a composed Array if it is not a Bus 
    % !! ASSUMPTION: BusCheck was already performed
    bIsArray = true;
    return;
end

iParentWidth = i_getNumElems(hBlockVar); 
if (iParentWidth < 2)
    % Parent is not even an array --> just return now
    return;
end

iChildWidth = 0;
for i = 1:length(ahChildBlockVars)
    iChildWidth = iChildWidth + i_getNumElems(ahChildBlockVars(i));
    if (iChildWidth > iParentWidth)
        % if the width of the children exceeds the parent width, children 
        % represent instance signals instead of array components
        return;
    end
end
bIsArray = true; % TODO: check if iChildWidth == iParentWidth?
end


%%
function iElems = i_getNumElems(hBlockVar)
iElems = 1;
if dsdd('Exist', hBlockVar, 'Property', {'name', 'Width'})
    iElems = prod(dsdd('GetWidth', hBlockVar));
end
end


%%
function bIsBus = i_isBusRelation(hBlockVar, ahChildBlockVars)
bIsBus = false;
if isempty(ahChildBlockVars)
    % no children, no bus element
    return;
end

% Use heuristic: Bus == MainSignal has Name && _all_ ChildSignals have Names
bIsBus = i_hasSignalName(hBlockVar);
if ~bIsBus
    return;
end
for i = 1:length(ahChildBlockVars)
    bIsBus = bIsBus && i_hasSignalName(ahChildBlockVars(i));
end
end


%%
function bHasSigName = i_hasSignalName(hBlockVar)
bHasSigName = dsdd('Exist', hBlockVar, 'Property', {'name', 'SignalName'});
end


%%
function [aiElements, aiElements2] = i_getVariableElements(stEnv, hBlockVar)
aiElements  = [];
aiElements2 = [];
if atgcv_verLessThan('TL4.0')
    if dsdd('Exist', hBlockVar, 'property', {'name', 'Elements'})
        aiElements = atgcv_mxx_dsdd(stEnv, 'GetElements', hBlockVar);
    end
else
    if dsdd('Exist', hBlockVar, 'property', {'name', 'VariableElements'})
        aiElements = atgcv_mxx_dsdd(stEnv, 'GetVariableElements', hBlockVar, -1);
    end
    if dsdd('Exist', hBlockVar, 'property', {'name', 'VariableElements(#2)'})
        aiElements2 = atgcv_mxx_dsdd(stEnv, 'GetVariableElements', hBlockVar, 2);
    end
end
end


%%
function [aiElements1, aiElements2] = i_getSignalElements(stEnv, hBlockVar)
aiElements1 = [];
aiElements2 = [];
if ~atgcv_verLessThan('TL4.0')
    if dsdd('Exist', hBlockVar, 'property', {'name', 'SignalElements'})
        aiElements1 = atgcv_mxx_dsdd(stEnv, 'GetSignalElements', hBlockVar, -1);
    end
    if dsdd('Exist', hBlockVar, 'property', {'name', 'SignalElements(#2)'})
        aiElements2 = atgcv_mxx_dsdd(stEnv, 'GetSignalElements', hBlockVar, 2);
    end
end
end


%% 
function hBlockVar = i_checkNormalizeBlockVarHandle(stEnv, hBlockVar)
if ischar(hBlockVar)
    hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDObject');
end
sObjectKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'objectKind');
if ~strcmpi(sObjectKind, 'BlockVariable')
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Argument is not a DD BlockVariable handle.');
end
end


%%
function bIsBlockVar = i_isBlockVar(stEnv, hBlockVar)
bIsBlockVar = strcmpi(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'objectKind'), 'BlockVariable');
end


%%
function sSignalName = i_getSignalName(stEnv, hBlockVar)
if i_hasSignalName(hBlockVar)
    sSignalName = atgcv_mxx_dsdd(stEnv, 'GetSignalName', hBlockVar);
else
    sSignalName = '';
end
end


%%
function sFullSignalName = i_getFullSignalName(stEnv, hBlockVar)
sFullSignalName = '';
while (i_isBlockVar(stEnv, hBlockVar) && i_hasSignalName(hBlockVar))
    sSignalName = i_getSignalName(stEnv, hBlockVar);
    if isempty(sFullSignalName)
        sFullSignalName = sSignalName;
    else
        sFullSignalName = [sSignalName, '.', sFullSignalName]; %#ok<AGROW>
    end
    hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDParent');
end
end


%%
function [bIsMacro, bIsExternMacro] = i_checkMacro(stEnv, hVar)
stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
bIsMacro = ~isempty(stInfo.hClass) && stInfo.bIsMacro;
if bIsMacro
    bIsExternMacro = strcmpi(stInfo.sStorage, 'extern');
else
    bIsExternMacro = false;
end
end


%%
function hVariableRef = i_tryVariantRef(stEnv, hBlockVar)
hVariableRef = [];

casProp = atgcv_mxx_dsdd(stEnv, 'GetPropertyNames', hBlockVar);
abIsVvr = strncmp(casProp, 'VariantVariableRef', 18);
if any(abIsVvr)
    casProp = casProp(abIsVvr);

    hTlSubsys = i_getTlSub(stEnv, hBlockVar);
    ahActiveVars = atgcv_m01_active_dv_vars_get(stEnv, hTlSubsys);
    for i = 1:length(casProp)
        hVariantRef = atgcv_mxx_dsdd(stEnv, 'Get', hBlockVar, {'name', casProp{i}});

        if any(hVariantRef == ahActiveVars)
            hVariableRef = hVariantRef;
            return;
        end
    end
end   
end


%%
function hVariableRef = i_tryAutosarRef(stEnv, hBlockVar)
hVariableRef = [];
hOrigBlockVar = hBlockVar;

bIsCompound = false;
hAutosarAccessPoint = atgcv_mxx_dsdd(stEnv, 'Find', hBlockVar, 'ObjectKind', 'AutosarAccessPoint');
while isempty(hAutosarAccessPoint)
    % if we are inside a compound signal, try to get the parent block var
    hBlockVar = i_findDdAncestorKind(stEnv, hBlockVar, 'BlockVariable', false);
    if isempty(hBlockVar)
        break;
    end
        
    bIsCompound = true;
    hAutosarAccessPoint = atgcv_mxx_dsdd(stEnv, 'Find', hBlockVar, 'ObjectKind', 'AutosarAccessPoint');
end
if ~isempty(hAutosarAccessPoint)
    ahRef = i_getRefProp(stEnv, hAutosarAccessPoint);
    if (length(ahRef) ~= 1)
        error('ATGCV:MOD_ANA:DEBUG', 'Wrong assumption here. Expecting one and only one reference.');
    end
    hAccess = ahRef(1);    
    hVariableRef = i_findVariableRef(stEnv, hAccess, hOrigBlockVar);
    bIsCompound = bIsCompound || i_hasVarStructType(stEnv, hVariableRef);
    
    if bIsCompound
        hBlockVarRef = atgcv_mxx_dsdd(stEnv, 'Find', hVariableRef, 'Property', {'Value', hOrigBlockVar});        
        if (length(hBlockVarRef) == 1)
            hVariableRefCandidate = ...
                i_findDdAncestorKind(stEnv, hBlockVarRef, 'Variable', true);
            if ~isempty(hVariableRefCandidate)
                hVariableRef = hVariableRefCandidate;
            end
        end
    end
end
end


%%
function hVariableRef = i_findVariableRef(stEnv, hAccess, hOrigBlockVar)
try
    stAll = atgcv_mxx_dsdd(stEnv, 'GetAll', hAccess);
    casFields = fieldnames(stAll);
    for i = 1:length(casFields)
        sField = casFields{i};
        if ~isempty(regexp(sField, '^RteFrameVariableRef', 'once'))
            hVariableRefCandidate = stAll.(sField);
            hBlockVarRef = atgcv_mxx_dsdd(stEnv, 'Find', hVariableRefCandidate, 'Property', {'Value', hOrigBlockVar});
            if ~isempty(hBlockVarRef)
                hVariableRef = hVariableRefCandidate;
                return;
            end
        end
    end
end
hVariableRef = atgcv_mxx_dsdd(stEnv, 'Get', hAccess, 'RteFrameVariableRef');
end


%%
function bHasStructType = i_hasVarStructType(stEnv, hVar)
hComponents = atgcv_mxx_dsdd(stEnv, 'GetComponents', hVar);
bHasStructType = ~isempty(hComponents);
end


%%
function ahRefs = i_getRefProp(stEnv, hObj)
casProps = i_getPropertiesEndingWithRef(stEnv, hObj);
ahRefs = cellfun(@(sProp) atgcv_mxx_dsdd(stEnv, 'Get', hObj, sProp), casProps); 
end


%%
function casProp = i_getPropertiesEndingWithRef(stEnv, hObj)
casProp = atgcv_mxx_dsdd(stEnv, 'GetPropertyNames', hObj);
if isempty(casProp)
    return;
end

abSelect = false(size(casProp));
for i = 1:length(casProp)
    if ~isempty(regexp(casProp{i}, 'Ref$', 'once'))
        abSelect(i) = true;
    end
end
casProp = casProp(abSelect);
end


%%
function hTlSub = i_getTlSub(stEnv, hObj)
hTlSub = dsdd('GetChildren', '//DD0/Subsystems');
if (length(hTlSub) > 1)
    sObjPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'path');
    for i = 1:length(hTlSub)
        sTlPath = [atgcv_mxx_dsdd(stEnv, 'GetAttribute', hTlSub(i), 'path'), '/'];
        if ~isempty(strfind(sObjPath, sTlPath))
            hTlSub = hTlSub(i);
            return;
        end
    end
    hTlSub = []; % if we didn't find any matches return empty array
end
end


%%
function hAncestor = i_findDdAncestorKind(stEnv, hObject, sKind, bIncludeSelf)
if (nargin < 4)
    bIncludeSelf = false;
end
hAncestor = [];
if (isempty(hObject) || ~dsdd('Exist', hObject))
    return;
end

if bIncludeSelf
    hCandidate = hObject;
else
    hCandidate = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObject, 'hDDParent');
end
sObjectKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hCandidate, 'objectKind');
while ~strcmpi(sObjectKind, sKind)
    hCandidate = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hCandidate, 'hDDParent');
    if isempty(hCandidate)
        % we are at the root node and have found no matching ancestor
        return;
    end
    sObjectKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hCandidate, 'objectKind');
end

hAncestor = hCandidate;
end



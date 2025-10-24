function [stSrc, stDest] = atgcv_m01_dest_src_find(stEnv, stDest, bIsArgSrc)
% find source of signal from the info about its destination
%
% function [stSrc, stDest] = atgcv_m01_dest_src_find(stEnv, stDest, bIsArgSrc)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)         environment struct
%
%     stDest            (struct)         struct with following fields
%      .hBlock          (handle)         handle of current block
%      .sPort           (string)         port type of incoming signal 
%                                        e.g. '1', '2', ...
%      .iSigIdx         (integer)        signal index
%      .sSigName        (string)         provided name of signal, that
%                                        takes priority over identified one
%     bIsArgSrc         (bool)           true if argment is src instead of dest
%                                        (optional: default == false)
%
%   OUTPUT              DESCRIPTION
%     stSrc             (struct)         struct with following fields
%      .hBlock          (handle)         handle of src block
%      .sPort           (string)         port type of outgoing signal 
%                                        e.g. '1', '2', ...
%      .iSigIdx         (integer)        signal index
%      .sSigName        (string)         name of outgoing signal
%
%     stDest            (struct)         struct with following fields
%                                        (non-empty only if src block is virtual)
%      .hBlock          (handle)         handle of new destination block
%                                        (might be different from src block,
%                                        e.g. outport of subsystem)
%      .sPort           (string)         port type of incoming signal 
%                                        e.g. '1', '2', ...
%      .iSigIdx         (integer)        signal index
%      .sSigName        (string)         name of incoming signal
%
%   REMARKS
%
%   <et_copyright>


%% check input 
if ischar(stDest.hBlock)
    try
        stDest.hBlock = get_param(stDest.hBlock, 'handle');
    catch
        error('ATGCV:MOD_ANA:WRONG_USAGE', ...
            'Argument not a valid Simulink handle.');
    end
end
if (~isfield(stDest, 'sPort') || isempty(stDest.sPort))
    stDest.sPort = '1';
end
if ~isfield(stDest, 'iSigIdx')
    stDest.iSigIdx = 1;
end
if ~isfield(stDest, 'sSigName')
    stDest.sSigName = '';
end

%% main
% argument dest or source ?
if (nargin < 3)
    bIsArgSrc = false;
end

% signal backtracking
if bIsArgSrc
    stSrc = stDest;
else
    stSrc = i_getSrcFromDest(stEnv, stDest);
end
stDest = i_getDestFromSrc(stEnv, stSrc);
end




%%
function bIsPropag = i_isPropagatingBlock(hBlock)
casPropagBlocks = { ...
    'Inport', ...
    'Outport', ...
    'SubSystem', ...
    'From', ...
    'Goto'};
bIsPropag = any(strcmpi(get_param(hBlock, 'BlockType'), casPropagBlocks));
end


%%
function sSigName = i_getSigName(~, stDest, stSrc)
sSigName = stDest.sSigName;
if ~isempty(sSigName)
    return;
end

% name of input signal of dest block
stPortHandles = get_param(stDest.hBlock, 'PortHandles');
sSigName = get_param(stPortHandles.Inport(str2double(stDest.sPort)), 'Name');
if ~isempty(sSigName)
    sSigName = i_getCleanName(sSigName);
    return;
end

% name of propagated signal of src block
if (~isempty(stSrc.hBlock) && i_isPropagatingBlock(stSrc.hBlock))
    stPortHandles = get_param(stSrc.hBlock, 'PortHandles');
    sPropagName = get_param(stPortHandles.Outport(str2double(stSrc.sPort)), ...
        'PropagatedSignals');
    
    % if we have multiple names, the main component has no name for itself
    if ~isempty(strfind(sPropagName, ','))
        sPropagName = '';
    end
    
    if ~isempty(sPropagName)
        sSigName = i_getCleanName(sPropagName);
        return;
    end
end

% signal name seems to be undefined, so use Simulink heuristics:
% 1) if dest type == "Mux" or "BusCreator" --> signal name depends on
% number of inport
% 2) otherwise use "signal1"
% if strcmpi(get_param(stDest.hBlock, 'BlockType'), {'Mux', 'BusCreator'})
%     sSigName = ['signal', stDest.sPort];
% else
%     sSigName = 'signal1';
% end
end


%%
function stDefault = i_getDefaultDestSrc()
stDefault = struct( ...
    'hBlock',   [], ...
    'sPort',    '', ...
    'iSigIdx',  [], ...
    'sSigName', '');    
end


%% i_getSrcFromDest
function stSrc = i_getSrcFromDest(stEnv, stDest)

stSrc = i_getDefaultDestSrc();
stSrc.iSigIdx  = stDest.iSigIdx;
stSrc.sSigName = stDest.sSigName;

% find the needed src connection
astPortCon = get_param(stDest.hBlock, 'PortConnectivity');
stPortCon  = [];
for i = 1:length(astPortCon)
    % select only the inports of block (==> SrcBlock is non-empty)
    if ~isempty(astPortCon(i).SrcBlock)
        % select only the needed SrcPort (i.e. '1' or '2' or ...)
        if strcmpi(astPortCon(i).Type, stDest.sPort)
            stPortCon = astPortCon(i);
            break;
        end
    end
end
if isempty(stPortCon)
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', ...
        'Could not find the exact inport type of block "%s".', ...
        getfullname(stDest.hBlock));
end

if (stPortCon.SrcBlock == -1)
    % dest block is not connected to anything
    stSrc.hBlock = [];
    stSrc.sPort  = '';
elseif (bdroot(stPortCon.SrcBlock) == stPortCon.SrcBlock)
    % we are the topmost level of model (src is model itself)
    stSrc.hBlock = [];
    stSrc.sPort  = '';
else
    stSrc.hBlock = stPortCon.SrcBlock;
    stSrc.sPort  = sprintf('%i', stPortCon.SrcPort + 1);
end

if isempty(stSrc.sSigName)
    stSrc.sSigName = i_getSigName(stEnv, stDest, stSrc); 
end
end


%%
function stDest = i_getDestFromSrc(stEnv, stSrc)
stDest = [];
if (isempty(stSrc) || isempty(stSrc.hBlock))
    return;
end

sBlockType = lower(get_param(stSrc.hBlock, 'BlockType'));
switch sBlockType
    case 'subsystem'
        stDest = i_getSubsystemDest(stEnv, stSrc);
    case 'inport'
        stDest = i_getInportDest(stEnv, stSrc);
    case 'from'
        stDest = i_getFromDest(stEnv, stSrc);
    case 'mux'
        stDest = i_getMuxDest(stEnv, stSrc);
    case 'demux'
        stDest = i_getDemuxDest(stEnv, stSrc);
    case 'buscreator'
        stDest = i_getBusCreatorDest(stEnv, stSrc);
    case 'busselector'
        stDest = i_getBusSelectorDest(stEnv, stSrc);
    case 'modelreference'
        stDest = i_getModelReferenceDest(stEnv, stSrc);
    otherwise
        % assume that block is origin of signal, so there is no dest
end
end


%%
function stDest = i_getSubsystemDest(~, stSrc)
stDest = i_getDefaultDestSrc();
hOutport = find_system(stSrc.hBlock, ...
    'LookUnderMasks',    'all', ...
    'FollowLinks',       'on', ...
    'SearchDepth',       1, ...
    'BlockType',         'Outport', ...
    'Port',              stSrc.sPort);

stDest.hBlock  = hOutport;
stDest.sPort   = '1';
stDest.iSigIdx = stSrc.iSigIdx;
end

%%
function stDest = i_getModelReferenceDest(~, stSrc)
stDest = i_getDefaultDestSrc();
sModelName = get(stSrc.hBlock, 'ModelName');
hOutport = find_system(get_param(sModelName, 'Handle'), ...
    'LookUnderMasks',    'all', ...
    'FollowLinks',       'on', ...
    'SearchDepth',       1, ...
    'BlockType',         'Outport', ...
    'Port',              stSrc.sPort);

stDest.hBlock  = hOutport;
stDest.sPort   = '1';
stDest.iSigIdx = stSrc.iSigIdx;
end


%%
% for Inports we have to find corresponding inport of Subsystem block
function stDest = i_getInportDest(~, stSrc)
sParent = get_param(stSrc.hBlock, 'Parent');
if isempty(get_param(sParent, 'Parent'))
    % if parent of parent is empty, the inport is at the toplevel of model
    % so we have no corresponding subsystem
    stDest = [];
    return;
end

stDest = i_getDefaultDestSrc();
stDest.hBlock  = get_param(sParent, 'Handle');
stDest.sPort   = get_param(stSrc.hBlock, 'Port');
stDest.iSigIdx = stSrc.iSigIdx;
end


%%
function stDest = i_getFromDest(~, stSrc)
stDest = i_getDefaultDestSrc();
stDest.sPort   = '1';
stDest.iSigIdx = stSrc.iSigIdx;

sGotoTag      = get_param(stSrc.hBlock, 'GotoTag');
sFromParent   = get_param(stSrc.hBlock, 'Parent');
hFromParent   = get_param(sFromParent,  'Handle');
casCommonArgs = { ...
    'LookunderMasks',  'all', ...
    'FollowLinks',     'on', ...
    'GotoTag',         sGotoTag};
    
% 1) look for local Goto block
hGoto = find_system(hFromParent, ...
    'SearchDepth',    1, ...
    casCommonArgs{:}, ...
    'BlockType',      'Goto', ...
    'TagVisibility',  'local');
if ~isempty(hGoto)
    if (length(hGoto) > 1)
        error('ATGCV:MOD_ANA:INTERNAL_ASSERT', ...
            'Unexpected: Found more than one local Goto.');
    end
    
    stDest.hBlock = hGoto;
    return;
end

% 2) look for scoped Goto
hSys    = bdroot(stSrc.hBlock);
ahVisib = find_system(hSys, casCommonArgs{:}, ...
    'BlockType', 'GotoTagVisibility');
if ~isempty(ahVisib)
    % find lowest (in hierarchy) possible visibility block
    sLowestVisibParent = '';
    for i = 1:length(ahVisib)
        sVisibParent = get_param(ahVisib(i), 'Parent');
        if ~isempty(regexp(sFromParent, ...
                ['^', regexptranslate('escape', sVisibParent)], 'once'))
            if (length(sVisibParent) > length(sLowestVisibParent))
                sLowestVisibParent = sVisibParent;
            end
        end
    end
    
    % search from lowest common subsystem for corresponding scoped goto
    if ~isempty(sLowestVisibParent)
        hLowestVisibParent = get_param(sLowestVisibParent, 'Handle');
        hGoto = find_system(hLowestVisibParent, ...
            casCommonArgs{:}, ...
            'BlockType',      'Goto', ...
            'TagVisibility',  'scoped');
        if ~isempty(hGoto)
            if (length(hGoto) > 1)
                error('ATGCV:MOD_ANA:INTERNAL_ASSERT', ...
                    'Unexpected: Found more than one scoped Goto.');
            end
            
            stDest.hBlock = hGoto(1);
            return;
        end
    end
end
    
% 3) worst case: look for global Goto
hGoto = find_system(hSys, ...
    casCommonArgs{:}, ...
    'BlockType',     'Goto', ...
    'TagVisibility', 'global');
if ~isempty(hGoto)
    if (length(hGoto) > 1)
        error('ATGCV:MOD_ANA:INTERNAL_ASSERT', ...
            'Unexpected: Found more than one global Goto.');
    end
    
    stDest.hBlock = hGoto;
    return;
end

% if we are here, somthing went wrong
stDest = [];
end


%%
function stDest = i_getMuxDest(~, stSrc)

astPortCon = get_param(stSrc.hBlock, 'PortConnectivity');
abIsInport = true(size(astPortCon));
for i = 1:length(astPortCon)
    abIsInport(i) = (~isempty(astPortCon(i).SrcBlock) && ...
        ~isletter(astPortCon(i).Type(1)));
end
astPortCon = astPortCon(abIsInport); % only the inports

stCompPortWidths = get_param(stSrc.hBlock, 'CompiledPortWidths');
if ~isempty(stCompPortWidths)
    % with compiled info we have a better chance to find the right inport
    aiMaxPortIdx = cumsum(stCompPortWidths.Inport);
    iPortIdx = find(stSrc.iSigIdx <= aiMaxPortIdx, 1);
    if (iPortIdx > 1)
        iSigIdx = stSrc.iSigIdx - aiMaxPortIdx(iPortIdx - 1);
    else
        iSigIdx = stSrc.iSigIdx;
    end
else
    % just a guess here: assuming that only scalar signals enter mux block,
    % which of course doesn't have to be true
    iPortIdx = stSrc.iSigIdx;
    iSigIdx  = 1;
end
if (isempty(iPortIdx) || (iPortIdx > length(astPortCon)))
    stDest = [];
    return;
else
    stDest = i_getDefaultDestSrc();
    stDest.hBlock   = stSrc.hBlock;
    stDest.sPort    = sprintf('%i', iPortIdx);
    stDest.iSigIdx  = iSigIdx;
end
end


%%
function stDest = i_getDemuxDest(~, stSrc)
iPortIdx = str2double(stSrc.sPort);
stCompPortWidths = get_param(stSrc.hBlock, 'CompiledPortWidths');
if ~isempty(stCompPortWidths)
    % with compiled info we have a better chance to find the right inport
    if (iPortIdx > 1)
        aiPortWidths = stCompPortWidths.Outport;
        iSigIdx = sum([aiPortWidths(1:(iPortIdx - 1)), stSrc.iSigIdx]);
    else
        iSigIdx = stSrc.iSigIdx;
    end
else
    % just a guess here: assuming that only scalar signals leave demux block,
    % which of course doesn't have to be true
    iSigIdx  = iPortIdx;
end

% demux block has only one input port
stDest = i_getDefaultDestSrc();
stDest.hBlock   = stSrc.hBlock;
stDest.sPort    = '1';
stDest.iSigIdx  = iSigIdx;
end


%%
function stDest = i_getBusCreatorDest(stEnv, stSrc)
stDest = i_getMuxDest(stEnv, stSrc);
end


%%
function stDest = i_getBusSelectorDest(~, stSrc)

casCellInputs = get_param(stSrc.hBlock, 'InputSignals');
casIn = i_getBusSignalNames(casCellInputs);

sOut    = get_param(stSrc.hBlock, 'OutputSignals');
ccasOut = textscan(sOut, '%s', 'delimiter', ',');
casOut  = ccasOut{1};
bOutIsBus = strcmpi(get_param(stSrc.hBlock, 'OutputAsBus'), 'on');
if ~bOutIsBus
    if isempty(stSrc.sPort)
        casOut = casOut(1);
    else
        casOut = casOut(str2double(stSrc.sPort));
    end
end

stCompDims = get_param(stSrc.hBlock, 'CompiledPortDimensions');
if isempty(stCompDims)
    % since no info on compiled model --> 
    % assumption: every input signal is scalar (often not true!)
    aiInWidths = ones(size(casIn));
    
else
    aiInWidths = [];
    if (stCompDims.Inport(1) < 0)
        % perfect: all info for getting dimensions of subsignals is there
        aiInWidths = stCompDims.Inport(4:2:end);
        if (length(aiInWidths) ~= length(casIn))
            % something is wrong: number of dims and number of input signals is
            % not consistent --> try different strategy
            aiInWidths = [];
        end
    end
    
    if isempty(aiInWidths)
        % special case: check if input signals are all scalar
        stCompWidths = get_param(stSrc.hBlock, 'CompiledPortWidths');
        if (stCompWidths.Inport == length(casIn))
            % every incoming subsignal is scalar
            aiInWidths = ones(1, length(casIn));
        else
            % incoming subsignals are not scalar ==> we cannot successfully get
            % the right incoming index, so give it up
            aiInWidths = [];
        end
    end
end

if isempty(aiInWidths)
    iSigIdx = [];
else
    casOutSigs = {};
    aiOutWidths = [];
    for i = 1:length(casOut)
        abIsOut = strcmpi(casOut{i}, casIn) | ...
            strncmpi([casOut{i}, '.'], casIn, (length(casOut{i})+ 1));
        casOutSigs  = [casOutSigs, casIn(abIsOut)]; %#ok<AGROW>
        aiOutWidths = [aiOutWidths, aiInWidths(abIsOut)]; %#ok<AGROW>
    end
    aiMaxOutIdx = cumsum(aiOutWidths);    
    iOutSigIdx  = find(stSrc.iSigIdx <= aiMaxOutIdx, 1);
    if ~isempty(iOutSigIdx)
        sInSig = casOutSigs{iOutSigIdx};
        if (iOutSigIdx > 1)
            iSigIdx = stSrc.iSigIdx - aiMaxOutIdx(iOutSigIdx - 1);
        else
            iSigIdx = stSrc.iSigIdx;
        end

        iInSigIdx = find(strcmpi(sInSig, casIn));
        if (iInSigIdx > 1)
            iSigIdx = iSigIdx + sum(aiInWidths(1:iInSigIdx-1));
        end
    else
        iSigIdx = [];
    end
end

% BusSelector block has only one input port
stDest = i_getDefaultDestSrc();
stDest.hBlock   = stSrc.hBlock;
stDest.sPort    = '1';
stDest.iSigIdx  = iSigIdx;
end


%%
function casFullNames = i_getBusSignalNames(casCellNames)
casFullNames = cell(0);
for i = 1:length(casCellNames)
    if ischar(casCellNames{i})
        casFullNames{end + 1} = casCellNames{i}; %#ok<AGROW>
    else
        sRootName = casCellNames{i}{1};
        casFullNamesSub = i_getBusSignalNames(casCellNames{i}{2});
        for j = 1:length(casFullNamesSub)
            casFullNames{end + 1} = [sRootName, '.', casFullNamesSub{j}]; %#ok<AGROW>
        end
    end
end
end


%%
function sName = i_getCleanName(sName)
casClean = regexp(sName, '^<(.*)>$', 'tokens', 'once');
if ~isempty(casClean)
    sName = casClean{1};
end
end


function [stInfo, bIsValid] = atgcv_m01_signal_info_get(stEnv, stDest, bIsArgSrc)
% Get info on dest/src signal of block.
%
% function stInfo = atgcv_m01_signal_info_get(stEnv, stDest, bIsArgSrc)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)         environment struct
%     stDest            (struct)         struct with following fields
%      .hBlock          (handle)         handle of destination block
%      .sPort           (string)         port type of incoming(outgoing) signal 
%
%     bIsArgSrc         (bool)           true if argument is src instead of dest
%                                        (optional: default = false)
%
%   OUTPUT              DESCRIPTION
%     stInfo             (struct)         info data:
%      .astSigs          (array)          structs with following info 
%        .sName          (string)         name of subsignal
%        .sUserType      (string)         type of subsignal (might be an alias)
%        .sType          (string)         base type of subsignal (builtin or fixed-point-type)
%        .iWidth         (integer)        width of subsignal
%      .sSigKind         (string)         'simple' | 'bus' | 'composite' | 
%                                         'pseudo_bus'
%
%   REMARKS
% 
%
%   <et_copyright>


%% internal
%
%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 214424 $
%   Last modified: $Date: 2016-09-14 15:56:39 +0200 (Mi, 14 Sep 2016) $
%   $Author: ahornste $


%% input check
if (nargin < 3)
    bIsArgSrc = false;
end
stDest.iSigIdx  = 1;
stDest.sSigName = '';

%% default output
stInfo = struct( ...
    'astSigs',  [], ...
    'aiDim',    [], ...
    'sSigKind', '');
bIsValid = false;

%%
bIsBusStrictMode = i_isBusStrictMode(stDest.hBlock);
if bIsBusStrictMode
    i_validBusReadouts({'BusCreator', 'BusSelector', 'BusAssignment', 'SignalConversion'});
else
    i_validBusReadouts({'BusCreator', 'BusSelector', 'Mux'});
end

%% main
i_handleCheckedDest('clear'); % initialize global checked cache

if bIsArgSrc
    stSrc = stDest;
    [stSigInfo, bIsBus] = i_getSrcSigInfo(stSrc);
    if (bIsBusStrictMode && ~bIsBus)
        stReadoutSrc = [];
        oBus = [];
    else
        [stReadoutSrc, oBus] = i_findSrcBusReadout(stEnv, stSrc);
    end
else
    [stSigInfo, bIsBus] = i_getDestSigInfo(stDest);
    if (bIsBusStrictMode && ~bIsBus)
        stReadoutSrc = [];
        oBus = [];
    else
        [stReadoutSrc, oBus] = i_findDestBusReadout(stEnv, stDest); 
    end
end

bFoundConsistentReadout = false;
if ~isempty(stReadoutSrc)
    stReadoutInfo = i_getSrcSigInfo(stReadoutSrc);
    bFoundConsistentReadout = (stSigInfo.iWidth == stReadoutInfo.iWidth);
end

if bFoundConsistentReadout
    [stInfo.astSigs, stInfo.sSigKind] = i_readBusInfo(stEnv, stReadoutSrc, stSigInfo.sName);
    bIsValid = true;
else
    % life is simpler with a BusObject
    if ~isempty(oBus)
        stInfo.astSigs = ...
            atgcv_m01_bus_object_signal_info_get(stEnv, oBus, stSigInfo.sName, i_getResolver([], stReadoutSrc.hBlock));
        stInfo.sSigKind = 'bus';
        bIsValid = true;
    else
        % workaround/hack for special case: "auto" should be replaced by the most 
        % often used type: "double"
        if strcmp(stSigInfo.sType, 'auto')
            stSigInfo.sType = 'double';
        end
        stInfo.astSigs  = stSigInfo;
        stInfo.sSigKind = 'simple';
    end   
end

i_handleCheckedDest('clear'); % cleanup (just in case)
end




%%
function bIsBusStrictMode = i_isBusStrictMode(hBlock)
iLevel = atgcv_m01_persistent('iBusStrictLevel');
if isempty(iLevel)
    iLevel = i_getCurrentBusStrictLevel(bdroot(hBlock));
    atgcv_m01_persistent('iBusStrictLevel', iLevel);
end
bIsBusStrictMode = (iLevel > 0);
end


%%
% the following Levels are supported
%
%  'none' | 'warning'           ==  0
%  'ErrorLevel1'                ==  1 
%  'WarnOnBusTreatedAsVector'   ==  2
%  'ErrorOnBusTreatedAsVector'  ==  3
%
function iLevel = i_getCurrentBusStrictLevel(sModel)
iLevel = 0;
sCurrentLevel = get_param(sModel, 'StrictBusMsg');
switch sCurrentLevel 
    case 'ErrorLevel1'
        iLevel = 1;
    case 'WarnOnBusTreatedAsVector'
        iLevel = 2;
    case 'ErrorOnBusTreatedAsVector'
        iLevel = 3;
end
end


%%
% avoid checking dest that have already been checked --> keep list im memory
function varargout = i_handleCheckedDest(sCmd, varargin)
persistent astCheckedDest;

switch sCmd
    case 'is_checked'
        bIsChecked = false;
        if ~isempty(astCheckedDest)
            stDest = varargin{1};
            
            aiFind = find(stDest.hBlock == [astCheckedDest(:).hBlock]);
            for i = 1:length(aiFind)
                stFoundDest = astCheckedDest(aiFind(i));
                if strcmp(stFoundDest.sPort, stDest.sPort)
                    bIsChecked = true;
                    break;
                end
            end
        end
        varargout{1} = bIsChecked;
        
    case 'add_as_checked'
        stDest = varargin{1};
        
        if ~i_handleCheckedDest('is_checked', stDest)
            if isempty(astCheckedDest)
                astCheckedDest = stDest; 
            else
                astCheckedDest(end + 1) = stDest;
            end
        end
        
    case 'clear'
        astCheckedDest = [];
        
    otherwise
        error('ATGCV:MOD_ANA:ERROR', 'Internal error: Unknown command %s.', sCmd);        
end
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
function bCanPropagateName = i_canPropagateNameBlock(hBlock)
bCanPropagateName = strcmpi(get_param(hBlock, 'BlockType'), 'BusSelector');
bCanPropagateName = bCanPropagateName || i_isPropagatingBlock(hBlock);
end


%%
function [stReadoutSrc, oBus] = i_findSrcBusReadout(stEnv, stSrc)
stReadoutSrc = [];
oBus         = [];

if i_isBusReadout(stSrc)
    stReadoutSrc = stSrc;
    oBus = i_getBusObjectFromBlock(stSrc.hBlock);
else
    astCheckDest = [];
    [stSrc, stDest] = atgcv_m01_dest_src_find(stEnv, stSrc, true);
    if isempty(stDest)
        [stDest, astCheckDest] = i_getBusDest(stSrc);
        if isempty(stDest)
            return;
        end
    end
    if strcmpi(get_param(stDest.hBlock, 'BlockType'), 'Demux')
        return;
    end
    if isempty(astCheckDest)
        [stReadoutSrc, oBus] = i_findDestBusReadout(stEnv, stDest);
    else
        [stReadoutSrc, oBus] = i_findDestBusReadout(stEnv, stDest, astCheckDest);
    end
end
end


%%
function oBusObject = i_getBusObjectFromBlock(hBlock)
oBusObject = [];

if i_isUsingBusObject(hBlock)
    sBusName = get_param(hBlock, 'BusObject');
    if ~isempty(sBusName)
        hResolverFunc = atgcv_m01_generic_resolver_get(hBlock);
        [xResolvedBus, nScope] = feval(hResolverFunc, sBusName);
        if (nScope > 0)
            oBusObject = xResolvedBus;
        end
    end
end
end


%%
function bIsUsing = i_isUsingBusObject(hBlock)
% all blocks that can specify a BusObject
casPossibleBlocks = { ...
    'BusCreator', ...
    'Inport', ...
    'Outport'};
bIsUsing = ...
    any(strcmp(get_param(hBlock, 'BlockType'), casPossibleBlocks)) ...
    && strcmpi(get_param(hBlock, 'UseBusObject'), 'on');
end


%%
function [stReadoutSrc, oBus] = i_findDestBusReadout(stEnv, stDest, astCheckDest)
stReadoutSrc = [];
oBus         = [];

% shortcut for outports if possible
if (strcmpi('outport', get_param(stDest.hBlock, 'BlockType')) && i_isBusReadout(stDest))
    stReadoutSrc = [];
    oBus = i_getBusObjectFromBlock(stDest.hBlock);
    if ~isempty(oBus)
        return;
    end
end

if (nargin < 3)
    astCheckDest = repmat(stDest, 0, 0);
end

iCount = 0;
while (iCount < 1000)
    i_handleCheckedDest('add_as_checked', stDest); % memorize dest to avoid loops
    
    [stSrc, stDest] = atgcv_m01_dest_src_find(stEnv, stDest);
    if (isempty(stSrc) || isempty(stSrc.hBlock))
        return;
    end
    
    if i_isBusReadout(stSrc)
        if i_checkAllDestBus(stEnv, astCheckDest)
            stReadoutSrc = stSrc;
            oBus = i_getBusObjectFromBlock(stSrc.hBlock);
        end
        return;
    else
        if isempty(stDest)
            [stDest, astCheckDestThis] = i_getBusDest(stSrc);
            if ~isempty(astCheckDestThis)
                astCheckDest = [astCheckDest, astCheckDestThis]; %#ok<AGROW>
            end
        end
        if isempty(stDest)
            return;
        end
        if strcmpi(get_param(stDest.hBlock, 'BlockType'), 'Demux')
            return;
        end
        
        % shortcut for outports if possible
        if (strcmpi('outport', get_param(stDest.hBlock, 'BlockType')) && i_isBusReadout(stDest))
            stReadoutSrc = [];
            oBus = i_getBusObjectFromBlock(stDest.hBlock);
            if ~isempty(oBus)
                return;
            end
        end
    end
    iCount = iCount + 1; % safety counter
end
end


%%
function bAllDestBus = i_checkAllDestBus(stEnv, astDest)
bAllDestBus = true;
for i = 1:length(astDest)
    if ~i_handleCheckedDest('is_checked', astDest(i))
        bAllDestBus = bAllDestBus && ...
            ~isempty(i_findDestBusReadout(stEnv, astDest(i)));
        if ~bAllDestBus
            return;
        end
    end
end
end


%%
% all blocks that can handle bus signals without beeing virtual
function [stDest, astCheckDest] = i_getBusDest(stSrc)
astCheckDest = [];
switch lower(get_param(stSrc.hBlock, 'BlockType'))
    case {'signalspecification', 'zeroorderhold', 'ratetransition', 'unitdelay', 'memory'}
        stDest = i_getDefaultDest(stSrc);
    case 'merge'
        [stDest, astCheckDest] = i_getMultiInportDest(stSrc);
    case 'switch'
        % second input is the switch_signal, so do not use it
        [stDest, astCheckDest] = i_getMultiInportDest(stSrc, '2');
    case 'multiportswitch'
        % first input is the swich_signal, so do not use it
        [stDest, astCheckDest] = i_getMultiInportDest(stSrc, '1');
    otherwise
        % assume invalid block: i.e. a block that is _not_ bus-capable
        stDest = [];
end
end


%%
function [stDest, astCheckDest] = i_getMultiInportDest(stSrc, sForbiddenPort)
if (nargin < 2)
    sForbiddenPort = '';
end
astPortCon = get_param(stSrc.hBlock, 'PortConnectivity');
abIsValid = true(size(astPortCon));
for i = 1:length(astPortCon)
    abIsValid(i) = (~isempty(astPortCon(i).SrcBlock) && ...
        ~isletter(astPortCon(i).Type(1)) && ...
        ~strcmp(astPortCon(i).Type, sForbiddenPort));
end
astPortCon = astPortCon(abIsValid); % only the allowed inports
if ~isempty(astPortCon)
    % use the first connection as dest
    stDest = stSrc;
    stDest.sPort = astPortCon(1).Type;
    astPortCon(1) = [];
    
    % use the rest for checking
    if ~isempty(astPortCon)
        astCheckDest = repmat(stDest, 1, length(astPortCon));
        for i = 1:length(astPortCon)
            astCheckDest(i).sPort = astPortCon(i).Type;
        end
    else
        astCheckDest = [];
    end
else
    stDest = [];
    astCheckDest = [];
end
end


%%
% just use the first (or provided) inport of the block as new dest
function stDest = i_getDefaultDest(stSrc)
stDest = stSrc;
stDest.sPort = '1';
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
function [stSigInfo, bIsBus] = i_getSrcSigInfo(stSrc)
stSigInfo = i_getInitSigInfo();

stPortHandles = get_param(stSrc.hBlock, 'PortHandles');
hPort = stPortHandles.Outport(str2double(stSrc.sPort));
sName = i_getCleanName(get_param(hPort, 'Name'));
if (isempty(sName) && i_canPropagateNameBlock(stSrc.hBlock))
    sName = i_getPropagatedSignalRootName(hPort);
end
stSigInfo.sName     = sName;
stSigInfo.sUserType = get_param(hPort, 'CompiledPortDataType');
stSigInfo.sType     = i_evaluateType(stSigInfo.sUserType, i_getResolver(hPort, stSrc.hBlock));
stSigInfo.iWidth    = get_param(hPort, 'CompiledPortWidth');
stSigInfo.aiDim     = get_param(hPort, 'CompiledPortDimensions');

bIsBus = get_param(hPort, 'CompiledPortBusMode');
end


%%
function hResolverFunc = i_getResolver(hPort, hBlock)
if isempty(hBlock)
    if isempty(hPort)
        hResolverFunc = atgcv_m01_generic_resolver_get();
    else
        hResolverFunc = atgcv_m01_generic_resolver_get(hPort);
    end
else
    hResolverFunc = atgcv_m01_generic_resolver_get(hBlock);
end
end


%%
function [stSigInfo, bIsBus] = i_getDestSigInfo(stDest)
stSigInfo = i_getInitSigInfo();

stPortHandles = get_param(stDest.hBlock, 'PortHandles');
hPort = stPortHandles.Inport(str2double(stDest.sPort));
sName = i_getCleanName(get_param(hPort, 'Name'));
if isempty(sName)
    hLine = get_param(hPort, 'Line');
    if (hLine > 0)
        hSrcBlock = get_param(hLine, 'SrcBlockHandle');
        % negative hSrcBlock means an _unconnected_ line
        if ((hSrcBlock > 0) && i_canPropagateNameBlock(hSrcBlock))
            hSrcPort = get_param(hLine, 'SrcPortHandle');
            sName = i_getPropagatedSignalRootName(hSrcPort);
        end
    end
end
stSigInfo.sName     = sName;
stSigInfo.sUserType = get_param(hPort, 'CompiledPortDataType');
stSigInfo.sType     = i_evaluateType(stSigInfo.sUserType, i_getResolver(hPort, stDest.hBlock));
stSigInfo.iWidth    = get_param(hPort, 'CompiledPortWidth');
stSigInfo.aiDim     = get_param(hPort, 'CompiledPortDimensions');

bIsBus = get_param(hPort, 'CompiledPortBusMode');
end


%%
function sName = i_getPropagatedSignalRootName(hPort)
sName = '';
bIsValid = false;

if i_isBusStrictMode(hPort)
    [sName, bIsValid] = i_getNameFromSignalHierarchy(hPort);
end
if (bIsValid && ~isempty(sName))
    return;
end

% sometimes we get an empty SignalName from hierarchy but 
sPropagName = get_param(hPort, 'PropagatedSignals');
if isempty(strfind(sPropagName, ','))
    sPropagName = i_getCleanName(sPropagName);
else
    sPropagName = '';
end

% now we need to decide whom to trust
% a) the SignalHierarchy
% b) the PropagatedSignals
if bIsValid
    % sometimes the PropatedName is the name of the one Child-Signal of the
    % Root-Signal:
    % if this is the case, keep the Name from the SignalHierarchy
    % otherwise use the PropagName
    if ~isempty(sPropagName)
        [bHasSingleChild, sChildName] = i_hasSingleChild(hPort);
        if (~bHasSingleChild || ~strcmpi(sChildName, sPropagName))
            sName = sPropagName;
        end
    end
else
    % if the SignalHierarchy name is not valid, always trust the PropagatedSig
    sName = sPropagName;
end
end


%%
function[bHasSingleChild, sChildName] = i_hasSingleChild(hPort)
bHasSingleChild = false;
sChildName = '';
try
    stSignalHierarchy = get_param(hPort, 'SignalHierarchy');
    if (~isempty(stSignalHierarchy) && (length(stSignalHierarchy.Children) == 1))
        bHasSingleChild = true;
        sChildName = stSignalHierarchy.Children.SignalName;
    end
catch %#ok<CTCH>
end
end


%%
function [sName, bIsValid] = i_getNameFromSignalHierarchy(hPort)
sName = '';
bIsValid = false;
try
    sType = get_param(hPort, 'CompiledBusType');
    if strcmpi(sType, 'NOT_BUS')
        return;
    end
    stSignalHierarchy = get_param(hPort, 'SignalHierarchy');
    if ~isempty(stSignalHierarchy)
        sName = stSignalHierarchy.SignalName;
        bIsValid = true;
    end
catch %#ok<CTCH>
end
end


%%
function bIsReadout = i_isBusReadout(stSrc)
bIsReadout = false;
sBlockType = get_param(stSrc.hBlock, 'BlockType');

% 1) SL readouts
if any(strcmpi(sBlockType, i_validBusReadouts()))
    bIsReadout = true;
end

% 2) ModelReferences (are required to communicate BusSignalType via BusObjects)
if (~bIsReadout && strcmpi(sBlockType, 'ModelReference'))
    iPort = str2double(stSrc.sPort);
    stBusInfo = get_param(stSrc.hBlock, 'CompiledPortBusMode');
    bIsReadout = stBusInfo.Outport(iPort);
end

% 3) Inport/Outport _if_ they have a BusObject
if (~bIsReadout && any(strcmpi(sBlockType, {'Inport', 'Outport'})))
    bIsReadout = strcmpi(get_param(stSrc.hBlock, 'UseBusObject'), 'on');
end
end


%%
function varargout = i_validBusReadouts(varargin)
persistent casValidReadouts;

if (nargin > 0)
    casValidReadouts = varargin{1};
end
if (nargout > 0)
    varargout{1} = casValidReadouts;
end
end


%%
function [astSigs, sSigKind] = i_readBusInfo(stEnv, stSrc, sRootName)
sBlockType = lower(get_param(stSrc.hBlock, 'BlockType'));
switch sBlockType
    case {'busassignment', 'buscreator'}
        astBusStruct = get_param(stSrc.hBlock, 'BusStruct');
        astSigs = i_resolveBusStruct(stEnv, astBusStruct, sRootName);
        sSigKind = 'bus';
        
    case 'signalconversion'
        stPortHandles = get_param(stSrc.hBlock, 'PortHandles');        
        astSigs = i_resolvePortSignalHierarchy(stEnv, stPortHandles.Outport, sRootName);
        sSigKind = 'bus';
        
    case 'busselector'
        % get all signals running into selector
        astBusStruct = get_param(stSrc.hBlock, 'BusStruct');
        astInSigs    = i_resolveBusStruct(stEnv, astBusStruct);
        
        % now get the right outputs
        sOut    = get_param(stSrc.hBlock, 'OutputSignals');
        ccasOut = textscan(sOut, '%s', 'delimiter', ',');
        casOut  = ccasOut{1};
        bOutIsBus = strcmp(get_param(stSrc.hBlock, 'OutputAsBus'), 'on');
        if ~bOutIsBus
            if isempty(stSrc.sPort)
                casOut = casOut(1);
            else
                casOut = casOut(str2double(stSrc.sPort));
            end
        end
        
        casRemovePattern = cell(size(casOut));
        for j = 1:length(casOut)
            % remove name part till and including the last delimiter "."
            ccRemove = regexp(casOut{j}, '(.*\.)', 'once', 'tokens');
            if isempty(ccRemove)
                casRemovePattern{j} = '';
            else
                casRemovePattern{j} = ['^', ccRemove{1}];
            end
        end
        
        % modify root part of component name
        astSigs = repmat(astInSigs(1), 0, 0);
        for j = 1:length(casOut)
            sOutName = casOut{j};
            sPattern1 = ['^', regexptranslate('escape', sOutName), '$'];
            sPattern2 = ['^', regexptranslate('escape', sOutName), '\.'];
            sPattern  = [sPattern1, '|', sPattern2];
            
            jKnownNames = java.util.HashSet(numel(astInSigs));
            for i = 1:numel(astInSigs)
                sInName = astInSigs(i).sName;
                if jKnownNames.contains(sInName)
                    % sometimes it is possible that two input names are equal
                    % in this case Simulink selects the first one!
                    % ==> so, skip inner loop if input name is
                    % the same as a previous one
                    continue;
                else
                    jKnownNames.add(sInName);
                end
                
                if ~isempty(regexp(astInSigs(i).sName, sPattern, 'once'))
                    astSigs(end + 1) = astInSigs(i); %#ok<AGROW>
                    astSigs(end).sName = regexprep(astSigs(end).sName, casRemovePattern{j}, '');
                end
            end
        end
        
        % add/replace root name info
        if bOutIsBus
            % if output is a bus, the root name is prepended
            sPrefix = [sRootName, '.'];
            for i = 1:length(astSigs)
                astSigs(i).sName = [sPrefix, astSigs(i).sName];
            end
        else
            % 1) if output is component it keeps its root name
            % 2) however provided root name has priority, so if it is not empty, replace current root name
            for i = 1:length(astSigs)
                sReplacePatt = ['^', regexptranslate('escape', strtok(astSigs(i).sName, '.'))];
                astSigs(i).sName = regexprep(astSigs(i).sName, sReplacePatt, sRootName);
            end                
        end
        
        if (length(astSigs) > 1)
            sSigKind = 'bus';
        else
            iPort = str2double(stSrc.sPort);
            astBusInfo = get_param(stSrc.hBlock, 'CompiledPortBusMode');
            bRealBus = astBusInfo.Outport(iPort);
            if ~bRealBus
                astInfo = get_param(stSrc.hBlock, 'CompiledPortDataTypes');
                astSigs(1).sUserType = astInfo.Outport{iPort};
                astSigs(1).sType = astSigs(1).sUserType;
            end
            if bRealBus
                sSigKind = 'bus';
            else
                sSigKind = 'pseudo_bus';
                % pseudo-bus has repeated name level
                if ~isempty(astSigs(1).sName)
                    astSigs(1).sName = [astSigs(1).sName, '.', astSigs(1).sName];
                end
            end
        end
        
    case 'mux'
        astSigs  = i_getMuxBusInfo(stEnv, stSrc.hBlock, sRootName);                
        sSigKind = 'composite';
    
    case {'inport', 'outport'}
        % expecting a BusObject here
        sObjectName = get_param(stSrc.hBlock, 'BusObject');
        astSigs = atgcv_m01_bus_object_signal_info_get(stEnv, sObjectName, sRootName, i_getResolver([], stSrc.hBlock));
        sSigKind = 'bus';
        
    case 'modelreference'
        iPort = str2double(stSrc.sPort);
        stInfo = get_param(stSrc.hBlock, 'CompiledPortDataTypes');
        sObjectName = stInfo.Outport{iPort};
        astSigs = ...
            atgcv_m01_bus_object_signal_info_get(stEnv, sObjectName, sRootName, i_getResolver([], stSrc.hBlock));
        sSigKind = 'bus';
        
    otherwise
        error('ATGCV:MOD_ANA:ERROR', 'Not implemented yet.');
end
end


%%
function hPortHandle = i_getSourcePortHandle(hSrcBlock, iSrcPort)
stPortHandles = get_param(hSrcBlock, 'PortHandles');
if (iSrcPort > 0)
    hPortHandle = stPortHandles.Outport(iSrcPort);
 else 
    % must be an unconnected input of bus creator
    % get port from the inport of the srcBlock
    hPortHandle = stPortHandles.Inport(abs(iSrcPort));
end            
end


%%
function astSigs = i_resolveBusStruct(stEnv, astBusStruct, sRootName)
stSig = i_getInitSigInfo();

astSigs = repmat(stSig, 1, 0);
for i = 1:length(astBusStruct)
    if i_isBusSignalBus(astBusStruct(i))
        if (nargin < 3)
            sName = astBusStruct(i).name;
        else
            sName = [sRootName, '.', astBusStruct(i).name];
        end
        
        hPortHandle = i_getSourcePortHandle(astBusStruct(i).src, astBusStruct(i).srcPort);
        sType = get_param(hPortHandle, 'CompiledPortDataType');
        hResolverFunc = i_getResolver(hPortHandle, []);
        
        [bIsBusType, oBus] = i_isBusType(sType, hResolverFunc);
        if bIsBusType
            astCompSigs = atgcv_m01_bus_obj_store('get', sType, oBus, sName);
            if isempty(astCompSigs)
                astCompSigs = atgcv_m01_bus_object_signal_info_get(stEnv, oBus, sName, hResolverFunc);
                atgcv_m01_bus_obj_store('set', sType, oBus, astCompSigs);
            end
            
        elseif strcmp(sType, 'auto')
            stBusSrc = struct( ...
                'hBlock', astBusStruct(i).src, ...
                'sPort',  num2str(astBusStruct(i).srcPort)); 
            [stReadoutSrc, oBus] = i_findSrcBusReadout(stEnv, stBusSrc);
            if ~isempty(oBus)
                astCompSigs = atgcv_m01_bus_object_signal_info_get(stEnv, oBus, sName, hResolverFunc);
            else
                astCompSigs = i_readBusInfo(stEnv, stReadoutSrc, sName);
            end
        else
            if ~isempty(astBusStruct(i).signals)
                astCompSigs = i_resolveBusStruct(stEnv, astBusStruct(i).signals, sName);
            else
                astCompSigs = i_resolvePortSignalHierarchy(stEnv, hPortHandle, sName, sType);
            end
        end
        
        astSigs = [astSigs, astCompSigs]; %#ok<AGROW>

    else
        % elementary signal component found
        astSigs(end + 1) = stSig; %#ok<AGROW>
        
        if (nargin < 3)
            astSigs(end).sName = astBusStruct(i).name;
        else
            astSigs(end).sName = [sRootName, '.', astBusStruct(i).name];
        end
        
        hPortHandle = i_getSourcePortHandle(astBusStruct(i).src, astBusStruct(i).srcPort);        
        sType = get_param(hPortHandle, 'CompiledPortDataType');
        hResolverFunc = i_getResolver(hPortHandle, []);

        % compiled info only available in compiled mode
        if ~isempty(sType)
            astSigs(end).sUserType = sType;
            astSigs(end).sType     = i_evaluateType(astSigs(end).sUserType, hResolverFunc);
            astSigs(end).iWidth    = get_param(hPortHandle, 'CompiledPortWidth');
            astSigs(end).aiDim     = get_param(hPortHandle, 'CompiledPortDimensions');

            % get the source port
            iSrcPort = astBusStruct(i).srcPort;
            if (iSrcPort > 0)
                if i_isBusType(astSigs(end).sType, hResolverFunc)
                    [sElemType, iElemWidth] = ...
                        i_getBusElementType(stEnv, astSigs(end).sType, astSigs(end).sName, hResolverFunc);                    
                    if ~strcmp(sElemType, astSigs(end).sType)
                        astSigs(end).sUserType = sElemType;
                        astSigs(end).sType     = astSigs(end).sUserType;
                        astSigs(end).iWidth    = iElemWidth;                        
                    end
                end
            end            
        end            
    end
end
end


%%
function astSigs = i_resolvePortSignalHierarchy(stEnv, hPortHandle, sName, sType)
if (nargin < 4)
    sType = get_param(hPortHandle, 'CompiledPortDataType');
    if (nargin < 3)
        % TODO: ???? is this the right approach to get the name ????
        sName = get_param(hPortHandle, 'SignalNameFromLabel');
    end
end
stSignalHierarchy = get_param(hPortHandle, 'SignalHierarchy');
if isempty(stSignalHierarchy)
    astSigs = repmat(i_getInitSigInfo(), 0, 0);
    return;
end
stSignalHierarchy.SignalName = sName;
astSigs = i_resolveSignalHierarchy(stEnv, stSignalHierarchy, sType, i_getResolver(hPortHandle, []));
if isempty(astSigs)
    return;
end

caiDims = i_getIndividualSignalDimensions(hPortHandle);
nSigs = length(astSigs);
if (nSigs == length(caiDims))
    for k = 1:nSigs
        astSigs(k).aiDim = caiDims{k};
        if (length(astSigs(k).aiDim) < 3)
            % simple sig
            astSigs(k).iWidth = prod(astSigs(k).aiDim);
        else
            astSigs(k).iWidth = prod(astSigs(k).aiDim(2:end));
        end
    end
end
end


%%
function astSigs = i_resolveSignalHierarchy(stEnv, stSignalHierarchy, sType, hResolverFunc)
if ~isempty(stSignalHierarchy.BusObject)
    astSigs = atgcv_m01_bus_object_signal_info_get(stEnv, ...
        stSignalHierarchy.BusObject, stSignalHierarchy.SignalName, hResolverFunc);
else
    if isempty(stSignalHierarchy.Children)
        astSigs = i_getInitSigInfo();
        astSigs.sUserType = sType;
        astSigs.sType     = astSigs.sUserType;
        astSigs.sName     = stSignalHierarchy.SignalName;

        %!Note: we do not have any width info here; just use one for now;
        %       BUT this will be _wrong_ in general!
        astSigs.iWidth = 1;
        astSigs.aiDim  = [1 1];
    else
        sRootName = stSignalHierarchy.SignalName;
        stChild = stSignalHierarchy.Children(1); 
        stChild.SignalName = [sRootName, '.', stChild.SignalName];
        astSigs = i_resolveSignalHierarchy(stEnv, stChild, sType, hResolverFunc);
        for i = 2:length(stSignalHierarchy.Children)
            stChild = stSignalHierarchy.Children(i); 
            stChild.SignalName = [sRootName, '.', stChild.SignalName];
            astSigs = [astSigs, i_resolveSignalHierarchy(stEnv, stChild, sType, hResolverFunc)]; %#ok<AGROW>
        end
    end
end
end


%%
function caiDims = i_getIndividualSignalDimensions(hBlockPort)
caiDims = {};

aiDims = get_param(hBlockPort, 'CompiledPortDimensions');
if (~isempty(aiDims) && (aiDims(1) == -2))
    nSigs = aiDims(2);
    aiDims = aiDims(3:end);
    caiDims = cell(1, nSigs);
    
    bSuccess = true;
    iIdx = 1;
    for i = 1:nSigs
        if (iIdx > length(aiDims))
            bSuccess = false;
            break;
        end
        try
            if (aiDims(iIdx) > 1)
                % Matrix Signal
                caiDims{i} = aiDims(iIdx:iIdx+2);
                iIdx = iIdx + 3;
            else
                % Simple Signal
                caiDims{i} = aiDims(iIdx:iIdx+1);
                iIdx = iIdx + 2;
            end
        catch oEx
            bSuccess = false;
            break;
        end
    end
    if ~bSuccess
        caiDims = {};
    end
end
end


%%
function bIsBus = i_isBusSignalBus(stBusStruct)
bIsBus = ~isempty(stBusStruct.signals);

% Do a re-check if we have the Strict mode available
% e.g. for Conti models we have sometimes the wrong info with empty 
%      stBusStruct.signals
if (~bIsBus && i_isBusStrictMode())
    if ~isempty(stBusStruct.src)
        hPortHandle = i_getSourcePortHandle(stBusStruct.src, stBusStruct.srcPort);
        sBusType = get_param(hPortHandle, 'CompiledBusType');        
        bIsBus = ~strcmpi(sBusType, 'NOT_BUS');
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


%%
function astSigs = i_getMuxBusInfo(stEnv, hMux, sRootName)
stSig = i_getInitSigInfo();

astSigs = repmat(stSig, 0, 0);    

stPorts = get_param(hMux, 'PortHandles');
nIn = length(stPorts.Inport);
for i = 1:nIn
    stDest = struct( ...
        'hBlock',   hMux, ...
        'sPort',    sprintf('%i', i));
    
    stInfo = atgcv_m01_signal_info_get(stEnv, stDest);
    bIsPseudo = strcmpi(stInfo.sSigKind, 'pseudo_bus');
    for j = 1:length(stInfo.astSigs)
        sName = stInfo.astSigs(j).sName;
        if (isempty(sName) || (sName(1) == '.'))
            % if signal is unnamed, use the signal name according to incoming
            % signal port number
            sName = ['signal', stDest.sPort, sName]; %#ok<AGROW>
        end
        if bIsPseudo
            % if we have a pseudo_bus from a selector do _not_ use the component
            % name
            sName = regexprep(sName, '\..*$', '', 'once');
        end
        stInfo.astSigs(j).sName = [sRootName, '.', sName];
        astSigs(end + 1) = stInfo.astSigs(j); %#ok<AGROW>
    end
end

% heurstics: If Simulink finds multiple inputs with the same name, it appends
% a ' (signal %i)' for _every_ name.
nSubSig = length(astSigs);
if (length(unique({astSigs(:).sName})) < nSubSig)
    for i = 1:nSubSig
        astSigs(i).sName = [astSigs(i).sName, sprintf(' (signal %i)', i)];
    end
end
end


%%
function [bIsBus, oBus] = i_isBusType(sType, hResolverFunc)
bIsBus = false;
oBus = [];

if i_isBuiltInSignalType(sType)
    return;
end

try
    [xResolvedType, nScope] = feval(hResolverFunc, sType);
    if (nScope > 0)
        bIsBus = isa(xResolvedType, 'Simulink.Bus');
        if bIsBus
            oBus = xResolvedType;
        end
    end
catch
end
end


%%
function bIsBuiltIn = i_isBuiltInSignalType(sCheckType)
persistent casTypes;

if isempty(casTypes)
    casTypes = {  ...
        'double', ...
        'single', ...
        'int8',   ...
        'uint8',  ...
        'int16',  ...
        'uint16', ...
        'int32',  ...
        'uint32', ...
        'boolean'};
end
bIsBuiltIn = any(strcmpi(sCheckType, casTypes));

% if not built-in, check fixed-types
if ~bIsBuiltIn
    bIsBuiltIn = ~isempty(regexp(sCheckType, '^[s,u]fix', 'once'));
end
end


%%
function sEvalType = i_evaluateType(sType, hResolverFunc)
sEvalType = sType;
stTypeInfo = ep_sl_type_info_get(sType, hResolverFunc);
if stTypeInfo.bIsValidType
    sEvalType = stTypeInfo.sEvalType;
end
end


%%
function [sElemType, iWidth] = i_getBusElementType(stEnv, sBusType, sElemName, hResolverFunc)
sElemType = sBusType;
iWidth = 1;

try
    [oBusObject, nScope] = feval(hResolverFunc, sBusType);
    if ((nScope > 0) && isa(oBusObject, 'Simulink.Bus'))
        astSigs = atgcv_m01_bus_object_signal_info_get(stEnv, oBusObject, '', hResolverFunc);
        sElemName = ['.', sElemName];
        % look for the element name at the _end_ of the signal name
        sMatcher = [regexptranslate('escape', sElemName), '$'];
        for i = 1:length(astSigs)
            stSig = astSigs(i);
            
            % AlHo: TODO ASAP!!!
            % change this algo
            % currently only the first Match is evaluated <-- this is errorprone
            % there could be multiple Elements like "x.a", "y.a" matching the
            % element name ".a" --> this needs to be resolved cleanly
            if ~isempty(regexp(stSig.sName, sMatcher, 'once'))
                sElemType = stSig.sType;
                iWidth    = stSig.iWidth;
                break;
            end
        end
    end
catch  %#ok just ignore
end
end

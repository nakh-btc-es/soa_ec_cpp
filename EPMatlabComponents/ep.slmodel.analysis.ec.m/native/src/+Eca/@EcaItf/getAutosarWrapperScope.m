function [oWrapRootScope, aoRunnableScopes] = getAutosarWrapperScope(oEca)
% Create Root scope object representing the wrapper subsystem

oWrapRootScope = Eca.MetaScope;
oWrapRootScope.bIsRootScope = true;
oWrapRootScope.bScopeIsSubsystem = true;
oWrapRootScope.bScopeIsModelBlock = false;
oWrapRootScope.bIsWrapperModel = true;

%Subsystem info
oWrapRootScope.sSubSystemName = get_param(oEca.sAutosarWrapperRootSubsystem, 'Name');
oWrapRootScope.sSubSystemFullName = oEca.sAutosarWrapperRootSubsystem;
oWrapRootScope.sSubSystemAccess = oEca.sAutosarWrapperRootSubsystem;
oWrapRootScope.nHandle = get_param(oEca.sAutosarWrapperRootSubsystem, 'handle');

%Sampletime
oWrapRootScope.nSampleTime = oEca.getSubsystemCompiledSampleTime(oWrapRootScope.nHandle);

%Function info
% Note: for wrappers we can have
% a) Wrapper code that was stubbed              <--> incomplete Wrapper
% b) Wrapper code that was generated from model <--> complete Wrapper
%
% for the second case we do not have any wrapper code info at this moment
% TODO: for now just fake it; longterm: replace it by a better data flow
casStubIncludePaths = {};
stWrapperCodeInfo = oEca.stAutosarWrapperCodeInfo;
bIsCompleteWrapper = isempty(stWrapperCodeInfo);
if bIsCompleteWrapper
    stCInfo = oEca.getCodeInfoModel();
    oWrapRootScope.sCFunctionName = stCInfo.sCFunctionName;
    oWrapRootScope.sInitCFunctionName = stCInfo.sInitCFunctionName;
    oWrapRootScope.sCFunctionDefinitionFileName = stCInfo.sCFunctionDefinitionFileName;
    oWrapRootScope.sCFunctionDefinitionFile = stCInfo.sCFunctionDefinitionFile;
    oWrapRootScope.sEPCFunctionPath = stCInfo.sEPCFunctionPath;
else
    oWrapRootScope.sCFunctionName = stWrapperCodeInfo.sStepFunName;
    oWrapRootScope.sInitCFunctionName = stWrapperCodeInfo.sInitFunName;
    oWrapRootScope.sCFunctionDefinitionFileName = char(Eca.EcaItf.FileName(stWrapperCodeInfo.sCFile));
    oWrapRootScope.sCFunctionDefinitionFile = stWrapperCodeInfo.sCFile;
    oWrapRootScope.sEPCFunctionPath = [oWrapRootScope.sCFunctionDefinitionFileName, ':1:',oWrapRootScope.sCFunctionName];    
    casStubIncludePaths = stWrapperCodeInfo.casIncludePaths;
end

%CodeGenPath
oWrapRootScope.sCodegenPath = fileparts(oWrapRootScope.sCFunctionDefinitionFile);

%Pre step function
oWrapRootScope.sPreStepCFunctionName = oEca.sPreStepCFunctionName;

%Analyse the Runnables Scopes as children scope of the wrapper
bAnalyzeRunChldScopes = oEca.stActiveConfig.ScopeCfg.AnalyzeScopesHierarchy;
aoRunnableScopes = oEca.getAutosarRunnableScopes(oWrapRootScope, bAnalyzeRunChldScopes, oEca.sAutosarWrapperRefSubsystem);

if oEca.bDiagMode
    for iRun = 1:numel(aoRunnableScopes)
        sLink = sprintf('<a href = "matlab:open_system(''%s'');hilite_system(''%s'')">%s</a>',...
            oEca.sModelName,aoRunnableScopes(iRun).sSubSystemFullName,aoRunnableScopes(iRun).sSubSystemFullName);
        fprintf('\n## Scope %s has been detected \n',sLink);
    end
end

%Runnables as children scopes of this root scope
oWrapRootScope.oaChildrenScopes = aoRunnableScopes;

%Sources files
if bIsCompleteWrapper
    oWrapRootScope.astCodegenSourcesFiles = aoRunnableScopes(1).astCodegenSourcesFiles;
else
    oWrapRootScope.astCodegenSourcesFiles = [struct(...
        'path', oWrapRootScope.sCFunctionDefinitionFile, ...
        'codecov', true, ...
        'hide', false), aoRunnableScopes(1).astCodegenSourcesFiles];
end
%Header files
oWrapRootScope.casCodegenHeaderFiles = unique(...
    regexprep([oEca.findHeaderFiles(fileparts(oWrapRootScope.sCFunctionDefinitionFile)), ...
    aoRunnableScopes(1).casCodegenHeaderFiles],'/|\', filesep),'stable');

%Include paths (append Plugin "Includes" directory)
oWrapRootScope.casCodegenIncludePaths = unique(...
    regexprep([fileparts(oWrapRootScope.sCFunctionDefinitionFile), ...
    aoRunnableScopes(1).casCodegenIncludePaths, ...
    casStubIncludePaths],'/|\', filesep),'stable');
%Defines
oWrapRootScope.astDefines = aoRunnableScopes(1).astDefines;

% Inports/Outports of wrapper Root Scope
aoRunInputItfs = i_getUniqRunnablesRootIOItfs([aoRunnableScopes(:).oaInputs]);
aoRunOutputItfs = i_getUniqRunnablesRootIOItfs([aoRunnableScopes(:).oaOutputs]);

i_portBlockToSignalManager('clear');
if oEca.bIsWrapperComplete
    [oWrapRootScope.oaInputs, oWrapRootScope.oaOutputs] = i_createWrapperInterfacesBySigPropag( ...
        oWrapRootScope, ...
        oEca.sAutosarWrapperVariantSubsystem, ...
        aoRunInputItfs, ...
        aoRunOutputItfs);
else
    warning('EP:EC:LEGACY_WRAPPER', ...
        'You are using a legacy wrapper that will not be supported anymore in future releases.');
    [oWrapRootScope.oaInputs, oWrapRootScope.oaOutputs] = i_createWrapperInterfacesByMatchingName( ...
        oWrapRootScope, ...
        aoRunInputItfs, ...
        aoRunOutputItfs);
end

%Locals
oWrapRootScope.oaLocals = [aoRunnableScopes(:).oaLocals];

%Parameters
oWrapRootScope.oaParameters = oEca.aoModelWiseCalParams;

%Defines
oWrapRootScope.oaDefines = [aoRunnableScopes(:).oaDefines];
end


%%
function [aoInputs, aoOutputs] = i_createWrapperInterfacesBySigPropag(oRootScope, sVariantSub, aoRunInputItfs, aoRunOutputItf)
mNameToRootPort = i_mapPortNamesToRootPort(sVariantSub);
hRootScope = get_param(oRootScope.sSubSystemFullName, 'handle');

mPortToArComponentRootSignal = containers.Map;
aoInputs = [];
for i = 1:numel(aoRunInputItfs)
    oRunnableItf = aoRunInputItfs(i);
    sPortNameOrig = get_param(oRunnableItf.hRootIOSrcBlk, 'Name');
    sPortName = i_normalizePortName(sPortNameOrig);
    
    if mNameToRootPort.isKey(sPortName)
        hWrapperPortBlock = mNameToRootPort(sPortName);
    else
        % fallback: if not found by signal propagation, try to find by name
        hWrapperPortBlock = i_findPortByName(hRootScope, 'Inport', sPortNameOrig);
    end
    if ~isempty(hWrapperPortBlock)
        if mPortToArComponentRootSignal.isKey(sPortName)
            oSig = mPortToArComponentRootSignal(sPortName);
        else
            oSig = i_getSigFromPortBlock(oRunnableItf.hRootIOSrcBlk);
            mPortToArComponentRootSignal(sPortName) = oSig;
        end
        oItf = i_copyAndAdaptToWrapper(oRunnableItf, oRootScope, hWrapperPortBlock, oSig);
        aoInputs = [aoInputs, oItf]; %#ok<AGROW>
    end
end

aoOutputs = [];
for i = 1:numel(aoRunOutputItf)
    oRunnableItf = aoRunOutputItf(i);
    sPortNameOrig = get_param(oRunnableItf.hRootIOSrcBlk, 'Name');
    sPortName = i_normalizePortName(sPortNameOrig);
    
    if mNameToRootPort.isKey(sPortName)
        hWrapperPortBlock = mNameToRootPort(sPortName);
    else
        % fallback: if not found by signal propagation, try to find by name
        hWrapperPortBlock = i_findPortByName(hRootScope, 'Outport', sPortNameOrig);
    end
    if ~isempty(hWrapperPortBlock)
        if mPortToArComponentRootSignal.isKey(sPortName)
            oSig = mPortToArComponentRootSignal(sPortName);
        else
            oSig = i_getSigFromPortBlock(oRunnableItf.hRootIOSrcBlk);
            mPortToArComponentRootSignal(sPortName) = oSig;
        end
        oItf = i_copyAndAdaptToWrapper(oRunnableItf, oRootScope, hWrapperPortBlock, oSig);
        aoOutputs = [aoOutputs, oItf]; %#ok<AGROW>
    end
end
end


%%
function oSig = i_getSigFromPortBlock(hPortBlock)
stPortHandles = get_param(hPortBlock, 'PortHandles');
if isempty(stPortHandles.Inport)
    hSigPort = stPortHandles.Outport; % note: we have an Inport block
else
    hSigPort = stPortHandles.Inport; % note: we have an Outport block
end
try
    oSig = ep_core_feval('ep_sl_signal_from_port_get', hSigPort);
catch oEx
    oSig = [];
end
end


%%
function hPortBlock = i_findPortByName(hSub, sBlockType, sName)
hPortBlock = [];

ahFoundBlocks = ep_core_feval('ep_find_system', hSub , ...
    'SearchDepth', 1, ...
    'BlockType',   sBlockType, ...
    'Name',        sName);
if (numel(ahFoundBlocks) == 1)
    hPortBlock = ahFoundBlocks;
end
end


%%
% note: Variant subsystem mirror the port names of the contained referenced models; now, with this knowledge ...
% 1) find the port handle X of the variant subsystem for a Inport/Outport name Y inside the referenced model
% 2) find the root Inport/Outport Z of the wrapper connected to X
% 3) create map entry Y --> Z
function mNameToRootPort = i_mapPortNamesToRootPort(sVariantSub)
mNameToRootPort = containers.Map;

hVariantSub = get_param(sVariantSub, 'handle');
stPorts = get_param(hVariantSub, 'PortHandles');

ahInBlocks = ep_core_feval('ep_find_system', hVariantSub, ...
    'SearchDepth',    1, ...
    'LookUnderMasks', 'all', ...
    'BlockType',      'Inport');
for i = 1:numel(ahInBlocks)
    hPortBlock = ahInBlocks(i);
    
    iPortNum = sscanf(get_param(hPortBlock, 'Port'), '%d');
    mNameToRootPort(i_normalizePortName(get_param(hPortBlock, 'Name'))) = i_findRootPortBlock(stPorts.Inport(iPortNum));
end
ahOutBlocks = ep_core_feval('ep_find_system', hVariantSub, ...
    'SearchDepth',    1, ...
    'LookUnderMasks', 'all', ...
    'BlockType',      'Outport');
for i = 1:numel(ahOutBlocks)
    hPortBlock = ahOutBlocks(i);
    
    iPortNum = sscanf(get_param(hPortBlock, 'Port'), '%d');
    mNameToRootPort(i_normalizePortName(get_param(hPortBlock, 'Name'))) = i_findRootPortBlock(stPorts.Outport(iPortNum));
end
end


%%
function sName = i_normalizePortName(sName)
sName = strtrim(sName);
end


%%
function hRootPortBlock = i_findRootPortBlock(hPortHandle)
hRootPortBlock = [];

hRootPortHandle = ep_core_feval('ep_ec_port_src_dst_trace', hPortHandle);
if ~isempty(hRootPortHandle)
    hRootPortBlock = get_param(get_param(hRootPortHandle, 'Parent'), 'handle');
end
end



%%
function [oaInputs, oaOutputs] = i_createWrapperInterfacesByMatchingName(oWrapRootScope, aoRunInputItfs, aoRunOutputItfs)
ahInportBlks = cell2mat(get_param(ep_core_feval('ep_find_system', oWrapRootScope.sSubSystemFullName, ...
    'SearchDepth', 1, ...
    'BlockType',   'Inport'), 'handle'));
oaInputs = i_matchWrapperItfsWithRunnablesItfs(oWrapRootScope, aoRunInputItfs, ahInportBlks);

ahOutportBlks = cell2mat(get_param(ep_core_feval('ep_find_system', oWrapRootScope.sSubSystemFullName, ...
    'SearchDepth', 1, ...
    'BlockType',   'Outport'), 'handle'));
oaOutputs = i_matchWrapperItfsWithRunnablesItfs(oWrapRootScope, aoRunOutputItfs, ahOutportBlks);
end


%%
function aoItfs = i_matchWrapperItfsWithRunnablesItfs(oWrapRootScope, aoRunRootIOItfs, ahIOBlks)
aoItfs = [];
for iBlk = 1:numel(ahIOBlks)
    for iItf = 1:numel(aoRunRootIOItfs)
        if strcmp(get(aoRunRootIOItfs(iItf).hRootIOSrcBlk, 'Name'), get(ahIOBlks(iBlk), 'Name'))
            oItf = i_copyAndAdaptToWrapper(aoRunRootIOItfs(iItf), oWrapRootScope, ahIOBlks(iBlk));
            aoItfs = [aoItfs, oItf];
        end
    end
end
end


%%
function oItf = i_copyAndAdaptToWrapper(oRunnableItf, oWrapRootScope, hWrapperPortBlock, oSigSL)
% copy
oItf = oRunnableItf;

% adapt
oItf.sourceBlockFullName  = getfullname(hWrapperPortBlock);
oItf.sourceBlockName      = get(hWrapperPortBlock, 'Name');
oItf.handle               = hWrapperPortBlock;
oItf.ioPortNumber         = str2double(get(hWrapperPortBlock, 'Port'));
oItf = oItf.getSourcePortHandle(oWrapRootScope.bScopeIsModelBlock);
oItf.sParentScopeDefFile  = oWrapRootScope.sCFunctionDefinitionFileName;
oItf.sParentScopeFuncName = oWrapRootScope.sCFunctionName;
oItf.sParentScopePath     = oWrapRootScope.sSubSystemFullName;
oItf.sParentScopeAccess   = oWrapRootScope.sSubSystemAccess;
oItf.sParentScopeModelRef = oWrapRootScope.sSubSystemModelRef;

% If we have extra info with a signal add it also
if ((nargin > 3) && ~isempty(oSigSL))
    oItf.oSigSL_ = oSigSL;
end
end


%%
function varargout = i_portBlockToSignalManager(sCmd, varargin)
persistent p_mPortToSignal
if isempty(p_mPortToSignal)
    p_mPortToSignal = containers.Map('KeyType', 'double', 'ValueType', 'any');
end

switch sCmd
    case 'clear'
        p_mPortToSignal = containers.Map('KeyType', 'double', 'ValueType', 'any');

    case 'add'
        hPortBlock = varargin{1};
        oSig = varargin{2};
        p_mPortToSignal(hPortBlock) = oSig;

    case 'get'
        hPortBlock = varargin{1};
        bExist = p_mPortToSignal.isKey(hPortBlock);
        if bExist
            varargout{1} = p_mPortToSignal(hPortBlock);
        else
            varargout{1} = [];
        end
        varargout{2} = bExist;

    otherwise
        error('EP:INTERNAL_ERROR', 'Unknown command "%s".', sCmd);
end
end


%%
function oIts = i_getUniqRunnablesRootIOItfs(aoRunItfs)
oIts = [];
aoRunItfs = i_getRootIOs(aoRunItfs);
if ~isempty(aoRunItfs)
    %Unique regarding code variable -> filter the "duplicated" interfaces
    % i.e. the interfaces of the same kind IN or OUT accessing the same
    % variable). Duplication can happen because of the aggregation of all
    % runnables interfaces (e.g. 2 runnables accessing the same top level
    % autosar interface).
    casRootVariables = {aoRunItfs(:).codeVariableName};
    casRootStructComponentAccess = {aoRunItfs(:).codeStructComponentAccess};
    casRootStructName = {aoRunItfs(:).codeStructName};
    for i=1:numel(casRootVariables)
        if(isempty(casRootVariables{i}))
            % if oItf.isBusElement && oItf.getMetaBus().iBusObjElement
            % only the .codeStructName and .codeStructComponentAccess is
            % set
            if (isempty(casRootStructName{i}))
                casRootVariables{i} = strcat('unique not used', num2str(i));
            end
        end
    end
    
    casUniqueID = strcat(casRootVariables, ':',...
        casRootStructComponentAccess,':',...
        casRootStructName);
    [~, idx] = unique(casUniqueID, 'stable');
    oIts = aoRunItfs(idx);
end
end


%%
function aoRootRunItfs = i_getRootIOs(aoRunItfs)
aoRootRunItfs = [];
if ~isempty(aoRunItfs)
    aoRootRunItfs = aoRunItfs([aoRunItfs(:).bIsRootIO]);
end
end

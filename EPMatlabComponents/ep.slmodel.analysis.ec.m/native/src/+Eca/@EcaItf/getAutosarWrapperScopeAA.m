function oWrapRootScope = getAutosarWrapperScopeAA(oEca, oOrigRootScope)
% Create Root scope object for AA models representing the wrapper subsystem

oWrapRootScope = i_createWrapperRootScope(oEca);
oWrapRootScope = i_transferCodeFileInfo(oOrigRootScope, oWrapRootScope);
oWrapRootScope = i_transferInterfaceAttributes(oOrigRootScope, oWrapRootScope);
end


%%
function oWrapRootScope = i_createWrapperRootScope(oEca)
oWrapRootScope = Eca.MetaScope;

oWrapRootScope.bIsRootScope       = true;
oWrapRootScope.bScopeIsSubsystem  = true;
oWrapRootScope.bScopeIsModelBlock = false;
oWrapRootScope.bIsWrapperModel    = true;

oWrapRootScope.sSubSystemName     = get_param(oEca.sAutosarWrapperRootSubsystem, 'Name');
oWrapRootScope.sSubSystemFullName = oEca.sAutosarWrapperRootSubsystem;
oWrapRootScope.sSubSystemAccess   = oEca.sAutosarWrapperRootSubsystem;
oWrapRootScope.nHandle            = get_param(oEca.sAutosarWrapperRootSubsystem, 'handle');

oWrapRootScope.nSampleTime = oEca.getSubsystemCompiledSampleTime(oWrapRootScope.nHandle);

% Note:
% Wrapper code will be generated from the wrapper model. Later in the dataflow. At this moment we do not
% have any info about it!
%
% TODO: for now just fake it; longterm: replace it by a better data flow
%
stCInfo = oEca.getCodeInfoModel();
oWrapRootScope.sCFunctionName               = stCInfo.sCFunctionName;
oWrapRootScope.sInitCFunctionName           = stCInfo.sInitCFunctionName;
oWrapRootScope.sCFunctionDefinitionFileName = stCInfo.sCFunctionDefinitionFileName;
oWrapRootScope.sCFunctionDefinitionFile     = stCInfo.sCFunctionDefinitionFile;
oWrapRootScope.sEPCFunctionPath             = stCInfo.sEPCFunctionPath;

oWrapRootScope.sCodegenPath           = fileparts(oWrapRootScope.sCFunctionDefinitionFile);
oWrapRootScope.sPreStepCFunctionName  = oEca.sPreStepCFunctionName;
end


%%
function oWrapRootScope = i_transferCodeFileInfo(oOrigRootScope, oWrapRootScope)
oWrapRootScope.astCodegenSourcesFiles = oOrigRootScope.astCodegenSourcesFiles;
oWrapRootScope.casCodegenHeaderFiles  = oOrigRootScope.casCodegenHeaderFiles;
oWrapRootScope.casCodegenIncludePaths = oOrigRootScope.casCodegenIncludePaths;
oWrapRootScope.astDefines             = oOrigRootScope.astDefines;
end


%%
function oWrapRootScope = i_transferInterfaceAttributes(oOrigRootScope, oWrapRootScope)
[oWrapRootScope.oaInputs, oWrapRootScope.oaOutputs] = i_transferPortInfoByMatchingName( ...
    oWrapRootScope, ...
    i_selectAutosarComInterfaces(oOrigRootScope.oaInputs), ...
    i_selectAutosarComInterfaces(oOrigRootScope.oaOutputs));
end


%%
function aoInterfaces = i_selectAutosarComInterfaces(aoInterfaces)
if ~isempty(aoInterfaces)
    abSelect = arrayfun(@(o) o.bIsAutosarCom, aoInterfaces);
    aoInterfaces = aoInterfaces(abSelect);
end
end


%%
function [aoInputs, aoOutputs] = i_transferPortInfoByMatchingName(oWrapRootScope, aoOrigInputs, aoOrigOutputs)
mInportsByName = i_findAndMapBlockNamesToHandle(oWrapRootScope.sSubSystemFullName, 'Inport');
aoInputs = i_createWrapperItfsFromOriginalItfs(oWrapRootScope, aoOrigInputs, mInportsByName);

mOutportsByName = i_findAndMapBlockNamesToHandle(oWrapRootScope.sSubSystemFullName, 'Outport');
aoOutputs = i_createWrapperItfsFromOriginalItfs(oWrapRootScope, aoOrigOutputs, mOutportsByName);
end


%%
function mNameToHandle = i_findAndMapBlockNamesToHandle(sModel, sBlockType)
mNameToHandle = containers.Map;

hModel = get_param(sModel, 'handle');
ahBlocks = ep_core_feval('ep_find_system', hModel, ...
    'SearchDepth',    1, ...
    'LookUnderMasks', 'all', ...
    'BlockType',      sBlockType);
for i = 1:numel(ahBlocks)
    hBlock = ahBlocks(i);
    
    mNameToHandle(i_normalizeName(get_param(hBlock, 'Name'))) = hBlock;
end
end


%%
function sName = i_normalizeName(sName)
sName = strtrim(sName);
end


%%
function aoWrapperItfs = i_createWrapperItfsFromOriginalItfs(oWrapRootScope, aoOrigItfs, mWrapperPortsByName)
aoWrapperItfs = [];

for i = 1:numel(aoOrigItfs)
    oItf = aoOrigItfs(i);
    sName = i_normalizeName(get(oItf.hRootIOSrcBlk, 'Name'));

    if mWrapperPortsByName.isKey(sName)
        oWrapperItf = i_copyAndAdaptToWrapper(oItf, oWrapRootScope, mWrapperPortsByName(sName));
        aoWrapperItfs = [aoWrapperItfs, oWrapperItf]; %#ok<AGROW> 
    else
        % if IO is not found, it indicates an error; for now throw an error; no fallback possible
        error('EP:ERROR:MISSING_PORT', 'Port "%s" was not found in the wrapper model.', sName);
    end
end
end


%%
function oItf = i_copyAndAdaptToWrapper(oOrigItf, oWrapRootScope, hWrapperPortBlock)
% copy
oItf = oOrigItf;

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

% Update metaBusSignal structs -> needed for mapping definition
if oItf.isBusElement && oItf.getMetaBus().iBusObjElement
    oWrapperSig = i_getSignalFromPortBlock(hWrapperPortBlock);
    
    aiIdxDots = strfind(oItf.getMetaBus().modelSignalPath, '.');
    
    if ~isempty(oWrapperSig)
        sWrapperSignalName = oWrapperSig.getName();
    else
        sWrapperSignalName = '';
    end
    if isempty(sWrapperSignalName)
        oItf.metaBusSignal.modelSignalPath = ...
            ['.<signal1>.', oItf.getMetaBus().modelSignalPath(aiIdxDots(2)+1:end)];
    else
        oItf.metaBusSignal.modelSignalPath = ...
            ['.', sWrapperSignalName, '.', oItf.getMetaBus().modelSignalPath(aiIdxDots(2)+1:end)];
    end
end
end


%%
function oSig = i_getSignalFromPortBlock(hPortBlock)
stPortHandles = get_param(hPortBlock, 'PortHandles');
if ~isempty(stPortHandles.Inport)
    hPortHandle = stPortHandles.Inport(1);

elseif ~isempty(stPortHandles.Outport)
    hPortHandle = stPortHandles.Outport(1);

else
    hPortHandle = [];
end

if ~isempty(hPortHandle)
    oSig = ep_core_feval('ep_sl_signal_from_port_get', hPortHandle);
else
    oSig = [];
end
end


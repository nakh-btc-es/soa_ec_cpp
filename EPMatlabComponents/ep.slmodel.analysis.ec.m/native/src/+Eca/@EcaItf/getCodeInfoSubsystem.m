function stCodeInfo = getCodeInfoSubsystem(oEca, oScope)

stCodeInfo = oEca.getCodeInfoDefault();
if ~strcmp(get(oScope.nHandle, 'IsSubsystemVirtual'), 'off')
    return;
end


% Special treatment for all exported function subsystems that do not have any arguments information (==> void_void subsystems)
if oEca.isExportFuncModel()
    bHasMatchGraphicalInterface = oEca.oCodeDescSubInfoMap.isKey(oScope.sSubSystemAccess);
    if ~bHasMatchGraphicalInterface   
        astExpFuncSubs = oEca.getSubsystemsMappableToExportFuncs();
        for i = 1:numel(astExpFuncSubs)
            stExpFuncSub = astExpFuncSubs(i);
            if strcmp(stExpFuncSub.sSubsystem, oScope.sSubSystemAccess)
                stCodeInfo = oEca.getCodeInfoExportFunc(oScope, stExpFuncSub.sFcnCallInport);
                return;
            end
        end
    end
end

if strcmp(get(oScope.nHandle, 'RTWSystemCode'), 'Nonreusable function')
    stCodeInfo = i_getForNonReusableFuncs(oEca, oScope);
    return;
end
end


%%
function stCodeInfo = i_getForNonReusableFuncs(oEca, oScope)
stCodeInfo = oEca.getCodeInfoDefault();

% function name
if strcmp(get(oScope.nHandle,'RTWFcnNameOpts'), 'User specified')
    stCodeInfo.sCFunctionName = get(oScope.nHandle, 'RTWFcnName');
    
elseif strcmp(get(oScope.nHandle,'RTWFcnNameOpts'), 'Use subsystem name')
    stCodeInfo.sCFunctionName = i_getCustomSubsystemName(oScope, oEca);
    
end
if isempty(stCodeInfo.sCFunctionName)
    % if we do not have the C-function name, it makes no sense to continue ...
    return;
end

% file name
if strcmp(get(oScope.nHandle, 'RTWFileNameOpts'), 'Auto')  % Take parent scope file
    if oScope.bIsRootScope
        stCodeInfo.sCFunctionDefinitionFileName = [oEca.sModelName, '.c'];
    else
        stCodeInfo.sCFunctionDefinitionFileName = oScope.oParentScope.sCFunctionDefinitionFileName;
    end
    
elseif strcmp(get(oScope.nHandle, 'RTWFileNameOpts'), 'Use function name')
    stCodeInfo.sCFunctionDefinitionFileName = [stCodeInfo.sCFunctionName, '.c'];
    
elseif strcmp(get(oScope.nHandle, 'RTWFileNameOpts'), 'Use subsystem name')
    sCustomName = i_getCustomFileName(oScope, oEca);
    if ~isempty(sCustomName)
        stCodeInfo.sCFunctionDefinitionFileName = [sCustomName, '.c'];
    end
    
elseif strcmp(get(oScope.nHandle, 'RTWFileNameOpts'), 'User specified')
    stCodeInfo.sCFunctionDefinitionFileName = [get(oScope.nHandle, 'RTWFileName') '.c'];
end

if isempty(stCodeInfo.sCFunctionDefinitionFileName)
    % note: if exact file is unknown, add a marker for the EC import integration
    stCodeInfo.sCFunctionDefinitionFileName = '*';
else
    % TODO: the next line is plain *wrong* for subsystems in model references
    % <-- for model references there are extra code locations inside ./sprj/ert/...
    stCodeInfo.sCFunctionDefinitionFile = fullfile(oEca.sCodegenPath, stCodeInfo.sCFunctionDefinitionFileName);
end

% init/pre-step functions

if oScope.bIsRootScope
    oAncestorScope = [];
else
    oAncestorScope = oScope.getAncestorWithCodeInfo();
end

if isempty(oAncestorScope)
    stCodeInfo.sInitCFunctionName = [oEca.sModelName, '_initialize'];
    stCodeInfo.sEPCFunctionPath = i_getStackPath( ...
        '',  ...
        stCodeInfo.sCFunctionName, ...
        stCodeInfo.sCFunctionDefinitionFileName);
else
    stCodeInfo.sInitCFunctionName = oAncestorScope.sInitCFunctionName;
    stCodeInfo.sPreStepCFunctionName = oAncestorScope.sPreStepCFunctionName;
    stCodeInfo.sEPCFunctionPath = i_getStackPath( ...
        oAncestorScope.sEPCFunctionPath, ...
        stCodeInfo.sCFunctionName, ...
        stCodeInfo.sCFunctionDefinitionFileName);
end

stCodeInfo.bHasFuncArgs = ~strcmp(get(oScope.nHandle, 'FunctionInterfaceSpec'), 'void_void');
stCodeInfo.sCFunctionUpdateName = i_getCFunctionUpdateName(oEca, oScope.nHandle, stCodeInfo.sCFunctionName);
end


%%
function sStackPath = i_getStackPath(sAncestorStackPath, sCFunctionName, sCFunctionDefinitionFileName)
if ~isempty(sAncestorStackPath)
    sStackPath = [sAncestorStackPath, '/', [sCFunctionDefinitionFileName, ':1:', sCFunctionName]];
else
    sStackPath = [sCFunctionDefinitionFileName, ':1:', sCFunctionName];
end
end


%%
function bIsUsingCombinedStepFunc = i_isUsingCombinedStepFunc(oScope, oEca)
hParentModel = get_param(oScope.getParentModelName(), 'handle');
sSetting = oEca.mCombineOutputUpdate(hParentModel);
bIsUsingCombinedStepFunc = ~strcmpi(sSetting, 'off');
end


%%
function sFuncName = i_getCFunctionUpdateName(oEca, nHandle, sFuncPrefix)
hModel = bdroot(nHandle);
mMap = oEca.mCombineOutputUpdate;
sSetting = mMap(hModel);
if strcmp(sSetting, 'off')
    sFuncName = [sFuncPrefix '_Update'];
else
    sFuncName = '';
end
end


%%
function sCustomSubName = i_getCustomSubsystemName(oScope, oEca)
[bHasMinimalSupport, bStartsWithRootModelMacro] = i_hasMinimalSupportedSymbolMacro(oScope, oEca);
if bHasMinimalSupport
    sArtifactPrefix = '';
    if (bStartsWithRootModelMacro || oScope.isPartOfReferencedModel())
        sArtifactPrefix = [oScope.getParentModelName(), '_'];
    end
    sCustomSubName = [sArtifactPrefix, oScope.sSubSystemName];
else
    sCustomSubName = '';
end
end


%%
function sCustomFileName = i_getCustomFileName(oScope, oEca)
if oEca.hasModelReferences()
    [bHasMinimalSupport, bStartsWithRootModelMacro] = i_hasMinimalSupportedSymbolMacro(oScope, oEca);
    bMainModelAffected = bHasMinimalSupport && bStartsWithRootModelMacro;
    if (bMainModelAffected || oScope.isPartOfReferencedModel())
        sArtifactPrefix = [oScope.getParentModelName(), '_'];
    else
        sArtifactPrefix = '';
    end
else
    sArtifactPrefix = '';
end
sCustomFileName = [sArtifactPrefix, oScope.sSubSystemName];
end


%%
function [bIsSupported, bStartsWithRootModelMacro] = i_hasMinimalSupportedSymbolMacro(oScope, oEca)
bIsSupported = false;
bStartsWithRootModelMacro = false;

oModel = get_param(oScope.getParentModelName(), 'object');
oModelActiveCfg = oModel.getActiveConfigSet();
if isempty(oModelActiveCfg)
    return;
end
sCustomSymbolTemplate = oModelActiveCfg.get_param('CustomSymbolStrFcn');
if strncmp(sCustomSymbolTemplate, '$R', 2)
    bStartsWithRootModelMacro = true;
    if (numel(sCustomSymbolTemplate) > 2)
        sCustomSymbolTemplate = sCustomSymbolTemplate(3:end);
    else
        sCustomSymbolTemplate = '';
    end
end

bIsUsingCombinedStepFunc = i_isUsingCombinedStepFunc(oScope, oEca);
if bIsUsingCombinedStepFunc
    casAllowedSymbolTemplates = { ...
        '$N$M', ...
        '$M$N', ...
        '$N$M$F', ...
        '$M$N$F'};
else
    casAllowedSymbolTemplates = { ...
        '$N$M$F', ...
        '$M$N$F'};
end

bIsSupported = any(strcmp(sCustomSymbolTemplate, casAllowedSymbolTemplates));
end

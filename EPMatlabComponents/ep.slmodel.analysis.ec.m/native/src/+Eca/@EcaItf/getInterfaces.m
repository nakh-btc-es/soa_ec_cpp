function oScope = getInterfaces(oEca, oScope)

%Inputs/Outputs
oScope = i_evalArgumentsInfo(oEca.oCodeDescSubInfoMap, oScope);

if oEca.bIsAdaptiveAutosar
    bForce = true;
    oScope.oaInputs = oEca.getSignalInterfaces(oScope, 'IN', bForce);
    oScope.oaOutputs = oEca.getSignalInterfaces(oScope, 'OUT', bForce);
    return;
else
    oScope.oaInputs = oEca.getSignalInterfaces(oScope, 'IN');
    oScope.oaOutputs = oEca.getSignalInterfaces(oScope, 'OUT');
end

% -- for non-AA models --
oScope.astSLFunctions = i_assignUsedSLFunctions(oScope, oEca.astSLFunctions);

%DataStores
if ~isempty(oEca.stDataStores)
    oScope.oaInputs  = [oScope.oaInputs, oEca.getDataStoreInterfaces(oScope, 'IN')];
    oScope.oaOutputs = [oScope.oaOutputs, oEca.getDataStoreInterfaces(oScope, 'OUT')];
end
%Locals
if oEca.bDetectLocals
    oScope.oaLocals = oEca.getSignalInterfaces(oScope, 'LOCAL');
end
%Parameters
if oEca.bAllowParameters
    oScope.oaParameters = oEca.getCalibrationParameters(oScope);
end
%Defines
oScope.oaDefines = oEca.getDefinesParameters(oScope);


if oEca.bMergedArch
    % Search for missing declaration & definition files of interfaces and
    % deactivate mapping if code variables is mapped mutiple times in the same scope
    oScope.oaInputs = oScope.postTreatNonAutosarInterfaces (oScope.oaInputs);
    oScope.oaOutputs = oScope.postTreatNonAutosarInterfaces(oScope.oaOutputs);
    oScope.oaLocals = oScope.postTreatNonAutosarInterfaces(oScope.oaLocals);
    oScope.oaParameters = oScope.postTreatNonAutosarInterfaces(oScope.oaParameters);
    oScope.oaDefines = oScope.postTreatNonAutosarInterfaces(oScope.oaDefines);
end

oScope.stExtendedInterface = i_getExtendedInterface(oScope);
end


%%
function oScope = i_evalArgumentsInfo(mSubToArgsInfo, oScope)
sSubsysPath = oScope.sSubSystemAccess;
bIsAvailable = ~isempty(mSubToArgsInfo) && isKey(mSubToArgsInfo, sSubsysPath);
if bIsAvailable
    oScope.stArgsInfo = mSubToArgsInfo(sSubsysPath);
end
end


%%
function astUsedSLFunctions = i_assignUsedSLFunctions(oScope, astAllSLFunctions)
sScopePath = oScope.sSubSystemFullName;
sRootPathMatchPattern = ['^', regexptranslate('escape', sScopePath), '/'];

abIsUsedByScope = false(size(astAllSLFunctions));
for i = 1:numel(astAllSLFunctions)
    stSlFunc = astAllSLFunctions(i);
    
    bIsContainedInScopeContext = false;
    for k = 1:numel(stSlFunc.astCallers)
        sCallerPath = stSlFunc.astCallers(k).sVirtualPath;
        
        bIsContainedInScopeContext = ~isempty(regexp(sCallerPath, sRootPathMatchPattern, 'once'));
        if bIsContainedInScopeContext
            break; % shortcut: at least one caller found within the scope context --> scope is using SL-function
        end
    end
    abIsUsedByScope(i) = bIsContainedInScopeContext;
end
astUsedSLFunctions = astAllSLFunctions(abIsUsedByScope);
end


%%
function stInterface = i_getExtendedInterface(oScope)
stInterface = struct( ...
    'bHasEnablePort',  false, ...
    'bHasTriggerPort', false, ...
    'bHasFcnCallPort', false);

% note: for the main model itself, we have no extended interfaces per definitionem
if oScope.bScopeIsModel
    return;
end

if ~oScope.isActive()
    return;
end

sSubsystem = oScope.sSubSystemAccess;
if ~isempty(oScope.sSubSystemModelRef)
    sSubsystem = oScope.sSubSystemModelRef;
end

stPortHandles = get_param(sSubsystem, 'PortHandles');
stInterface.bHasEnablePort = ~isempty(stPortHandles.Enable);

% note: potentially could be multiple handles
ahTriggerPorts = stPortHandles.Trigger;
for i = 1:numel(ahTriggerPorts)
    hPort = ahTriggerPorts(i);
    
    % note: trigger port can be a *real* trigger port or fcn-call port (note: totally different handling in SL/EC)
    if i_isFcnCallTrigger(hPort)
        stInterface.bHasFcnCallPort = true;
    else
        stInterface.bHasTriggerPort = true;
    end
end
end


%%
function bIsFcnCall = i_isFcnCallTrigger(hTriggerPort)
bIsFcnCall = strcmp('fcn_call', get_param(hTriggerPort, 'CompiledPortDataType'));
end

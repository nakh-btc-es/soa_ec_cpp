function [aoScopes, astEval] = getAllScopesWithEvaluatedValidity(oEca)

[aoScopes, astInfo] = i_getAllScopesWithValidityInfo(oEca);
astEval = i_evaluateValidity(aoScopes, astInfo, i_getValidityConstraints(oEca));
end


%%
function astEval = i_evaluateValidity(aoScopes, astInfo, stConstraints)
astEval = repmat(struct( ...
    'bIsValid',           true, ...
    'bIsValidForCode',    true, ...
    'bIsValidForMapping', true, ...
    'casNotes', {{}}), 1, numel(aoScopes));
for k = 1:numel(aoScopes)
    
    % special handling for the root subsystem --> always valid without further checking
    if aoScopes(k).bIsRootScope
        continue;
    end
    
    % no support for triggered subsystems
    if (~aoScopes(k).isActive())
        astEval(k).bIsValid           = false;
        astEval(k).bIsValidForCode    = false;
        astEval(k).bIsValidForMapping = false;
        
        astEval(k).casNotes = {'Inactive subsystems are not supported.'};
        continue;
    end
    
    % no support for SL functions
    if aoScopes(k).bIsSlFunction
        astEval(k).bIsValid           = false;
        astEval(k).bIsValidForCode    = false;
        astEval(k).bIsValidForMapping = false;
        
        astEval(k).casNotes = {'SL functions are currently not supported.'};
        continue;
    end
    
    % no support for Export Function models
    if aoScopes(k).isExportFuncModel()
        astEval(k).bIsValid           = false;
        astEval(k).bIsValidForCode    = false;
        astEval(k).bIsValidForMapping = false;
        
        astEval(k).casNotes = {'Export function models are not considered.'};
        continue;
    end
    
    % no support for triggered subsystems
    if (aoScopes(k).hasTriggerPort() || aoScopes(k).hasEnablePort())
        astEval(k).bIsValid           = false;
        astEval(k).bIsValidForCode    = false;
        astEval(k).bIsValidForMapping = false;
        
        astEval(k).casNotes = {'Triggered/enabled subsystems are currently not supported.'};
        continue;
    end
    
    % only with unique step func
    if ~astInfo(k).bHasUniqueStepFunc
        astEval(k).bIsValid           = ~stConstraints.bRequireUniqueStepFunc;
        astEval(k).bIsValidForCode    = false;
        astEval(k).bIsValidForMapping = false;
        
        if ~astEval(k).bIsValid
            astEval(k).casNotes = {'Missing a unique step function for the subsystem.'};
            continue;
        end
    end
        
    % only with fully mapped IOs
    if ~astInfo(k).bHasFullyMappedIOs
        astEval(k).bIsValid = ~stConstraints.bRequireFullyMappedIOs;
        
        if ~astEval(k).bIsValid
            astEval(k).casNotes = {'Missing mapping between model and code for the interfaces of the subsystem.'};
            continue;
        end
    end
    
    % only if not containing AUTOSAR client calls
    if astInfo(k).bHasClientCalls
        astEval(k).bIsValid           = ~stConstraints.bRequireNoClientCalls;
        astEval(k).bIsValidForCode    = ~stConstraints.bRequireNoClientCalls;
        astEval(k).bIsValidForMapping = ~stConstraints.bRequireNoClientCalls;
        
        if ~astEval(k).bIsValid
            astEval(k).casNotes = {'Subsystem contains AUTOSAR client calls.'};
            continue;
        end
    end
    
    % .... maybe more to come
    
end
end


%%
function stConstraints = i_getValidityConstraints(oEca)
bExcludeScopesMissingIOMapping = false;
bExcludeScopesWithoutMapping   = false;
bExcludeScopesWithClientCalls  = false; 
if oEca.bMergedArch
    if oEca.bIsAutosarArchitecture
        bExcludeScopesMissingIOMapping = oEca.stActiveConfig.General.bExcludeScopesWithMissingIOMapping;
        bExcludeScopesWithoutMapping = oEca.stActiveConfig.General.bExcludeScopesWithoutMapping;
        bExcludeScopesWithClientCalls = oEca.stActiveConfig.General.bExcludeScopesWithClientCalls;
    else
        bExcludeScopesWithoutMapping = oEca.stActiveConfig.General.bExcludeScopesWithoutMapping;
    end
else
end

stConstraints = struct( ...
    'bRequireFullyMappedIOs', bExcludeScopesMissingIOMapping, ...
    'bRequireUniqueStepFunc', bExcludeScopesWithoutMapping, ...
    'bRequireNoClientCalls',  bExcludeScopesWithClientCalls);
end


%%
function [aoScopes, astInfo] = i_getAllScopesWithValidityInfo(oEca)
aoScopes = oEca.getAllScopes();
astInfo  = repmat(struct( ...
    'bHasClientCalls',     false, ...
    'bHasUniqueStepFunc',  false, ...
    'bHasFullyMappedIOs',  false), 1, numel(aoScopes));
if isempty(aoScopes)
    return;
end

abHasUniqueStepFunc = i_hasValidUniqueStepFunc(oEca, aoScopes);
abHasClientCalls    = i_hasClientCalls(oEca, aoScopes);
for k = 1:numel(aoScopes)
    astInfo(k).bHasClientCalls    = abHasClientCalls(k);
    astInfo(k).bHasUniqueStepFunc = abHasUniqueStepFunc(k);
    astInfo(k).bHasFullyMappedIOs = aoScopes(k).hasFullyMappedIOs();
end
end


%%
function abHasClientCalls = i_hasClientCalls(oEca, aoScopes)
abHasClientCalls = false(size(aoScopes));

if (~oEca.bIsAutosarArchitecture || oEca.bIsAdaptiveAutosar)
    return;
end

casCallerPaths = i_getCallerPaths(oEca.oAutosarMetaProps.astClientPorts);
if isempty(casCallerPaths)
    return;
end

for i = 1:numel(aoScopes)
    sScopePath = aoScopes(i).sSubSystemAccess;
    
    for k = 1:numel(casCallerPaths)
        if i_scopeContainsBlock(sScopePath, casCallerPaths{k})
            abHasClientCalls(i) = true;
            break; % break *inner* k-loop
        end
    end
end
end


%%
function bContainsBlock = i_scopeContainsBlock(sSubsystemPath, sBlockPath)
bContainsBlock = startsWith(sBlockPath, sSubsystemPath);
end


%%
function casCallerPaths = i_getCallerPaths(astClientPorts)
casCallerPaths = {};
for i = 1:numel(astClientPorts)
    for k = 1:numel(astClientPorts(i).astOperations)
        casBlocks = astClientPorts(i).astOperations(k).casCallerBlocks;
        casCallerPaths = [casCallerPaths, casBlocks];
    end
end
end


%%
function bAllAreModelRefs = i_allScopesAreReferences(aoScopes)
bAllAreModelRefs = all([aoScopes(:).bScopeIsModelBlock]);
end


%%
function abIsHasUniqueStepFunc = i_hasValidUniqueStepFunc(oEca, aoScopes)
oFuncNameIdxMap = containers.Map;

abIsHasUniqueStepFunc = true(size(aoScopes));
for iScopeIdx = 1:numel(aoScopes)
    oScope = aoScopes(iScopeIdx);
    
    if oEca.bMergedArch
        sStepFcn = oScope.sCFunctionName;
        if isempty(sStepFcn)
            abIsHasUniqueStepFunc(iScopeIdx) = false;
        else
            if oFuncNameIdxMap.isKey(sStepFcn)
                oFuncNameIdxMap(sStepFcn) = [oFuncNameIdxMap(sStepFcn), iScopeIdx];
            else
                oFuncNameIdxMap(sStepFcn) = iScopeIdx;
            end
        end
    end
end
if oEca.bMergedArch
    casFcnNames = oFuncNameIdxMap.keys;
    for iFcnIdx = 1:numel(casFcnNames)
        sFcnName = casFcnNames{iFcnIdx};
        
        aiScopeIdx = oFuncNameIdxMap(sFcnName);
        if (numel(aiScopeIdx) > 1)
            if ~i_allScopesAreReferences(aoScopes(aiScopeIdx))
                % note: same step function-name shared for mulitple non-reusable subsystems --> error!
                abIsHasUniqueStepFunc(aiScopeIdx) = false;
            end
        end
    end
end
end



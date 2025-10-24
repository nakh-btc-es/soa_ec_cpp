function [oEca, bSuccess] = analyzeSimulinkSilArchitecture(oEca)
% Find subsystems/parameters/Locals interfaces compliant with Simulink SIL use case

%%
bSuccess = false;

% load and compile model
load_system(oEca.sModelName);
for iMod = 1:numel(oEca.casModelRefs)
    load_system(oEca.casModelRefs{iMod});
end

% compile
oEca.startModelCompilation(oEca.sModelName);
oOnCleanupStopCompile = onCleanup(@() oEca.stopModelCompilation(oEca.sModelName));

%Get subsystem or modelblock
sRootScopePath = char(oEca.searchTopLevelSubsystemsAndModelblocks());
if ~isempty(sRootScopePath)

    % Parameters and Constants
    [oEca.aoModelWiseCalParams, oEca.astConstants] = i_getParametersAndConstants(oEca);
    
    % Scopes
    oScope = Eca.MetaScope;
    oScope.bIsRootScope = true;
    
    sType = get_param(sRootScopePath, 'Type');
    if strcmp(sType, 'block_diagram')
        oScope.bScopeIsModel = true;
    else
        oScope.bScopeIsSubsystem  = strcmp(get_param(sRootScopePath, 'BlockType'), 'SubSystem');
        oScope.bScopeIsModelBlock = ~oScope.bScopeIsSubsystem;
    end
    
    %Subsystem info
    oScope.sSubSystemName = get_param(sRootScopePath, 'Name');
    oScope.sSubSystemFullName = sRootScopePath;
    oScope.sSubSystemAccess = sRootScopePath;
    oScope.nHandle = get_param(sRootScopePath, 'handle');
    
    %Interfaces (Params and Local Interfaces)
    if oEca.bAllowParameters
        oScope.oaParameters = oEca.getCalibrationParameters(oScope);
        if ~isempty(oScope.oaParameters)
            %set bMappingValid to true to make them usable in createModelXml()
            [oScope.oaParameters(:).bMappingValid] = deal(true);
        end
    end
    if oEca.bDetectLocals
        oScope.oaLocals = oEca.getSignalInterfaces(oScope, 'LOCAL');
        if ~isempty(oScope.oaLocals)
            %Exclude bus signals not supported for Simulink SIL logging
            oScope.oaLocals = oScope.oaLocals(not([oScope.oaLocals(:).isBusElement]));
            %Set bMappingValid to make them usable in createModelXml()
            [oScope.oaLocals(:).bMappingValid] = deal(true);
        end
    end
    % ChildrenScopes : recursive search inside the current scope
    if oEca.stActiveConfig.ScopeCfg.AnalyzeScopesHierarchy
        oScope.oaChildrenScopes = i_getChildrenScopes(oEca, oScope);
    end
    
    %Return
    oEca.oRootScope = oScope;
    bSuccess = true;
end
end


%%
function [aoCalParams, astConstants] = i_getParametersAndConstants(oEca)
astParams = i_findParametersInModel(oEca);

stBlackList = oEca.evalHook('ecahook_param_blacklist', i_getHookArgsParamBlacklist(oEca));
casParamBlackList = stBlackList.casParamlist;

%Parameters interfaces
aoCalParams = oEca.getModelWiseParameters('PARAM', astParams, casParamBlackList);

%Constants
astConstants = oEca.getConstants(astParams);
end


%%
function astParams = i_findParametersInModel(oEca)
xEnv = oEca.EPEnv;

if oEca.bIsAutosarArchitecture
    sModelName = oEca.sAutosarModelName;
else
    sModelName = oEca.sModelName;
end
stResult = ep_core_feval('ep_model_params_get', ...
    'Environment',   xEnv, ...
    'ModelContext',  sModelName, ...
    'SearchMethod',  'cached', ...
    'IncludeModelWorkspace', oEca.bMergedArch);

astParams = reshape(stResult.astParams, 1, []);
astParams = arrayfun(@i_extendWithObjectInfo, astParams);
end


%%
function stParam = i_extendWithObjectInfo(stParam)
stParam.oObj = i_getVariableObjFromParam(stParam);
end


%%
function oObj = i_getVariableObjFromParam(stParam)
oObj = [];
if isempty(stParam.astBlockInfo)
    return;
end

oModelContext = EPModelContext.get(stParam.astBlockInfo(1).sPath);
oObj = oModelContext.getVariable(stParam.sRawName);
end


%%
function stAdditionalInfo = i_getHookArgsParamBlacklist(oEca)
stAdditionalInfo = oEca.getHookCommonAddInfo();
end


%%
function aoScopes = i_getChildrenScopes(oEca, oParentScope)

aoScopes = [];

%Get subsystems or modelblocks
[astBlockPaths, astModelRefBlockPaths] = oEca.searchLowerLevelSubsystemsAndModelblocks(oParentScope);
if ~isempty(astBlockPaths)
    aoScopes = i_evaluateChildren(oEca, astBlockPaths, oParentScope, false);
end
if ~isempty(astModelRefBlockPaths)
    aoScopes = [aoScopes, i_evaluateChildren(oEca, astModelRefBlockPaths, oParentScope, true)];
end
end


%%
function aoScopes = i_evaluateChildren(oEca, astBlockPaths, oParentScope, bIsModelRef)
if ~isempty(astBlockPaths)
    %Create children scope objets
    aoLowerScopes(numel(astBlockPaths)) = Eca.MetaScope;
    
    for k = 1:numel(aoLowerScopes)
        aoLowerScopes(k).bIsRootScope = false;
        aoLowerScopes(k).oParentScope = oParentScope;
        
        if bIsModelRef
            aoLowerScopes(k).sSubSystemModelRef = astBlockPaths(k).sModelRef;
            aoLowerScopes(k).bScopeIsSubsystem = false;
            aoLowerScopes(k).nHandle = get_param(astBlockPaths(k).sModelRef, 'handle');
        else
            aoLowerScopes(k).bScopeIsSubsystem = strcmp(get_param(astBlockPaths(k).sAccess, 'BlockType'), 'SubSystem');
            aoLowerScopes(k).nHandle = get_param(astBlockPaths(k).sAccess, 'handle');
        end
        
        %Top Subsystem info
        
        aoLowerScopes(k).sSubSystemName = get_param(astBlockPaths(k).sAccess, 'Name');
        aoLowerScopes(k).sSubSystemFullName = astBlockPaths(k).sPath; 
        aoLowerScopes(k).sSubSystemAccess = astBlockPaths(k).sAccess;
        
        
        %Interfaces (Params and Local Interfaces)
        if oEca.bAllowParameters
            aoLowerScopes(k).oaParameters = oEca.getCalibrationParameters(aoLowerScopes(k));
            if ~isempty(aoLowerScopes(k).oaParameters)
                %set bMappingValid to make them usable in createModelXml()
                [aoLowerScopes(k).oaParameters(:).bMappingValid] = deal(true);
            end
        end
        if oEca.bDetectLocals
            aoLowerScopes(k).oaLocals = oEca.getSignalInterfaces(aoLowerScopes(k), 'LOCAL');
            if ~isempty(aoLowerScopes(k).oaLocals)
                %exclude bus signals not supported for Simulink SIL logging
                aoLowerScopes(k).oaLocals = aoLowerScopes(k).oaLocals(not([aoLowerScopes(k).oaLocals(:).isBusElement]));
                %set bMappingValid to make them usable in createModelXml()
                [aoLowerScopes(k).oaLocals(:).bMappingValid] = deal(true);
            end
        end
        
        %ChildrenScopes : recursive search starting from TopLevel-1 subsystems
        aoLowerScopes(k).oaChildrenScopes = i_getChildrenScopes(oEca, aoLowerScopes(k));
        
    end
    aoScopes = aoLowerScopes;
end
end

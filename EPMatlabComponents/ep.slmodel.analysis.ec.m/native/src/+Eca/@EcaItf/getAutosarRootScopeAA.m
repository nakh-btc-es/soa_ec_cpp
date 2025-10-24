function oRootScope = getAutosarRootScopeAA(oEca)
% Return root scope for Adaptive AUTOSAR models (either direct from model or indirect via Wrapper).
%

%%
if strcmp(oEca.sAutosarArchitectureType, 'SWC')
    oRootScope = i_getComponentRootScope(oEca);
else
    oOrigRootScope = i_getComponentRootScope(oEca);
    oRootScope = oEca.getAutosarWrapperScopeAA(oOrigRootScope);
end
end


%%
function oRootScope = i_getComponentRootScope(oEca)
oRootScope = [];
oScope = Eca.MetaScope;

sRootScopePath = oEca.sAutosarModelName;
if ~isempty(sRootScopePath)
    oScope.bIsRootScope = true;
    
    sType = get_param(sRootScopePath, 'Type');
    if strcmp(sType, 'block_diagram')
        oScope.bScopeIsModel = true;
    else
        error('EP:ERROR', 'For Adaptive AUTOSAR models only the model level is supported as SUT.');
    end
    
    %Subsystem info
    oScope.sSubSystemName = get_param(sRootScopePath, 'Name');
    oScope.sSubSystemFullName = sRootScopePath;
    if oScope.bScopeIsModelBlock
        oScope.sSubSystemAccess = get_param(sRootScopePath, 'ModelName');
        oScope.sSubSystemModelRef = sRootScopePath;
    else
        oScope.sSubSystemAccess = sRootScopePath;
    end
    oScope.nHandle = get_param(sRootScopePath, 'handle');
    oScope.nSampleTime = oEca.dModelSampleTime;
    oScope.sCodegenPath = oEca.sCodegenPath;
    
    % transfer codegen data from main object to root (TODO: check if this can be avoided)
    oScope.astCodegenSourcesFiles = oEca.astCodegenSourcesFiles;
    oScope.casCodegenHeaderFiles  = oEca.casCodegenHeaderFiles;
    oScope.casCodegenIncludePaths = oEca.casCodegenIncludePaths;
    oScope.astDefines = oEca.astDefines;
    
    stCodeInfo = oEca.createAdapterCodeAA();
    if ~isempty(stCodeInfo)
        oScope = i_addAdapterSourceFile(oScope, stCodeInfo.sCFunctionDefinitionFile);

        % Prestep function
        sPreStepFunc = oEca.sPreStepCFunctionName;
        if ~isempty(sPreStepFunc)
            stCodeInfo.sPreStepCFunctionName = sPreStepFunc;
        end
        
        casAttributes = fieldnames(stCodeInfo);
        for m = 1:numel(casAttributes)
            sAttribute = casAttributes{m};
            oScope.(sAttribute) = stCodeInfo.(sAttribute);
        end
    end
    
    oScope = oEca.getInterfaces(oScope);
    oRootScope = oScope;
end
end


%%
function oScope = i_addAdapterSourceFile(oScope, sAdapterFile)
stFile.path    = sAdapterFile;
stFile.codecov = false;
stFile.hide    = false;

oScope.astCodegenSourcesFiles(end + 1) = stFile;
end

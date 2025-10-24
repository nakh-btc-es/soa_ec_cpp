function [oDummyRootScope, aoRunnableScopes] = getAutosarDummyScope(oEca)
% Create Root scope object representing the toplevel dummy subsystem

sModelName = oEca.sModelName;

oDummyRootScope = Eca.MetaScope;
oDummyRootScope.bIsRootScope = true;
oDummyRootScope.bScopeIsModel = true;

%Subsystem info
oDummyRootScope.sSubSystemName = sModelName;
oDummyRootScope.sSubSystemFullName = sModelName;
oDummyRootScope.sSubSystemAccess = sModelName;
oDummyRootScope.nHandle = get_param(sModelName, 'handle');

%Params (need formally to be associated with the root subsystem; neeeded later)
oDummyRootScope.oaParameters = oEca.aoModelWiseCalParams;

%Sampletime
oDummyRootScope.nSampleTime = oEca.dModelSampleTime;

%CodeGenPath
oDummyRootScope.sCodegenPath = oEca.sCodegenPath;

%Function info
oDummyRootScope.sCFunctionName = '';
oDummyRootScope.sInitCFunctionName = '';
oDummyRootScope.sCFunctionDefinitionFileName = '';
oDummyRootScope.sCFunctionDefinitionFile = '';
oDummyRootScope.sEPCFunctionPath = '';

%Analyse the Runnables Scopes as children scope of the wrapper
bAnalyzeRunChldScopes = oEca.stActiveConfig.ScopeCfg.AnalyzeScopesHierarchy;
aoRunnableScopes = oEca.getAutosarRunnableScopes(oDummyRootScope, bAnalyzeRunChldScopes);

if oEca.bDiagMode
    for iRun = 1:numel(aoRunnableScopes)
        sLink = sprintf('<a href = "matlab:open_system(''%s'');hilite_system(''%s'')">%s</a>',...
            oEca.sModelName,aoRunnableScopes(iRun).sSubSystemFullName,aoRunnableScopes(iRun).sSubSystemFullName);
        fprintf('\n## Scope %s has been detected \n',sLink);
    end
end

%Runnables as children scopes of this root scope
oDummyRootScope.oaChildrenScopes = aoRunnableScopes;

%Sources files
oDummyRootScope.astCodegenSourcesFiles = aoRunnableScopes(1).astCodegenSourcesFiles;
%Header files
oDummyRootScope.casCodegenHeaderFiles = unique(strrep(aoRunnableScopes(1).casCodegenHeaderFiles,'/',filesep),'stable');

%Include paths (append Plugin "Includes" directory)
oDummyRootScope.casCodegenIncludePaths = unique(strrep(aoRunnableScopes(1).casCodegenIncludePaths, '/', filesep),'stable');


%Defines
oDummyRootScope.astDefines = aoRunnableScopes(1).astDefines;

%Pre step function
oDummyRootScope.sPreStepCFunctionName = oEca.sPreStepCFunctionName;
end

function aoRunnableScopes = getAutosarRunnableScopes(oEca, oParentScope, bAnalyzeRunChldScopes, sReferencePath)
if (nargin < 4)
    sReferencePath = '';
end

% Create scope object for modeled Runnables

%Filter list of runnables of the ones used in the model.
aoRunnables = oEca.aoRunnables([oEca.aoRunnables(:).bIsModeled]);
%Init Runnable
oRunnableInit = oEca.aoRunnables([oEca.aoRunnables(:).bIsInitFunction]);
if ~isempty(oRunnableInit)
    sInitFunctionName = oRunnableInit.sSymbol;
end

%For all Runnables, anlayis scope and autosar interfaces
%Sources files
%get external depedencies
astSourceFiles = oEca.astCodegenSourcesFiles;
casHeaderFiles  = oEca.casCodegenHeaderFiles;
casIncludePaths = oEca.casCodegenIncludePaths;
astDefines      = oEca.astDefines;

% Use Code Descriptor for the wrapper usecase no build info is available
if ~contains(oEca.sSystemTargetFileName, 'ert.tlc')
    oEca.oCodeDescSubInfoMap = i_getCodeDescSubInfoMap(oEca.sModelName);
end

%Header files
%Include paths
%Create Runnable Scopes
aoRunnableScopes(numel(aoRunnables)) = Eca.MetaScope;
for iRun = 1:numel(aoRunnables)
    sBlockPath = aoRunnables(iRun).sSubsysPath;
    sType = get_param(sBlockPath, 'Type');
    if strcmp(sType, 'block_diagram')
        aoRunnableScopes(iRun).bScopeIsModel = true;
    else
        aoRunnableScopes(iRun).bScopeIsSubsystem = strcmp(get_param(sBlockPath, 'BlockType'), 'SubSystem');
        aoRunnableScopes(iRun).bScopeIsModelBlock = ~aoRunnableScopes(iRun).bScopeIsSubsystem;
    end
    aoRunnableScopes(iRun).oParentScope = oParentScope;
    %Subsystem info
    aoRunnableScopes(iRun).sSubSystemName = get_param(sBlockPath, 'Name');
    if isempty(sReferencePath)
        aoRunnableScopes(iRun).sSubSystemFullName = sBlockPath;
    else
        % if AUTOSAR model is referenced from wrapper model, replace the block path with the path of the reference block
        % to create the *virtual* path needed here
        aoRunnableScopes(iRun).sSubSystemFullName = i_replaceModelName(sBlockPath, sReferencePath);
    end
    aoRunnableScopes(iRun).sSubSystemAccess = sBlockPath;
    aoRunnableScopes(iRun).nHandle = get_param(sBlockPath, 'handle');
    %Sampletime
    aoRunnableScopes(iRun).nSampleTime = ...
        oEca.getSubsystemCompiledSampleTime(aoRunnableScopes(iRun).nHandle); %oEca.dModelSampleTime;
    %CodeGenPath
    aoRunnableScopes(iRun).sCodegenPath = oEca.sAutosarCodegenPath;
    %Sources files
    aoRunnableScopes(iRun).astCodegenSourcesFiles = astSourceFiles;
    %Header files
    aoRunnableScopes(iRun).casCodegenHeaderFiles = casHeaderFiles;
    %Include paths (append Plugin "Includes" directory)
    aoRunnableScopes(iRun).casCodegenIncludePaths = casIncludePaths;
    %Defines
    aoRunnableScopes(iRun).astDefines = astDefines;
    %PreStep Function
    aoRunnableScopes(iRun).sPreStepCFunctionName = oEca.sPreStepCFunctionName;
    %Function info
    if aoRunnables(iRun).bIsStepFunction || aoRunnables(iRun).bIsExportFunction ||  aoRunnables(iRun).bIsInitFunction
        %Step Function Name
        aoRunnableScopes(iRun).sCFunctionName = aoRunnables(iRun).sSymbol;
        aoRunnableScopes(iRun).sInitCFunctionName = sInitFunctionName;
        %Definition File
        aoRunnableScopes(iRun).sCFunctionDefinitionFileName = [oEca.sAutosarModelName '.c'];
        aoRunnableScopes(iRun).sCFunctionDefinitionFile = [oEca.sAutosarCodegenPath, filesep, oEca.sAutosarModelName '.c'];
        if (isa(oParentScope, 'Eca.MetaScope') && ~isempty(oParentScope.sEPCFunctionPath))
            %If Wrapper scope is give, include the parent c-function path
            aoRunnableScopes(iRun).sEPCFunctionPath = [oParentScope.sEPCFunctionPath, '/', ...
                aoRunnableScopes(iRun).sCFunctionDefinitionFileName, ':1:',aoRunnableScopes(iRun).sCFunctionName];
        else
            aoRunnableScopes(iRun).sEPCFunctionPath = ...
                [aoRunnableScopes(iRun).sCFunctionDefinitionFileName, ':1:', aoRunnableScopes(iRun).sCFunctionName];
        end
        aoRunnableScopes(iRun).sRunnableName = aoRunnables(iRun).sName;
    elseif aoRunnables(iRun).bIsSlFunction
        aoRunnableScopes(iRun).bIsSlFunction = true;
        aoRunnableScopes(iRun).sCFunctionName = aoRunnables(iRun).sSymbol;
        aoRunnableScopes(iRun).sInitCFunctionName = sInitFunctionName;
        %Definition File
        aoRunnableScopes(iRun).sCFunctionDefinitionFileName = [aoRunnables(iRun).sSymbol '.c'];
        aoRunnableScopes(iRun).sCFunctionDefinitionFile = [oEca.sAutosarCodegenPath '/' aoRunnables(iRun).sSymbol '.c'];
        if isa(oParentScope, 'Eca.MetaScope')
            %If Wrapper scope is given, include the parent c-function path
            aoRunnableScopes(iRun).sEPCFunctionPath = [oParentScope.sEPCFunctionPath '/' ...
                aoRunnableScopes(iRun).sCFunctionDefinitionFileName, ':1:',aoRunnableScopes(iRun).sCFunctionName];
        else
            aoRunnableScopes(iRun).sEPCFunctionPath = ...
                [aoRunnableScopes(iRun).sCFunctionDefinitionFileName, ':1:', aoRunnableScopes(iRun).sCFunctionName];
        end
        aoRunnableScopes(iRun).sRunnableName = aoRunnables(iRun).sName;
    else
        error('The runnable %s is not supported as Scope. Its interface may not be stubeed');
    end
    aoRunnableScopes(iRun).bIsAutosarRunnable = true;
        
    %Interfaces
    aoRunnableScopes(iRun) = oEca.getInterfaces(aoRunnableScopes(iRun));
    
    %Analyse children scopes
    if bAnalyzeRunChldScopes
        aoRunnableScopes(iRun).oaChildrenScopes = oEca.getChildrenScopes(aoRunnableScopes(iRun));
    end
end
end


%%
function oCodeDescSubInfoMap = i_getCodeDescSubInfoMap(sModelName)
oCodeDescSubInfoMap = ep_core_feval('ep_ec_code_desc_subs_info_get', sModelName);
end


%%
function sBlockPath = i_replaceModelName(sBlockPath, sReferencePath)
% transformatioon: <model-name>/<rest-of-path> --> <reference-path>/<rest-of-path>
sBlockPath = regexprep(sBlockPath, '^[^/]+', sReferencePath);
end

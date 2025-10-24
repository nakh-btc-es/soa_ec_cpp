classdef MetaScope
    
    properties        
        nHandle = [];
        
        sSubSystemName = '';
        sSubSystemFullName = '';
        sSubSystemAccess = '';
        sSubSystemModelRef = '';
        
        nSampleTime = [];
        
        % code info
        sCFunctionName = '';
        sCFunctionUpdateName = '';
        sInitCFunctionName = '';
        sPreStepCFunctionName = '';
        sCFunctionDefinitionFileName = '';
        sCFunctionDefinitionFile = '';
        sEPCFunctionPath = '';
        bHasFuncArgs = false;
        
        casCodegenIncludePaths = {};
        
        astCodegenSourcesFiles = struct( ...
            'path',    '', ...
            'codecov', '');
        astDefines = struct( ...
            'name',  '', ...
            'value', '');
        casCodegenHeaderFiles = {};
        casStubFiles = {};
        sStubVarInitFunc = '';
        
        % tree hierarchy info
        oParentScope = [];
        
        % interfaces
        oaInputs        = [];
        oaOutputs       = [];
        oaParameters    = [];
        oaLocals        = [];
        oaDefines       = [];
        
        % used SL-functions
        astSLFunctions = [];
        
        % special interfaces
        stExtendedInterface = struct( ...
            'bHasEnablePort',  false, ...
            'bHasTriggerPort', false, ...
            'bHasFcnCallPort', false);
        
        % Stubbed interfaces
        oaStubbedIfs    = [];
        oaStubbedDefs   = [];
        
        % Apply for Root scope
        bIsRootScope = false;
        bIsWrapperModel = false;
                
        %Apply for Lower scope
        bScopeIsModel          = false;
        bScopeIsSubsystem      = false;
        bScopeIsModelBlock     = false;
        
        
        oaChildrenScopes = []; % Eca.MetaScope
        sCodegenPath = '';
        
        bIsAutosarRunnable = false;
        sRunnableName = '';
        
        bIsAutosarRunnableChild = false;
        sParentRunnablePath = '';
        bIsSlFunction = false;

        stArgsInfo = [];

        mPort2Var
    end
    
    methods
        %%
        function oObj = MetaScope()
            oObj.mPort2Var = containers.Map;
        end

        %%
        function bHasArgsInfo = hasArgsInfo(oObj)
            bHasArgsInfo = ~isempty(oObj.stArgsInfo);
        end
        
        %%
        function stArgsInfo = getArgsInfo(oObj)
            stArgsInfo = oObj.stArgsInfo;
        end

        %%
        function bHasMapping = hasPort2VarMapping(oObj)
            bHasMapping = ~isempty(oObj.mPort2Var);
        end
        
        %%
        function sVarName = mapPort2Var(oObj, sPortName)
            if isKey(oObj.mPort2Var, sPortName)
                sVarName = oObj.mPort2Var(sPortName);
            else
                sVarName = '';
            end
        end

        %%
        function bHasFullyMappedIOs = hasFullyMappedIOs(oScope)
            aoIOItfs = [oScope.oaInputs oScope.oaOutputs];
            if isempty(aoIOItfs)
                bHasFullyMappedIOs = true;
            else
                bHasFullyMappedIOs = all([aoIOItfs(:).bMappingValid]);
            end
        end
        
        %%
        function bIsExpFuncModel = isExportFuncModel(oScope)
            bIsExpFuncModel = ...
                (oScope.bScopeIsModelBlock || oScope.bScopeIsModel) ...
                && i_hasFcnCallRootInport(oScope.sSubSystemAccess);
        end
        
        %%
        % depth-first hierarchy
        function aoScopes = getDescendants(oScope)
            aoScopes = getSelfAndDescendants(oScope);
            aoScopes(1) = [];
        end
        
        %%
        % depth-first hierarchy including self
        function aoScopes = getSelfAndDescendants(oScope)
            aoScopes = oScope;
            
            for i = 1:numel(oScope.oaChildrenScopes)
                aoScopes = [aoScopes, getSelfAndDescendants(oScope.oaChildrenScopes(i))]; %#ok<AGROW>
            end
        end
        
        %%
        function sMainModel = getMainModelName(oScope)
            sMainModel = i_getModelRootPart(oScope.sSubSystemFullName);
        end
                
        %%
        function sParentModel = getParentModelName(oScope)
            sParentModel = i_getModelRootPart(oScope.sSubSystemAccess);
        end
        
        %%
        function bIsInModelRef = isPartOfReferencedModel(oScope)
            sMainModel = oScope.getMainModelName();
            sParentModel = oScope.getParentModelName();
            bIsInModelRef = ~strcmp(sMainModel, sParentModel);
        end

        %%
        function oAncestorScope = getAncestorWithCodeInfo(oScope)
            oAncestorScope = []; % no ancestor found
            
            n_MAX_HIERARCHY_DEPTH = 1000; % how many levels do we want to go up during the search
            for i = 1:n_MAX_HIERARCHY_DEPTH
                oScope = oScope.oParentScope;
                if isempty(oScope)
                    % breaking out if we have no ancestors above us
                    break;
                end
                
                if ~isempty(oScope.sCFunctionName)
                    oAncestorScope = oScope;
                    % breaking out for the first ancestor that has a non-empty code info
                    break;
                end
            end
        end
        
        %%
        function bHas = hasTriggerPort(oScope)
            bHas = oScope.stExtendedInterface.bHasTriggerPort;
        end
        
        %%
        function bHas = hasEnablePort(oScope)
            bHas = oScope.stExtendedInterface.bHasEnablePort;
        end
        
        %%
        function hIsPathInScopeContext = getContextMatcherForScope(oScope)
            if isempty(oScope.astSLFunctions)
                casContextPaths = {oScope.sSubSystemFullName};
            else
                casContextPaths = {oScope.sSubSystemFullName, oScope.astSLFunctions(:).sVirtualPath};
            end
            hIsPathInScopeContext = i_getRootPathMatcher(casContextPaths);
        end
        
        %%
        function bIsActive = isActive(oScope)
            bIsActive = ~isempty(oScope.nHandle) && i_isActive(oScope);
        end

    end
end


%%
function bIsActive = i_isActive(oScope)
if oScope.bScopeIsModel
    bIsActive = true;
    return;
end

try
    sActiveState = get_param(oScope.nHandle, 'CompiledIsActive');
    bIsActive = ~strcmp(sActiveState, 'off');
    
catch oEx %#ok<NASGU>
    bIsActive = false;
end
end


%%
function sModel = i_getModelRootPart(sBlockPath)
sModel = regexprep(sBlockPath, '/.+$', '');
end


%%
function bHasRootFcnCall = i_hasFcnCallRootInport(sModel)
bHasRootFcnCall = numel(ep_core_feval('ep_find_system', sModel, ...
    'SearchDepth',        1, ...
    'BlockType',          'Inport', ...
    'OutputFunctionCall', 'on')) > 0;
end


%%
function hMatcher = i_getRootPathMatcher(casCandidateRootPaths)
casMatchPatterns = cellfun(@(s) ['^', regexptranslate('escape', s), '/'], casCandidateRootPaths, 'uni', false);

hMatcher = @(s) i_anyMatch(s, casMatchPatterns);
end


%%
function bIsMatching = i_anyMatch(sString, casMatchingPatterns)
bIsMatching = false;

for i = 1:numel(casMatchingPatterns)
    bIsMatching = ~isempty(regexp(sString, casMatchingPatterns{i}, 'once'));
    if bIsMatching
        return;
    end
end
end
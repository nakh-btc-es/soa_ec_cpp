function [oRootScope, aoRunnableScopes] = getAutosarRootScope(oEca)
%Scopes as Autosars Runnables

if strcmp(oEca.sAutosarArchitectureType, 'SWC')
    % Get all Runnables as Scopes
    aoRunnableScopes = oEca.getAutosarRunnableScopes([], false);
    if (numel(aoRunnableScopes) == 1)
        aoRunnableScopes.bIsRootScope = true;
        oRootScope = aoRunnableScopes;
        
        % Get children scopes of the single runnable
        if oEca.stActiveConfig.ScopeCfg.AnalyzeScopesHierarchy
            oRootScope.oaChildrenScopes = oEca.getChildrenScopes(oRootScope);
        end
    else
        [oRootScope, aoRunnableScopes] = oEca.getAutosarDummyScope();
    end
	
	if oEca.bDiagMode
		sLink = sprintf('<a href = "matlab:open_system(''%s'');hilite_system(''%s'')">%s</a>',...
			oEca.sModelName, oRootScope.sSubSystemFullName, oRootScope.sSubSystemFullName);
		fprintf('\n## Scope %s has been detected \n', sLink);
	end	
else
    %SWC_WRAPPER (Multiple Runnables)
    [oRootScope, aoRunnableScopes] = oEca.getAutosarWrapperScope();
end
end

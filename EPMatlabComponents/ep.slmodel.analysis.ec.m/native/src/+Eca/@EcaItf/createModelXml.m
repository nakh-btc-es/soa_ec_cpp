function createModelXml(oEca)
if oEca.bDiagMode
	fprintf('\n## Generation of Model whitelist xml file ...\n')
end

if oEca.bIsAdaptiveAutosar
    aoScopes = oEca.oRootScope;
else
    aoScopes = oEca.getAllValidScopes();
end

%Subsystems
castSubsystems = {};
for k = 1:numel(aoScopes)
    if aoScopes(k).bIsRootScope
        Attributes.isTopLevel = 'true';
    else
        Attributes.isTopLevel = 'false';
    end
    Attributes.modelPath = aoScopes(k).sSubSystemFullName;
    castSubsystems{end + 1}.Attributes = Attributes; %#ok<AGROW>
end

% Parameters
castParameters = {};
if oEca.bMergedArch
    if oEca.bIsAdaptiveAutosar
        % TODO: support for Parameters in AA models
        aoParamItfs = [];
    else
        stGeneral = oEca.stActiveConfig.General;
        aoParamItfs = oEca.oRootScope.getAllValidUniqParamInclChdrScopes(stGeneral.bExcludeParamsWithoutMapping);
    end
else
    % Simulink SIL
    aoParamItfs = oEca.oRootScope.oaParameters;
end
if ~isempty(aoParamItfs)
    casParamNames = arrayfun(@(o) o.getName(), aoParamItfs, 'UniformOutput', false);
    for k = 1:numel(casParamNames)
        castParameters{end + 1}.Attributes.name = casParamNames{k}; %#ok<AGROW>
    end
end

% Locals
castLocals = {};
if oEca.bMergedArch
    if oEca.bIsAdaptiveAutosar
        % TODO: support for Locals in AA models
        oaLocalItfs = [];
    else
        oaLocalItfs = oEca.oRootScope.getAllValidUniqLocalsInclChdrScopes();
    end
else
    % Simulink SIL
	oaLocalItfs = oEca.oRootScope.oaLocals;
end
if ~isempty(oaLocalItfs)
    % Find unique local signal block and port
    casLocalsPathsUniqueTmp = {};
     for k = 1:numel(oaLocalItfs)
        casLocalsPathsUniqueTmp{end + 1} = ...
            [oaLocalItfs(k).sourceBlockFullName, '(',num2str(oaLocalItfs(k).sourceBlockPortNumber),')']; %#ok<AGROW>
     end
    [casLocalsPathsUnique, idxSource, ~] = unique(casLocalsPathsUniqueTmp);
    for k = 1:numel(casLocalsPathsUnique)
        castLocals{end + 1}.Attributes.modelPath = oaLocalItfs(idxSource(k)).sourceBlockFullName; %#ok<AGROW>
        castLocals{end}.Port.Attributes.number = num2str(oaLocalItfs(idxSource(k)).sourceBlockPortNumber);
    end
end

stAdditionalModelInformation.Subsystems.Attributes.usage  = 'whitelist';
stAdditionalModelInformation.Subsystems.Subsystem         = castSubsystems;
stAdditionalModelInformation.Parameters.GlobalParameter   = castParameters;
stAdditionalModelInformation.Locals.Local                 = castLocals;

stETXml.AdditionalModelInformation = stAdditionalModelInformation;

ep_core_feval('epecastruct2xml', stETXml, oEca.sModelInfoXmlFile);
end

function createMessages(oEca)
if isempty(oEca.EPEnv)
    return;
end

if isempty(oEca.oRootScope)
    oEca.addMessageEPEnv('EP:SLC:WARNING', 'msg', 'No EP compliant scope has been detected in the model.');
    return;
end

% TODO: later support warnings/errors also for AA models
if oEca.bIsAdaptiveAutosar
    return;
end

casWarnings = {};
[aoScopes, astEval] = oEca.getAllScopesWithEvaluatedValidity();
for iScope = 1:numel(aoScopes)
    if ~astEval(iScope).bIsValid
        casWarnings{end + 1} = ...
            sprintf('Subsystem "%s" has been excluded from the scopes hierarchy:\n%s', ...
            aoScopes(iScope).sSubSystemFullName, ...
            i_concatWithNewline(astEval(iScope).casNotes)); %#ok<AGROW>
    else
        if ~aoScopes(iScope).hasFullyMappedIOs()
            casWarnings{end + 1} = ...
                sprintf('Subsystem "%s" has incomplete interface mapping.', ...
                aoScopes(iScope).sSubSystemFullName); %#ok<AGROW>
        end
    end
end
if ~isempty(casWarnings)
    oEca.addMultiWarningsEPEnv(casWarnings);
end

if ~oEca.anyInterfacesMapped(aoScopes)
    oEca.addMessageEPEnv('EP:SLC:ERROR', 'msg', 'The model analysis reported no interface mapping for all analyzed scopes.')
else
    %potential analysis notes of each interfaces
    casWarnings = {};
    for iScope = 1:numel(aoScopes)
        oScope = aoScopes(iScope);
        oaItfs = [oScope.oaInputs, oScope.oaOutputs, oScope.oaParameters, oScope.oaLocals];
        if isempty(oaItfs)
            if ~oScope.isExportFuncModel() && oScope.isActive()
                casWarnings{end + 1} = ...
                    sprintf('No interfaces have been detected for scope %s.', oScope.sSubSystemFullName); %#ok<AGROW>
            end
        else
            for iItf = 1:numel(oaItfs)
                if ~isempty(oaItfs(iItf).casAnalysisNotes)
                    casWarnings{end + 1} = ...
                        sprintf('[%s] interface "%s" of scope "%s": %s', oaItfs(iItf).kind, ...
                        oaItfs(iItf).getDisplayName(), oScope.sSubSystemFullName,  ...
                        i_concatWithNewline(oaItfs(iItf).casAnalysisNotes)); %#ok<AGROW>
                end
            end
        end
    end
    if ~isempty(casWarnings)
        oEca.addMultiWarningsEPEnv(casWarnings);
    end
    
    %stub generation messages
    if oEca.bStubGenerated
        oEca.addMessageEPEnv('EP:SLC:WARNING', 'msg', sprintf('The following stub files have been created\n%s', ...
            i_concatWithNewline(oEca.oRootScope.casStubFiles)));
        
        %Stubbed interfaces
        aoStubItfs = oEca.oRootScope.oaStubbedIfs;        
        
        if ~isempty(aoStubItfs)
            for iItf = 1:numel(aoStubItfs)
                str = '';
                if aoStubItfs(iItf).bHFileMissing
                    str = sprintf( ...
                        '%sStub declaration of [%s] interface "%s" has been created in the generated stub file "%s".\n', ...
                        str, aoStubItfs(iItf).kind, aoStubItfs(iItf).name, aoStubItfs(iItf).codeHeaderFile);
                end
                if aoStubItfs(iItf).bCFileMissing
                    sDefStubFile = oEca.getStubSourceFile('main');
                    if oEca.stConfig.General.GenerateSeparateStubFiles && ~isempty(aoStubItfs(iItf).codeDefinitionFile)
                        sDefStubFile = fullfile(fileparts(sDefStubFile), aoStubItfs(iItf).codeDefinitionFile);
                    end
                    str = sprintf( ...
                        '%sStub definition of [%s] interface "%s" has been created in the generated stub file "%s".', ...
                        str, aoStubItfs(iItf).kind, aoStubItfs(iItf).name, sDefStubFile);
                end
                %write message
                oEca.addMessageEPEnv('EP:SLC:INFO', 'msg', str);
            end
        end
        
        %Stubbed defines
        stubDefineItfs = oEca.oRootScope.oaStubbedDefs;
        if ~isempty(stubDefineItfs)
            for iItf = 1:numel(stubDefineItfs)
                %write message
                oEca.addMessageEPEnv('EP:SLC:INFO', 'msg', ...
                    sprintf('Stub definition of macro "%s" has been defined in the generated stub file "%s".',...
                    stubDefineItfs(iItf).name, stubDefineItfs(iItf).codeHeaderFile));
            end
        end
    end
end
end


%%
function sString = i_concatWithNewline(casStrings)
if isempty(casStrings)
    sString = '';
else
    casStrings = cellstr(casStrings);
    sString = sprintf('%s\n', casStrings{:});
    sString(end) = [];
end
end

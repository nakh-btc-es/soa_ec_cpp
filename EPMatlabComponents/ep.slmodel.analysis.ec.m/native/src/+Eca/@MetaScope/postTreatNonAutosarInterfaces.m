%postTreatNonAutosarInterfaces
function aoItfs = postTreatNonAutosarInterfaces(oScope, aoItfs)
% 1) Search for missing declaration & definition files of interfaces and mark interfaces to be stubded
% 2) Deactivate mapping if code variables is mapped mutiple times in the same scope

if ~isempty(aoItfs)
    %g et C-files names
    if ~isempty(oScope.astCodegenSourcesFiles)
        casAllCFileNames = Eca.EcaItf.FileName({oScope.astCodegenSourcesFiles(:).path});
    else
        casAllCFileNames = {};
    end
    % get H-files names
    if ~isempty(oScope.casCodegenHeaderFiles)
        casAllHFileNames = Eca.EcaItf.FileName(oScope.casCodegenHeaderFiles);
    else
        casAllHFileNames = {};
    end
    
    % 1) Search for missing declaration & definition files of interfaces
    nIdxTreated = [];
    nIdxMapped = [aoItfs(:).bMappingValid];
    casNames = {aoItfs(:).name};
    casStructNames = {aoItfs(:).codeStructName};
    casStructAccess = {aoItfs(:).codeStructComponentAccess};
    casCodeVars = {aoItfs(:).codeVariableName};
    
    for iItf = 1:numel(aoItfs)
        % Treat only Interfaces which have valid mapping
        if aoItfs(iItf).bMappingValid
            % Apply to only non-autosar interfaces which require stubbed variables
            if ~aoItfs(iItf).bIsAutosarCom && ~isempty(aoItfs(iItf).codeFormatCfg) && aoItfs(iItf).codeFormatCfg.Stub.canBeStubbed
                % Missing files
                if strcmpi(aoItfs(iItf).kind , 'DEFINE')
                    isHFileMissing = ~ismember(aoItfs(iItf).codeHeaderFile, casAllHFileNames);
                    aoItfs(iItf).bHFileMissing = isHFileMissing;
                    aoItfs(iItf).bStubNeeded   = isHFileMissing;
                else
                    if ~isempty(aoItfs(iItf).codeFormatCfg)
                        if aoItfs(iItf).bMappingValid
                            isHFileMissing = ~ismember(aoItfs(iItf).codeHeaderFile, casAllHFileNames);
                            isCFileMissing = ~ismember(aoItfs(iItf).codeDefinitionFile, casAllCFileNames);
                            aoItfs(iItf).bCFileMissing = isCFileMissing;
                            aoItfs(iItf).bHFileMissing = isHFileMissing;
                            aoItfs(iItf).bStubNeeded   = isCFileMissing || isHFileMissing;
                        end
                    end
                end
            end
            
            % 2) Deactivate mapping if code variables is mapped mutiple times in the same scope
            if ismember(aoItfs(iItf).kind , {'IN', 'OUT', 'LOCAL'})
                if not(ismember(iItf, nIdxTreated))
                    nIdxName = ismember(casNames, aoItfs(iItf).name);
                    %Logical indexes of other interfaces having same name and same code variable
                    if aoItfs(iItf).isCodeStructComponent
                        nIdxCodeStructName = ismember(casStructNames, aoItfs(iItf).codeStructName);
                        nIdxCodeStructComponentAccess = ismember(casStructAccess, aoItfs(iItf).codeStructComponentAccess);
                        nIdxSameCodeRep = nIdxName & nIdxCodeStructName & nIdxCodeStructComponentAccess & nIdxMapped;
                    else
                        nIdxCodeVariableName = ismember(casCodeVars, aoItfs(iItf).codeVariableName);
                        nIdxSameCodeRep = nIdxName & nIdxCodeVariableName & nIdxMapped;
                    end
                    %Logical indexes of the ones detected as mappable
                    nIdxSameCodeRep = find(nIdxSameCodeRep);
                    
                    if (numel(nIdxSameCodeRep) > 1)
                        casItfBlockPaths = {aoItfs(nIdxSameCodeRep).sourceBlockFullName};
                        %Deactivate mapping on other interfaces
                        for iItfTmp = 1:numel(nIdxSameCodeRep)
                            aoItfs(nIdxSameCodeRep(iItfTmp)).bMappingValid = false;
                            aoItfs(nIdxSameCodeRep(iItfTmp)).bMappingCanceled = true;
                            aoItfs(nIdxSameCodeRep(iItfTmp)).casAnalysisNotes{end + 1} = ...
                                sprintf('Signal cannot be mapped because its code variable is accessed by multiple interfaces: %s',...
                                sprintf('\n-- %s', casItfBlockPaths{:}));
                        end
                        nIdxTreated = [nIdxTreated nIdxSameCodeRep];
                    end
                end
            end
        end
    end
end
end

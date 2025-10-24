function oEca = updateSourceFileList(oEca, casStubHFiles, casStubCFiles, sStubVarInitFunc)
% Update file dependencies with newly generated files


%%
if (nargin < 4)
    sStubVarInitFunc = '';
end

% Source files
for k = 1:numel(casStubCFiles)
    if ~ismember(strrep(casStubCFiles{k},'/','\'), strrep({oEca.oRootScope.astCodegenSourcesFiles(:).path},'/','\'))
        %Sources files
        stTmp.path  = casStubCFiles{k};
        stTmp.codecov = false;
        stTmp.hide = true;
        oEca.oRootScope.astCodegenSourcesFiles(end+1) = stTmp;
        
        % hack: currently the list is handled in (all) scopes *and* in main object
        oEca.astCodegenSourcesFiles(end+1) = stTmp;
    end
end
% Header files
for k = 1:numel(casStubHFiles)
    if ~ismember(strrep(casStubHFiles{k},'/','\'), strrep(oEca.oRootScope.casCodegenHeaderFiles,'/','\'))
        %Sources files
        oEca.oRootScope.casCodegenHeaderFiles{end+1} = casStubHFiles{k};
        
        % hack: currently the list is handled in (all) scopes *and* in main object
        oEca.casCodegenHeaderFiles{end+1} = casStubHFiles{k};
    end
end
% Include paths
casPaths = cellfun(@(x) fileparts(x), [casStubHFiles, casStubCFiles], 'UniformOutput', false);
for k = 1:numel(casPaths)
    if ~ismember(strrep(casPaths{k},'/','\'), strrep(oEca.oRootScope.casCodegenIncludePaths,'/','\'))
        %Sources files
        oEca.oRootScope.casCodegenIncludePaths{end+1} = casPaths{k};
        
        % hack: currently the list is handled in (all) scopes *and* in main object
        oEca.casCodegenIncludePaths{end+1} = casPaths{k};
    end
end
oEca.oRootScope.casStubFiles = [casStubHFiles, casStubCFiles];
oEca.oRootScope.sStubVarInitFunc = sStubVarInitFunc;
end

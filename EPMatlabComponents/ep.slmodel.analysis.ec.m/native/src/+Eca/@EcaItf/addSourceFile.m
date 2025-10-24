function oEca = addSourceFile(oEca, sSourceFile)
% Add a new source file to the list of known source files



%%
if ~ismember(strrep(sSourceFile, '/', '\'), strrep({oEca.oRootScope.astCodegenSourcesFiles(:).path}, '/' , '\'))
    stFile.path    = sSourceFile;
    stFile.codecov = true;
    stFile.hide    = false;

    oEca.oRootScope.astCodegenSourcesFiles(end + 1) = stFile;

    % hack: currently the list is handled in (all) scopes *and* in main object
    oEca.astCodegenSourcesFiles(end + 1) = stFile;
end
end

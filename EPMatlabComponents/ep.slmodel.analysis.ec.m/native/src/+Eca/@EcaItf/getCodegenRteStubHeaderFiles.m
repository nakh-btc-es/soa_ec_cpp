function casHeaderFiles = getCodegenRteStubHeaderFiles(oEca)

oBuildInfo = oEca.getStoredBuildInfo();

bConcatPaths = true;
bReplaceAnchors = false;
casHeaderFilesWithAnchors = oBuildInfo.getIncludeFiles(bConcatPaths, bReplaceAnchors);

abSelect = false(size(casHeaderFilesWithAnchors));
for i = 1:numel(casHeaderFilesWithAnchors)
    sFile = casHeaderFilesWithAnchors{i};
    if ~isempty(regexp(casHeaderFilesWithAnchors{i}, '^\$\(START_DIR\)', 'once'))
        [sPath, sName] = fileparts(sFile);

        if ~isempty(regexp(sName, '^Rte_', 'once'))
            [~, sParentDirName] = fileparts(sPath);
            if strcmpi(sParentDirName, 'stub')
                abSelect(i) = true;
            end
        end
    end
end

if any(abSelect)
    bConcatPaths = true;
    bReplaceAnchors = true;
    casAllHeaderFiles = oBuildInfo.getIncludeFiles(bConcatPaths, bReplaceAnchors);
    casHeaderFiles = casAllHeaderFiles(abSelect);
else
    casHeaderFiles = {};
end
end

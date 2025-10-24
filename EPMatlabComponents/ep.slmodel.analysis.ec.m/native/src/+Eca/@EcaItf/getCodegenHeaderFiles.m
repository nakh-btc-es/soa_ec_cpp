function casHeaderFiles = getCodegenHeaderFiles(oEca, bReducedToStartDir)
if (nargin < 2)
    bReducedToStartDir = false;
end

oBuildInfo = oEca.getStoredBuildInfo();
casHeaderFiles = getFullFileList(oBuildInfo, 'include');
if bReducedToStartDir
    bConcatenatePaths = true;
    bReplaceMatlabroot = false;
    casAllHeaders = oBuildInfo.getFiles('include', bConcatenatePaths, bReplaceMatlabroot);
    abContainsStartDir = contains(casAllHeaders, '(START_DIR)');
    casHeaderFiles = casHeaderFiles(abContainsStartDir);
end
end

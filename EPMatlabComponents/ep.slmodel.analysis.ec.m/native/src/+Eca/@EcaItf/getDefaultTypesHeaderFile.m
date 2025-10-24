function [sMainHeaderFile, casDefaultTypesHeaderFiles] = getDefaultTypesHeaderFile(oEca)
% This function return the main header file (by default it is model.h) and the types header (by default model_types.h)

oBuildInfo = oEca.getStoredBuildInfo();
casIncludeFiles = oBuildInfo.getIncludeFiles(false, false);

sMainHeaderFile = casIncludeFiles{1};
casDefaultTypesHeaderFiles = casIncludeFiles(~cellfun('isempty', regexp(casIncludeFiles, '(.*)types(.*).h', 'once')));
end


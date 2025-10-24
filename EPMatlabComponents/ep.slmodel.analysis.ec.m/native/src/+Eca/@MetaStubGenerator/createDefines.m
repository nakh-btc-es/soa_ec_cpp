%% Defines
function sFileContent = createDefines(oStubGen, aoStubInfo)

sFileContent = '';
if ~isempty(aoStubInfo)
    for iItem = 1:numel(aoStubInfo)
        sFileContent =  [sFileContent, '#define  ', aoStubInfo(iItem).sDefineName, ' ', aoStubInfo(iItem).sDefineValue, ' \n'];
    end
    sFileContent  = sprintf(sFileContent);
end
end
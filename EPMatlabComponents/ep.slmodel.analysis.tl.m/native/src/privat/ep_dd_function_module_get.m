function [sModuleName, sModuleType] = ep_dd_function_module_get(hFunc)
sModuleName = '';
sModuleType = '';

if verLessThan('tl', '23.1')
    hFuncParent = dsdd('GetAttribute', hFunc, 'hDDParent');
else
    hFuncGroup  = dsdd('GetAttribute', hFunc, 'hDDParent');
    hFuncParent = dsdd('GetAttribute', hFuncGroup, 'hDDParent');
end
[bExist, hModule] = dsdd('Exist', hFuncParent, 'objectKind', 'Module');
if bExist
    hModuleInfo = dsdd('GetModuleInfo', hModule);
    ahFileInfo = dsdd('Find', hModuleInfo, 'objectKind', 'FileInfo', 'property', {'name', 'FileType'});
    nFiles = length(ahFileInfo);
    for i = 1:nFiles
        hFileInfo = ahFileInfo(i);
        sFileKind = dsdd('GetFileKind', hFileInfo);
        if strcmpi(sFileKind, 'SourceFile')
            sModuleName = dsdd('GetFileName', hFileInfo);
            sModuleType = dsdd('GetFileType', hFileInfo);
            break;
        end
    end
end
end

function oEca = createMultiInstanceAdapterLayer(oEca)
% Update file dependencies with newly generated files


%%
if oEca.bIsWrapperComplete
    oRunnableScope = oEca.aoRunnableScopes(1);
    [oRunnableScope, stFile] = ...
        i_createMultiInstanceAdapterLayer(oRunnableScope, oEca.getStubCodeDir());
    oEca.aoRunnableScopes(1) = oRunnableScope;
    oEca.oRootScope.oaChildrenScopes(1) = oRunnableScope;
    oEca.oRootScope.astCodegenSourcesFiles = [stFile, oEca.oRootScope.astCodegenSourcesFiles];

else
    oEca.oRootScope = i_createMultiInstanceAdapterLayer(oEca.oRootScope, oEca.getStubCodeDir());
end
end


%%
function [oRootScope, stFile] = i_createMultiInstanceAdapterLayer(oRootScope, sStubCodeDir)
sAdapterFileName = 'ep_autosar_multi_instance_adapter.c';
sAdapterFile = fullfile(sStubCodeDir, sAdapterFileName);

sStepFunc = oRootScope.sCFunctionName;
sAdapterStepFunc = ep_core_feval('ep_ec_ar_multi_instance_adapter_function_get', sStepFunc);

sInitFunc = oRootScope.sInitCFunctionName;
sAdapterInitFunc = ep_core_feval('ep_ec_ar_multi_instance_adapter_function_get', sInitFunc);

casContentLines = {...
    '#include "Rte_Type.h"', ...
    '', ...
    sprintf('extern void %s(Rte_Instance self);', sStepFunc) ...
    sprintf('extern void %s(Rte_Instance self);', sInitFunc) ...
    '', ...
    sprintf('void %s() {', sAdapterStepFunc) ...
    sprintf('  %s((void*)0);', sStepFunc), ...
    '}', ...
    '', ...
    sprintf('void %s() {', sAdapterInitFunc) ...
    sprintf('  %s((void*)0);', sInitFunc), ...
    '}'};
i_writeFile(sAdapterFile, casContentLines);

oRootScope.sCFunctionName = sAdapterStepFunc;
oRootScope.sInitCFunctionName = sAdapterInitFunc;
oRootScope.sCFunctionDefinitionFileName = sAdapterFileName;
oRootScope.sCFunctionDefinitionFile = sAdapterFile;

% after adapting the C-function and C-file names, also the C-Path as used in EP has to be adapted
sNewCPathPart = sprintf('%s:1:%s', sAdapterFileName, sAdapterStepFunc);
sOldCPath = oRootScope.sEPCFunctionPath;
bIsChildPath = any(sOldCPath == '/'); % we have a child path, if there is a path separator '/'
if bIsChildPath
    % if we have a child C-Path path, only replace the child part of the original C-Path
    sNewCPath = [regexprep(sOldCPath, '(.*/).*$', '$1'), sNewCPathPart];
else
    sNewCPath = sNewCPathPart;
end
oRootScope.sEPCFunctionPath = sNewCPath;

stFile = struct( ...
    'path',    sAdapterFile, ...
    'codecov', false, ...
    'hide',    false);
oRootScope.astCodegenSourcesFiles = [stFile, oRootScope.astCodegenSourcesFiles];
end


%%
function i_writeFile(sFile, casLines)
sDir = fileparts(sFile);
if ~exist(sDir, 'dir')
    mkdir(sDir);
end

hFid = fopen(sFile, 'wt');
if (hFid)
    xOnCleanupClose = onCleanup(@() fclose(hFid));
    
    for i = 1:length(casLines)
        fprintf(hFid, '%s\n', casLines{i});
    end
end
end



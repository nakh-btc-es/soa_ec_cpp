function oScope = getCodeInfoModelAA(oEca, oScope)
% Extracting C-Artifact info for the AA model directly.
%

sModelName = oEca.sAutosarModelName;
sCodegenPath = oEca.getStubCodeDir;

oScope.sCFunctionName               = sprintf('%s_step', sModelName);
oScope.sCFunctionUpdateName         = '';
oScope.sInitCFunctionName           = sprintf('%s_init', sModelName);
oScope.sCFunctionDefinitionFileName = sprintf('%s_adapter.cpp', sModelName);
oScope.sCFunctionDefinitionFile     = fullfile(sCodegenPath, oScope.sCFunctionDefinitionFileName);


oScope.sEPCFunctionPath = [oScope.sCFunctionDefinitionFileName, ':1:', oScope.sCFunctionName];
end


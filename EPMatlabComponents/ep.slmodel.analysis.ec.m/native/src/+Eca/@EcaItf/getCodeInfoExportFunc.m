function stCodeInfo = getCodeInfoExportFunc(oEca, oScope, sExportFunName)

sMainModel = oScope.getMainModelName();
sParentModel = oScope.getParentModelName();
bIsScopeInsideRefModel = ~strcmp(sMainModel, sParentModel);

sFuncPrefix = '';
sCodegenPath = oEca.sCodegenPath;
if bIsScopeInsideRefModel
    sFuncPrefix = [sParentModel, '_'];
    sCodegenPath = ''; % note: with current info not possible to determine the location of the model reference C-file
end


stCodeInfo = oEca.getCodeInfoDefault();
stCodeInfo.sCFunctionName                = [sFuncPrefix, sExportFunName];
stCodeInfo.sInitCFunctionName            = [sMainModel, '_initialize'];
stCodeInfo.sCFunctionDefinitionFileName  = [sParentModel, '.c'];
stCodeInfo.sCFunctionDefinitionFile      = fullfile(sCodegenPath, stCodeInfo.sCFunctionDefinitionFileName);
stCodeInfo.sEPCFunctionPath              = [stCodeInfo.sCFunctionDefinitionFileName, ':1:', stCodeInfo.sCFunctionName];
stCodeInfo.bHasFuncArgs                  = false;
stCodeInfo.sCFunctionUpdateName          = ''; % note: it seems there are *no* update functions for exported functions
end


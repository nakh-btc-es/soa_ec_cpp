function stCodeInfo = getCodeInfoModel(oEca)
% Extracting C-Artifact info for the model directly.
%

sModelName = oEca.sModelName;
nHandle = get_param(sModelName, 'handle');
sCodegenPath = oEca.sCodegenPath;

hModel = bdroot(nHandle);
map = oEca.mCombineOutputUpdate;
sSetting = map(hModel);

stCodeInfo = oEca.getCodeInfoDefault();
if strcmp(sSetting, 'off')
    stCodeInfo.sCFunctionName = [sModelName, '_output'];
    stCodeInfo.sCFunctionUpdateName = [sModelName, '_update'];
else
    stCodeInfo.sCFunctionName = [sModelName, '_step'];
    stCodeInfo.sCFunctionUpdateName = '';
end
stCodeInfo.sInitCFunctionName = [sModelName '_initialize'];
if oEca.bIsAdaptiveAutosar
    stCodeInfo.sCFunctionDefinitionFileName = [sModelName '.cpp'];
else
    stCodeInfo.sCFunctionDefinitionFileName = [sModelName '.c'];
end
stCodeInfo.sCFunctionDefinitionFile = fullfile(sCodegenPath, stCodeInfo.sCFunctionDefinitionFileName);


if oEca.isExportFuncModel()
    stCodeInfo.sCFunctionName = '';
else
    oFuncSpec = RTW.getFunctionSpecification(sModelName);
    if isa(oFuncSpec, 'RTW.ModelSpecificCPrototype')
        % model specified specific function prototype (including function arguments)
        stCodeInfo.sCFunctionName       = oFuncSpec.FunctionName;
        stCodeInfo.sInitCFunctionName   = oFuncSpec.InitFunctionName;   
        stCodeInfo.bHasFuncArgs         = (oFuncSpec.getNumArgs() > 0);
        stCodeInfo.sCFunctionUpdateName = [];
    end
end
if ~isempty(stCodeInfo.sCFunctionName)
    stCodeInfo.sEPCFunctionPath = [stCodeInfo.sCFunctionDefinitionFileName, ':1:', stCodeInfo.sCFunctionName];
end
end


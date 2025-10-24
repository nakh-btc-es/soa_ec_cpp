function stCodeInfo = createAdapterCodeAA(oEca)


sModelName  = oEca.sAutosarModelName;
sAdapterFileName = [sModelName '_adapter.cpp'];
sAdapterSourceFile = fullfile(oEca.sAutosarCodegenPath, sAdapterFileName);

stAdapterInfo = ep_core_feval('ep_ec_aa_adapter_code_create', sModelName, sAdapterSourceFile);
stCodeInfo = i_getCodeInfoModel(oEca, sAdapterSourceFile, stAdapterInfo);
end



%%
function stCodeInfo = i_getCodeInfoModel(oEca, sAdapterSourceFile, stAdapterInfo)
% Extracting C-Artifact info for the model directly.
%

[~, f, e] = fileparts(sAdapterSourceFile);
sAdapterSourceFileName = [f, e];

stCodeInfo = oEca.getCodeInfoDefault();
stCodeInfo.sCFunctionName               = stAdapterInfo.sStepFunc;
stCodeInfo.sCFunctionUpdateName         = '';
stCodeInfo.sInitCFunctionName           = stAdapterInfo.sInitFunc;
stCodeInfo.sCFunctionDefinitionFileName = sAdapterSourceFileName;
stCodeInfo.sCFunctionDefinitionFile     = sAdapterSourceFile;

if ~isempty(stCodeInfo.sCFunctionName)
    stCodeInfo.sEPCFunctionPath = [stCodeInfo.sCFunctionDefinitionFileName, ':1:', stCodeInfo.sCFunctionName];
end
end


function oEca = generateCode(oEca)

% generate or re-use existing code (note: slightly different for AUTOSAR and non-AUTOSAR)
oEca.consoleInfoPrint('## Start code generation ...');
if oEca.bIsAutosarArchitecture
    % call hook for wrapper if needed
    if (strcmp(oEca.sAutosarArchitectureType, 'SWC_WRAPPER') && ~oEca.bIsWrapperComplete)
        oEca = i_callWrapperHook(oEca);
    end
    oModelOrigActiveCfg = getActiveConfigSet(oEca.hAutosarModel);

    stCodeInfo = i_generateOrReuseCode(oEca.hAutosarModel, oEca);
    oEca.sAutosarCodegenPath = stCodeInfo.sCodegenPath;
    oEca.oAutosarBuildInfo = stCodeInfo.oBuildInfo;

    if ~oEca.bIsAdaptiveAutosar
        ep_core_feval('ep_ec_autosar_extended_rte_types_create', 'ModelName', oEca.sAutosarModelName);
    end
    
else
    oModelOrigActiveCfg = getActiveConfigSet(oEca.hModel);
    
    stCodeInfo = i_generateOrReuseCode(oEca.hModel, oEca);
    oEca.sCodegenPath = stCodeInfo.sCodegenPath;
    oEca.oBuildInfo = stCodeInfo.oBuildInfo;
end
oEca.oModelActiveCfg = oModelOrigActiveCfg;
end


%%
function oEca = i_callWrapperHook(oEca)
stUserDefinedSchedulerFun = oEca.evalHook('ecahook_autosar_wrapper_function_info');

if ~isempty(stUserDefinedSchedulerFun.sCFile)
    % Wrapper code provided by hook function
    oEca.stAutosarWrapperCodeInfo = stUserDefinedSchedulerFun;
else
    % Generate wrapper code
    oEca.consoleInfoPrint('## Generate wrapper code ...');
    oEca.stAutosarWrapperCodeInfo = oEca.generateCodeAutosarScheduler(stUserDefinedSchedulerFun.casIncludePaths);
    oEca.sAutosarWrapperCodegenPath = fileparts(oEca.stAutosarWrapperCodeInfo.sCFile);
end
end


%%
function stResult = i_generateOrReuseCode(hModel, oEca)
bReuseExistingCode = oEca.bReuseExistingCode;
sUserCodegenPath = oEca.stActiveConfig.General.sCodegenPath;
[stResult, bSuccess] = ep_core_feval('ep_ec_codegen', hModel, bReuseExistingCode, sUserCodegenPath);

if ~bSuccess
    if isempty(stResult.oBuildInfo)
        throw(oEca.addMessageEPEnv('EP:CODE_GEN:EC_MISSING_EXISTING_CODE'));
    else
        casMissingFiles = stResult.casMissingFiles;
        for i = 1:numel(casMissingFiles)
            oEca.addMessageEPEnv('EP:CODE_GEN:EC_MISSING_CODEGEN_FILE', 'file', casMissingFiles{i});
        end
        throw(oEca.addMessageEPEnv('EP:CODE_GEN:EC_INCOMPLETE_EXISTING_CODE'));
    end
end
end

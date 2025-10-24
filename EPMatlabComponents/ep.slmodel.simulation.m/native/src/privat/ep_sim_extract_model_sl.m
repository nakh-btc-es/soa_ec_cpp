function stResult = ep_sim_extract_model_sl(xEnv, stSrcModelInfo, stExtrModelInfo, stArgs)
% This function extracts a subsystem from a model
%
% function stResult = ep_sim_extract_model_sl(xEnv, stArgs)
%
%  INPUT              DESCRIPTION
%   - xEnv            (object)  environment
%   - stSrcModelInfo  (struct)  Information about the SUT
%   - stArgs          (struct)  Information for the extraction model
%      .ModelRefMode  (int)     Model Reference Mode (0- Keep refs | 1- Copy refs | 2- Break refs)

%%

% create init script
sInitScriptFile = i_createInitScript(stExtrModelInfo.sName, stSrcModelInfo.xSubsys);

% copy content
[hSub, sNewSubsysPath] = i_copySutIntoExtractionModel(xEnv, stArgs, stSrcModelInfo, stExtrModelInfo);

% copy model settings
i_copyModelSettings(xEnv, stSrcModelInfo, stExtrModelInfo, stArgs);

% note: for the SL-workflow the outer harness is always directly connected to the SUT (!different to TL)
bHasDirectHarnessConnection = true;

% Result
stResult = struct( ...
    'ExtractionModel',              fullfile(stExtrModelInfo.sPath, [stExtrModelInfo.sName, '.slx']), ...
    'InitScript',                   sInitScriptFile, ...
    'TopLevelSubsystem',            getfullname(hSub), ...
    'hSubsystem',                   hSub, ...
    'sNewSubsysPath',               sNewSubsysPath, ...
    'hInnerHarnessLeft',            [], ...
    'hInnerHarnessRight',           [], ...
    'ModuleName',                   '', ...
    'stExtrModelInfo',              stExtrModelInfo, ...
    'bHasDirectHarnessConnection',  bHasDirectHarnessConnection);
end


%%
function [hSub, sNewSubsysPath] = i_copySutIntoExtractionModel(xEnv, stArgs, stSrcModelInfo, stExtrModelInfo)
[hSub, sNewSubsysPath] = ep_sut_subsystem_add(xEnv, stExtrModelInfo.hModel, stArgs, stSrcModelInfo);

stEnv = ep_core_legacy_env_get(xEnv, false);
atgcv_m13_add_memory_blocks(stEnv, stExtrModelInfo.sName, stSrcModelInfo.sSubsysPathPhysical, stSrcModelInfo.nUsage);
atgcv_m13_add_addfile_blocks(stExtrModelInfo.sName,  stSrcModelInfo.sSubsysPathPhysical, stSrcModelInfo.nUsage);
end


%%
function sInitScript = i_createInitScript(sName, xSubsystem)
sTargetPath = pwd;
bTLSilMode = false;
sInitScript = ep_simenv_init_script_gen(sTargetPath, [], sName , bTLSilMode, xSubsystem, true);
end


%%
function i_copyModelSettings(xEnv, stSrcModelInfo, stExtrModelInfo, stArgs)
stEnv = ep_core_legacy_env_get(xEnv, false);

hSubsystemParentModel = bdroot(get_param(stSrcModelInfo.sSubsysPathPhysical, 'handle'));
atgcv_m13_mdlbase_copy(hSubsystemParentModel, stExtrModelInfo.hModel);
atgcv_m13_mdl_callbacks_copy(stEnv, stSrcModelInfo.hModel, stExtrModelInfo.hModel);

sModelRefPath = atgcv_m13_modelref_get(stSrcModelInfo.xSubsys, stSrcModelInfo.bIsTlModel);
if isempty(sModelRefPath)
    ep_simenv_copy_model_settings(stEnv, bdroot(hSubBlock), stExtrModelInfo.hModel,  stSrcModelInfo.sSampleTime);
else
    hModelRef = get_param(sModelRefPath, 'handle');
    ep_simenv_copy_model_settings(stEnv, bdroot(hModelRef), stExtrModelInfo.hModel,  stSrcModelInfo.sSampleTime);
end

if stArgs.ModelRefMode ~= 0
    atgcv_m13_sf_settings_copy(stEnv, stSrcModelInfo.sModelName, stExtrModelInfo.sName, ...
        stSrcModelInfo.sModelPath, stExtrModelInfo.sPath,  stSrcModelInfo.sSampleTime);
end

atgcv_m13_sfdebug_disable(stEnv, stExtrModelInfo.sName); %see BTS/21566
end



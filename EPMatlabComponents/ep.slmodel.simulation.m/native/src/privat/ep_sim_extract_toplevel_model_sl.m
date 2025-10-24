function stResult = ep_sim_extract_toplevel_model_sl(xEnv, stSrcModelInfo, stExtrModelInfo, stArgs)
% This function extracts a subsystem from a model
%
% function stResult = ep_sim_extract_model_sl(xEnv, stArgs)
%
%  INPUT              DESCRIPTION
%   - xEnv             (object)  environment
%   - stSrcModelInfo   (struct)  Information about the SUT
%   - stExtrModelInfo  (struct)  Information about the extraction model
%   - stArgs           (struct)  additional arguments (really needed ???)
%

%%
% create init script
% Note: for SL-Top an init script is actually not required; however, the Java side cannot handle an empty return value
% for the InitScriptFile
sInitScriptFile = i_createInitScript(stExtrModelInfo.sName);
    
% copy content
[hSub, sNewSubsysPath] = i_createModelReferenceToSUT(stExtrModelInfo.hModel, stSrcModelInfo.sModelName, stSrcModelInfo.sModelExtension);

% copy model settings
i_copyModelSettings(xEnv, stSrcModelInfo, stExtrModelInfo.hModel);

% create post-open and pre-close callbacks
i_createOpenCloseCallbacks(stExtrModelInfo.sName, stSrcModelInfo.sModelName);

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
function [hSub, sNewSubsysPath] = i_createModelReferenceToSUT(hTargetModel, sSourceModelName, sSourceModelExt)
% create the model reference to the SUT.
hSub = i_addModelBlockSub(hTargetModel, sSourceModelName, sSourceModelExt);
sNewSubsysPath = getfullname(hSub);

% set position
arPosition = get_param(hSub, 'Position');
if (arPosition(2) < 100)
    arPosition(4) = arPosition(4) + 100 - arPosition(2);
    arPosition(2) = 100;
end
arNewPosition = [400 arPosition(2) 600 arPosition(4)];
set_param(hSub, 'Position', arNewPosition );
end


%%
function sInitScript = i_createInitScript(sTargetModel)
sTargetPath = pwd;
sInitScript = ep_sim_init_script_gen(sTargetPath, sTargetModel, @i_addContent);
end


%%
function i_copyModelSettings(xEnv, stSrcModelInfo, hTargetModel)
stEnv = ep_core_legacy_env_get(xEnv, false);
ep_simenv_copy_model_settings(stEnv, stSrcModelInfo.hModel, hTargetModel, stSrcModelInfo.sSampleTime);
end


%%
% src model shall be referenced from the target model
function hSub = i_addModelBlockSub(hTargetModel, sSrcModelName, sSourceModelExt)
% switch off warnings for now
if ~atgcv_debug_status
    stCurrentWarnings = warning('off', 'all');
    oOnCleanupRestoreWarning = onCleanup(@() warning(stCurrentWarnings));
end

sTargetModel = getfullname(hTargetModel);
hSub = add_block('built-in/ModelReference', [sTargetModel, '/', sSrcModelName]);
set_param(hSub, 'ModelName', [sSrcModelName sSourceModelExt]);

sSimMode = 'normal';
set_param(hSub, 'SimulationMode', sSimMode);
end


%%
%adds content to init script
function i_addContent(hFile)
fprintf(hFile, '\n%s\n', '% no special initialization steps required (intentionally left blank)');
end


%%
function i_createOpenCloseCallbacks(sExtModelName, sSimModelName)
ep_sim_sl_top_scripts_gen(sExtModelName, sSimModelName);
end



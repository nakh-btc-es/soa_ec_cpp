function ep_sim_sl_top_scripts_gen(sExtModelName, sSimModelName, sTargetDir)
% Generates a post open/pre close scripts for TL models in SL-TOP context
%
% function ep_sim_sl_top_scripts_gen(sExtModelName, sSimModelName, sTargetDir)
%
% INPUTS:
%     sExtModelName    (string)    name of the extraction model for which script is generated
%     sSimModelName    (string)    name of the SUT model
%     sTargetDir       (string)    optional: full path to the target folder where the scripts are placed
%                                  (default = pwd)


%%
if (nargin < 3)
    sTargetDir = pwd;
end

%%
bIsTL = i_isTLModel(sSimModelName);
if bIsTL
    i_crateCallbacksForTL(sExtModelName, sSimModelName, sTargetDir);    
else
    % TODO: nothing to do yet for SL models; later we should move SL-DD handling here
end
end


%%
function i_crateCallbacksForTL(sExtModelName, sSimModelName, sTargetDir)
hSimModel = get_param(sSimModelName, 'Handle');
hMilHandler = ep_find_system(hSimModel, 'FindAll', 'On', 'SearchDepth', 1, 'MaskType', 'TL_MilHandler');
if isempty(hMilHandler)
    return;
end
sMilHandlerPath = getfullname(hMilHandler);

sPostOpenCallbackFile = fullfile(sTargetDir, sprintf('%s_postOpen.m', sExtModelName));
i_createPostOpenCallbackTL(sPostOpenCallbackFile, sMilHandlerPath);

sPreCloseCallbackFile = fullfile(sTargetDir, sprintf('%s_preClose.m', sExtModelName));
i_createPreCloseCallbackTL(sPreCloseCallbackFile, sSimModelName, sMilHandlerPath);

% create stubs for TLDS functionality and thus avoiding issues because of the out-commented MIL handler for TL
i_createStubFunctionFile(sTargetDir, 'tlds_init');
i_createStubFunctionFile(sTargetDir, 'tlds_start');
i_createStubFunctionFile(sTargetDir, 'tlds_stop');
end

%%
function i_createPostOpenHeader(fid, sScriptName)
ep_simenv_print_script_header(fid, sScriptName, ...
    'This file contains the post open code for models in SL-TOP context.');
end

%%
function i_createPostOpenCallbackTL(sPostOpenCallbackFile, sMilHandlerPath)
hFid = fopen(sPostOpenCallbackFile, 'wt');
xOnCleanupFile = onCleanup(@() fclose(hFid));

[~, sPostOpenScriptName] = fileparts(sPostOpenCallbackFile);
i_createPostOpenHeader(hFid, sPostOpenScriptName);

fprintf(hFid, 'set_param(''%s'', ''Commented'', ''on'');\n', sMilHandlerPath);
% exclude TL-warning: MIL handler missing and TL-note: MIL handler out-commented
fprintf(hFid, 'ds_error_set(''defaultexcludedmessages'', [%d, %d]);\n', 2294, 2485);
end

%%
function i_createPreCloseHeader(hFid, sScriptName)
ep_simenv_print_script_header(hFid, sScriptName, ...
    'This file contains the pre close code for models in SL-TOP context.');
end

%%
function i_createPreCloseCallbackTL(sPreCloseCallbackFile, sSimModelName, sMilHandlerPath)
hFid = fopen(sPreCloseCallbackFile, 'wt');
xOnCleanupFile = onCleanup(@() fclose(hFid));

[~, sPreCloseScriptName] = fileparts(sPreCloseCallbackFile);
i_createPreCloseHeader(hFid, sPreCloseScriptName);
fprintf(hFid, 'set_param(''%s'', ''Commented'', ''off'');\n', sMilHandlerPath);
fprintf(hFid, 'set_param(''%s'', ''Dirty'', ''off'');\n', sSimModelName);
end

%%
function bIsTL = i_isTLModel(sSimModelName)
hModel = get_param(sSimModelName, 'Handle');
hMainDialog = ep_find_system(hModel, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'MaskType',       'TL_MainDialog');
bIsTL = ~isempty(hMainDialog);
end

%%
function i_createStubFunctionFile(sTargetDir, sFuncName, sContent)
sFile = fullfile(sTargetDir, [sFuncName, '.m']);
hFid = fopen(sFile, 'w');
oOnCleanupClose = onCleanup(@() fclose(hFid));

fprintf(hFid, 'function %s(varargin)\n', sFuncName);
if ((nargin > 2) && ~isempty(sContent))
    fprintf(hFid, '%s', sContent);
end
fprintf(hFid, 'end\n');
end

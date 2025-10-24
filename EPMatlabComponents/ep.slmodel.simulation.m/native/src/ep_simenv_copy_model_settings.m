function ep_simenv_copy_model_settings(stEnv, hSrcMdl, hTrgModel, sSampleTime)
% Copies model settings from source model to target model.
%
% function ep_simenv_copy_model_settings(stEnv, hSrcMdl, hTrgModel, sSampleTime)
%
%   INPUT               DESCRIPTION
%     - stEnv               environment
%     - hSrcMdl             source model
%     - hTrgMdl             target model
%     - sSampleTime         sample time for the model
%   OUTPUT              DESCRIPTION
%     -                   -


%%
% to distinguish from the source model the destination model will get a different background color
if strcmpi(get_param(hSrcMdl, 'screencolor'), 'gray')
    set_param(hTrgModel, 'screencolor', 'cyan');
else
    set_param(hTrgModel, 'screencolor', 'gray');
end

% Specifies the data type used to override fixed-point data types.
% Set by the Data type override control on the Fixed-Point Settings dialog box. (-> just a copy)
sMode = get_param(hSrcMdl, 'DataTypeOverride');
set_param(hTrgModel, 'DataTypeOverride', sMode);

atgcv_m13_slconfiguration_set(stEnv, hSrcMdl, hTrgModel, sSampleTime);

i_adaptDiagnostics(hTrgModel);
end


%%
function i_adaptDiagnostics(hModel)
oConfig = getActiveConfigSet(hModel);
oDiag = oConfig.getComponent('Diagnostics');
sCurrent = oDiag.getProp('ModelReferenceVersionMismatchMessage');
if ~strcmp(sCurrent, 'none')
    oDiag.set('ModelReferenceVersionMismatchMessage', 'none');
end
end

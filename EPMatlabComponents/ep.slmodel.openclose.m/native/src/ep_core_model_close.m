function bIsClosed = ep_core_model_close(xEnv, stOpenRes)
% Closes the current model, DD and removes the enhanced ML search path
%
% function bIsClosed = ep_core_model_close(stEnv, stOpenRes)
%
%
%   INPUT               DESCRIPTION
%   - xEnv                (struct)  environment structure
%   - stOpenRes           (struct)  result of ep_core_model_open
%       .sModelFile       (string)  save input param for model_close
%       .casModelRefs       (cell)  contains all model references
%       .abIsModelRefOpen  (array)  TRUE if corresponding ModelRef was already
%                                   open/loaded, FALSE otherwise
%       .caInitScripts (cell array) save input param for model_close
%       .bIsTL           (boolean)  save input param for model_close
%       .bIsModelOpen       (bool)  TRUE if TL-Model is open, FALSE for
%                                   model is loaded
%       .sSearchPath      (string)  enhanced matlab search path or empty
%       .sDdFile          (string)  name of the DD to be reopened
%       .astAddDD          (array)  currently open additional DDs and Workspaces
%           .sFile        (string)  Full path to the DD File
%           .nDDIdx      (numeric)  Id of the DD workspace this DD is loaded in
%
%
%   OUTPUT              DESCRIPTION
%   - bIsClosed             (bool)  TRUE if the model is closed, FALSE if it remains open
%
%   REMARKS
%       Perform following steps:
%       a) close the model without saving changes
%       b) close current DD if the current model was a TL model without
%          saving changes
%       c) remove the enhanced ML search path
%



%%
xOnCleanupFreeResources = onCleanup(@() ep_core_model_handle('free', stOpenRes));

stEnvLegacy = ep_core_legacy_env_get(xEnv, true);
bIsClosed = atgcv_m_model_close(stEnvLegacy, stOpenRes);
end

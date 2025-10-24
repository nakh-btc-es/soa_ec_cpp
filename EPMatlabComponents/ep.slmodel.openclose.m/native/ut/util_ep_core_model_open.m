function stOpenRes = util_ep_core_model_open(xEnv, stArgs)
% Opens the current model and evaluate the init scripts.
%
% function stOpenRes = ep_core_model_open(xEnv, stArgs)
%
%
%   INPUT               DESCRIPTION
%   - xEnv                             (struct)     environment structure
%   - stArgs                           (struct)     Input arguments.
%       .sModelFile                    (string)     Full path to TargetLink model file (.mdl|.slx).
%                                                   File has to exist.
%       .caInitScripts                 (cell array) List of Scripts defining all variables
%                                                   needed for initialization of the model or empty {}.
%       .bIsTL                         (boolean)    current model is a TL model: load
%                                                   associated DataDictionary
%       .bCheck                        (boolean)    optional: check model initialization,
%                                                   default: false
%       .casAddPaths                   (cell)       optional: cell array of string with paths
%                                                   that are needed for initialization of model
%       .bActivateMil                  (boolean)    TRUE if MIL mode should be activated
%                                                   permanently (default: true)
%       .bIgnoreInitScriptFail         (boolean)    TRUE if exceptions during the execution of
%                                                   the InitScript(s) should be ignored
%                                                   (default: false)
%       .bIgnoreAssertModelKind        (boolean)    If TRUE, the model kind will be not checked.
%                                                   Default is false. Note, the model kind is
%                                                   only checked, if bCheck is true.
%       .bEnableBusObjectLabelMismatch (boolean)    optional: If TRUE, the "Element Name Missmatch" option will
%                                                   be set to "error".
%                                                   Default is false. 
%
%
%   OUTPUT              DESCRIPTION
%   - stOpenRes           (struct)  results in struct
%       .hModel           (handle)  model handle
%       .sModelFile       (string)  save input param for model_close
%       .casModelRefs       (cell)  contains all model references
%       .abIsModelRefOpen  (array)  TRUE if corresponding ModelRef was already
%                                   open/loaded, FALSE otherwise
%       .caInitScripts      (cell)  save input param for model_close
%       .bIsTL           (boolean)  save input param for model_close
%       .bIsModelOpen       (bool)  TRUE if model was already open/loaded,
%                                   FALSE if model had to be loaded
%       .sSearchPath      (string)  enhanced matlab search path or empty
%       .sDdFile          (string)  currently open DD File
%       .astAddDD          (array)  currently open additional DDs and Workspaces
%           .sFile        (string)  Full path to the DD File
%           .nDDIdx      (numeric)  Id of the DD workspace this DD is loaded in
%       .sActiveVariant   (string)  currently active DataVariant in DD
%
%
%   REMARKS
%       (1)
%       Perform following steps:
%       a) evaluate init scripts
%       b) enhance matlab search path
%       c) open model
%       d) put into MIL mode [only TL-model]
%       e) do model initialization
%
%       (2)
%       Function throws exceptions caused by legacy code:
%           ATGCV:SLAPI:INITIALIZATION_FAILED  ---  init of model not possible
%           ATGCV:SLAPI:MODEL_NOT_TL           ---  model has not the right type
%                                                   "TargetLink model"
%           ATGCV:SLAPI:MODEL_NOT_SL           ---  model has not the right type
%                                                   "Simulink model"
%
%       (3)
%       caInitScripts: List is evaluated by "first come first served".
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%%
if ~isfield(stArgs, 'caInitScripts')
    stArgs.caInitScripts = {};
end

if ~isfield(stArgs, 'bIsTL')
    stArgs.bIsTL = true;
end

if ~isfield(stArgs, 'bCheck')
    stArgs.bCheck = true;
end

if ~isfield(stArgs, 'casAddPaths')
    stArgs.casAddPaths = {};
end

if ~isfield(stArgs, 'bActivateMil')
    stArgs.bActivateMil = true;
end

if ~isfield(stArgs, 'bIgnoreInitScriptFail')
    stArgs.bIgnoreInitScriptFail = true;
end

if ~isfield(stArgs, 'bIgnoreAssertModelKind')
    stArgs.bIgnoreAssertModelKind = true;
end

if ~isfield(stArgs, 'bEnableBusObjectLabelMismatch')
    stArgs.bEnableBusObjectLabelMismatch = false;
end


stEnvLegacy = ep_core_legacy_env_get(xEnv, true);
stOpenRes = atgcv_m_model_open(...
    stEnvLegacy, ...
    stArgs.sModelFile, ...
    stArgs.caInitScripts, ...
    stArgs.bIsTL, ...
    stArgs.bCheck, ...
    stArgs.casAddPaths, ...
    stArgs.bActivateMil, ...
    stArgs.bIgnoreInitScriptFail, ...
    stArgs.bIgnoreAssertModelKind, ...
    stArgs.bEnableBusObjectLabelMismatch);


%% be more robust for allocating additional stuff
try
    stOpenRes = ep_core_model_handle('allocate', stOpenRes);
catch oEx
    warning('EP:MODEL:OPEN_ALLOC_FAILED', '%s', oEx.message);
end
end


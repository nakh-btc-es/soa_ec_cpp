function stRes = atgcv_m_model_open(stEnv, sModelFile, caInitScripts, bIsTL, varargin)
% Open the current model and evaluate the init scripts.
% Serves as a wrapper for ep_core_model_open to meet legacy requirements
%
% function stRes = atgcv_m_model_open(stEnv, sModelFile, caInitScripts, ...
%    bIsTL, bCheck, casAddPaths, bActivateMil, bIgnoreInitScriptFail)
%
%
% INPUT                         TYPE            DESCRIPTION
% stEnv                         (struct)        environment structure
% sModelFile                    (string)        Full path to TargetLink model file (.mdl).
%                                               File has to exist.
% caInitScripts                 (cell array)    List of Scripts defining all variables
%                                               needed for initialization of the model or empty {}.
% bIsTL                         (boolean)       current model is a TL model: load
%                                               associated DataDictionary
% bCheck                        (boolean)       optional: check model initialization,
%                                               default: false
% casAddPaths                   (cell)          optional: cell array of string with paths
%                                               that are needed for initialization of model
% bActivateMil                  (boolean)       TRUE if MIL mode should be activated
%                                               permanently (default: true)
% bIgnoreInitScriptFail         (boolean)       TRUE if exceptions during the execution of
%                                               the InitScript(s) should be ignored
%                                               (default: false)
% bIgnoreAssertModelKind        (boolean)       If TRUE, the model kind will be not checked.
%                                               Default is false. Note, the model kind is
%                                               only checked, if bCheck is true.
% bEnableBusObjectLabelMismatch (boolean)       optional: If TRUE, the "Element Name Missmatch" option will
%                                               be set to "error". Default is false.
%
%
%   OUTPUT              DESCRIPTION
%     stRes               (struct)  results in struct
%       .hModel           (handle)  model handle
%       .sModelFile       (string)  save input param for model_close
%       .casModelRefs       (cell)  contains all model references
%       .abIsModelRefOpen  (array)  TRUE if corresponding ModelRef was already
%                                   open/loaded, FALSE otherwise
%       .caInitScripts      (cell)  save input param for model_close
%       .bIsTL           (boolean)  Indicates if a model is really a
%                                   TargetLink model
%       .bIsModelOpen       (bool)  TRUE if model was already open/loaded,
%                                   FALSE if model had to be loaded
%       .sSearchPath      (string)  enhanced matlab search path or empty
%       .sDdFile          (string)  currently open DD File
%       .astAddDD          (array)  currently open additional DDs and Workspaces
%           .sFile        (string)  Full path to the DD File
%           .nDDIdx      (numeric)  Id of the DD workspace this DD is loaded in
%       .sActiveVariant   (string)  currently active DataVariant in DD
%                                   --> (!!DEPRECATED!!)
%      .casOpenSys    (cell array)  contains all aready loaded/open models and libraries
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
%       Function throws exceptions:
%           ATGCV:SLAPI:INITIALIZATION_FAILED  ---  init of model not possible
%           ATGCV:SLAPI:MODEL_NOT_TL           ---  model has not the right type
%                                                   "TargetLink model"
%           ATGCV:SLAPI:MODEL_NOT_SL           ---  model has not the right type
%                                                   "Simulink model"
%
%       (3)
%       caInitScripts: List is evaluated by "first come first served".
%

%% main
stArgs = i_evalArgs(sModelFile, caInitScripts, bIsTL, varargin{:});
stRes = ep_core_model_open(stEnv, stArgs);

end

%%
% function stArgs = i_evalArgs(stEnv, sModelFile, caInitScripts, bIsTL, ...
%     bCheck, casAddPaths, bActivateMil, bIgnoreInitScriptFail, bIgnoreAssertModelKind)
%
function stArgs = i_evalArgs(sModelFile, caInitScripts, bIsTL, varargin)
stArgs = struct( ...
    'sModelFile',             sModelFile, ...
    'caInitScripts',          {{}}, ...
    'bIsTL',                  bIsTL, ...
    'bCheck',                 false, ...
    'casAddPaths',            {{}}, ...
    'bActivateMil',           true, ...
    'bIgnoreInitScriptFail',  false, ...
    'bIgnoreAssertModelKind', false, ...
    'bEnableBusObjectLabelMismatch', false);

% to support legacy usage also handle the cases
%  caInitScripts == ''
%  caInitScripts == []
if isempty(caInitScripts)
    stArgs.caInitScripts = {};
elseif ~iscell(caInitScripts)
    stArgs.caInitScripts = {caInitScripts};
else
    % 1) get abs path for every script
    % 2) legacy stuff: remove things like {''}
    abSelect = true(size(caInitScripts));
    for i = 1:length(caInitScripts)
        if isempty(caInitScripts{i})
            abSelect(i) = false;
        else
            caInitScripts{i} = atgcv_canonical_path(caInitScripts{i});
        end
    end
    stArgs.caInitScripts = caInitScripts(abSelect);
end

% handle the optional arguments
caxOpt = varargin;
nOpt = length(caxOpt);
if (nOpt < 1)
    return;
end
stArgs.bCheck = caxOpt{1};

if (nOpt < 2)
    return;
end
stArgs.casAddPaths = caxOpt{2};

if (nOpt < 3)
    return;
end
stArgs.bActivateMil = caxOpt{3};

if (nOpt < 4)
    return;
end
stArgs.bIgnoreInitScriptFail = caxOpt{4};

if (nOpt < 5)
    return;
end
stArgs.bIgnoreAssertModelKind = caxOpt{5};

if (nOpt < 6)
    return;
end
stArgs.bEnableBusObjectLabelMismatch = caxOpt{6};
end
function stRes = ep_core_model_open(xEnv, stArgs)
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
%       .bIsTL           (boolean)  indicates if a model is really a TL
%                                   model
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

%%
if ~isfield(stArgs, 'caInitScripts')
    stArgs.caInitScripts = {};
end

if ~isfield(stArgs, 'bIsTL')
    bCheckTLStatus = true;
    stArgs.bIsTL = false;
else
    bCheckTLStatus = false;
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

if isa(xEnv,'EPEnvironment')
    stEnv = ep_core_legacy_env_get(xEnv, true);
else
    stEnv=xEnv;
end

% prepare output struct
stRes = struct( ...
    'hModel',            [], ...
    'sModelName',        '', ...
    'sModelFile',        atgcv_canonical_path(stArgs.sModelFile), ...
    'casModelRefs',      {{}}, ...
    'abIsModelRefOpen',  [], ...
    'caInitScripts',     {stArgs.caInitScripts}, ...
    'bIsTL',             stArgs.bIsTL && ~bCheckTLStatus, ...
    'bIsModelOpen',      false, ...
    'sSearchPath',       '',  ...
    'sDdFile',           '', ...
    'astAddDD',          [], ...
    'sActiveVariant',    '', ...
    'astSim',            [], ...
    'casOpenSys',        {{}}, ...
    'casOpenSLDDs',      {{}});

% Check which systems are already open
stRes.casOpenSys = i_findOpenSys();

% get the name of all models that already are open
casOpenModels = find_system('type', 'block_diagram');

% check for current loaded models
[sMdlPath, stRes.sModelName, stRes.bIsModelOpen] = i_getModelPathAndName(stArgs.sModelFile, casOpenModels);

casOpenSLDDs = Simulink.data.dictionary.getOpenDictionaryPaths();
if ~isempty(casOpenSLDDs)
    stRes.casOpenSLDDs = casOpenSLDDs;
else
    stRes.casOpenSLDDs = {};
end

% memorize current DD name
stRes.sDdFile = i_findCurrentDataDictionary(casOpenModels);

% close current DD to avoid any interferences
% note: we have to close DD even if we are opening a Simulink model
% because user could wrongly provide a TargeLink model
% later we will revert closing if model is really a Simulink model
bHaveClosedDd = false;
if (~isempty(stRes.sDdFile) && ~stRes.bIsModelOpen)
    if atgcv_use_tl
        if dsdd('IsModified')
            dsdd('Close', 'Save', 'on');
        else
            dsdd('Close', 'Save', 'off');
        end
        bHaveClosedDd = true;
    end
end

stRes.sSearchPath = i_addToSearchPath(sMdlPath, stArgs.casAddPaths);

bPreOpenError = ~isempty(i_evalInitScripts(stEnv, stArgs.caInitScripts));

% load model
[stRes.hModel, casLibs] = i_openModel(stEnv, stRes);

% Check if model is a TL model
if bCheckTLStatus
    stRes.bIsTL = i_isTLModel(stRes.hModel);
end

% close unrelated DD and DD workspaces
if atgcv_use_tl
    stRes.astAddDD = i_closeDDWorkspaces(fileparts(stRes.sModelFile));
end

[stRes.casModelRefs, stRes.abIsModelRefOpen, casModelRefLibs] = i_openModelRefs(stEnv, stRes.sModelName, casOpenModels);
casLibs = [casLibs, casModelRefLibs]; %#ok<NASGU>

% if we had errors with the init scripts before loading the model,
% try to eval them again now that the model is loaded
if bPreOpenError
    casErrorScripts = i_evalInitScripts(stEnv, stArgs.caInitScripts);
    if ~isempty(casErrorScripts)
        i_handleErrorsInInitScripts(stEnv, casErrorScripts, ~stArgs.bIgnoreInitScriptFail, stRes);
    end
end

% ------ Check1: check if we really have the right kind of model (TL or SL)
if (stArgs.bCheck && ~stArgs.bIgnoreAssertModelKind)
    try
        i_assertModelKind(stEnv, stRes.sModelName, stRes.sModelFile, stRes.bIsTL);
    catch
        stErr = osc_lasterror();
        atgcv_m_model_close(stEnv, stRes);
        osc_throw(stErr);
    end
end

% at this point we can be sure that TL is really TL and SL is really SL,
% so revert the closing of DD for Simulink models
if (~isempty(stRes.sDdFile) && bHaveClosedDd && ~stRes.bIsTL)
    atgcv_dd_open('File', stRes.sDdFile);
end

if stRes.bIsTL
    % check if current DD is the one we need for model
    sDD = dsdd_manage_project('GetProjectFile', stRes.sModelName);
    sCurrDd = i_getCurrentDd();
    
    % current DD not the one we need, so load the right one
    if ~strcmp(sDD, sCurrDd)
        atgcv_dd_close();
        sBatchMode = ds_error_get('BatchMode');
        ds_error_set('BatchMode', 'on');
        atgcv_dd_open('File', sDD)
        ds_error_set('BatchMode', sBatchMode);
    end
    
    % for TL-model: activate MIL mode if 1) asked for or if 2) init check is needed
    if (stArgs.bActivateMil || stArgs.bCheck)
        % Note: force MIL mode if asked for OR we did open the model ourselves
        bForceMilActively = stArgs.bActivateMil || ~stRes.bIsModelOpen;
        i_activateMIL(stEnv, stRes.sModelName, bForceMilActively);
    end
end

% ------ Check2: check if init possible
if stArgs.bCheck
    [oOnCleanupResetDiagnostics, bIsSetBusObjectLabelMismatch] = ...
        i_enableModelBusObjectLabelMismatchCheck(stArgs.bEnableBusObjectLabelMismatch, stRes.hModel); %#ok<ASGLU> onCleanup
    try
        i_checkModelInitialization(stEnv, stRes.sModelName, sMdlPath);
        
        % sometimes libraries get unloaded by the init procedure --> reload them again
        i_loadLibraries(stEnv, casLibs);
    catch
        stErr = osc_lasterror();
        if ~isempty(regexp(stErr.message, 'Subsystem reference block ''.*'' has unapplied changes.', 'ONCE'))
             xEnv.throwException(xEnv.addMessage('EP:SIM:DIRTY_MODEL', 'model', stRes.sModelFile));
        end
        if bIsSetBusObjectLabelMismatch  
            osc_messenger_add(stEnv, 'ATGCV:STD:SWITCH_DIAG_ELEM_NAME_MISMATCH');
        end
        clear oOnCleanupResetDiagnostics;
        atgcv_m_model_close(stEnv, stRes);
        osc_throw(stErr);
    end
end

%% be more robust for allocating additional stuff
try
    stRes = ep_core_model_handle('allocate', stRes);
catch oEx
    warning('EP:MODEL:OPEN_ALLOC_FAILED', '%s', oEx.message);
end
end


%%
% Set diagnostic "BusObjectLabelMismatch" to error to identify mismatches of bus objects with labels
% This is mandatory since SL Feature "Override bus names" leads to errors in EP (see EPDEV-53413)
%
function [oOnCleanupResetDiagnostics, bIsSetBusObjectLabelMismatch] = i_enableModelBusObjectLabelMismatchCheck(bEnableBusObjectLabelMismatch, hModel)
bIsSetBusObjectLabelMismatch = false;
oOnCleanupResetDiagnostics = [];
if bEnableBusObjectLabelMismatch
    sBusObjectLabelMismatchOrigValue = get_param(hModel, 'BusObjectLabelMismatch');
    if ~isequal(sBusObjectLabelMismatchOrigValue, 'error')
        bIsModelInCleanState = strcmp(get_param(hModel, 'Dirty'), 'off');
        
        oActiveConfig = getActiveConfigSet(hModel);
        if isa(oActiveConfig, 'Simulink.ConfigSetRef')   % the configset is only a reference, must get the original
            oActiveConfig = getRefConfigSet(oActiveConfig);
        end
        set_param(oActiveConfig, 'BusObjectLabelMismatch', 'error');
        bIsSetBusObjectLabelMismatch = true;
        
        oOnCleanupResetDiagnostics = onCleanup( ...
            @() i_resetChange(oActiveConfig, sBusObjectLabelMismatchOrigValue, hModel, bIsModelInCleanState));
    end
end
end


%%
function i_resetChange(oActiveConfig, sBusObjectLabelMismatchOrigValue, hModel, bIsModelInCleanState)
set_param(oActiveConfig, 'BusObjectLabelMismatch', sBusObjectLabelMismatchOrigValue)
if bIsModelInCleanState
    set_param(hModel, 'Dirty', 'off');
end
end


%%
function i_activateMIL(stEnv, sModelName, bForceMilActively)
stErr = [];
% note: xSimModes might be a string for one TL-Subsystem or a cell-array of string for multiple TL-Subsystems
xSimModes = ep_tl_get_sim_mode('Model', sModelName);
nToModify = sum(~strcmpi('TL_BLOCKS_HOST', xSimModes));
if (nToModify > 0)
    if bForceMilActively
        % set MIL mode for whole model in one step
        tl_set_sim_mode('Model', sModelName, 'SimMode', 'TL_BLOCKS_HOST');
    else
        casSub = get_tlsubsystems(sModelName);
        for i = 1:length(casSub)
            stInfo = tl_get_subsystem_info(casSub{i});
            if ~strcmpi(stInfo.simMode, 'TL_BLOCKS_HOST')
                stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:MIL_MODE_NOT_ENABLED', 'model', sModelName);
            end
        end
    end
end
if ~isempty(stErr)
    osc_throw(stErr);
end
end


%%
function i_handleErrorsInInitScripts(stEnv, casErrorScripts, bIsErrorFatal, stRes)
if isempty(casErrorScripts)
    return;
end

sErrorScript = casErrorScripts{end};
stErr = osc_lasterror();
sMsg = stErr.message;

if bIsErrorFatal
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:INIT_SCRIPT_FAILED_FATAL', 'script', sErrorScript, 'text', sMsg);
    try
        atgcv_m_model_close(stEnv, stRes);
    catch
    end
    osc_throw(stErr);
else
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:INIT_SCRIPT_FAILED', 'script', sErrorScript, 'text', sMsg);
    warning('ATGCV:MOD_ANA:INIT_SCRIPT_FAILED', '%s', sMsg);
end
end

%%
function sCurrDd = i_findCurrentDataDictionary(casOpenModels)
sCurrDd = '';
if atgcv_use_tl
    sCurrDd = i_getCurrentDd();
end

% try to find abs path from possibly rel. path
if ~isempty(sCurrDd)
    if exist(sCurrDd, 'file')
        sCurrDd = atgcv_canonical_path(sCurrDd);
    else
        % try the file paths of all open models
        for i = 1:length(casOpenModels)
            sModel = casOpenModels{i};
            
            try
                sFullModel = get_param(sModel, 'FileName');
            catch
                sFullModel = '';
            end
            if ~isempty(sFullModel)
                sModelPath = fileparts(sFullModel);
                sTryDd = fullfile(sModelPath, sCurrDd);
                if exist(sTryDd, 'file')
                    sCurrDd = atgcv_canonical_path(sTryDd);
                    return;
                end
            end
        end
        % if the right DD was not found reset DD name to indicate failure
        sCurrDd = '';
    end
end
end


%%
function [sMdlPath, sMdlName, bIsModelOpen] = i_getModelPathAndName(sModelFile, casOpenModels)
[sMdlPath, sMdlName] = fileparts(sModelFile);

iFound = find(strcmpi(sMdlName, casOpenModels));
bIsModelOpen = ~isempty(iFound);
if bIsModelOpen
    sRealName = casOpenModels{iFound};
    i_assertNameSameCase(sMdlName, sRealName, sModelFile);
    sMdlName = sRealName;
    
    i_assertSameFilePath(sMdlName, sModelFile);
end
end


%%
function [casModelRefs, abIsModelRefOpen, casLibNames] = i_openModelRefs(stEnv, sMdlName, casOpenModels)
casModelRefs = {};
abIsModelRefOpen = [];
casLibNames = {};

% make sure all model references are loaded
casFoundRefs = ep_find_mdlrefs(sMdlName); % find all modelrefs recursively
casFoundRefs(end) = []; % delete last model ref (always the main model itself)
if ~isempty(casFoundRefs)
    casModelRefs     = reshape(casFoundRefs, 1, []);
    abIsModelRefOpen = false(size(casModelRefs));
    for i = 1:length(abIsModelRefOpen)
        sModelRef = casModelRefs{i};
        
        abIsModelRefOpen(i) = any(strcmpi(sModelRef, casOpenModels));
        if ~abIsModelRefOpen(i)
            warning('off', 'MATLAB:class:EnumerationValueChanged');
            load_system(sModelRef);
            warning('on', 'MATLAB:class:EnumerationValueChanged');
            casLibsRefModel = i_loadLibrariesForModel(stEnv, sModelRef);
            casLibNames = [casLibNames, casLibsRefModel]; %#ok<AGROW>
        end
    end
end
end


%%
function sModelName = i_getCaseSensitiveModelName(sMdlFile)
casOpenModels = find_system('type', 'block_diagram');

[~, sMdlName] = fileparts(sMdlFile);
iFound = find(strcmpi(sMdlName, casOpenModels));
if ~isempty(iFound)
    sModelName = casOpenModels{iFound};
else
    sModelName = sMdlName;
end
end


%%
function [hModel, casLibs] = i_openModel(stEnv, stRes)
if atgcv_use_tl
    sBatchMode = ds_error_get('BatchMode');
    ds_error_set('BatchMode', 'on');
    xOnCleanupResetBatchTL = onCleanup(@() ds_error_set('BatchMode', sBatchMode));
end
try
    if ~stRes.bIsModelOpen
        try
            bOnlyLibs = false;
            [hModel, casLibs] = i_loadModel(stEnv, stRes.sModelFile, bOnlyLibs);
        catch oEx
            if strcmpi(oEx.identifier, 'Simulink:Commands:LoadModelFullNameConflict')
                warning('ATGCV:STD:MODEL_OPEN_BLOCKED', '%s', oEx.message);
                error('ATGCV:STD:MODEL_OPEN_BLOCKED', '%s', oEx.message);
            else
                warning('ATGCV:STD:MODEL_OPEN_FAILED', '%s', oEx.message);
            end
            
            % dirty: as a fallback try to load the model in current dir
            hModel = load_system(stRes.sModelName);
            
            casLibs = i_loadLibrariesForModel(stEnv, stRes.sModelName);
        end
    else
        % model already open, so just ensure that the libs are also available
        hModel = get_param(stRes.sModelName, 'handle');
        
        bOnlyLibs = true;
        [~, casLibs] = i_loadModel(stEnv, stRes.sModelFile, bOnlyLibs);
    end
catch
    stErr = osc_lasterror();
    if atgcv_use_tl
        atgcv_dd_close('Save', false);
    end
    if ~isempty(stRes.sDdFile)
        atgcv_dd_open('File', stRes.sDdFile)
    end
    if ~isempty(stRes.sSearchPath)
        rmpath(stRes.sSearchPath);
    end
    osc_throw(stErr);
end
end


%%
function sSearchPath = i_addToSearchPath(sMdlPath, casAddPaths)
sSearchPath = '';

% look if needed paths are already included in Matlab path or not
% note: by adding a pathsep() at the end we make sure that we find the whole
% path in the search_path and not just a subpath
casAddPaths = [sMdlPath, casAddPaths];
sAllPathSep = [path(), pathsep()];
for i = 1:length(casAddPaths)
    sPath     = casAddPaths{i};
    sPathSep  = [sPath, pathsep()];
    bNotFound = ~contains(sAllPathSep, sPathSep);
    if bNotFound
        if isempty(sSearchPath)
            sSearchPath = sPath;
        else
            sSearchPath = [sSearchPath, pathsep(), sPath]; %#ok<AGROW>
        end
    end
end

% add to Matlab search path
if ~isempty(sSearchPath)
    addpath(sSearchPath);
    rehash();
end
end


%%
function i_callInitScript(sInitScript)
sPwd = pwd();
xOnCleanupReturn = onCleanup(@() cd(sPwd));
[sPath, sCmd] = fileparts(sInitScript);
if (~isempty(sPath) && exist(sPath, 'dir'))
    cd(sPath);
end
if ~isempty(sCmd)
    evalin('base', sCmd);
end
end


%%
function i_mlintInitScript(stEnv, sInitScript)
stLint = checkcode(sInitScript, '-id');

% find syntax errors - 'SyntaxErr:EmptyFile' will be ignored
sSyntaxErr = 'SyntaxErr';
nSyntaxErr = length(sSyntaxErr);
for k = 1:length(stLint)
    if (strncmpi(stLint(k).id, sSyntaxErr,nSyntaxErr) && ~strcmpi(stLint(k).id, 'SyntaxErr:EmptyFile'))
        sShortInfo = sprintf('Syntax error in line %g: %s.', stLint(k).line, stLint(k).message);
        stErr = osc_messenger_add(stEnv, 'ATGCV:STD:INTERNAL_SCR_ERR', ...
            'scriptname', sInitScript, ...
            'shortinfo',  sShortInfo);
        osc_throw(stErr);
    end
end
end


%%
function i_checkModelInitialization(stEnv, sModel, sMdlPath)
sPwd = pwd();
xOnCleanupReturn = onCleanup(@() cd(sPwd));
try
    warnStatus = warning;
    warning('off', 'all');
    xOnCleanupResetWarningSL = onCleanup(@() warning(warnStatus));
    
    % switch off interactive display of TL errors/warnings
    if atgcv_use_tl
        xTlBatchMode = ds_error_get('BatchMode');
        ds_error_set('BatchMode', 'on');
        xOnCleanupResetBatchTL = onCleanup(@() ds_error_set('BatchMode', xTlBatchMode));
    end
    
    if ~isempty(sModel)
        cd(sMdlPath);
        
        % according to dSPACE calling the init function with return value yields better validation results
        hSys = feval(sModel, [], [], [], 0); %#ok
          
    end
catch exception
    sMsg = i_get_full_error_message(exception);
    
    sErrID = 'ATGCV:SLAPI:INITIALIZATION_FAILED';
    if (strcmp(exception.identifier, 'Simulink:SL_CallbackEvalErr') && contains(sMsg, 'TargetLink license check failed'))
        sErrID = 'ATGCV:SLAPI:TARGETLINK_LICENSE_FAILED';
    end
    stErr = osc_messenger_add(stEnv, sErrID, 'model', sModel, 'text', sMsg);
    
    stErr.message = sMsg;
    osc_throw(stErr);
end
end


%%
function sMsg = i_get_full_error_message(oEx, sPrefix)
if (nargin < 2)
    sPrefix = '';
end

sMsg = [sPrefix, oEx.getReport('basic', 'hyperlinks', 'off')];

caoCauses = oEx.cause;
for i = 1:length(caoCauses)
    oCause = caoCauses{i};
    
    sSubMsg = i_get_full_error_message(oCause, [sPrefix, '  ']);
    sMsg = sprintf('%s\n%s', sMsg, sSubMsg);
end
end


%%
function i_assertModelKind(stEnv, sMdlName, sModelFile, bIsTL)

% analyze model characteristics
hModel = get_param(sMdlName, 'Handle');
ahMainDialog = ep_find_system(hModel, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'MaskType',       'TL_MainDialog');
ahSimFrame = ep_find_system(hModel, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'MaskType',       'TL_SimFrame');

% Assumption1: TL model has
% a) at least one TL main dialog
% b) at least one TL simulation frame
bCheckTL = ~isempty(ahMainDialog) && ~isempty(ahSimFrame);

% Assumption2: everything that's not a TL model is an SL model
bCheckSL = ~bCheckTL;

% Exception Case1: we want TL but got SL
if (bIsTL && bCheckSL)
    stErr = osc_messenger_add(stEnv, 'ATGCV:SLAPI:MODEL_NOT_TL', 'model', sModelFile);
    osc_throw(stErr);
end

% Exception Case2: we want SL but got TL
if (~bIsTL && bCheckTL)
    stErr = osc_messenger_add(stEnv, 'ATGCV:SLAPI:MODEL_NOT_SL', 'model', sModelFile);
    osc_throw(stErr);
end

% !!! without Assumption2 there could be a Case3: model is neither SL nor TL
end


%%
function bSuccess = i_inDirLoadDD(sDir, sDdFile)
bSuccess = false;
if (isempty(sDir) || ~isdir(sDir))
    return;
end

sPwd = pwd();
xOnCleanupReturnToPwd = onCleanup(@() cd(sPwd));
try
    cd(sDir);
    iErr = atgcv_dd_open('File', sDdFile);
    bSuccess = (iErr == 0);
catch
    %  could not fully restore user DD
end
end


%%
% Note: DD needs to be closed and re-opened --> switch into Model Path to avoid issues with relative paths
function astAddDD = i_closeDDWorkspaces(sModelPath)
astAddDD = [];

sDDFile = i_getCurrentDd();
if (~isempty(sDDFile) && exist(sDDFile, 'file'))
    [stMainDD, astAddDD] = atgcv_dd_close('Save', true);
    if ~isempty(stMainDD)
        % first try to load DD in Model path, if successful return early
        if (~isempty(sModelPath) && exist(sModelPath, 'dir'))
            if i_inDirLoadDD(sModelPath, stMainDD.sFile)
                return;
            end
        end
        
        % if loading was not successul, retry in DD path
        sDdPath = fileparts(stMainDD.sFile);
        if (~isempty(sDdPath) && exist(sDdPath, 'dir'))
            i_inDirLoadDD(sDdPath, stMainDD.sFile);
        end
    end
end
end


%%
function [hModel, casLibs] = i_loadModel(stEnv, sModelFile, bOnlyLibs)
hModel = [];

sPwd = pwd();
xOnCleanupReturn = onCleanup(@() cd(sPwd));

sPath = fileparts(sModelFile);
if (~isempty(sPath) && exist(sPath, 'dir'))
    cd(sPath);
end

if bOnlyLibs
    % assume that the model is open and find its name
    sModelName = i_getCaseSensitiveModelName(sModelFile);
else
    warning('off', 'SLDD:sldd:ReferencedEnumDefinedExternally');
    hModel = load_system(sModelFile);
    warning('on', 'SLDD:sldd:ReferencedEnumDefinedExternally');
    sModelName = get_param(hModel, 'Name');
end

casLibs = i_loadLibrariesForModel(stEnv, sModelName);
end


%%
function casErrorScripts = i_evalInitScripts(stEnv, casInitScripts)
casErrorScripts = {};
for k = 1:length(casInitScripts)
    sScript = casInitScripts{k};
    if (~isempty(sScript) && exist(sScript, 'file'))
        i_mlintInitScript(stEnv, sScript);
        try
            i_callInitScript(sScript);
        catch
            casErrorScripts{end + 1} = sScript; %#ok<AGROW>
        end
    end
end
end


%%
function sCurrDd = i_getCurrentDd()
sCurrDd = dsdd('GetDDAttribute', 0, 'fileName');
end


%%
% Since Matlab 8.0 it is necessary to load the libraries explicitly  to keep them open.
% Otherwise the code generation fails, because the libraries cannot be found.
function casLibNames = i_loadLibrariesForModel(stEnv, sModel)
casLibNames = {};
astLibInfoData = ep_libinfo(sModel);
if isempty(astLibInfoData)
    return;
end

% filter out inactive links
abIsInactive = strcmp('inactive',  {astLibInfoData(:).LinkStatus});
astLibInfoData(abIsInactive) = [];

if isempty(astLibInfoData)
    return;
end
casLibNames = unique({astLibInfoData(:).Library});
i_loadLibraries(stEnv, casLibNames);
end


%%
function i_loadLibraries(stEnv, casLibNames)
jOpenDiags = i_getOpenLibsAndModels();
for i = 1:length(casLibNames)
    sLibName = casLibNames{i};
    
    bIsAlreadyOpen = jOpenDiags.contains(sLibName);
    if ~bIsAlreadyOpen
        try
            load_system(sLibName);
        catch
            osc_messenger_add(stEnv, 'ATGCV:STD:LIB_OPEN_FAILED', 'libname', sLibName);
        end
    end
end
end


%%
function jOpenDiags = i_getOpenLibsAndModels()
casDiags = cellstr(get_param(Simulink.allBlockDiagrams, 'Name'));

jOpenDiags = java.util.HashSet();
for i = 1:numel(casDiags)
    jOpenDiags.add(casDiags{i});
end
end


%%
function i_assertSameFilePath(sMdlName, sModelFile)
sFilePath = '';
try
    sFilePath = get_param(sMdlName, 'FileName');
catch
end
if ~isempty(sFilePath)
    sFilePath = atgcv_canonical_path(sFilePath);
    if ~strcmpi(sModelFile, sFilePath)
        error('ATGCV:STD:MODEL_OPEN_BLOCKED', ...
            'Cannot load model "%s" because a model with the same name but different path "%s" is already open.', ...
            sModelFile, sFilePath);
    end
end
end


%%
% Note: case letters only relevant for R2016b (aka ML9.1)
function i_assertNameSameCase(sMdlName, sRealName, sModelFile)
if ((atgcv_version_p_compare('ML9.1') >= 0) && ~strcmp(sMdlName, sRealName))
    warning('ATGCV:STD:MODEL_OPEN_NAME_CASE_DIFF', ...
        'Model file "%s" is loaded as "%s". The different case letters might cause issues for model paths.', ...
        sModelFile, sRealName);
end
end


%%
function casOpenSys = i_findOpenSys
casOpenSys = find_system('SearchDepth', 0);
casOpenSys = unique(casOpenSys);
casOpenSys = casOpenSys(bdIsLoaded(casOpenSys));
end


%%
function bIsTL = i_isTLModel(hModel)
hMainDialog = ep_find_system(hModel, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'MaskType',       'TL_MainDialog');
bIsTL = ~isempty(hMainDialog);
end

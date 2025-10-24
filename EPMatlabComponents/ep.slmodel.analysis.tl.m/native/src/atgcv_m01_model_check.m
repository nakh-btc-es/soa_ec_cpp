function stRes = atgcv_m01_model_check(stEnv, sTlModelFile, varargin)
%  check validity of TargetLink model and return toplevel subsystem
%
% function stRes = atgcv_m01_model_check(stEnv, sTlModelFile, varargin)
%
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)  Environment structure.
%     sTlModelFile        (string)  Full path to TargetLink model file (.mdl). 
%                                   (Argument is obligatory.) File is existing.
%                                   
%
%     varargin     ([Key, Value]*)  Pairs of strings with the following 
%                                   possibles values (all of them optional!)
%
%       Key:                    Meaning of the Value:               
%         TlInitScript              Script defining all variables needed for 
%                                   initialization of TL-model. File is existing.
%         SlModelFile               If the MIL simulation shall take place on 
%                                   a separate Simulink model, full path to
%                                   SL model must be specified. File is existing.
%         SlInitScript              Script defining all variables needed for 
%                                   initialization of SL-model. File is existing.
%         TlSubsystem               Name of TargetLink subsystem (with path)
%                                   representing  the toplevel subsystem of the 
%                                   analysis. (only needed if there is more
%                                   than one toplevel system)
%
%   OUTPUT              DESCRIPTION
%     stRes               (struct)   results in struct
%       .bAdaptiveAutosar (boolean)  Indicates if the code is generated in adaptive autosar mode
%       .sTlSubsystem     (string)   name of TargetLink toplevel subsystem 
%                                    (with path)
%       .astTlModules     (struct)   TargetLink model files (see below)
%       .astSlModules     (struct)   Simulink model files (see below)
%
%         ----------------------------
%                 stModule 
%                     .sKind         (string)   model | library | model_ref
%                     .sFile         (string)   full path to model/lib file
%                     .sVersion      (string)   version of model/lib file 
%                     .sCreated      (string)   creation date of model/lib file 
%                     .sModified     (string)   last modification date of model/lib file 
%                     .sCreator      (string)   model creator
%                     .sIsModified   (string)   'yes'|'no' depending on modified
%                                               state of model/lib
%
%
%     
%   REMARKS
%   1) provided models (TL and SL) are assumed to be loaded/open
%
%   2) Function throws exception: 
%      ATGCV:TLAPI:MULTIPLE_TL_SUBSYSTEMS_FOUND  ---  multiple toplevel TL subsystems
%           .caTlSubsystem  (cell array)    list of all TL subsystems
%
%      ATGCV:SLAPI:INITIALIZATION_FAILED  ---  init of model not possible
%     
%   <et_copyright>


%% TODO
% AH TODO: replace deprecated dependecy on model_files by model_names
% <---> file paths not really needed for whole check process because it is
% assumed that the corresponding models are open/loaded


%% default output
stRes = struct( ...
    'bAdaptiveAutosar', false, ...
    'sTlSubsystem', '', ...
    'astTlModules', '', ...
    'astSlModules', '');

%% main
try    
    % get variable arguments
    stArgs = i_parseArgs(stEnv, sTlModelFile, varargin{:});

    stRes.bAdaptiveAutosar = i_assertSupportedCodegenMode(stEnv, stArgs.sTlModel);
    i_checkSampleTime(stEnv, stArgs.sTlModel, stArgs.sSlModel);
    stRes.sTlSubsystem = i_checkTLSubsystem(stEnv, stArgs.sTlModel, stArgs.sTlSubsystem);

    stRes.astTlModules = i_getModules(stArgs.sTlModel);
    stRes.astSlModules = i_getModules(stArgs.sSlModel);
    
catch
    osc_throw(osc_lasterror());
end
end


%%
function stArgs = i_parseArgs(stEnv, sTlModelFile, varargin)
stArgs = struct( ...
    'sTlModelFile',  sTlModelFile, ...
    'sTlInitScript', '', ...
    'sSlModelFile',  '', ...
    'sSlInitScript', '', ...
    'sTlSubsystem',  '', ...
    'sTlModel',      '', ...
    'sSlModel',      '');

casKeyVals = varargin(:);
for i = 1:2:length(casKeyVals)
    sKey = casKeyVals{i};
    switch lower(sKey)
        case 'tlsubsystem'
            stArgs.sTlSubsystem  = casKeyVals{i + 1};
        case 'slmodelfile'
            stArgs.sSlModelFile  = casKeyVals{i + 1};
        case 'tlinitscript'
            stArgs.sTlInitScript = casKeyVals{i + 1};
        case 'slinitscript'
            stArgs.sSlInitScript = casKeyVals{i + 1};
        otherwise
            stErr = osc_messenger_add(stEnv, 'ATGCV:STD:WRONG_PARAM_VAL', ...
                'param_name',  sKey, ...
                'wrong_value', casKeyVals{i + 1});
            osc_throw(stErr);
    end
end

if ~isempty(stArgs.sTlModelFile)
    [p, stArgs.sTlModel, e] = fileparts(stArgs.sTlModelFile); %#ok p, e not used
end
if ~isempty(stArgs.sSlModelFile)
    [p, stArgs.sSlModel, e] = fileparts(stArgs.sSlModelFile); %#ok p, e not used
end
end
 

%%
% currently not supported codegen modes: RTOS and Adaptive AUTOSAR
function bAdaptiveAutosar = i_assertSupportedCodegenMode(stEnv, sTlModel)
hMainDialog = i_findMainDialog(stEnv, sTlModel);

% enum values for iMode: 1 --> Standard,  2 --> Classic AUTOSAR,  3 --> RTOS, 4 --> Adaptive AUTOSAR
iMode = tl_get(hMainDialog, 'codegenerationmode');
if (iMode == 3)
    osc_throw(osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:RTOS_MULTIRATE_ENABLED', 'model', sTlModel));
end

bAdaptiveAutosar = iMode == 4;
if (bAdaptiveAutosar && ep_core_version_compare('TL5.1') < 0)
    osc_throw(osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:TLAA_BELOW_SUPPORTED_VERSION', 'model', sTlModel , ...
        'msg', 'TL Adaptive-Autosar models are only supported with TL-version 5.1 or higher.'));
end

end


%%
function hMainDialog = i_findMainDialog(stEnv, sTlModel)
hModel = get_param(sTlModel, 'Handle');
hMainDialog = ep_find_system(hModel, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'MaskType',       'TL_MainDialog');
if isempty(hMainDialog)
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:CHECK_MODEL_INVALID', ...
        'model', sTlModel, ...
        'msg',   'Required TL MainDialog not found in model.');
    osc_throw(stErr);
end

% multiple MainDialog blocks are not an error; the parameters are synchronized by TL, so choose the first one
if (length(hMainDialog) > 1)
    hMainDialog = hMainDialog(1);
end
end


%%
function i_checkSampleTime(stEnv, sTlModel, sSlModel)
sSolverType = get_param(sTlModel, 'SolverType');
if ~strcmpi(sSolverType, 'fixed-step')
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:SOLVER_TYPE_NOT_SUPPORTED', ...
        'solver_type',  sSolverType, ...
        'model',        sTlModel);
    osc_throw(stErr);
end

if ~isempty(sSlModel)
    sSolverType = get_param(sSlModel, 'SolverType');
    if ~strcmpi(sSolverType, 'fixed-step')
        stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:SOLVER_TYPE_NOT_SUPPORTED', ...
            'solver_type', sSolverType, ...
            'model',       sSlModel);
        osc_throw(stErr);
    end

    % TODO: compare sample times of SL and TL model
end
end


%%
% two functions depending on input: sTlSubsystem
% 1) no TL subsystem given 
%    a) check for multiple TL Subsystems --> exception if more than one
%    b) return the name of the one TL Subsystem
% 2) one TL subsystem given
%    a) check that provided TL subsystem is valid
%   
function sTlSubsystem = i_checkTLSubsystem(stEnv, sTlModel, sTlSubsystem)
if (nargin < 3)
    sTlSubsystem = '';
end

casTlSubsystems = ep_get_tlsubsystems(sTlModel);
if isempty(casTlSubsystems)
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:CHECK_MODEL_INVALID', ...
        'model', sTlModel, ...
        'msg',   'No valid TL Subsystem found in model.');
    osc_throw(stErr);
end

if isempty(sTlSubsystem)
    % TL Subsystem not provided --> 1)
    if (length(casTlSubsystems) < 2)
        sTlSubsystem = i_getTlSubsystemPath(casTlSubsystems{1});
        
    else
        stErr = osc_messenger_add(stEnv, 'ATGCV:TLAPI:MULTIPLE_TL_SUBSYSTEMS_FOUND', 'model',  sTlModel);
        osc_throw(stErr);
    end
else
    % if all Subsystems are accepted, take the first one and return early
    if strcmp(sTlSubsystem, '*')
        sTlSubsystem = casTlSubsystems{1};
        return;
    end
    
    % check for a correct TL subsystem name
    bIsValid = false;
    for k = 1:length(casTlSubsystems)
        sTlPath = i_getTlSubsystemPath(casTlSubsystems{k});
        if strcmp(sTlSubsystem, sTlPath)
            bIsValid = true;
            break;
        end

        sTlName = i_getTlSubsystemName(casTlSubsystems{k});
        if strcmp(sTlSubsystem, sTlName)
            sTlSubsystem = sTlPath;
            bIsValid = true;
            break;
        end
    end
    if ~bIsValid
        stErr = osc_messenger_add(stEnv, 'ATGCV:STD:WRONG_PARAM_VAL', ...
            'param_name',  'TlSubsystem', ...
            'wrong_value', sTlSubsystem);
        stErr.message = 'No matching TargetLink toplevel subsystem found!';   
        osc_throw(stErr);
    end
end
end


%%
% get "outer" TL subsystem path
function sTlPath = i_getTlSubsystemPath(sTlSubsystem)
stInfo = [];
try
    stInfo = tl_get_subsystem_info(sTlSubsystem);
catch
    % do nothing
end
if (~isempty(stInfo) && isfield(stInfo, 'tlSubsystemPath'))
    sTlPath = stInfo.tlSubsystemPath;
else
    % remove last two layers
    sTlPath  = fileparts(fileparts(sTlSubsystem));
end
end


%%
function sTlName = i_getTlSubsystemName(sTlSubsystem)
stInfo = [];
try
    stInfo = tl_get_subsystem_info(sTlSubsystem);
catch
    % do nothing
end
if (~isempty(stInfo) && isfield(stInfo, 'tlSubsystemName'))
    sTlName = stInfo.tlSubsystemName;
else
    [p, sTlName] = fileparts(sTlSubsystem); %#ok p not used
end
end


%%
function astModules = i_getModules(sModelName)
if isempty(sModelName)
    astModules = [];
end
if isempty(sModelName)
    return;
end

% remove last model found by "find_mdlrefs" because it is the name of the main model itself
casModelRefs = ep_find_mdlrefs(sModelName);
casModelRefs(end) = [];

% do not read any info from following libs
casBlackListLibs = {...
    'tllib', ...
    'tldummylib', ...
    'simulink', ...
    'atgcv_lib', ...
    'evlib'}; 

casBlackListPaths = {};

sMlPath = matlabroot();
if ~isempty(sMlPath)
    casBlackListPaths{end + 1} = sMlPath;
end
sTlPath = ep_dspaceroot();
if isempty(sTlPath)
    sTlPath = getenv('TL_ROOT');
end
if ~isempty(sTlPath)
    casBlackListPaths{end + 1} = sTlPath;
end


% get all lib references in model
astLibInfo = ep_libinfo(sModelName);

if ~isempty(astLibInfo)
    % remove all unresolved/inactive lib references
    astLibInfo = astLibInfo(strcmpi({astLibInfo.LinkStatus}, 'resolved'));
    
    % remove double entries
    casLibs = unique({astLibInfo(:).Library});
    
    % exclude tllib and simulink from libs
    abSelect = true(1, length(casLibs));
    for i = 1:length(casLibs)
        abSelect(i) = ~any(strcmpi(casLibs{i}, casBlackListLibs));
    end
    casLibs = casLibs(abSelect);
else
    casLibs = {};
end

astModules = i_getMdlSpec(sModelName, 'model');
if ~isempty(casModelRefs)
    nModelRefs = length(casModelRefs);
    for i = 1:nModelRefs
        try
            get_param(casModelRefs{i}, 'handle');
        catch
            % maybe throw warning here
            continue;
        end        
        astModules(end + 1) = i_getMdlSpec(casModelRefs{i}, 'model_ref'); %#ok<AGROW>
    end
end

if ~isempty(casLibs)
    nLibs = length(casLibs);
    
    for i = 1:nLibs
        % use lib only if it is accessible (robustness)
        try
            get_param(casLibs{i}, 'handle');
        catch
            % maybe throw warning here
            continue;
        end        
        astModules(end + 1) = i_getMdlSpec(casLibs{i}, 'library'); %#ok<AGROW>
    end
end

% avoid libs from certain places: MATLABROOT, TL_ROOT (DSPACE_ROOT)
for i = 1:length(casBlackListPaths)
    if (length(astModules) > 1)    
        sPath = casBlackListPaths{i};
        nPathLen = length(sPath);
        
        % don't keep modules if they have the paths from the blacklist
        abKeepModules = ~strncmpi(sPath, {astModules(:).sFile}, nPathLen);
        
        % always keep the original model info (i.e. the first module)
        abKeepModules(1) = true;
        
        astModules = astModules(abKeepModules);
    end
end
end


%%
function stSpec = i_getMdlSpec(sMdlName, sKind)
stSpec = struct( ...
    'sKind',       sKind, ...
    'sFile',       get_param(sMdlName, 'FileName'), ...
    'sVersion',    get_param(sMdlName, 'ModelVersion'), ...
    'sCreated',    get_param(sMdlName, 'Created'), ...
    'sModified',   get_param(sMdlName, 'LastModifiedDate'), ...
    'sCreator',    get_param(sMdlName, 'Creator'), ...
    'sIsModified', i_isMdlModified(sMdlName));
end


%%
% translates Dirty:on|off --> IsModified:yes|no
function sIsModified = i_isMdlModified(sMdlName)
sIsModified = 'no';
sDirty = get_param(sMdlName, 'Dirty');
if strcmpi(sDirty, 'on')
    sIsModified = 'yes';
end
end



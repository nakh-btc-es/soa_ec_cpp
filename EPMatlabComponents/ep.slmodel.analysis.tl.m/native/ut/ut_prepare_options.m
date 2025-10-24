function stOpt = ut_prepare_options(stOpt, sTargetDir)
% Get default options and combine them wit the provided ones.
%
% function stOpt = ut_prepare_options(stOpt, sTargetDir)
%
%   INPUT               DESCRIPTION
%     stOpt               (struct)  structure with options for model analysis
%       .sDdPath          (string)  full path to DataDictionary to be used
%                                   for analysis
%       .sTlModel         (string)  name of TargetLink model to be used for
%                                   analysis (assumed to be open)
%       .sSlModel         (string)  name of Simulink model corresponding to the
%                                   TargetLink model (optional parameter)
%       .sTlSubsystem     (string)  name (without path) of TL toplevel Subsystem
%                                   (optional if there is just one Subsystem in
%                                   the model; obligatory if there are many)
%       .bCalSupport        (bool)  TRUE if CalibrationSupport shall be
%                                   activated, otherwise FALSE
%       .bDispSupport       (bool)  TRUE if DisplaySupport shall be
%                                   activated, otherwise FALSE
%       .bParamSupport      (bool)  TRUE if ParameterSupport shall be
%                                   activated, otherwise FALSE
%       .sDsmMode         (string)  DataStoreMode support
%                                   'all' | <'read'> | 'none'
%       .bExcludeTLSim      (bool)  TRUE if only the pure ProductionCode shall
%                                   be considered (i.e. all files from TLSim
%                                   directory are excluded)
%                                   default is FALSE
%       .sModelMode       (String)  <'TL'> | 'SL'
%       .sAddModelInfo    (String)  Path to the XML file including
%                                   additional model information.
%       .bAddEnvironment    (bool)  consider also the Parent-Subsystem of the
%                                   TL-TopLevel Subsystem
%                                   default is FALSE
%       .bIgnoreStaticCal   (bool)  if TRUE, ignore all STATIC_CAL Variables
%                                   default is FALSE
%       .bIgnoreBitfieldCal (bool)  if TRUE, ignore all CAL Variables with Type
%                                   Bitfield; default is FALSE
%



%% main
if (nargin < 1)
    stOpt = i_getDefaultArgs();
    stOpt = i_checkSetOptions(stOpt);
else
    % check options and set defaults if necessary
    stOpt = i_checkSetOptions(stOpt);
end
stOpt.sModelAnalysis = fullfile(sTargetDir, 'ModelAnalysis.xml');
stOpt.sAssumptions = fullfile(sTargetDir, 'Assumptions.xml');
stOpt = i_extendResultOpt(sTargetDir, stOpt);
stOpt = i_extendConstraintOpt(sTargetDir, stOpt);
if ~isfield(stOpt, 'bAdaptiveAutosar')
    stOpt.bAdaptiveAutosar = false;
end

if ~isempty(stOpt.sTlModel)
    stOpt = i_addCodegenInfo(sTargetDir, stOpt);
end
end


%%
function stOpt = i_getDefaultArgs(sMode)
sDd = i_getCurrentDd();
bIsSL = isempty(sDd);
if ((nargin > 0) && strcmpi(sMode, 'SL'))
    error('UT:ILLEGAL_SL_UT', 'Illegal SL test! SL functionality shall be checked in base analysis bundle.');
end
if bIsSL
    stOpt = struct( ...
        'sSlModel',   bdroot(gcs()), ...
        'sCalMode',   'explicit', ...
        'sDispMode',  'all', ...
        'sModelMode', 'SL');
else
    stOpt = struct( ...
        'sTlModel',   bdroot(gcs()), ...
        'sDdPath',    sDd, ...
        'sCalMode',   'explicit', ...
        'sDispMode',  'all');
    casSubsystems = get_tlsubsystems(stOpt.sTlModel);
    if (length(casSubsystems) > 1)
        casNames = cellfun( ...
            @(x)(get_param(x, 'Name')), ...
            casSubsystems, ...
            'UniformOutput', false);
        iIdx = find(strcmpi(get_param(gcbh, 'Name'), casNames));
        if isempty(iIdx)
            iIdx = 1;
        end
        stOpt.sTlSubsystem = get_param(casSubsystems{iIdx}, 'Name');
    end
end
end


%%
function sCurrDd = i_getCurrentDd()
sCurrDd = dsdd('GetDDAttribute', 0, 'fileName');
if strcmpi(sCurrDd, 'untitled.dd')
    sCurrDd = '';
end
end


%%
function stOpt = i_checkSetOptions(stOpt)
% set default options
if ~isfield(stOpt, 'sTlModel')
    stOpt.sTlModel = '';
end
if ~isfield(stOpt, 'sDdPath')
    stOpt.sDdPath = '';
end
if ~isfield(stOpt, 'sSlModel')
    stOpt.sSlModel = '';
end
if ~isfield(stOpt, 'sTlSubsystem')
    stOpt.sTlSubsystem = '';
end
if ~isfield(stOpt, 'sAddModelInfo')
    stOpt.sAddModelInfo = '';
end
bProvidedModelTL = ~isempty(stOpt.sTlModel);
bProvidedModelSL = ~isempty(stOpt.sSlModel);
if (~isfield(stOpt, 'sModelMode') || isempty(stOpt.sModelMode))
    if (bProvidedModelSL && ~bProvidedModelTL)
        % special case: SL provided but no TL --> indicates SL-only use case
        stOpt.sModelMode = 'SL';
    else
        if ~isempty(stOpt.sAddModelInfo)
            % additional model info was provided --> SL-only use case
            stOpt.sModelMode = 'SL';
        else
            stOpt.sModelMode = 'TL';
        end
    end
end

% CAL support
% Note: Mode-String is always overriding the boolean Flags!
if (~isfield(stOpt, 'sCalMode') || isempty(stOpt.sCalMode))
    if ~isfield(stOpt, 'bCalSupport')
        stOpt.bCalSupport = false;
    end
    if ~isfield(stOpt, 'bParamSupport')
        if stOpt.bCalSupport
            stOpt.bParamSupport = false;
        else
            stOpt.bParamSupport = true;
        end
    end
    if stOpt.bCalSupport
        stOpt.sCalMode = 'limited';
    elseif stOpt.bParamSupport
        stOpt.sCalMode = 'explicit';
    else
        stOpt.sCalMode = 'none';
    end
else
    switch lower(stOpt.sCalMode)
        case 'explicit'
            stOpt.bCalSupport   = false;
            stOpt.bParamSupport = true;
            
        case 'limited'
            stOpt.bCalSupport   = true;
            stOpt.bParamSupport = false;
            
        case 'none'
            stOpt.bCalSupport   = false;
            stOpt.bParamSupport = false;
            
        otherwise
            error('ATGCV:INTERNAL:ERROR', 'Unknown CAL mode.');
    end
end

% DISP support
if (~isfield(stOpt, 'sDispMode') || isempty(stOpt.sDispMode))
    if ~isfield(stOpt, 'bDispSupport')
        stOpt.bDispSupport = true;
    end
    if (stOpt.bDispSupport)
        stOpt.sDispMode = 'all';
    else
        stOpt.sDispMode = 'none';
    end
else
    switch lower(stOpt.sDispMode)
        case 'all'
            stOpt.bDispSupport = true;
            
        case 'none'
            stOpt.bDispSupport = false;
            
        otherwise
            error('ATGCV:INTERNAL:ERROR', 'Unknown DISP mode.');
    end
end

% DSM support
if (~isfield(stOpt, 'sDsmMode') || isempty(stOpt.sDsmMode))
    stOpt.sDsmMode = 'all';
end

% Environment support
if (~isfield(stOpt, 'bAddEnvironment') || isempty(stOpt.bAddEnvironment))
    stOpt.bAddEnvironment = false;
end

% STATIC_CAL handling
if (~isfield(stOpt, 'bIgnoreStaticCal') || isempty(stOpt.bIgnoreStaticCal))
    stOpt.bIgnoreStaticCal = false;
end

% handling of CALs with Type Bitfield
if (~isfield(stOpt, 'bIgnoreBitfieldCal') || isempty(stOpt.bIgnoreBitfieldCal))
    stOpt.bIgnoreBitfieldCal = false;
end

% TLSim handling
if ~isfield(stOpt, 'bExcludeTLSim')
    stOpt.bExcludeTLSim = false;
end
% clear atgcv_m01_module_check; % re-set the persistent variables
% if stOpt.bExcludeTLSim
%     atgcv_m01_module_check('EXCLUDE_TLSIM');
% end

% check mandatory parameters
if (strcmp(stOpt.sModelMode, 'TL'))
    if (isempty(stOpt.sDdPath) || isempty(stOpt.sTlModel))
        stDef = i_getDefaultArgs('TL');
        if isempty(stOpt.sDdPath)
            stOpt.sDdPath = stDef.sDdPath;
        end
        if isempty(stOpt.sTlModel)
            stOpt.sTlModel = stDef.sTlModel;
        end
    end
    if isempty(stOpt.sDdPath)
        error('ATGCV:INTERNAL:ERROR', 'Path to DD has to be provided.');
    end
    if isempty(stOpt.sTlModel)
        error('ATGCV:INTERNAL:ERROR', 'Name of TL model has to be provided.');
    end
else
    if isempty(stOpt.sSlModel)
        stDef = i_getDefaultArgs('SL');
        stOpt.sSlModel = stDef.sSlModel;
    end
    if isempty(stOpt.sSlModel)
        error('ATGCV:INTERNAL:ERROR', 'Path to SL has to be provided.');
    end
end
stOpt.sTlModel = i_normalizeModelName(stOpt.sTlModel);
stOpt.sSlModel = i_normalizeModelName(stOpt.sSlModel);
end


%%
function sModel = i_normalizeModelName(sModel)
if isempty(sModel)
    return;
end
% remove path and extension if there are any
[~, sModel] = fileparts(sModel);
try
    % try to get Model handle just to check if name is consistent
    get_param(sModel, 'handle');
    
    % avoid problems with wrong case letters and use the name as
    % returned from the get_param() function
    sModel = get_param(sModel, 'name');
catch
    % AH TODO: maybe replace by messenger entry
    error('ATGCV:MOD_ANA:INVALID_MODEL', 'Could not find model "%s".', sModel);
end
end


%%
function stOpt = i_extendResultOpt(sResultPath, stOpt)
if ~isfield(stOpt, 'sTlResultFile')
    stOpt.sTlResultFile = fullfile(sResultPath, 'tlResult.xml');
end
if ~isfield(stOpt, 'sSlResultFile')
    stOpt.sSlResultFile = fullfile(sResultPath, 'slResult.xml');
end
if ~isfield(stOpt, 'sCResultFile')
    stOpt.sCResultFile = fullfile(sResultPath, 'cResult.xml');
end
if ~isfield(stOpt, 'sMappingResultFile')
    stOpt.sMappingResultFile = fullfile(sResultPath, 'mappingResult.xml');
end
if ~isfield(stOpt, 'astTlModules')
    if (isfield(stOpt, 'sTlModel') && ~isempty(stOpt.sTlModel))
        stOpt.astTlModules = i_getModules(stOpt.sTlModel);
    else
        stOpt.astTlModules = [];
    end
end
if ~isfield(stOpt, 'astSlModules')
    if (isfield(stOpt, 'sSlModel') && ~isempty(stOpt.sSlModel))
        stOpt.astSlModules = i_getModules(stOpt.sSlModel);
    else
        stOpt.astSlModules = [];
    end
end
end


%%
function stOpt = i_extendConstraintOpt(sResultPath, stOpt)
if (isfield(stOpt, 'sTlModel') && ~isempty(stOpt.sTlModel))
    if ~isfield(stOpt, 'sTlArchConstrFile')
        stOpt.sTlArchConstrFile = fullfile(sResultPath, 'tlConstr.xml');
    end
    if ~isfield(stOpt, 'sCArchConstrFile')
        stOpt.sCArchConstrFile = fullfile(sResultPath, 'cConstr.xml');
    end
else
    stOpt.sTlArchConstrFile = '';
    stOpt.sCArchConstrFile = '';
end
if (isfield(stOpt, 'sSlModel') && ~isempty(stOpt.sSlModel))
    if ~isfield(stOpt, 'sSlArchConstrFile')
        stOpt.sSlArchConstrFile = fullfile(sResultPath, 'slConstr.xml');
    end
else
    stOpt.sSlArchConstrFile = '';
end
end


%%
function stOpt = i_addCodegenInfo(sResultPath, stOpt)
if ~exist(sResultPath, 'dir')
    mkdir(sResultPath);
end
stOpt.sFileList = fullfile(sResultPath, 'CodeGeneration.xml');

oEnv = EPEnvironment();
oOnCleanupClearEnv = onCleanup(@() oEnv.clear());

stEnvLegacy = ep_core_legacy_env_get(oEnv, true);
if (isfield(stOpt, 'sEnvironmentFileList') && ~isempty(stOpt.sEnvironmentFileList))
    sUserFileList = stOpt.sEnvironmentFileList;
else
    sUserFileList = '';
end

sTlSubsystem = stOpt.sTlSubsystem;
if isempty(sTlSubsystem)
    casSubsystems = get_tlsubsystems(stOpt.sTlModel);
    sTlSubsystem = get_param(casSubsystems{1}, 'Name');
end

i_fakeCodegenXML(stEnvLegacy, sTlSubsystem, sUserFileList, stOpt.sFileList, stOpt.sTlModel);
end


%%
function astModules = i_getModules(sModelName)
if isempty(sModelName)
    astModules = [];
end
if isempty(sModelName)
    return;
end

% remove last model found by "find_mdlrefs" because it is the name of the main
% model itself
casModelRefs = find_mdlrefs(sModelName);
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
sTlPath = '';
try
    sTlPath = ep_dspaceroot();
catch
end
if isempty(sTlPath)
    sTlPath = getenv('TL_ROOT');
end
if ~isempty(sTlPath)
    casBlackListPaths{end + 1} = sTlPath;
end


% get all lib references in model
astLibInfo = libinfo(sModelName);

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
        
        % don't keep modules if they have the wrong paths
        abKeepModules = ~strncmpi(sPath, {astModules(:).sFile}, nPathLen);
        
        % always keep the original model info (i.e. the first module)
        abKeepModules(1) = true;
        
        astModules = astModules(abKeepModules);
    end
end
end


%%
function stSpec = i_getMdlSpec(sMdlName, sKind)
% first translate Dirty:on|off --> IsModified:yes|no
sIsModified = 'no';
sDirty = get_param(sMdlName, 'Dirty');
if strcmpi(sDirty, 'on')
    sIsModified = 'yes';
end
stSpec = struct( ...
    'sKind',       sKind, ...
    'sFile',       get_param(sMdlName, 'FileName'), ...
    'sVersion',    get_param(sMdlName, 'ModelVersion'), ...
    'sCreated',    get_param(sMdlName, 'Created'), ...
    'sModified',   get_param(sMdlName, 'LastModifiedDate'), ...
    'sCreator',    get_param(sMdlName, 'Creator'), ...
    'sIsModified', sIsModified);
end



%%
function i_fakeCodegenXML(stEnv, sTlSubsystem, sUserFileList, sCodegenXml, sTlModel)
casSubs = atgcv_mxx_dd_subsystem_tree_get(stEnv, sTlSubsystem);
astArtifacts = atgcv_m02_cfiles_get(stEnv, casSubs);

bWithTLSim = true;
stCombined = atgcv_m02_cfiles_combine(astArtifacts, bWithTLSim);
atgcv_m02_export_codegen_xml(stEnv, stCombined, sUserFileList, sCodegenXml, sTlModel);
end



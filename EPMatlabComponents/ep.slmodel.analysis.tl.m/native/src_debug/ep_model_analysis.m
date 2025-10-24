function stModel = ep_model_analysis(stOpt)
% wrapper for atgcv_model_analysis for the EP2.x project
%
% function stOpt = ep_options_get(stOpt)
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
%        ... TODO ...
%

%% main
if (nargin < 1)
    stOpt = struct();
end

stOpt = atgcv_m01_options_get(stOpt);
stOpt.xEnv = EPEnvironment();

sResultDir = fullfile(pwd, 'results_ep_mdl_analyze');
if exist(sResultDir, 'dir')
    rmdir(sResultDir, 's');
end
mkdir(sResultDir);

if ~isfield(stOpt, 'iOutputGen')
    stOpt.iOutputGen = 1;
end

stOpt.sModelAnalysis = fullfile(sResultDir, 'ModelAnalysis.xml');
stOpt.sAssumptions = fullfile(sResultDir, 'Assumptions.xml');
stOpt = i_extendResultOpt(sResultDir, stOpt);
stOpt = i_extendConstraintOpt(sResultDir, stOpt);

if strcmpi(stOpt.sModelMode, 'TL')
    stOpt = i_addCodegenInfo(sResultDir, stOpt);
end

stModel = ep_model_analyse(stOpt);

sErrorFile = fullfile(sResultDir, 'errors.xml');
stOpt.xEnv.exportMessages(sErrorFile);
stOpt.xEnv.clear();
end



%%
function stOpt = i_addCodegenInfo(sResultPath, stOpt)
if ~exist(sResultPath, 'dir')
    mkdir(sResultPath);
end
stOpt.sFileList = fullfile(sResultPath, 'CodeGeneration.xml');

stEnvLegacy = ep_core_legacy_env_get(stOpt.xEnv, true);

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

i_fakeCodegenXML(stEnvLegacy, sTlSubsystem, sUserFileList, stOpt.sFileList, stOpt.bAdaptiveAutosar);

sOscTypes = fullfile(pwd, 'osc_types.c');
if exist(sOscTypes, 'file')
    movefile(sOscTypes, sResultPath)
end
end


%%
function i_fakeCodegenXML(stEnv, sTlSubsystem, sUserFileList, sCodegenXml, bAddTlCodeSfncDefine)
casSubs = atgcv_mxx_dd_subsystem_tree_get(stEnv, sTlSubsystem);
astArtifacts = atgcv_m02_cfiles_get(stEnv, casSubs);
astArtifacts = arrayfun(@(stArtf) i_applyFallbackIfCodeWasMoved(stEnv, stArtf), astArtifacts);

bWithTLSim = true;
stCombined = atgcv_m02_cfiles_combine(astArtifacts, bWithTLSim);
atgcv_m02_export_codegen_xml(stEnv, stCombined, sUserFileList, sCodegenXml, bAddTlCodeSfncDefine);
end


%%
function sCommonRootDir = i_getCommonRootDir(sDir1, sDir2)
sDir1 = atgcv_canonical_path(sDir1);
sDir2 = atgcv_canonical_path(sDir2);
if strcmpi(sDir1, sDir2)
    sCommonRootDir = sDir1;
else
    sCommonRootDir = '';
    casParts1 = regexp(sDir1, '\', 'split');
    casParts2 = regexp(sDir2, '\', 'split');
    nMinLen = min(numel(casParts1), numel(casParts2));
    for i = 1:nMinLen
        if strcmpi(casParts1{i}, casParts2{i})
            if isempty(sCommonRootDir)
                sCommonRootDir = casParts1{i};
            else
                sCommonRootDir = [sCommonRootDir, '\', casParts1{i}]; %#ok<AGROW>
            end
        else
            break;
        end
    end
    if ~isempty(sCommonRootDir)
        sCommonRootDir = atgcv_canonical_path(sCommonRootDir);
    end
end
end


%%
function stArtifact = i_applyFallbackIfCodeWasMoved(stEnv, stArtifact)
if (i_haveArtifactsBeenMoved(stArtifact) && ~isempty(stArtifact.sModelFile))
    [~, sModelName] = fileparts(stArtifact.sModelFile);
    sCurrModelFile = i_getCurrentModelFile(sModelName);
    if ~isempty(sCurrModelFile)
        stArtifactFallback = i_applyFallback(stEnv, stArtifact, sCurrModelFile);
        if (~isempty(stArtifactFallback) && ~i_haveArtifactsBeenMoved(stArtifactFallback))
            stArtifact = stArtifactFallback;
        end
    end
end
end


%%
function sModelFile = i_getCurrentModelFile(sModelName)
try
    sModelFile = get_param(sModelName, 'FileName');
catch
    sModelFile  = '';
end
end


%%
function bHaveBeenMoved = i_haveArtifactsBeenMoved(stArtifact)
bHaveBeenMoved = false;
if isempty(stArtifact.casGeneratedFiles)
    return;
end

stArtifact = atgcv_m02_cfiles_abspaths_get(stArtifact);
abExist = cellfun(@(sFile) logical(exist(sFile, 'file')), stArtifact.casGeneratedFiles);
bHaveBeenMoved = all(~abExist);
end


%%
%  A fallback can be applied if the working directory (WD) and the model file (MF) have been moved but still have the
%  same relative position to each other. In this case we are able to determine the new working directory by making use
%  of the new location of the model file, which we know.
%  Idea:
%     1) compute the common root path X of WD and MF
%     2) compute the relative path from X to MF (--> the MF-Remainder)
%     3) subtract the MF-Remainder from the new MF location (MF') to get the candidate for the new location of the
%        common root path X'
%     4) compute the relative path from X to WD (--> the WD-Remainder)
%     5) add the WD-Remainder to X' which yields the new WD location WD'
%     
function stArtifactFallback = i_applyFallback(~, stArtifact, sNewModelFileLocation)
stArtifactFallback = [];


sCommonRootDir = i_getCommonRootDir(stArtifact.sWorkingDirectory, fileparts(stArtifact.sModelFile));
if isempty(sCommonRootDir)
    % if WorkingDir WD and ModelFile MF do not have a common root path, the fallback cannot be applied
    return;
end

nCommonLen = length(sCommonRootDir);
sModelFileRemainder = stArtifact.sModelFile(nCommonLen+1:end);
nRemainderLen = length(sModelFileRemainder);

sNewModelFileLocation = atgcv_canonical_path(sNewModelFileLocation);
sNewModelFileRemainder = sNewModelFileLocation(end - nRemainderLen + 1:end);
if ~strcmpi(sModelFileRemainder, sNewModelFileRemainder)
    % if the remainder of the model file has changed, the fallback cannot be applied
    return;
end

sNewCommonRootDir = sNewModelFileLocation(1:end - nRemainderLen);
if ~exist(sNewCommonRootDir, 'dir')
    return;
end

if (length(stArtifact.sWorkingDirectory) > nCommonLen)
    sWorkingDirRemainder = stArtifact.sWorkingDirectory(nCommonLen + 1:end);
    if (sWorkingDirRemainder(1) == '\')
        sNewWorkingDirectory = [sNewCommonRootDir, sWorkingDirRemainder];
    else
        sNewWorkingDirectory = [sNewCommonRootDir, '\', sWorkingDirRemainder];
    end
else
    sNewWorkingDirectory = sNewCommonRootDir;
end
if ~exist(sNewWorkingDirectory, 'dir')
    return;
end

stArtifactFallback = stArtifact;
stArtifactFallback.sWorkingDirectory = atgcv_canonical_path(sNewWorkingDirectory);
stArtifactFallback.sModelFile = sNewModelFileLocation;
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
        astModules(end + 1) = i_getMdlSpec(casModelRefs{i}, 'model_ref');
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
        astModules(end + 1) = i_getMdlSpec(casLibs{i}, 'library');
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
    'sCreator',    get_param(sMdlName, 'Creator'), ...
    'sModified',   get_param(sMdlName, 'LastModifiedDate'), ...
    'sIsModified', sIsModified);
end



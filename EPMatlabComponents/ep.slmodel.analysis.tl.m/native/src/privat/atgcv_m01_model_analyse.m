function stModel = atgcv_m01_model_analyse(stEnv, stOpt)
% Analyse TL or SL model and corresponding C-code.
%
% function stModel = atgcv_m01_model_analyse(stEnv, stOpt)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)  environment structure
%     stOpt               (struct)  structure with options for model analysis
%       .sDdPath          (string)  full path to DataDictionary to be used for analysis
%       .sTlModel         (string)  name of TargetLink model to be used for analysis (assumed to be open)
%       .sSlModel         (string)  name of Simulink model corresponding to the TargetLink model (optional parameter)
%       .sTlSubsystem     (string)  name (without path) of TL toplevel Subsystem
%                                   (optional if there is just one Subsystem in the model; obligatory if there are many)
%       .bCalSupport        (bool)  TRUE if CalibrationSupport shall be activated, otherwise FALSE
%       .bDispSupport       (bool)  TRUE if DisplaySupport shall be activated, otherwise FALSE
%       .bParamSupport      (bool)  TRUE if ParameterSupport shall be activated, otherwise FALSE
%       .sDsmMode         (string)  DataStoreMode support
%                                   'all' | <'read'> | 'none'
%       .bExcludeTLSim      (bool)  TRUE if only the pure ProductionCode shall be considered
%                                   (i.e. all files from TLSim directory are excluded); default is FALSE
%       .bAddEnvironment    (bool)  consider also the Parent-Subsystem of the TL-TopLevel Subsystem; default is FALSE
%       .bIgnoreStaticCal   (bool)  if TRUE, ignore all STATIC_CAL Variables; default is FALSE
%       .bIgnoreBitfieldCal (bool)  if TRUE, ignore all CAL Variables with Type Bitfield; default is FALSE
%        ... TODO ...
%
%   OUTPUT              DESCRIPTION
%     stModel             (struct) result structure
%        ... TODO ...
%


%% prepare data
clear ep_sl_type_info_get; % clear internal cache

if (nargin < 2)
    stEnv = 0;
    stOpt = atgcv_m01_options_get();
else
    stOpt = atgcv_m01_options_get(stOpt);
end

% analyse
stModel = i_analyseTL(stEnv, stOpt);
stModel.astTypeInfos = ep_sl_type_info_get();
end


%%
function stModel = i_analyseTL(stEnv, stOpt)
xOnCleanupRestoreBatchMode = i_switchOnBatchMode(); %#ok<NASGU>
sBeforeDD = i_getCurrentDD();
xOnCleanupRestore = onCleanup(@() i_openDdForModel(stEnv, stOpt.sTlModel, sBeforeDD));

i_openDdForModel(stEnv, stOpt.sTlModel, stOpt.sDdPath);

% get toplevel and model info
stToplevel = i_getToplevelInfo(stEnv, stOpt);
stModel = atgcv_m01_model_info_get(stEnv, stToplevel.hDd, stOpt);

% add extra info
stModel.sTlModel        = stOpt.sTlModel;
stModel.sSlModel        = stOpt.sSlModel;
stModel.sTlRoot         = stToplevel.sTlRoot;
stModel.sSlRoot         = stToplevel.sSlRoot;
stModel.hTlSubDD        = stToplevel.hDd;
stModel.bParamSupport   = stOpt.bParamSupport;
stModel.bIsSimulinkOnly = false;
[stModel.bAutosarCode, stModel.bAdaptiveAutosar] = i_checkCodegenAutosar(stEnv, stModel.sTlModel);
stModel.bSetGlobalInitFuncForAutosar = false;
if stModel.bAutosarCode && ~stModel.bAdaptiveAutosar
    stModel.bSetGlobalInitFuncForAutosar = true;
end


% SL check
if ~isempty(stModel.sSlRoot)
    stModel = i_adaptSlPathAndRemoveInvalidSlSubsystems(stEnv, stModel);
end

% add model params
stModel = i_addModelParameters(stEnv, stModel);
end


%%
function sCurrDd = i_getCurrentDD()
sCurrDd = dsdd('GetDDAttribute', 0, 'fileName');
if strcmpi(sCurrDd, 'untitled.dd')
    sCurrDd = '';
end
end


%%
function xOnCleanupRestore = i_switchOnBatchMode()
sUserBatchMode = ds_error_get('BatchMode');
ds_error_set('BatchMode', 'on');
xOnCleanupRestore = onCleanup(@() ds_error_set('BatchMode', sUserBatchMode));
end


%%
% check for AUTOSAR UseCase
function [bIsClassicAutosar, bIsAdaptiveAutosar] = i_checkCodegenAutosar(stEnv, sTlModel)
hMainDialog = i_findMainDialog(stEnv, sTlModel);
iMode = tl_get(hMainDialog, 'codegenerationmode');
bIsClassicAutosar = iMode == 2;
bIsAdaptiveAutosar = iMode == 4;
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
function stToplevel = i_getToplevelInfo(stEnv, stOpt)
stToplevel = struct( ...
    'hDd',      [], ...
    'sTlRoot',  '', ...
    'sSlRoot',  '');

% get TL subsystem root path
casSubsystems = ep_get_tlsubsystems(stOpt.sTlModel);
nSub = length(casSubsystems);
if isempty(stOpt.sTlSubsystem)
    if (nSub > 1)
        % AH TODO: replace by messenger entry
        error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Multiple TL topelvel subsystems found. You have to select one of them.');
    else
        stToplevel.sTlRoot = casSubsystems{1};
    end
else
    for i = 1:nSub
        [p, sSubName] = fileparts(casSubsystems{i}); %#ok p not needed
        if strcmp(sSubName, stOpt.sTlSubsystem)
            stToplevel.sTlRoot = casSubsystems{i};
            break;
        end
    end
end
if isempty(stToplevel.sTlRoot)
    % AH TODO: replace by messenger entry
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Provided subsystem could not be found among TL toplevel subsystems.');
end

% get DD handle
[p, sName] = fileparts(stToplevel.sTlRoot); %#ok p not used
stToplevel.hDd = atgcv_mxx_dsdd(stEnv, 'Find', '/Subsystems', 'objectKind', 'Subsystem', 'name', sName);
if isempty(stToplevel.hDd)
    % AH TODO: replace by messenger entry
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Could not find DD handle for toplevel subsystem.');
end

% get+check SL subsystem root path
if ~isempty(stOpt.sSlModel)
    sBasePath = get_param(get_param(stToplevel.sTlRoot, 'Parent'), 'Parent');
    sSlRoot = regexprep(getfullname(sBasePath), ...
        ['^', regexptranslate('escape', stOpt.sTlModel)], stOpt.sSlModel, ...
        'ignorecase');
    try
        hSlRoot = get_param(sSlRoot, 'Handle');
    catch
        stErr = osc_messenger_add(stEnv, 'ATGCV:SLAPI:WRONG_HANDLE', 'simulink_path',  sSlRoot);
        osc_throw(stErr);
    end
    sBlockType = get_param(hSlRoot, 'blocktype');
    if ~strcmpi(sBlockType ,'SubSystem')
        stErr = osc_messenger_add(stEnv, 'ATGCV:SLAPI:WRONG_BLOCKTYPE', ...
            'name',         sSlRoot, ...
            'block_type',   sBlockType, ...
            'expectedtype', 'SubSystem');
        osc_throw(stErr);
    end
    stToplevel.sSlRoot = sSlRoot;
end
end


%%
function stModel = i_adaptSlPathAndRemoveInvalidSlSubsystems(stEnv, stModel)

% get map from virtual path to model path and sort in descending order of the length of the virtual path
astModelRefMap = i_sortMap(i_getModelRefMap(stModel.sSlModel));

sPatternTlRoot = ['^', regexptranslate('escape', stModel.sTlRoot)];

nSub = length(stModel.astSubsystems);
abIsValid = true(1, nSub);
for i = 1:nSub
    % get virtual path
    sSlPath = regexprep(stModel.astSubsystems(i).sTlPath, sPatternTlRoot, stModel.sSlRoot, 'ignorecase');
    sModelPath = sSlPath;
    if ~isempty(astModelRefMap)
        for j = 1:length(astModelRefMap)
            sVirtualPath = astModelRefMap(j).sVirtualPath;
            nPathLength = length(sVirtualPath);
            if strncmp(sSlPath, sVirtualPath, nPathLength)
                sModelPath = strrep(sSlPath, sVirtualPath, astModelRefMap(j).sModelPath);
                break;
            end
        end
    end

    % try out if we really have a correspondance between TL and SL subsystem
    try
        hSlBlock = get_param(sModelPath, 'handle');
    catch
        if stModel.astSubsystems(i).bIsToplevel
            stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:SL_SUBSYSTEM_NOT_FOUND', ...
                'sl_subsys',  sSlPath, ...
                'tl_subsys',  stModel.astSubsystems(i).sTlPath);
            osc_throw(stErr);
        else
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:SL_SUBSYSTEM_NOT_FOUND_RECOVERED', ...
                'sl_subsys',  sSlPath, ...
                'tl_subsys',  stModel.astSubsystems(i).sTlPath);
            abIsValid(i) = false;
            continue;
        end
    end

    % referenced models are root_level subsystems, i.e. they have no surrounding subsystem block
    try
        sParent = get_param(sModelPath, 'parent');
    catch
        sParent = '';
    end
    if ~isempty(sParent)
        sBlockType = get_param(hSlBlock, 'blocktype');
        if ~strcmpi(sBlockType ,'SubSystem')
            if stModel.astSubsystems(i).bIsToplevel
                stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:SL_SUBSYSTEM_NOT_FOUND', ...
                    'sl_subsys',  sSlPath, ...
                    'tl_subsys',  stModel.astSubsystems(i).sTlPath);
                osc_throw(stErr);
            else
                osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:SL_SUBSYSTEM_NOT_FOUND_RECOVERED', ...
                    'sl_subsys',  sSlPath, ...
                    'tl_subsys',  stModel.astSubsystems(i).sTlPath);
                abIsValid(i) = false;
            end
            abIsValid(i) = false;
            continue;
        end
    end
    stModel.astSubsystems(i).sSlPath      = sSlPath;
    stModel.astSubsystems(i).sModelPathSl = sModelPath;
end
stModel.astSubsystems = i_removeInvalidSubsystems(stEnv, stModel.astSubsystems, abIsValid);

bMatchingValid = false;
nSub = length(stModel.astSubsystems);
for i = 1:nSub
    if ~stModel.astSubsystems(i).bIsDummy
        bMatchingValid = true;
        break;
    end
end

if ~bMatchingValid
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:SL_TL_NO_MATCHING_SUBSYS');
    osc_throw(stErr);
end


% handle DISP vars
for i = 1:numel(stModel.astDispVars)
    for k = 1:numel(stModel.astDispVars(i).astBlockInfo)
        stBlockInfo = stModel.astDispVars(i).astBlockInfo(k);

        % get virtual path
        sSlPath = regexprep(stBlockInfo.sTlPath, sPatternTlRoot, stModel.sSlRoot, 'ignorecase');
        sModelPath = sSlPath;
        if ~isempty(astModelRefMap)
            for j = 1:length(astModelRefMap)
                sVirtualPath = astModelRefMap(j).sVirtualPath;
                nPathLength = length(sVirtualPath);
                if strncmp(sSlPath, sVirtualPath, nPathLength)
                    sModelPath = strrep(sSlPath, sVirtualPath, astModelRefMap(j).sModelPath);
                    break;
                end
            end
        end
        try
            get_param(sModelPath, 'handle');
            stModel.astDispVars(i).astBlockInfo(k).sSlPath = sModelPath;
        catch
            stModel.astDispVars(i).astBlockInfo(k).sSlPath = '';
        end
    end
end
end


%%
% model ref prepath and path are _overlapping_, i.e. the root element in model path has to be deleted before concatenating
%
% Example:  1) Prepath: main_model/top_A/Subsystem/top_A/sub_B/ref_model_C
%           2) Path:    sub_C/sub_D
%      ==>  3) Virtual: main_model/top_A/Subsystem/top_A/sub_B/ref_model_C/sub_D
function sVirtualPath = i_concatModelRefPaths(sModelRefPrepath, sModelPath)
if isempty(sModelRefPrepath)
    sVirtualPath = sModelPath;
else
    % Assumption: Paths start are empty OR they start _AND_ end with a non-separator, e.g. '', 'A', 'A/B', 'A/B/C'
    %
    % Pattern shall find the first separator '/' but _not_ multiple occurrences, e.g. '//', or '////', ...
    iFind = regexp(sModelPath, '[^/][/][^/]', 'once');
    if isempty(iFind)
        sVirtualPath = sModelRefPrepath;
    else
        sVirtualPath = [sModelRefPrepath, sModelPath(iFind+1:end)];
    end
end
end


%%
function astMap = i_getModelRefMap(sModelName, sModelRefPrepath)
if (nargin < 2)
    sModelRefPrepath = '';
end

astMap = repmat(struct( ...
    'sModelPath',   '', ...
    'sVirtualPath', ''), 0, 0);

[casRefModels, casRefPoints] = find_mdlrefs(sModelName, false); %#ok only ref points needed
for i = 1:length(casRefPoints)
    sVirtualPath = i_concatModelRefPaths(sModelRefPrepath, casRefPoints{i});
    sRefModel = get_param(casRefPoints{i}, 'ModelName');
    astMap(end + 1) = struct( ...
        'sModelPath',   sRefModel, ...
        'sVirtualPath', sVirtualPath); %#ok<AGROW>
    astMap = [astMap, i_getModelRefMap(sRefModel, sVirtualPath)]; %#ok<AGROW>
end
end


%%
function astMap = i_sortMap(astMap)
if (length(astMap) < 2)
    return;
end
casPaths = {astMap(:).sVirtualPath};
anLength = zeros(size(casPaths));
for i = 1:length(casPaths)
    anLength(i) = length(casPaths{i});
end

% sort in ascending order
[anDummy, aiSortIdx] = sort(anLength); %#ok only idx needed

% now revert sorted index and apply to map ==> sorted in descending order
astMap = astMap(aiSortIdx(end:-1:1));
end


%%
function stModel = i_addModelParameters(stEnv, stModel)
stModel.astSubsystems = i_addChildHierarchy(stEnv, stModel.astSubsystems);
stModel.astSubsystems = i_addSampleTime(stEnv, stModel.astSubsystems, stModel.sName);

if strcmpi(stModel.sModelMode, 'SL')
    nSub = length(stModel.astSubsystems);
    for i = 1:nSub
        stModel.astSubsystems(i).sId = sprintf('ss%i', i);
        stModel.astSubsystems(i).sDescription = '';

        stModel.astSubsystems(i).hInitFunc     = [];
        stModel.astSubsystems(i).sInitFunc     = '';
        stModel.astSubsystems(i).hPostInitFunc = [];
        stModel.astSubsystems(i).sPostInitFunc = '';

    end
else
    stModel.astSubsystems = i_addInitFunction(stEnv, stModel.astSubsystems, stModel.hTlSubDD);

    nSub = length(stModel.astSubsystems);
    for i = 1:nSub
        stSub = stModel.astSubsystems(i);
        stModel.astSubsystems(i).sId = sprintf('ss%i', i);
        stModel.astSubsystems(i).sDescription = i_getFuncDescription(stEnv, stSub.hFunc);
    end
end
end


%%
function dModelSampleTime = i_getModelSampleTime(sModelName)
dModelSampleTime = -1; % default value for "unknown"

% 1) try to use the explicit model sample time directly
hModel = get_param(sModelName, 'handle');
if (atgcv_version_p_compare('ML8.6') >= 0)
    try
        sCompiledStepSize = get_param(hModel, 'CompiledStepSize');
        if ~isempty(sCompiledStepSize)
            dModelSampleTime = str2double(sCompiledStepSize);
        end
    catch
    end
    if (dModelSampleTime > 0)
        return;
    end
end


sFixedStep = get_param(hModel, 'FixedStep');

% 1. try to convert directly (model sample time given as double value)
dFixedStep = str2double(sFixedStep);
if (isnumeric(dFixedStep) && ~isnan(dFixedStep))
    dModelSampleTime = dFixedStep;
else
    % 2. try to evaluate in Workspace
    % (indirect conversion <-> sample time given as string)

    % if the sample time was specified as a variable,
    % evaluate the variable in the base workspace or
    % in a model workspace
    [val, bSuccess] = osc_mtl_evalinws(sFixedStep, sModelName);
    if bSuccess
        if ischar(val)
            val = str2double(val);  % sprintf('%g',val);
        end
        if (isnumeric(val) && ~isnan(val))
            dModelSampleTime = val;
        end
    end
end
end


%%
% * given CompiledSampleTimes, select the smallest, fininte, positive one
% ( == Minimum Discrete SampleTime)
% * if none is found, return -1 indicating "unknown"
%
function dSampleTime = i_getDiscreteFiniteCompiledSampleTime(cadSampleTime)
dSampleTime = Inf;
for i = 1:length(cadSampleTime)
    adSampleTime = cadSampleTime{i};
    if isnumeric(adSampleTime)
        d = adSampleTime(1);
        if (isfinite(d) && (d > 0))
            dSampleTime = min(dSampleTime, d);
        end
    end

end
if ~isfinite(dSampleTime)
    dSampleTime = -1;  % default for "unknown"
end
end


%%
function astSubsystems = i_addSampleTime(stEnv, astSubsystems, sModelName)
if isempty(astSubsystems)
    return;
end

% global sample time to be used as fallback later
dGlobalSampleTime = -1; % dafault for "unknown"

nSub = length(astSubsystems);
adSubSampleTime = -ones(1, nSub); % default sample time for all subs: -1
for i = 1:nSub
    dSampleTime = -1;

    % get subsystem sample time directly from data dictionary
    if ~isempty(astSubsystems(i).hFunc)
        dSampleTime = atgcv_mxx_dsdd(stEnv, 'GetSampleTime', astSubsystems(i).hFunc);
    end

    if (dSampleTime < 0)
        dSampleTime = i_getDiscreteFiniteCompiledSampleTime(astSubsystems(i).stCompInterface.cadSampleTime);
    end

    if (dSampleTime > 0)
        adSubSampleTime(i) = dSampleTime;

        % set the global SampleTime as SampleTime of TopLevel Sub if found
        if astSubsystems(i).bIsToplevel
            dGlobalSampleTime = dSampleTime;
        end
    end
end

if any(adSubSampleTime < 0)
    % if any of the subsystem sample times is unknown we have to use the
    % some global sample time

    % 1) if the global SampleTime from TopLevel is "unknown", try the
    %    Model Sample Time
    if (dGlobalSampleTime < 0)
        dGlobalSampleTime = i_getModelSampleTime(sModelName);
    end

    % 2) if still unknown, use the smallest of the valid subsystem sample times
    if ((dGlobalSampleTime < 0) && any(adSubSampleTime > 0))
        dGlobalSampleTime = min(adSubSampleTime(adSubSampleTime > 0.0));
    end

    % 3) if still unknown, use the default 1
    if (dGlobalSampleTime < 0)
        dGlobalSampleTime = 1.0; % use 1 as default sample time
    end
end

% now register the subsystem sample times
for i = 1:nSub
    dSampleTime = adSubSampleTime(i);

    % if sample time is inherited (-1), get the sample time
    % from (active!) configuration set
    if (dSampleTime == -1)
        dSampleTime = dGlobalSampleTime;
    end
    astSubsystems(i).dSampleTime = dSampleTime;
end
end


%%
% return related function: sFunctionKind = RestartFunction | InitFunction
function hRelFunc = i_getRelatedFunction(stEnv, hFunc, sFunctionKind)
% first try directly
sPropName = [sFunctionKind, 'Ref'];
hRelatedFunc = atgcv_mxx_dsdd(stEnv, 'Find', hFunc, 'name', 'RelatedFunctions', 'property', {'name', sPropName});
if ~isempty(hRelatedFunc)
    sCmd = ['GetRelatedFunctions', sFunctionKind, 'RefTarget'];
    hRelFunc = atgcv_mxx_dsdd(stEnv, sCmd, hFunc);
else
    hRelFunc = [];
end

% now the heuristic <--> find main version
if isempty(hRelFunc)
    hParent   = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hFunc, 'hDDParent');
    sMainKind = ['Main', sFunctionKind];
    hRelFunc = atgcv_mxx_dsdd(stEnv, 'Find', hParent, ...
        'objectKind', 'Function', ...
        'property', {'name', 'FunctionKind', 'value', sMainKind});
end

% now the second heuristic <--> same kind
if isempty(hRelFunc)
    hRelFunc = atgcv_mxx_dsdd(stEnv, ...
        'Find', hParent, ...
        'objectKind', 'Function',...
        'property', {'name', 'FunctionKind', 'value', sFunctionKind});
end

% Now the 'AUTOSAR heuristic'.
% Since TL3.4 in conjunction with the AUTOSAR mode the related functions are
% stored in the simulation frame. The following heuristic tries to handle this.
if (atgcv_version_compare('TL3.4') >= 0) && isempty(hRelFunc)
    hRelFunc = i_getRelatedFuncFromTaskCallerChain(stEnv, hFunc, sFunctionKind);
end

if (length(hRelFunc) > 1)
    hRelFunc = hRelFunc(1);
end
end


%%
function hRelFunc = i_getRelatedFuncFromTaskCallerChain(stEnv, hFunc, sFunctionKind)
hRelFunc = [];

hCallers = atgcv_mxx_dsdd(stEnv, 'Find', hFunc, 'name', 'Callers', 'property', {'regexp', 'Task_.+'});
if ~isempty(hCallers)
    casProps = atgcv_mxx_dsdd(stEnv, 'GetPropertyNames', hCallers);
    for i = 1:length(casProps)
        sProp = casProps{i};
        if strncmpi(sProp, 'Task_', 5)
            hTaskCallerInstance = atgcv_mxx_dsdd(stEnv, 'Get', hCallers, sProp);
            if ~isempty(hTaskCallerInstance)
                hTaskCaller = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hTaskCallerInstance, 'hDDParent');
                sSearchProp = [sFunctionKind, 'Ref'];
                % Check if related functions are available
                hRelatedFunc = atgcv_mxx_dsdd(stEnv, 'Find', hTaskCaller, ...
                    'name', 'RelatedFunctions', ...
                    'property', {'name', sSearchProp});

                % If related functions are available, extract the corresponding.
                if ~isempty(hRelatedFunc)
                    sCmd = ['GetRelatedFunctions', sFunctionKind, 'RefTarget'];
                    hRelFunc = atgcv_mxx_dsdd(stEnv, sCmd, hTaskCaller);
                end

                % in TL4.1 we have nested Tasks_ functions
                if isempty(hRelFunc)
                    hRelFunc = i_getRelatedFuncFromTaskCallerChain(stEnv, hTaskCaller, sFunctionKind);
                end
            end
        end
    end
end
end


%%
function hStepFunc = i_getAnyStepRootFunction(hTlSubsystem)
hStepFunc = [];

try
    hRootFuncs = dsdd('GetRootFunctions', hTlSubsystem);
    stRoot = dsdd('GetAll', hRootFuncs);
    casCandidates = fieldnames(stRoot);
    for i = 1:length(casCandidates)
        sCand = casCandidates{i};
        hCand = stRoot.(sCand);
        if strcmpi('StepFcn', dsdd('GetFunctionKind', hCand))
            hStepFunc = hCand;
            return;
        end
    end
catch
end
end


%%
function astSubsystems = i_addInitFunction(stEnv, astSubsystems, hTlSubsystem)
iTop = find([astSubsystems(:).bIsToplevel]);
if (length(iTop) ~= 1)
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Could not find any toplevel sub.');
end
if astSubsystems(iTop).bIsEnv
    % if TopLevel is the Frame Subsystem and the TL TopLevel is inside, use the
    % child Susbystem (i.e. the real TL Subsystem)
    % --> Note: sometimes the TL Subsystem is thrown out because it is a
    %     Dummy-Subsystem --> then try to get it by using the children
    aiChildren = astSubsystems(iTop).aiChildIdx;
    if (length(aiChildren) > 1)
        hTopStepFunc  = i_getAnyStepRootFunction(hTlSubsystem);
    else
        hTopStepFunc = astSubsystems(aiChildren).hFunc;
    end
else
    hTopStepFunc = astSubsystems(iTop).hFunc;
end

hTopInitFunc     = i_getRootFunctionFromSub(stEnv, hTlSubsystem, 'RestartFcn');
hTopPostInitFunc = i_getRootFunctionFromSub(stEnv, hTlSubsystem, 'InitFcn');
if ~isempty(hTopStepFunc)
    % if available, prefer the direct info from the topmost function
    % note: not sure if this is a good approach
    hTopInitFuncTry = i_getRelatedFunction(stEnv, hTopStepFunc, 'RestartFunction');
    if ~isempty(hTopInitFuncTry)
        hTopInitFunc = hTopInitFuncTry;
    end
    hTopPostInitFuncTry = i_getRelatedFunction(stEnv, hTopStepFunc, 'InitFunction');
    if ~isempty(hTopPostInitFuncTry)
        hTopPostInitFunc = hTopPostInitFuncTry;
    end
end
if ~isempty(hTopInitFunc)
    sTopInitFunc = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hTopInitFunc, 'name');
else
    sTopInitFunc = '';
end
if ~isempty(hTopPostInitFunc)
    sTopPostInitFunc = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hTopPostInitFunc, 'name');
else
    sTopPostInitFunc = '';
end


nSub = length(astSubsystems);
for i = 1:nSub
    if ~astSubsystems(i).bIsEnv
        astSubsystems(i).hInitFunc = hTopInitFunc;
        astSubsystems(i).sInitFunc = sTopInitFunc;
        astSubsystems(i).hPostInitFunc = hTopPostInitFunc;
        astSubsystems(i).sPostInitFunc = sTopPostInitFunc;
    end
end
end


%%
function hFoundRootFunc = i_getRootFunctionFromSub(stEnv, hTlSubsystem, sKind)
hFoundRootFunc = [];

hRootFuncs = atgcv_mxx_dsdd(stEnv, 'GetRootFunctions', hTlSubsystem);
if isempty(hRootFuncs)
    return;
end

% Note: for now just return the first found RestartFcn
casFuncNames = dsdd('GetPropertyNames', hRootFuncs);
for i = 1:length(casFuncNames)
    hFunc = atgcv_mxx_dsdd(stEnv, 'GetFunctionRefTarget', hTlSubsystem, casFuncNames{i});
    if ~isempty(hFunc)
        sFuncKind = atgcv_mxx_dsdd(stEnv, 'GetFunctionKind', hFunc);
        if strcmpi(sFuncKind, sKind)
            hFoundRootFunc = hFunc;
            break;
        end
    end
end
end


%%
function sDescription = i_getFuncDescription(stEnv, hFunc)
if dsdd('Exist', hFunc, 'property', {'name', 'description'})
    sDescription = atgcv_mxx_dsdd(stEnv, 'GetDescription', hFunc);
else
    sDescription = '';
end
end


%%
function astSubsystems = i_addChildHierarchy(~, astSubsystems)
iTop = find([astSubsystems(:).bIsToplevel]);
if (length(iTop) ~= 1)
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Could not find any toplevel sub.');
end
% tmp set parent index of top from [] to -1 (cannot be found in algo)
iOrig = astSubsystems(iTop).iParentIdx;
astSubsystems(iTop).iParentIdx = -1;
aiParents = [astSubsystems(:).iParentIdx];
astSubsystems(iTop).iParentIdx = iOrig;

nSub = length(astSubsystems);
for i = 1:nSub
    astSubsystems(i).aiChildIdx = find(i == aiParents);
end
end


%%
function astValidSubsystems = i_removeInvalidSubsystems(~, astSubsystems, abIsValid)
nSubs = length(astSubsystems);

% build up parent-child hierarchy, but now only for valid subsystems
% strategy: get to the next highest valid subsystem for new parent
aiValidIdx = find(abIsValid);
for i = 1:nSubs
    if abIsValid(i)
        iParentIdx = astSubsystems(i).iParentIdx;

        % precaution: isempty() for toplevel subsystem
        while ~isempty(iParentIdx) && ~abIsValid(iParentIdx)
            iParentIdx = astSubsystems(iParentIdx).iParentIdx;
        end

        if isempty(iParentIdx)
            astSubsystems(i).iParentIdx = iParentIdx;
        else
            % new index is the index after the removal of all the
            % invalid subsystems
            iNewIdx = find(iParentIdx == aiValidIdx);
            astSubsystems(i).iParentIdx = iNewIdx;
        end
    end
end

% filter out all invalid subsystems
astValidSubsystems = astSubsystems(abIsValid);
end


%%
function bSuccess = i_inDirLoadDD(sDir, sDdFile)
bSuccess = false;
if (isempty(sDir) || ~isdir(sDir))
    return;
end

sPwd = pwd();
try
    cd(sDir);
    iErr = atgcv_dd_open('File', sDdFile);
    bSuccess = (iErr == 0);
catch
    %  could not fully restore user DD
end
cd(sPwd);
end


%%
function i_openDdForModel(~, sTlModel, sDdFile)
if (nargin < 3)
    % if DD was not provided use the Model's own DD
    sDdFile = dsdd_manage_project('GetProjectFile', sTlModel);
end
sCurrentDD = i_getCurrentDD();
if strcmpi(sCurrentDD, sDdFile)
    return;
end

% close current DD to avoid interferences
atgcv_dd_close('Save', false);
if isempty(sDdFile)
    return;
end

% 1) try to load DD from model path
sModelPath = i_getModelPath(sTlModel);
if i_inDirLoadDD(sModelPath, sDdFile)
    return;
end

% 2) try to load user DD from DD path
sDdPath = fileparts(sDdFile);
i_inDirLoadDD(sDdPath, sDdFile);
end


%%
function sModelPath = i_getModelPath(sModelName)
try
    sModelFile = get_param(sModelName, 'FileName');
    sModelPath = fileparts(sModelFile);
catch
    sModelPath = '';
end
end




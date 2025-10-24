function [astSubsystems, hInitFunc] = atgcv_m01_model_hierarchy_get(stEnv, hSubsystem, bAddEnv)
% Function determines the supported function hierarchy of the current model.
%
% function [astSubsystems, hInitFunc] = atgcv_m01_model_hierarchy_get(stEnv, hSubsystem, bAddEnv)
%
%   INPUT           DESCRIPTION
%     stEnv            (struct)   error/result environment
%     hSubsystem       (handle)   handle to current subsystem (DataDictionary->Subsystems->"Subsys")
%     bAddEnv          (handle)   optional: add Enviroment Subsystems(== Parent-Subsystem) (default == false)
%
%   OUTPUT          DESCRIPTION
%     astSubsystems    (array)    structs containing info with following data
%        .sKind          (string)   'subsystem' | 'stateflow'
%        .sTlPath        (string)   TL path to subsystem/chart
%        .hSub           (handle)   subsystem in ModelView
%        .hFunc          (handle)   corresponding function (step func) in C-code
%        .hFuncInstance  (handle)   corresponding instance of function (important for reusable functions)
%        .sStepFunc      (string)   name of step function in C-code
%        .sModuleName    (string)   name of the containing C-file
%        .sStorage       (string)   storage class of the function: global(== default), static, extern
%        .stProxyFunc    (struct)   info about proxy function (== Task function in AUTOSAR context)
%                                   global(== default), static, extern
%        .iParentIdx     (integer)  index of parent subsystem in returned array (empty for toplevel)
%        .bIsToplevel    (bool)     TRUE for toplevel sub, otherwise FALSE
%        .bIsDummy       (bool)     TRUE if the Subsystem is invalid (i.e. not fully supported by EP)
%        .bIsEnv         (bool)     TRUE if the Subsystem belongs to the environment (see bAddEnv option)
%        .hModelRefBlock (handle)   handle of block that references the subsystem (empty if not a referenced model)
%        .sModelPath     (string)   the real path as seen in next higher model
%                                   (for referenced models deviating from the sTlPath, which is a purely virtual path)
%
%     hInitFunc        (handle)   if existing, handle to generated INIT/RESTART function
%

%% input
if (nargin < 3)
    bAddEnv = false;
end
if ischar(hSubsystem)
    hSubsystem = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hSubsystem, 'hDDObject');
end


%% main
astSubsystems = i_findAllSubsystems(stEnv, hSubsystem);
if bAddEnv
    astSubsystems = i_addEnvironment(stEnv, astSubsystems);
end
astSubsystems = i_removeUnsupportedSubsystems(stEnv, hSubsystem, astSubsystems);
for i = 1:length(astSubsystems)
    if (~isempty(astSubsystems(i).hSub) && ~isempty(astSubsystems(i).hFunc))
        astSubsystems(i).stProxyFunc = atgcv_m01_dd_sub_function_get(stEnv, astSubsystems(i).hSub, 'proxy');
    end
end

%% optional outputs
if (nargout > 1)
    if isempty(astSubsystems)
        hInitFunc = [];
    else
        stTop = astSubsystems([astSubsystems(:).bIsToplevel]);
        hInitFunc = i_getGlobalInitFunctionFromFunc(stEnv, stTop.hFunc);
        if isempty(hInitFunc)
            hInitFunc = i_getGlobalInitFunctionFromSub(stEnv, hSubsystem);
        end
    end
end
end


%%
function astSubsystems = i_addEnvironment(stEnv, astSubsystems)
% determine the Parent of the TopLevel and add it to the Hierarchy as new TopLevel
iIdxTopLevel = find([astSubsystems(:).bIsToplevel]);
if isempty(iIdxTopLevel)
    return;
end

sParentTlPath = i_getParentPath(astSubsystems(iIdxTopLevel).sTlPath);
if (isempty(sParentTlPath) || ~i_isSubsystemPathValid(sParentTlPath))
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:TOPLEVEL_PARENT_MISSING', ...
        'subsystem', astSubsystems(iIdxTopLevel).sTlPath);
    osc_throw(stErr);
end
sParentModelPath = i_getParentPath(astSubsystems(iIdxTopLevel).sModelPath);

stNewTop             = i_getInitSubInfo();
stNewTop.sTlPath     = sParentTlPath;
stNewTop.sModelPath  = sParentModelPath;
stNewTop.bIsToplevel = true;
stNewTop.bIsDummy    = true;
stNewTop.bIsEnv      = true;

% Note: _prepend_ the new TopLevel to avoid side-effects in Functions that expect the TopLevel to be in Position 1
% --> this leads to increased index --> adapt this in all references !
astSubsystems = [stNewTop, astSubsystems];
for i = 2:length(astSubsystems)
    if astSubsystems(i).bIsToplevel
        % the old TopLevel is not a TopLevel anymore
        astSubsystems(i).bIsToplevel = false;
        % the new TopLevel at Position 1 is the Parent of former TopLevel
        astSubsystems(i).iParentIdx = 1;
    else
        % increasing index of all Parent references
        astSubsystems(i).iParentIdx = astSubsystems(i).iParentIdx + 1;
    end
end
end


%%
function bIsValid = i_isSubsystemPathValid(sSubPath)
bIsValid = false;
try
    sType = get_param(sSubPath, 'BlockType');
    bIsValid = strcmpi(sType, 'SubSystem');
catch
end
end


%%
% returns the ParentPath of provided Path
% Example: A/B/C --> A/B
%
% Special: If the provided Path ends with .../x/Subsystem/x, return the Parent of the Parent of the Parent.
% Example: A/B/C/Subsystem/C --> A/B
%
function sParentPath = i_getParentPath(sPath)
% note: using "fileparts" is risky because there could be "/" inside the Name
% TODO: use another algo here!
[p, sSubName] = fileparts(sPath);
if isempty(p)
    sParentPath = '';
    return;
end

sMatchSub = regexptranslate('escape', sSubName);
sParentPath = regexprep(sPath, ['(/', sMatchSub, '/Subsystem)?/', sMatchSub, '$'], '');
end


%%
function astSubsystems = i_findAllSubsystems(stEnv, hTopSubsystem)
hModelRefBlock   = [];
sModelRefPrepath = '';
astSubsystems = i_findAllSubsystemsRecur(stEnv, hTopSubsystem, hModelRefBlock, sModelRefPrepath, false);

% get parents of subsystems/charts (model view)
nAll   = length(astSubsystems);
ahSubs = [astSubsystems(:).hSub];
for i = 1:nAll
    % default is that the parent sub is the next highest node in the DD Tree
    hParent = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astSubsystems(i).hSub, 'hDDParent');
    if (hParent == hTopSubsystem)
        % for the TopLevel we do not need to look for parents
        astSubsystems(i).bIsToplevel = true;
        continue;
    end
    
    aiParentIdx = find(hParent == ahSubs);
    if (isempty(aiParentIdx) && ~isempty(astSubsystems(i).hModelRefBlock))
        % maybe the subsystems are disconnected in DD Tree because of ModelReferences
        %   --> try out the next highest node of the model ref block
        hParent = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astSubsystems(i).hModelRefBlock, 'hDDParent');
        aiParentIdx = find(hParent == ahSubs);
    end    
    if (numel(aiParentIdx) > 1)
        % for referenced subsystems (incremental/reference-model) we can have the same sub for multiple instances
        % --> try to find the correct subsystem by comparing the virtual model paths
        sChildPath = astSubsystems(i).sTlPath;
        casCandidateParentPaths = {astSubsystems(aiParentIdx).sTlPath};
        for k = 1:numel(casCandidateParentPaths)
            if i_startsWith(sChildPath, [casCandidateParentPaths{k}, '/'])
                aiParentIdx = aiParentIdx(k);
                break;
            end
        end
    end
    astSubsystems(i).iParentIdx = aiParentIdx;
end
end


%%
function astSubsystems = i_findAllSubsystemsRecur(stEnv, hSubsystem, hModelRefBlock, sModelRefPrepath, bIsRefInactive)
astSubsystems = [ ...
    i_findSubsystemsInModel(stEnv, hSubsystem, hModelRefBlock, sModelRefPrepath, bIsRefInactive), ...
    i_findSfChartsInModel(stEnv, hSubsystem, hModelRefBlock, sModelRefPrepath, bIsRefInactive)];
end


%%
function stSub = i_getInitSubInfo(hModelRefBlock, sKind)
if (nargin < 1)
    hModelRefBlock = [];
end
if (nargin < 2)
    sKind = 'subsystem';
end
stSub = struct( ...
    'sKind',          sKind, ...
    'sTlPath',        '', ...
    'hSub',           [], ...
    'hFunc',          [], ...
    'hFuncInstance',  [], ...
    'sStepFunc',      '', ...
    'sModuleName',    '', ...
    'sModuleType',    '', ...
    'sStorage',       '', ...
    'stProxyFunc',    [], ...
    'iParentIdx',     [], ...
    'bIsToplevel',    false, ...
    'bIsDummy',       false, ...
    'bIsEnv',         false, ...
    'hModelRefBlock', hModelRefBlock, ...
    'sModelPath',     '');
end


%%
function astSubsystems = i_findSubsystemsInModel(stEnv, hTlSubsystem, hModelRefBlock, sModelRefPrepath, bIsRefInactive)
% root subsystem in model
hModelView = atgcv_mxx_dsdd(stEnv, 'Find', hTlSubsystem, ...
    'name',       'ModelView', ...
    'objectKind', 'BlockGroup');

% all subsystems that have a GroupInfo node are candidates for the hierarchy
ahGroupInfos = atgcv_mxx_dsdd(stEnv, 'Find', hModelView, ...
    'name',     'GroupInfo', ...
    'property', {'name', 'IsAtomic'});
nSubs = numel(ahGroupInfos);

sRootPath = dsdd_get_block_path(hTlSubsystem);
if bIsRefInactive
    sRealRootPath = dsdd_get_block_path(hModelRefBlock);
else
    sRealRootPath = sRootPath;
end

% get info for subsystems
bIsSubtreeMapped = true;

astSubsystems = repmat(i_getInitSubInfo(hModelRefBlock, 'subsystem'), 1, nSubs);
for i = 1:nSubs
    hInfo = ahGroupInfos(i);
    
    hSub = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hInfo, 'hDDParent');
    astSubsystems(i).hSub = hSub;
    if strcmp(sRealRootPath, sRootPath)
        astSubsystems(i).sModelPath = dsdd_get_block_path(hSub);
    else
        astSubsystems(i).sModelPath = i_replacePrefix(dsdd_get_block_path(hSub), sRootPath, sRealRootPath);
    end
    astSubsystems(i).sTlPath = i_concatModelRefPaths(sModelRefPrepath, astSubsystems(i).sModelPath);
    
    bIsToplevel = (hModelView == hSub);
    if (bIsRefInactive && bIsToplevel)
        stFunc = atgcv_m01_dd_sub_function_get(stEnv, hModelRefBlock, 'step');
    else
        stFunc = [];
    end
    if isempty(stFunc)
        stFunc = atgcv_m01_dd_sub_function_get(stEnv, hSub, 'step');
    end
    if ~isempty(stFunc.hFuncInstance)
        astSubsystems(i).hFunc         = stFunc.hFunc;
        astSubsystems(i).hFuncInstance = stFunc.hFuncInstance;
        astSubsystems(i).sStepFunc     = stFunc.sName;
        astSubsystems(i).sModuleName   = stFunc.sModuleName;
        astSubsystems(i).sModuleType   = stFunc.sModuleType;
        astSubsystems(i).sStorage      = stFunc.sStorage;
        
        if bIsToplevel && ~stFunc.bIsMapped
            bIsSubtreeMapped = false;
        end
    end
end

if ~bIsSubtreeMapped
    for k = 1:numel(astSubsystems)
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_REUSE_MAPPING_INCOMPLETE', ...
            'subsystem', astSubsystems(k).sTlPath);
    end
    astSubsystems(:) = [];
    return;
end

% special handling for incrementally built functions
astSubsystems = i_tryReroutingInfoForIncremental(stEnv, astSubsystems);

% handle model references recursively
ahModelRefs = atgcv_mxx_dsdd(stEnv, 'Find', hModelView, ...
    'objectKind', 'Block', ...
    'property',   {'name', 'BlockType', 'value', 'ModelReference'});
for i = 1:length(ahModelRefs)
    hModelRef = ahModelRefs(i);
    
    hSubsys = atgcv_mxx_dsdd(stEnv, 'GetModelReferenceSubsystemRefTarget', hModelRef);
    
    sModelPath = dsdd_get_block_path(hModelRef);
    sModelRefPrepathLocal = i_concatModelRefPaths(sModelRefPrepath, sModelPath);
    
    astSubsystems = [astSubsystems, ...
        i_findAllSubsystemsRecur(stEnv, hSubsys, hModelRef, sModelRefPrepathLocal, false)]; %#ok<AGROW>
end

% special treatment for "dereferenced" ModelReferences (or subsystems marked for incremental build)
ahInactiveRefs = atgcv_mxx_dsdd(stEnv, 'Find', hModelView, ...
    'objectKind', 'Block', ...
    'property',   {'name', 'BlockType', 'value', 'Subsystem'});
for i = 1:length(ahInactiveRefs)
    hInactiveRef = ahInactiveRefs(i);
    
    sInactiveRefSub = atgcv_mxx_dsdd(stEnv, 'GetSubsystemSubsystemRefTarget', hInactiveRef);
    sInactiveRefSub = atgcv_mxx_dsdd(stEnv, 'GetAttribute', sInactiveRefSub, 'name');
    
    sInactiveRefSubPath = ['/Subsystems/', sInactiveRefSub];
    [bSubExists, hSubsys] = dsdd('Exist', sInactiveRefSubPath);
    if bSubExists
        if ~isempty(hSubsys)
            astSubsystems = [astSubsystems, ...
                i_findAllSubsystemsRecur(stEnv, hSubsys, hInactiveRef, sModelRefPrepath, true)]; %#ok<AGROW>
        end
    end
end
end


%%
% SPECIAL handling for Incremental Functions (see BTS/34573):
% -- Incremental Functions have an own Subsystem node inside the DD where
% there is more detailed Info about the Subsystem and all the Children
%
% ==> try to re-route the info to these special Subsystem nodes
%
function astSubsystems = i_tryReroutingInfoForIncremental(stEnv, astSubsystems)
% 1) try to identify the Incremental Subsystems
nSubs = length(astSubsystems);
abIsIncremental = false(1, nSubs);
for i = 1:nSubs
    if strcmpi(astSubsystems(i).sModuleType, 'ImportedFile')
        abIsIncremental(i) = true;
    end
end

% 2) separate the Incremental Subsystems from the rest
astIncrSubs = astSubsystems(abIsIncremental);
astSubsystems(abIsIncremental) = [];

% 3) try to re-route the Info
for i = 1:length(astIncrSubs)
    sIncrSubName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astIncrSubs(i).hSub, 'name');
    sIncrSubPath = ['/Subsystems/', sIncrSubName];
    [bSubExists, hSubsys] = dsdd('Exist', sIncrSubPath);
    if (bSubExists && ~isempty(hSubsys))
        % re-routing was successful --> replace original info with new one
        % take also the Children into account (i.e. recursive search)
        astSubsystems = [astSubsystems, i_findAllSubsystemsRecur(stEnv, hSubsys, astIncrSubs(i).hSub, false)]; %#ok<AGROW>
    else
        % re-routing was not successful --> use the existing Info
        astSubsystems = [astSubsystems, astIncrSubs(i)]; %#ok<AGROW>
    end
end
end


%%
% model ref prepath and path are _overlapping_, i.e. the root element in
% model path has to be deleted before concatenating
%
% Example:  1) Prepath: main_model/top_A/Subsystem/top_A/sub_B/ref_model_C
%           2) Path:    sub_C/sub_D
%      ==>  3) Virtual:
%                  main_model/top_A/Subsystem/top_A/sub_B/ref_model_C/sub_D
function sVirtualPath = i_concatModelRefPaths(sModelRefPrepath, sModelPath)
if isempty(sModelRefPrepath)
    sVirtualPath = sModelPath;
else
    % Assumption: Paths start are empty OR they start _AND_ end with a
    % non-separator, e.g. '', 'A', 'A/B', 'A/B/C'
    %
    % Pattern shall find the first separator '/' but _not_ multiple
    % occurrences, e.g. '//', or '////', ...
    iFind = regexp(sModelPath, '[^/][/][^/]', 'once');
    if isempty(iFind)
        sVirtualPath = sModelRefPrepath;
    else
        sVirtualPath = [sModelRefPrepath, sModelPath(iFind+1:end)];
    end
end
end


%%
function astCharts = i_findSfChartsInModel(stEnv, hTlSubsystem, hModelRefBlock, sModelRefPrepath, bIsRefInactive)
% root subsystem in DD
hModelView = atgcv_mxx_dsdd(stEnv, 'Find', hTlSubsystem, ...
    'name',       'ModelView', ...
    'objectKind', 'BlockGroup');

% all charts that have a step_function instance
ahSfNodes = atgcv_mxx_dsdd(stEnv, 'Find', hModelView, ...
    'name',     'StateflowNodes', ...
    'property', {'name', 'StepFunctionInstanceRef'});
nCharts = length(ahSfNodes);
abSelect = true(size(ahSfNodes));
for i = 1:nCharts
    abSelect(i) = ~isempty(atgcv_mxx_dsdd(stEnv, 'GetStepFunctionInstanceRef', ahSfNodes(i)));
end
ahSfNodes = ahSfNodes(abSelect);
nCharts = length(ahSfNodes);

% default output
astCharts = repmat(i_getInitSubInfo(hModelRefBlock, 'stateflow'), 1, nCharts);

% shortcut if no charts found
if (nCharts < 1)
    return;
end

sRootPath = dsdd_get_block_path(hTlSubsystem);
if bIsRefInactive
    sRealRootPath = dsdd_get_block_path(hModelRefBlock);
else
    sRealRootPath = sRootPath;
end

% get info for stateflow charts
for i = 1:nCharts
    hSfNode = ahSfNodes(i);
    
    hChart = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hSfNode, 'hDDParent');
    hSfNodes = atgcv_mxx_dsdd(stEnv, 'GetStateflowNodes', hChart);
    astCharts(i).hSub = hChart;
    
    if strcmp(sRealRootPath, sRootPath)
        astCharts(i).sModelPath = dsdd_get_block_path(hChart);
    else
        astCharts(i).sModelPath = i_replacePrefix(dsdd_get_block_path(hChart), sRootPath, sRealRootPath);
    end
    astCharts(i).sTlPath = i_concatModelRefPaths(sModelRefPrepath, astCharts(i).sModelPath);
    
    hFuncInstance = atgcv_mxx_dsdd(stEnv, 'GetStepFunctionInstanceRef', hSfNodes);
    hFunc = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hFuncInstance, 'hDDParent');
    astCharts(i).hFunc         = hFunc;
    astCharts(i).hFuncInstance = hFuncInstance;
    astCharts(i).sStepFunc     = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hFunc, 'name');
    
    [sModName, sModType] = ep_dd_function_module_get(hFunc);
    astCharts(i).sModuleName = sModName;
    astCharts(i).sModuleType = sModType;
    
    astCharts(i).sStorage = i_getStorageType(stEnv, hFunc);
end
end


%%
function sString = i_replacePrefix(sString, sPrefix, sNewPrefix)
sPattern = ['^', regexptranslate('escape', sPrefix)];
sString = regexprep(sString, sPattern, sNewPrefix);
end


%%
function bStartsWithPrefix = i_startsWith(sString, sPrefixCandidate)
sPattern = ['^', regexptranslate('escape', sPrefixCandidate)];
bStartsWithPrefix = ~isempty(regexp(sString, sPattern, 'once'));
end


%%
function astValidSubsystems = i_removeUnsupportedSubsystems(stEnv, hDdSubsys, astSubsystems)
abIsValid = i_checkValidity(stEnv, hDdSubsys, astSubsystems);

% if the toplevel is invalid, we have to use a different strategy
iIdxTopLevel     = find([astSubsystems(:).bIsToplevel]);
bIsTopLevelValid = abIsValid(iIdxTopLevel);
if ~bIsTopLevelValid
    % reset the validity of the toplevel --> TopLevel is now a DummySubsystem
    abIsValid(iIdxTopLevel) = true;
    astSubsystems(iIdxTopLevel).bIsDummy = true;
    
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:TOPLEVEL_INVALID_DUMMY', 'subsystem', astSubsystems(iIdxTopLevel).sTlPath);
end

% remove all invalid subsystems but keep hiearchy info intact
astValidSubsystems = atgcv_m01_hierarchy_reduce(astSubsystems, abIsValid);
end


%%
function abIsValid = i_checkValidity(stEnv, hDdSubsys, astSubsystems)
abIsValid     = true(size(astSubsystems));
abIsTriggered = false(size(astSubsystems));
if isempty(astSubsystems)
    return;
end

% Determine the Index of all Subsystems that need to be checked in For-Loops.
% Skip checking Subsystems that are already marked as Dummy because they are
% valid per se. Just check all _other_ Subsystems.
aiSubsIdx = find(~[astSubsystems(:).bIsDummy]);

% CHECK: Check for toplevel sub OR exactly one parent 
% --> get rid of "dangling" subsystems without parent or subsystems with too many parents (by wrong analysis)
for i = aiSubsIdx
    if ~abIsValid(i)
        continue;
    end
    
    abIsValid(i) = astSubsystems(i).bIsToplevel || (numel(astSubsystems(i).iParentIdx) == 1);
end

astSlFuncs = repmat(struct( ...
    'hBlock',          [], ...
    'sModelPath',      '', ...
    'astCallerBlocks', []), 1, 0);

% CHECK: Subsystem has a StepFunction.
for i = aiSubsIdx
    if ~abIsValid(i)
        continue;
    end
    
    if isempty(astSubsystems(i).hFunc)
        abIsValid(i) = false;
        if astSubsystems(i).bIsToplevel
            % give an extra Warning for TopLevel Subsystem
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:TOPLEVEL_NO_FUNC', 'subsystem', astSubsystems(i).sModelPath);
        else
            % ELSE check for SL function:
            % use heuristics: if we have a Subsystem without FunctionReference
            % but with a FunctionBlock inside the Subsystem --> EXTERN_FUNC            
            [bIsSlFunc, astCallerBlocks] = i_isSimulinkFunction(stEnv, astSubsystems(i));
            if bIsSlFunc
                astSlFuncs(end + 1) = struct( ...
                    'hBlock',          astSubsystems(i).hSub, ...
                    'sModelPath',      astSubsystems(i).sModelPath, ...
                    'astCallerBlocks', astCallerBlocks); %#ok<AGROW>
                osc_messenger_add(stEnv, ...
                    'ATGCV:MOD_ANA:SUBSYSTEM_UNSUPPORTED_SL_FUNC', 'subsystem', astSubsystems(i).sTlPath);
                continue;
            end
            
            % ... and check for EXTERN_FUNC:
            % use heuristics: if we have a Subsystem without FunctionReference
            % but with a FunctionBlock inside the Subsystem --> EXTERN_FUNC
            sSubPath = astSubsystems(i).sModelPath;
            bIsExternFunc = false;
            try
                casFuncBlocks = ep_find_system(sSubPath, ...
                    'SearchDepth', 1, ...
                    'BlockType',   'SubSystem', ...
                    'MaskType',    'TL_Function');
                bIsExternFunc = ~isempty(casFuncBlocks);
            catch
            end
            if bIsExternFunc
                osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_EXTERN_FUNC', 'function',  sSubPath);
                continue;
            end
            
            % ... other checks for the future
            
        end
    end
end

% CHECK: Subsystem's StepFunction has a valid module/function class.
for i = aiSubsIdx
    if abIsValid(i)
        abIsValid(i) = i_isModuleTypeValid(stEnv, astSubsystems(i));
    end
    if abIsValid(i)
        abIsValid(i) = i_isFuncClassValid(stEnv, astSubsystems(i));
    end
    if abIsValid(i)
        abIsValid(i) = i_isSelfContainedForSlFuncCallers(astSubsystems(i), astSlFuncs);
        if ~abIsValid(i)
            osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SUBSYSTEM_INCOMPLETE_SL_FUNC', 'subsystem', astSubsystems(i).sTlPath);
        end
    end
    
    abIsTriggered(i) = i_isTriggeredSubsys(astSubsystems(i).sModelPath);
    if (abIsValid(i) && abIsTriggered(i))
        if strcmpi(astSubsystems(i).sKind, 'stateflow')
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_INPUT_EVENTS_CHART', 'chart', astSubsystems(i).sTlPath);
            abIsValid(i) = false;
        end
    end
end
casTriggeredSubs = {astSubsystems(abIsTriggered).sTlPath};

% CHECK: Subsystem is not routing any function call trigger systems through its input or output interface.
for i = aiSubsIdx
    if abIsValid(i)
        abIsValid(i) = ~i_isProvidingFunctionCallSubsystem(stEnv, astSubsystems(i));
        if ~abIsValid(i)
            osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:LIMITATION_PROVIDING_FUNCTION_CALL_SUB', 'subsystem', astSubsystems(i).sTlPath);
        end
    end
end

% CHECK: Subsystem's outputs are not merge-optimized (BTS/12219).
ahValidCandidateSubs = [astSubsystems(abIsValid).hSub];
ahMergeOptSubs = i_getMergeOptSubs(stEnv, hDdSubsys, casTriggeredSubs, ahValidCandidateSubs);
if ~isempty(ahMergeOptSubs)
    for i = aiSubsIdx
        if abIsValid(i)
            abIsValid(i) = ~any(astSubsystems(i).hSub == ahMergeOptSubs);
            if ~abIsValid(i)
                osc_messenger_add(stEnv, ...
                    'ATGCV:MOD_ANA:RESTRICTION_MERGE_OPT_OUTPORT', 'subsystem', astSubsystems(i).sTlPath);
            end
        end
    end
end
end


%%
function bIsSelfContained = i_isSelfContainedForSlFuncCallers(stSubsystem, astSlFuncs)
bIsSelfContained = true;

sSubsysPath = stSubsystem.sModelPath;
for i = 1:numel(astSlFuncs)
    stSlFunc = astSlFuncs(i);
    
    % note: if the subsystem does not contain any caller of this SL-Function, it is trivially self-contained
    casCallerBlocks = {stSlFunc.astCallerBlocks(:).sModelPath};
    bContainsAtLeastOneCaller = any(cellfun(@(s) i_subsystemContainsBlock(sSubsysPath, s), casCallerBlocks));
    if bContainsAtLeastOneCaller
        bIsSelfContained = i_subsystemContainsBlock(sSubsysPath, stSlFunc.sModelPath);
        if ~bIsSelfContained
            break;
        end
    end    
end
end


%%
% TODO: reduce complexity of this function!
%
% providing means:
% a) for Subsystems: function_call events are coming through InPorts or/and
%    OutPorts
% b) for Charts: trigger events are coming from the outports of Chart
function bIsProviding = i_isProvidingFunctionCallSubsystem(stEnv, stSubsystem)
bIsProviding = false;
if strcmpi(stSubsystem.sKind, 'stateflow')
    ahBlockVars = atgcv_mxx_dsdd(stEnv, 'Find', stSubsystem.hSub, ...
        'objectKind', 'BlockVariable', 'property', 'FunctionCall');
    bIsProviding = ~isempty(ahBlockVars);
else
    hGroupInfo = atgcv_mxx_dsdd(stEnv, 'GetGroupInfo', stSubsystem.hSub);
    [bExist, hPorts] = dsdd('Exist', 'Ports', 'parent', hGroupInfo);
    if (bExist && ~isempty(hPorts))
        if ~isempty(hPorts)
            % first try directly
            ahFuncCallPorts = atgcv_mxx_dsdd(stEnv, 'Find', hPorts, ...
                'objectKind', 'Port', ...
                'property', {'name', 'Kind', 'value', 'FcnCallPort'});
            for i = 1:length(ahFuncCallPorts)
                % now check how these function-call signals enter the subsystem
                % a) normal TriggerPort --> not providing
                % b) Inport/Outport     --> providing
                hBlock = atgcv_mxx_dsdd(stEnv, 'GetBlockRef', ahFuncCallPorts(i));
                if ~isempty(hBlock)
                    sType = atgcv_mxx_dsdd(stEnv, 'GetBlockType', hBlock);
                    bIsProviding = any(strcmpi(sType, {'TL_Inport', 'TL_Outport'}));
                end
                if bIsProviding
                    return;
                end
            end
            
            % now try internal Ports (without TL annotation)
            ahPorts = atgcv_mxx_dsdd(stEnv, 'Find', hPorts, ...
                'objectKind', 'Port', ...
                'property', {'name', 'BlockRef'});
            for i = 1:length(ahPorts)
                hBlock = atgcv_mxx_dsdd(stEnv, 'GetBlockRef', ahPorts(i));
                if ~isempty(hBlock)
                    ahSourceSigs = atgcv_mxx_dsdd(stEnv, 'Find', hBlock, ...
                        'objectKind', 'BlockVariable', ...
                        'property', {'name', 'FunctionCall'});
                    if ~isempty(ahSourceSigs)
                        sType = atgcv_mxx_dsdd(stEnv, 'GetBlockType', hBlock);
                        bIsProviding = any(strcmpi(sType, {'TL_Inport', 'TL_Outport'}));
                        if bIsProviding
                            return;
                        end
                    end
                end
            end
        end
    end
end
end


%%
function bIsValid = i_isModuleTypeValid(stEnv, stSubsystem)
bIsValid = true;

% do accept StubFiles if we have a GeneratedFile with the same name, otherwise don't
% --> during the build process the StubFile gets replaced with the original file
if (strcmpi(stSubsystem.sModuleType, 'StubFile') && ~i_hasGenModule(stEnv, stSubsystem))
    bIsValid = false;
end

% do not accept any SimulationFrameFile
if strcmpi(stSubsystem.sModuleType, 'SimulationFrameFile')
    bIsValid = false;
end

if ~bIsValid
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:STUB_CODE_FUNCTION', 'subsystem',  stSubsystem.sTlPath);
end
end


%%
function bHasGenModule = i_hasGenModule(stEnv, stSubsystem)
ahFileInfos = atgcv_mxx_dsdd(stEnv, ...
    'Find',       '/Subsystems', ...
    'ObjectKind', 'FileInfo', ...
    'Property',   {'name', 'FileName', 'value', stSubsystem.sModuleName}, ...
    'Property',   {'name', 'FileType', 'value', 'GeneratedFile'});
bHasGenModule = ~isempty(ahFileInfos);
end


%%
function [bIsSlFunc, astCallerBlocks] = i_isSimulinkFunction(stEnv, stSubsystem)
bIsSlFunc = false;
astCallerBlocks = [];
if atgcv_verLessThan('TL5.1')
    return;
end

bIsSlFunc = atgcv_mxx_dsdd(stEnv, 'GetGroupInfoIsSimulinkFunctionSystem', stSubsystem.hSub);
if bIsSlFunc
    hTriggerBlock = atgcv_mxx_dsdd(stEnv, 'GetGroupInfoTriggerBlockRef', stSubsystem.hSub);
    if ~isempty(hTriggerBlock)
        hSlFunctionPort = atgcv_mxx_dsdd(stEnv, 'GetSimulinkFunctionPort', hTriggerBlock);
        if ~isempty(hSlFunctionPort)
            aiIdx = atgcv_mxx_dsdd(stEnv, 'GetAutoRenamePropertyIndices', hSlFunctionPort, 'CallerBlockRef');
            ahCallerBlocks = ...
                arrayfun(@(iIdx) atgcv_mxx_dsdd(stEnv, 'GetCallerBlockRefTarget', hTriggerBlock, iIdx), aiIdx);
            astCallerBlocks = arrayfun(@i_getInfoCallerBlock, ahCallerBlocks);
        end
    end
end
end


%%
function stCallerBlock = i_getInfoCallerBlock(hCallerBlock)
stCallerBlock = struct( ...
    'hBlock',     hCallerBlock, ...
    'sModelPath', dsdd_get_block_path(hCallerBlock));
end


%%
function bIsValid = i_isFuncClassValid(stEnv, stSubsystem)
bIsValid = false;

% reject helper functions
sKind = atgcv_mxx_dsdd(stEnv, 'GetFunctionKind', stSubsystem.hFunc);
if strcmpi(sKind, 'AuxFcn')
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_HIERARCHY_FCN_AUX', 'function', stSubsystem.sTlPath);
    return;
end

% reject implicitly inlined functions (do not mention it in messenger)
sFuncPath = dsdd_get_block_path(stSubsystem.hFuncInstance);
if (~strcmpi(sFuncPath, stSubsystem.sModelPath) && ~strcmpi(sFuncPath, dsdd_get_block_path(stSubsystem.hSub)))
    % AH: for "normal" subsystems we cannot issue a warning here because
    %     DocBlocks/ModelInfo also have BlockType "subsystem"
    %
    %     osc_messenger_add(stEnv,...
    %         'ATGCV:MOD_ANA:LIMITATION_HIERARCHY_FCN_INLINED', ...
    %         'function',  stSubsystem.sTlPath);
    
    % AH: however, for SF-chart we can produce a meaningful warning
    if strcmpi(stSubsystem.sKind, 'stateflow')
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_HIERARCHY_SF_INLINED', 'sf_chart', stSubsystem.sTlPath);
    end
    return;
end

% reject explicitly inlined functions
bIsInlined = atgcv_mxx_dsdd(stEnv, 'GetInlinedCode', stSubsystem.hFunc);
if bIsInlined
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_HIERARCHY_FCN_INLINED', 'function', stSubsystem.sTlPath);
    return;
end

% reject function classes: static SFEntry and SFExit
hClass = atgcv_mxx_dsdd(stEnv, 'GetFunctionClassTarget', stSubsystem.hFunc);
if ischar(hClass)
    sClass = hClass;
else
    sClass = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hClass, 'Name');
end
if any(strcmpi(sClass, {'StaticSFEntry', 'StaticSFExit'}))
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_HIERARCHY_FCN_SFENTRY_SFEXIT', 'function', stSubsystem.sTlPath);
    return;
end

% reject extern functions
if strcmpi(stSubsystem.sStorage, 'extern')
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_EXTERN_FUNC', 'function', stSubsystem.sTlPath);
    return;
end

% -------------------------------------------
% if we are here, function class is valid
bIsValid = true;
end


%%
function hInitFunc = i_getGlobalInitFunctionFromSub(stEnv, hSubsystem)
hInitFunc = [];

hRootFuncs = atgcv_mxx_dsdd(stEnv, 'GetRootFunctions', hSubsystem);
if isempty(hRootFuncs)
    return;
end

% Note: for now just return the first found RestartFcn
casFuncNames = dsdd('GetPropertyNames', hRootFuncs);
for i = 1:length(casFuncNames)
    hFunc = atgcv_mxx_dsdd(stEnv, 'GetFunctionRefTarget', hSubsystem, casFuncNames{i});
    if ~isempty(hFunc)
        sFuncKind = atgcv_mxx_dsdd(stEnv, 'GetFunctionKind', hFunc);
        if strcmpi(sFuncKind, 'RestartFcn')
            hInitFunc = hFunc;
        end
    end
end
end


%%
function hInitFunc = i_getGlobalInitFunctionFromFunc(stEnv, hFunc)
hInitFunc = [];

% no init function for empty functions
if isempty(hFunc)
    return;
end

% try directly
hRelatedFunc = atgcv_mxx_dsdd(stEnv, 'Find', hFunc, ...
    'name',     'RelatedFunctions', ...
    'property', {'name', 'RestartFunctionRef'});
if ~isempty(hRelatedFunc)
    hInitFunc = atgcv_mxx_dsdd(stEnv, 'GetRelatedFunctionsRestartFunctionRefTarget', hFunc);
end

% try heuristic
if isempty(hInitFunc)
    hParent   = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hFunc, 'hDDParent');
    hInitFunc = atgcv_mxx_dsdd(stEnv, 'Find', hParent, ...
        'objectKind', 'Function', ...
        'property', {'name', 'FunctionKind', 'value', 'MainRestartFcn'});
end

% try second heuristic
if isempty(hInitFunc)
    hInitFunc = atgcv_mxx_dsdd(stEnv, ...
        'Find', hParent, ...
        'objectKind', 'Function',...
        'property', {'name', 'FunctionKind', 'value', 'RestartFcn'});
end

if (length(hInitFunc) > 1)
    hInitFunc = hInitFunc(1);
end
end


%%
function hBlock = i_getBlock(stEnv, hObj)
hBlock = [];
while ~isempty(hObj)
    if strcmpi(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'objectKind'), ...
            'Block')
        hBlock = hObj;
        return;
    end
    hObj = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'hDDParent');
end
end


%%
function hSub = i_getSubsystem(stEnv, hObj)
hSub = [];
while ~isempty(hObj)
    if strcmpi(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'objectKind'), ...
            'BlockGroup')
        sModelPath = dsdd_get_block_path(hObj);
        if strcmpi(get_param(sModelPath, 'BlockType'), 'SubSystem')
            hSub = hObj;
            return;
        end
    end
    hObj = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hObj, 'hDDParent');
end
end


%%
function ahMergeOptSubs = i_getMergeOptSubs(stEnv, hDdSubsys, casTriggeredSubs, ahCandidateSubs)
ahMergeOptSubs = [];

if isempty(casTriggeredSubs)
    return;
end

[bExist, hModelView] = dsdd('Exist', 'ModelView', 'parent', hDdSubsys);
if ~bExist
    return;
end

% get all subsystems that are connected to merge blocks sharing the same C-variable for inport, outport, and merge block
ahMergeBlocks = atgcv_mxx_dsdd(stEnv, 'Find', hModelView, 'property', {'name', 'BlockType', 'value', 'TL_Merge'});
for i = 1:length(ahMergeBlocks)
    ahSubs = i_findMergeConnectedSubs(stEnv, ahMergeBlocks(i), ahCandidateSubs);
    if ~isempty(ahSubs)
        ahMergeOptSubs = [ahMergeOptSubs, ahSubs]; %#ok<AGROW>
    end
end
if isempty(ahMergeOptSubs)
    return;
end

ahMergeOptSubs = unique(ahMergeOptSubs);

% select only the subsystems that have triggered child subsystems
nSubs = length(ahMergeOptSubs);
nTrigSubs = length(casTriggeredSubs);
abHasTriggeredSub = false(1, nSubs);
for i = 1:length(ahMergeOptSubs)
    sPattern = ['^', regexptranslate('escape', dsdd_get_block_path(ahMergeOptSubs(i))), '/'];
    for j = 1:nTrigSubs
        if ~isempty(regexp(casTriggeredSubs{j}, sPattern, 'once'))
            abHasTriggeredSub(i) = true;
            break; % break triggered subs loop with counter j
        end
    end
end
ahMergeOptSubs = ahMergeOptSubs(abHasTriggeredSub);
end


%%
function ahSubs = i_findMergeConnectedSubs(stEnv, hMergeBlock, ahCandidateSubs)
ahSubs = [];

astSigs = atgcv_m01_block_output_signals_get(stEnv, hMergeBlock, [], false);
if isempty(astSigs)
    return;
end

ahMergeVars = [astSigs(:).hVariableRef];
if isempty(ahMergeVars)
    return;
end

ahSubs = i_getSameVarConnectedSubs(stEnv, hMergeBlock, ahMergeVars, ahCandidateSubs);
end


%%
% get all subsystems whose outports are connected to the provided block and are using the same variable
% NOTE: filter for the subsystems mentioned inside the CandidateSubs to avoid useless analysis
function ahSubs = i_getSameVarConnectedSubs(stEnv, hBlock, ahUsedVars, ahCandidateSubs)
ahSubs = [];

ahSource = atgcv_mxx_dsdd(stEnv, 'Find', hBlock, ...
    'RegExp',   'SourceSignal(\(#\d+\))?', ...
    'Property', {'Name', 'BlockVariableRef'});
if isempty(ahSource)
    return;
end

for i = 1:length(ahSource)
    if atgcv_verLessThan('TL3.5')
        hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', ahSource(i));
    else
        hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', ahSource(i), 0);
    end
    if isempty(hSrcBlockVar)
        continue;
    end
    
    hSrcBlock = i_getBlock(stEnv, hSrcBlockVar);
    sBlockType = atgcv_mxx_dsdd(stEnv, 'GetBlockType', hSrcBlock);
    if ~any(strcmpi(sBlockType, {'TL_Outport', 'Stateflow'}))
        continue;
    end
    
    % check if variable is used in merge block
    if dsdd('Exist', hSrcBlockVar, 'property', {'name', 'VariableRef'})
        hVar = atgcv_mxx_dsdd(stEnv, 'GetVariableRef', hSrcBlockVar);
    else
        % try AUTOSAR approach
        astSrcSigs = atgcv_m01_block_output_signals_get(stEnv, hSrcBlock, [], false);
        if (length(astSrcSigs) == 1)
            hVar = astSrcSigs.hVariableRef;
        else
            hVar = [];
        end
    end
    if (isempty(hVar) || ~any(hVar == ahUsedVars))
        continue;
    end
    
    if strcmpi(sBlockType, 'Stateflow')
        if (any(hSrcBlock == ahCandidateSubs) && i_isChartInput(stEnv, hSrcBlock, hVar))
            ahSubs = [ahSubs, hSrcBlock]; %#ok<AGROW>
        end
    else
        hSub = i_getSubsystem(stEnv, hSrcBlock);
        if (any(hSub == ahCandidateSubs) && i_isSubsystemInput(stEnv, hSub, hVar))
            ahSubs = [ahSubs, hSub]; %#ok<AGROW>
        end
    end
end
ahSubs = unique(ahSubs);
end


%%
function bIsInput = i_isChartInput(stEnv, hChart, hVar) %#ok currently fake
bIsInput = false;
end


%%
function bIsInput = i_isSubsystemInput(stEnv, hSub, hVar)
bIsInput = false;
hPorts = atgcv_mxx_dsdd(stEnv, 'GetGroupInfoPorts', hSub);
ahPortRefs = atgcv_mxx_dsdd(stEnv, 'GetChildren', hPorts);
for i = 1:length(ahPortRefs)
    sKind = atgcv_mxx_dsdd(stEnv, 'GetKind', ahPortRefs(i));
    if ~strcmpi(sKind, 'Inport')
        continue;
    end
    hBlock = atgcv_mxx_dsdd(stEnv, 'GetBlockRef', ahPortRefs(i));
    astSigs = atgcv_m01_block_output_signals_get(stEnv, hBlock);
    ahVarRefs = [astSigs(:).hVariableRef];
    if isempty(ahVarRefs)
        continue;
    end
    
    if any(hVar == ahVarRefs)
        bIsInput = true;
        return;
    end
end
end


%%
function bIsTriggered = i_isTriggeredSubsys(sModelPath)
sParent = get_param(sModelPath, 'Parent');
if isempty(sParent)
    % sModelPath is a root-level subsystem (e.g. referenced model)
    bIsTriggered = i_isTriggeredRootLevelSubsystem(sModelPath);
else
    stPortHandles = get_param(sModelPath, 'PortHandles');
    bIsTriggered = ...
        ~isempty(stPortHandles.Enable) || ...
        ~isempty(stPortHandles.Trigger) || ...
        ~isempty(stPortHandles.Ifaction);
end
end


%%
function bIsTriggered = i_isTriggeredRootLevelSubsystem(sModelPath)
bIsTriggered = false;

% Current Limitation (ML <= 2009b): The only Trigger-like blocks allowed in the
% root level are TriggerPorts with the kind set to "Function-Call".
casTriggerPorts = ep_find_system(sModelPath, 'SearchDepth', 1, 'BlockType', 'TriggerPort');
if ~isempty(casTriggerPorts)
    bIsTriggered = true;
end
end


%%
function sStorage = i_getStorageType(stEnv, hFunc)
sStorage = 'global';

hFuncClass = atgcv_mxx_dsdd(stEnv, 'GetFunctionClass', hFunc);
if ~isempty(hFuncClass)
    sStorage = atgcv_mxx_dsdd(stEnv, 'GetStorage', hFuncClass);
end
if (isempty(sStorage) || strcmpi(sStorage, 'default'))
    sStorage = 'global';
end
end


%%
function bContainsBlock = i_subsystemContainsBlock(sSubsysPath, sBlockPath)
bContainsBlock = strcmp(sSubsysPath, sBlockPath) || i_isPrefixPath(sSubsysPath, sBlockPath);
end


%%
function bIsPrefix = i_isPrefixPath(sPrefixPath, sPath)
sMatcher = ['^', regexptranslate('escape', [sPrefixPath, '/'])];
bIsPrefix = ~isempty(regexp(sPath, sMatcher, 'once'));
end

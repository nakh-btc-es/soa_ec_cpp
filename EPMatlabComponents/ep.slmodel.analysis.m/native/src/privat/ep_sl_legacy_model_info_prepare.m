function stModel = ep_sl_legacy_model_info_prepare(stEnv, stOpt)
% Analysis of a Simulink model.
%
% function stModel = ep_sl_legacy_model_info_prepare(stEnv, stOpt)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)    messenger environment
%     stOpt               (struct)    options
%       .sModel           (string)      model name
%       .hParamSearchFunc (handle)      search algorithm for parameters ...
%       .sCalMode         (string)      CalibrationMode: <'explicit'> | 'none'
%       .sDispMode        (string)      DispMode: <'all'> | 'none'
%       .sDsmMode         (string)      DataStoreMode: <'all'> |  'none'
%       .sAddModelInfo    (string)      path to the XML file containing additional model information
%
%   OUTPUT              DESCRIPTION
%     stModel             (struct)    model info data
%


%% check inputs
if (nargin < 1)
    stEnv = 0;
end
stOpt = i_checkSetOpt(stEnv, stOpt);

%% main
stModel = struct(...
    'sName',            stOpt.sModel, ...
    'sModelFile',       get_param(stOpt.sModel, 'FileName'), ...
    'sTopLevel',        i_getTopLevel(stEnv, stOpt.sModel, stOpt.stAddInfo, stOpt.sToplevel), ...
    'astSubsystems',    [],...
    'astParams',        [], ...
    'astLocals',        [], ...
    'astDsms',          []);

if stOpt.stAddInfo.bIsSubsysWhiteListActive && numel(stOpt.stAddInfo.astSubsystems) > 1
    bUseRoot = any(strcmp(stOpt.stAddInfo.sTopLevelSubsystem, {stOpt.stAddInfo.astSubsystems(:).modelPath}));
else
    bUseRoot = false;
end
stModel.astSubsystems = atgcv_m01_model_subsystems_get(stEnv,...
    struct('sModelContext', stModel.sTopLevel, 'bUseRoot', bUseRoot));
if stOpt.stAddInfo.bIsSubsysWhiteListActive
    % keep info about all Subsystems  --> needed for remapping the ModelRef Subsystems to virtual paths
    stModel.astAllSubsystems = stModel.astSubsystems;
    [stModel.astSubsystems, casMissing] = ...
        i_selectSubsOnWhitelist(stModel.astSubsystems, {stOpt.stAddInfo.astSubsystems.modelPath});
    for i = 1:length(casMissing)
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_FOUND_SIMULINK_SUBSYSTEM', ...
            'subsystem',    casMissing{i}, ...
            'addModelInfo', stOpt.sAddModelInfo);
    end
end
if strcmpi(stOpt.sDispMode, 'all')
    if (stOpt.stAddInfo.bIsValid && stOpt.stAddInfo.bIsLocalWhiteListActive)
        if ~isempty(stOpt.stAddInfo.astLocals)
            stModel.astLocals = i_filterOutInvalidUserLocals(stEnv, stOpt.stAddInfo.astLocals);
            
            if isfield(stModel, 'astAllSubsystems')
                astSubs = stModel.astAllSubsystems;
            else
                astSubs = stModel.astSubsystems;
            end
            stModel.astLocals = i_adaptVirtualPathInLocals(stModel.astLocals, astSubs);
        end
    else
        stModel.astLocals = atgcv_m01_model_locals_get(stEnv, struct('sModelContext', stModel.sTopLevel));
    end
end
stModel = i_getCompiledInfo(stEnv, stModel);

% !important to get CAL and DSM Info _after_ "compile"
% --> then able to use "cached" Search-mode for finding Model Parameters and DataStores
if ~isempty(stOpt.hParamSearchFunc)
    stSearchArgs = struct( ...
        'sModelContext', stModel.sTopLevel);    
    if (stOpt.stAddInfo.bIsValid && stOpt.stAddInfo.bIsParamWhiteListActive)
        if isempty(stOpt.stAddInfo.astParams)
            stSearchArgs.casWhiteListParams = {};
        else
            stSearchArgs.casWhiteListParams = {stOpt.stAddInfo.astParams.name};
        end
    end
    stModel.astParams = feval(stOpt.hParamSearchFunc, stSearchArgs);
end
if strcmpi(stOpt.sDsmMode, 'all')
    stModel.astDsms = i_getDsms(stEnv, stModel.sTopLevel);
end
end


%%
function astParams = i_getLegacyParamSearchFunc(stEnv, stArgs)
if isfield(stArgs, 'casWhiteListParams')
    % note: interpret an empty white list of parameters as "Do not retrieve any parameters!" --> skip param search
    if isempty(stArgs.casWhiteListParams)
        astParams = [];
    else
        astParams = i_getParams(stEnv, stArgs.sModelContext, stArgs.casWhiteListParams);
    end
else
    astParams = i_getParams(stEnv, stArgs.sModelContext);
end
end


%%
function astDsms = i_getDsms(stEnv, sModelContext)
stOpt = struct( ...
    'sModelContext', sModelContext, ...
    'SearchMethod',  'cached');
astDsms = atgcv_m01_model_datastores_get(stEnv, stOpt);
end


%%
function [astSubsystems, casMissing] = i_selectSubsOnWhitelist(astSubsystems, casUserPaths)
abFound = false(size(casUserPaths));
abDoSelect = false(size(astSubsystems));

for i = 1:numel(astSubsystems)
    sPath = astSubsystems(i).sPath;
    abEq = strcmpi(sPath, casUserPaths);
    if any(abEq)
        abDoSelect(i) = true;
        abFound = abFound | abEq;
    else
        sPath = astSubsystems(i).sVirtualPath; % toplevel Referenced Model
        abEq = strcmpi(sPath, casUserPaths);
        if any(abEq)
            abDoSelect(i) = true;
            abFound = abFound | abEq;
        end
    end
end
casMissing = casUserPaths(~abFound);
astSubsystems = ep_sl_subsystems_filter(astSubsystems, abDoSelect);
end


%%
function astLocals = i_filterOutInvalidUserLocals(stEnv, astUserLocals)
astLocals = i_transformUserDataToLocals(astUserLocals);
if isempty(astLocals)
    return;
end
abInvalid = cellfun('isempty', {astLocals(:).sPath});
astLocals(abInvalid) = [];

astInvalid = astUserLocals(abInvalid);
for i = 1:length(astInvalid)
    sPath = astInvalid(i).modelPath;
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_FOUND_LOCAL_DISPLAY', 'path', sPath);
end
end


%%
function astLocals = i_adaptVirtualPathInLocals(astLocals, astSubs)
astMap = i_getModelRefMap(astSubs);
if isempty(astMap)
    return;
end

casVirtualPaths = i_remapPathsToVirtualPaths({astLocals.sPath}, astMap);
for i = 1:length(astLocals)
    astLocals(i).sVirtualPath = casVirtualPaths{i};
end
end


%%
function astLocals = i_splitPortsIntoIndividualLocals(stLocal)
astLocals = repmat(stLocal, 1, length(stLocal.aiPorts));
for i = 1:length(stLocal.aiPorts)
    astLocals(i).aiPorts = stLocal.aiPorts(i);
end
end


%%
function astLocals = i_transformUserDataToLocals(astUserLocals)
if isempty(astUserLocals)
    astLocals = [];
    return;
end
astLocals = i_transformUserDataToLocal(astUserLocals(1));
for i = 2:length(astUserLocals)
    astLocals = [astLocals, i_transformUserDataToLocal(astUserLocals(i))]; %#ok<AGROW>
end
end


%%
function stLocal = i_transformUserDataToLocal(stUserLocal)
sName  = '';
sClass = '';
sPath  = stUserLocal.modelPath;
try
    sName = get_param(sPath, 'Name');
    sClass = class(get_param(sPath, 'Object'));
catch %#ok<CTCH>
    sPath = ''; % indicator for invalid Path
end

stLocal = struct( ...
    'sName',        sName, ...
    'sClass',       sClass, ...
    'sPath',        sPath, ...
    'sVirtualPath', sPath, ...
    'sSubPath',     '', ...
    'aiPorts',      stUserLocal.aiPorts);

if (~isempty(sPath) && atgcv_sl_block_isa(sPath, 'Stateflow'))
    stLocal = i_splitPortsIntoIndividualLocals(stLocal);
end
end


%%
function astParams = i_getParams(stEnv, sModelContext, casWhiteListParams)
stOpt = struct( ...
    'sModelContext', sModelContext, ...
    'SearchMethod',  'cached');

bWithUserWhiteList = (nargin > 2);
if bWithUserWhiteList
    stOpt.casParamNames = casWhiteListParams;
end
[astParams, casMissing] = atgcv_m01_model_params_get(stEnv, stOpt);

if bWithUserWhiteList
    for i = 1:length(casMissing)
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_FOUND_SIMULINK_PARAMETER', 'parameter', casMissing{i});
    end
end
end


%%
function stModel = i_getCompiledInfo(stEnv, stModel)
nSub = length(stModel.astSubsystems);
if (nSub > 0)
    casSubPaths = {stModel.astSubsystems.sPath};
else
    casSubPaths = {};
end
nLoc = length(stModel.astLocals);
if (nLoc > 0)
    casLocPaths = {stModel.astLocals.sPath};
else
    casLocPaths = {};
end

sModelRootPath = '';
if ~isempty(stModel.sModelFile)
    sModelRootPath = fileparts(stModel.sModelFile);
end
[astSubCompInfo, astLocCompInfo] = i_getCompiledInfoSubAndLoc(stEnv, casSubPaths, casLocPaths, sModelRootPath);

if ~isempty(astSubCompInfo)
    abIsValid = [astSubCompInfo(:).bIsInfoComplete];
    
    for i = 1:nSub
        if abIsValid(i)
            sSubPath = stModel.astSubsystems(i).sPath;
            if i_checkCompInterface(stEnv, astSubCompInfo(i), sSubPath)
                stModel.astSubsystems(i).stCompInfo = astSubCompInfo(i);
            else
                stModel.astSubsystems(i).stCompInfo = astSubCompInfo(i);
                abIsValid(i) = false;
            end
        end
    end
    if any(~abIsValid)
        iTop = find(cellfun('isempty', {stModel.astSubsystems(:).iParentID}));
        if ~abIsValid(iTop)
            if (sum(abIsValid) > 0)
                stModel.astSubsystems(iTop).bIsDummy = true;
                abIsValid(iTop) = true;
            else
                stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:TOPLEVEL_INVALID_NOT_RECOVERED', ...
                    'subsystem', stModel.astSubsystems(iTop).sPath);
                osc_throw(stErr);
            end
        end
        stModel.astSubsystems = ep_sl_subsystems_filter(stModel.astSubsystems, abIsValid);
    end
end

if ~isempty(astLocCompInfo)
    abIsValid = [astLocCompInfo(:).bIsInfoComplete];
    
    for i = 1:nLoc
        if abIsValid(i)
            stModel.astLocals(i).stCompInfo = astLocCompInfo(i);
        end
    end
    if any(~abIsValid)
        stModel.astLocals(~abIsValid) = []; % remove all invalid Locals
    end
    
    nLocals = numel(stModel.astLocals);
    abIsValid = true(size(stModel.astLocals));
    for i = 1:nLocals
        stLocal = stModel.astLocals(i);
        abIsValid(i) = i_checkIfLocalValid(stEnv, stLocal);
    end
    if any(~abIsValid)
        stModel.astLocals(~abIsValid) = []; % remove all invalid Locals
    end
end
end


%%
function bIsValid = i_checkIfLocalValid(stEnv, stLocal)
bIsValid = false;

% check first the SF locals
if isempty(stLocal.aiPorts)    
    sSfLocal = [stLocal.sSfRelPath, '/', stLocal.sName];
    for i = 1:numel(stLocal.stCompInfo.astLocals)
        stSfLocal = stLocal.stCompInfo.astLocals(i);
        sSfLocalCandidate = [stSfLocal.sSfRelPath, '/', stSfLocal.sSfName];
        if strcmp(sSfLocal, sSfLocalCandidate)
            bIsTypeValid = true;
            
            bIsBusValid = i_checkBusForBlockOutputsAndOutputPorts(stSfLocal);
            if bIsBusValid
                astSigs = stSfLocal.oSig.getLegacySignalInfos();
                bIsTypeValid = i_checkForSupportedTypes(astSigs);
            end
        
            if ~bIsBusValid
                osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_ARRAY_OF_BUSES_DISP', 'block_path', ...
                    [stLocal.stCompInfo.sPath, '/', sSfLocalCandidate]);
            end
            if ~bIsTypeValid
                osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_SUPPORTED_LOCAL_DISPLAY', 'path', ...
                    [stLocal.stCompInfo.sPath, '/', sSfLocalCandidate]);
            end
            
            bIsValid = bIsBusValid && bIsTypeValid;
            break;
        end
    end
    return;
end

for i = 1:numel(stLocal.aiPorts)
    bIsTypeValid = true;
    if ~isempty(stLocal.stCompInfo.astOutports)
        bIsBusValid = i_checkBusForBlockOutputsAndOutputPorts(stLocal.stCompInfo.astOutports(i));
        if bIsBusValid
            astSigs = stLocal.stCompInfo.astOutports(i).oSig.getLegacySignalInfos();
            bIsTypeValid = i_checkForSupportedTypes(astSigs);
        end
        
    else
        bIsBusValid = i_checkBusForBlockOutputsAndOutputPorts(stLocal.stCompInfo.astInports(i));
        if bIsBusValid
            astSigs = stLocal.stCompInfo.astInports(i).oSig.getLegacySignalInfos();
            bIsTypeValid = i_checkForSupportedTypes(astSigs);
        end
    end
    
    if ~bIsBusValid
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_ARRAY_OF_BUSES_DISP', 'block_path', stLocal.stCompInfo.sPath);
    end
    
    if ~bIsTypeValid
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_SUPPORTED_LOCAL_DISPLAY', 'path', stLocal.stCompInfo.sPath);
    end
    
    bIsValid = bIsBusValid && bIsTypeValid;    
end
end


%%
function bIsValid = i_checkForSupportedTypes(astSignals)
bIsValid = true;

oTypes = ep_sl.Types.getInstance();
for i = 1:length(astSignals)
    bIsValid = oTypes.isSupported(astSignals(i).sType);
    if ~bIsValid
        break;
    end
end
end


%%
function bIsValid = i_checkBusForBlockOutputsAndOutputPorts(stPort)
bIsValid = ~stPort.oSig.containsArrayOfBuses();
end


%%
function [astSubCompInfo, astLocCompInfo] = i_getCompiledInfoSubAndLoc(stEnv, casSubPaths, casLocPaths, sModelRootPath)
astSubCompInfo = [];
astLocCompInfo = [];

if (isempty(casSubPaths) && isempty(casLocPaths))
    return;
end

% get info for Subsystems and Blocks in one go
astCompInfo = ep_sl_compiled_info_get( ...
    'Environment',     stEnv, ...
    'InnerViewBlocks', casSubPaths, ...
    'OuterViewBlocks', casLocPaths, ...
    'ModelDir',        sModelRootPath);

% now split the info according to Type
nSub = length(casSubPaths);
if (nSub > 0)
    astSubCompInfo = astCompInfo(1:nSub);
end
nLoc = length(casLocPaths);
if (nLoc > 0)
    astLocCompInfo = astCompInfo(nSub + 1:end);
end
end


%%
function bIsValid = i_checkCompInterface(stEnv, stCompInterface, sSubPath)
stCheck = ep_sl_compiled_interface_check(stCompInterface);

bIsValid = ...
    isempty(stCheck.astInvalidPorts) ...
    && isempty(stCheck.astUnsupportedPorts) ...
    && isempty(stCheck.astHighDimPorts) ...
    && isempty(stCheck.astVarSize) ...
    && isempty(stCheck.astInvalidMessages);

if bIsValid
    return;
end

if ~isempty(stCheck.astInvalidPorts) || ~isempty(stCheck.astUnsupportedPorts)
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_UNSUPPORTED_TYPE_INTERFACE', 'subsystem', sSubPath);
end
if ~isempty(stCheck.astHighDimPorts)
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_MATRIX_SIGNAL', 'subsystem', sSubPath);
end
if ~isempty(stCheck.astVarSize)
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_VARIABLE_SIZE', 'subsystem', sSubPath);
end
if ~isempty(stCheck.astInvalidMessages)
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_VIRTUAL_BUS_MESSAGE_INTERFACE', 'subsystem', sSubPath);
end
end


%%
function stOpt = i_checkSetOpt(stEnv, stOpt)
try
    stOpt.sModel = bdroot(stOpt.sModel);
    stOpt.hModel = get_param(stOpt.sModel, 'handle');
catch %#ok<CTCH>
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:INVALID_SIMULINK_MODEL', 'modelName', stOpt.sModel);
    osc_throw(stErr);
end
stOpt.sToplevel = '';
stOpt.stAddInfo = i_readAdditionalModelInfo(stEnv, stOpt.sAddModelInfo);
if ~isfield(stOpt, 'hParamSearchFunc')
    if strcmpi(stOpt.sCalMode, 'explicit')
        stOpt.hParamSearchFunc = @(stArgs) i_getLegacyParamSearchFunc(stEnv, stArgs);
    else
        stOpt.hParamSearchFunc = [];
    end
end
end


%%
% This function extracts the additional model information concerning the given Simulink model.
% The extracted information is stored in the stAddInfo stucture.
function stAddInfo = i_readAdditionalModelInfo(stEnv, sAddModelInfo)
stAddInfo = struct( ...
    'bIsValid',                 false, ...    % check if valid info was even provided
    'sTopLevelSubsystem',       '', ...       % path to the top level subsystem
    'bIsSubsysWhiteListActive', false, ...    % Default is false.
    'bIsParamWhiteListActive',  false, ...    % Default is false.
    'bIsLocalWhiteListActive',  false, ...    % Default is false.
    'astSubsystems',            [], ...       % list of specified subsystems
    'astParams',                [], ...       % list of specified parameters
    'astLocals',                []);          % list of specified locals

% If no file is specified, the default settings will be returned.
if isempty(sAddModelInfo)
    return;
end

try
    hMaDoc = mxx_xmltree('load', sAddModelInfo);
catch %#ok<CTCH>
    stErr = osc_messenger_add(stEnv, 'ATGCV:STD:OPEN_FILE_FAILED', 'filename', sAddModelInfo);
    osc_throw(stErr);
end
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hMaDoc));

% OK, XML could be loaded
stAddInfo.bIsValid = true;

hSubsystems = mxx_xmltree('get_nodes', hMaDoc, '/AdditionalModelInformation/Subsystems');
if ~isempty(hSubsystems)
    
    % determine top level information, if possible
    ahTopLevels = mxx_xmltree('get_nodes', hSubsystems, './Subsystem[@isTopLevel="true"]');
    nTopLevel = length(ahTopLevels);
    if (nTopLevel == 1)
        stAddInfo.sTopLevelSubsystem = mxx_xmltree('get_attribute', ahTopLevels(1), 'modelPath');
    elseif (nTopLevel > 1)
        stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:MULTIPLE_TOP_LEVEL_SELECTION', 'addModelInfo', sAddModelInfo);
        osc_throw(stErr);
    end
    
    % determine if white list should be used
    stAddInfo.bIsSubsysWhiteListActive = i_isUseAsWhiteList(hSubsystems);
    
    % determine subsystem information
    stAddInfo.astSubsystems = mxx_xmltree('get_attributes', hSubsystems, './Subsystem', 'modelPath');
end

% Note: if the toplevel subsystem is inside a referenced model, we will use this model as the new main model
%       --> then all the exptected sub-paths need to be adapted
casSubPaths = atgcv_m01_virtual_path_resolve(stAddInfo.sTopLevelSubsystem);
if (length(casSubPaths) > 1)
    nSkippedReferenceLevels = length(casSubPaths) - 1;
    stAddInfo.sTopLevelSubsystem = casSubPaths{end};
    stAddInfo.astSubsystems = ...
        arrayfun(@(stSub) i_skipVirtualLevels(stSub, nSkippedReferenceLevels), stAddInfo.astSubsystems);
end

hParameters = mxx_xmltree('get_nodes', hMaDoc, '/AdditionalModelInformation/Parameters');
if ~isempty(hParameters)
    % always usage "whitelist" if node Parameters is provided
    stAddInfo.bIsParamWhiteListActive = true;
    
    % determine parameter information
    stAddInfo.astParams = mxx_xmltree('get_attributes', hParameters, './GlobalParameter', 'name');
end

% determine local information
hLocals = mxx_xmltree('get_nodes', hMaDoc, '/AdditionalModelInformation/Locals');
if ~isempty(hLocals)
    % always usage "whitelist" if node Locals is provided
    stAddInfo.bIsLocalWhiteListActive = true;
    
    ahLocals = mxx_xmltree('get_nodes', hLocals, './Local');
    stAddInfo.astLocals = repmat(struct( ...
        'modelPath', '', ...
        'aiPorts',   {{}}), 1, length(ahLocals));
    
    for i = 1:length(ahLocals)
        hLocal = ahLocals(i);
        
        stAddInfo.astLocals(i).modelPath = mxx_xmltree('get_attribute', hLocal, 'modelPath');
        
        astPorts = mxx_xmltree('get_attributes', hLocal, './Port', 'number');
        if ~isempty(astPorts)
            stAddInfo.astLocals(i).aiPorts = cellfun(@i_readInt, {astPorts(:).number});
        end
    end
end
end


%%
function stSub = i_skipVirtualLevels(stSub, nSkippedReferenceLevels)
casSubPaths = atgcv_m01_virtual_path_resolve(stSub.modelPath);
if (numel(casSubPaths) > nSkippedReferenceLevels)
    stSub.modelPath = i_rejoinVirtualPath(casSubPaths{nSkippedReferenceLevels + 1:end});
end
end


%%
function sVirtualPath = i_rejoinVirtualPath(varargin)
casPathParts = varargin;
sVirtualPath = casPathParts{1};
for i = 2:numel(casPathParts)
    sVirtualPath = [sVirtualPath, regexprep(casPathParts{i}, '^[^/]+', '')]; %#ok<AGROW>
end
end


%%
function bIsUseAsWhiteList = i_isUseAsWhiteList(hListNode)
bIsUseAsWhiteList = false; % default usage is NOT as white-list

% determine if white list should be used
sUsage = mxx_xmltree('get_attribute', hListNode, 'usage');
if ~isempty(sUsage) && strcmp(sUsage, 'whitelist')
    bIsUseAsWhiteList = true;
end
end


%%
function iInt = i_readInt(sString)
iInt = sscanf(sString, '%d');
end


%%
function sTopLevel = i_findTopLevel(xModelContext)
sTopLevel = get_param(bdroot(xModelContext), 'Name');
end


%%
function sTopLevel = i_getTopLevel(stEnv, sModel, stAddInfo, sExplicitToplevel)
if ~isempty(stAddInfo.sTopLevelSubsystem)
    sTopLevel = stAddInfo.sTopLevelSubsystem;
    try
        get_param(sTopLevel, 'handle');
    catch %#ok<CTCH>
        stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:INVALID_SIMULINK_TOP_LEVEL', 'topLevel', sTopLevel);
        osc_throw(stErr);
    end
elseif ~isempty(sExplicitToplevel)
    sTopLevel = sExplicitToplevel;
else
    sTopLevel = i_findTopLevel(sModel);
end
if isempty(sTopLevel)
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:UNDEFINED_TOP_LEVEL_SELECTION');
    osc_throw(stErr);
end
end


%%
% Note: this function needs to be adapted if there are multiple model references
%       to the _same_ model inside the main model!!
% ==> in this case the real model path maps to multiple virtual paths!
function casVirtualPaths = i_remapPathsToVirtualPaths(casPaths, astMap)
casVirtualPaths = casPaths;

casSourcePaths = {astMap(:).sSourcePath};
if isempty(casSourcePaths)
    return;
end

% Patterns for RegExp: try to match at beginning of path and include as last character a separator '/'
casPatterns = cell(size(casSourcePaths));
for k = 1:length(casPatterns)
    casPatterns{k} = ['^', regexptranslate('escape', casSourcePaths{k}), '/'];
end

for i = 1:length(casPaths)
    sPath = casPaths{i};
    ciFound = regexp(sPath, casPatterns, 'end', 'once');
    
    % get the index of the first non-empty match
    iIdx = find(~cellfun(@isempty, ciFound), 1);
    
    % if we have a match, replace the source path with the target path
    if ~isempty(iIdx)
        sTargetPath = astMap(iIdx).sTargetPath;
        
        % RegExp yielded location of the separator '/' after the source path
        iFirstCharAfterSource = ciFound{iIdx};
        
        % now do the mapping from source to target path:
        % cut away source path and prepend with target path
        casVirtualPaths{i} = [sTargetPath, sPath(iFirstCharAfterSource:end)];
    end
end
end


%%
function astMap = i_getModelRefMap(astSubsystems)
astMap = struct( ...
    'sSourcePath', {astSubsystems(:).sPath}, ...
    'sTargetPath', {astSubsystems(:).sVirtualPath});

% sort the map lexicographically on ModelPath (== SourcePath)
% needed for sorting out paths that have other paths as prefix
[~, aiSortIdx] = sort({astMap(:).sSourcePath});
astMap = astMap(aiSortIdx);

sPreviousPath = '';
abSelect = false(size(astMap));
for i = 1:length(astSubsystems)
    % the only relevant case for map: source deviates from target path
    if ~strcmp(astMap(i).sSourcePath, astMap(i).sTargetPath)
        
        % do not consider a path that has the previously selected path as prefix
        if (isempty(sPreviousPath) || ~strncmp(astMap(i).sSourcePath, sPreviousPath, length(sPreviousPath)))
            abSelect(i) = true;
            sPreviousPath = astMap(i).sSourcePath;
        end
    end
end
astMap = astMap(abSelect);
end

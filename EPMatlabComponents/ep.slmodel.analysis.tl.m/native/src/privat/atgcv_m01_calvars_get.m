function astVars = atgcv_m01_calvars_get(stEnv, hSubsys, sMode)
% get all LimitedBlockset/ExplicitParameters CAL objects in provided subsystem
%
% function astVars = atgcv_m01_calvars_get(stEnv, hSubsys, sMode)
%
%   INPUT           DESCRIPTION
%     stEnv             (struct)       environment structure
%     hSubsys           (handle)       DD handle to a current subsystem (DD->Subsystems->"TopLevelName")
%     sMode             (string)       what kind of CAL vars should be returned:
%                                      'limited': LimitedBlockset vars
%                                      'explicit': ExplicitParams
%
%   OUTPUT          DESCRIPTION
%     astVars            (array)      array of struct with following data
%       .hVar              (handle)      DD variable of CAL var
%       .stInfo            (struct)      resulting info_struct from "atgcv_m01_variable_info_get"
%       .astBlockInfo      (array)       resulting info_struct from "atgcv_m01_variable_block_info_get"
%       .stCal             (struct)      additional CAL info
%         .sKind             (string)      'limited' | 'explicit'
%         .sType             (string)      type of ML variable (default: double)
%         .sWorkspaceVar     (string)      name of variable in workspace (if any)
%         .sPoolVarPath      (string)      path to pool var in DD (if any)
%


%%
if (nargin < 3)
    sMode = 'explicit';
end

%% main
bAcceptMismatch = i_doAcceptMismatch();
astVars = i_getAllVars(stEnv, hSubsys);
if isempty(astVars)
    return;
end

astVars = i_addVariableInfoAndMergeSameVars(stEnv, astVars);
astVars = i_filterOutArtificialBlockRefs(stEnv, astVars);
astVars = i_removeUnsupportedVars(stEnv, astVars, sMode, bAcceptMismatch);
if strcmpi(sMode, 'explicit')
    astVars = i_addUniqueName(astVars);
end
end


%%
function astVars = i_addUniqueName(astVars)
% first try to use the short-form version of unique name
bUseShortForm = true;
casShortNames = arrayfun( ...
    @(stVar) i_getUniqueCalName(stVar.stCal, [stVar.stInfo.sRootName, stVar.stInfo.sAccessPath], bUseShortForm), ...
    astVars, ...
    'UniformOutput', false);

% not check if the short-form name is unique; and if not, use the long-form name
xIsUniqueMap = i_getUniquenessAsMap(casShortNames);
for i = 1:numel(astVars)
    sShortName = casShortNames{i};
    
    if xIsUniqueMap(sShortName)
        astVars(i).stCal.sUniqueName = sShortName;
    else
        % use the long version of CAL name, which is guarenteed to be unique (but less readable for users)
        astVars(i).stCal.sUniqueName = ...
            i_getUniqueCalName(astVars(i).stCal, [astVars(i).stInfo.sRootName, astVars(i).stInfo.sAccessPath], false);
    end
end
end


%%
function xIsUniqueMap = i_getUniquenessAsMap(casStrings)
xIsUniqueMap = containers.Map;
for i = 1:numel(casStrings)
    sString = casStrings{i};
    
    xIsUniqueMap(sString) = ~xIsUniqueMap.isKey(sString); % string is unique if it is not contained in map already
end
end


%%
function sName = i_getUniqueCalName(stCal, sCodeVarName, bUseShortForm)
if ~isempty(stCal.sWorkspaceVar)
    % for Parameters WorkspaceVar is shown with highest Prio
    sName = stCal.sWorkspaceVar;
else
    % if there is no WorkspaceVar, the Parameter is shown with
    %    1)DD-VarName
    % or
    %    2)C-VarName
    sDdPath = stCal.sPoolVarPath;
    if isempty(sDdPath)
        sName = sCodeVarName;
    else
        % translate the "Components" levels in DD-path to dot-notation of variable-names
        sName = regexprep(sDdPath, '/Components/', '.');
        if bUseShortForm
            % get rid of DD-Prefix including all VariableGroups //DD0/Pool/Variables/<VariableGroup1>/...
            % <==> everything before and including the last slash
            sName = regexprep(sName, '.*/', '');
        else
            % just get rid of toplevel DD-Prefix //DD0/Pool/Variables/
            sName = regexprep(sName, '.*/Pool/Variables/', '');
        end
    end
end
end


%%
function stVarInfo = i_getInitVarInfo()
stCal = struct( ...
    'sWorkspaceVar',  '', ...
    'sPoolVarPath',   '', ...
    'sNameTemplate',  '', ...
    'sUniqueName',    '', ...
    'sKind',          '', ...
    'sType',          '', ...
    'sClass',         '', ...
    'xValue',         [], ...
    'sMin',           '', ...
    'sMax',           '', ...
    'aiWidth',        []);
stVarInfo = struct( ...
    'hVar',           [], ...
    'stInfo',         [], ...
    'astBlockInfo',   [], ...
    'stCal',          stCal);
end


%%
function astVars = i_filterOutArtificialBlockRefs(~, astVars)
abIsValid = true(size(astVars));
for i = 1:length(astVars)
    astVars(i).astBlockInfo = astVars(i).astBlockInfo(arrayfun(@i_isValidCalLocation, astVars(i).astBlockInfo));
    abIsValid(i) = ~isempty(astVars(i).astBlockInfo);
end
astVars = astVars(abIsValid);
end


%%
% Heuristics: CAL location is valid if it
% A) does not have block usage "output" (<-- output might be an optimized)
% OR
% B) does have a non-empty Param value from the model
function bIsValid = i_isValidCalLocation(stBlockInfo)
bIsValid = ~strcmpi(stBlockInfo.sBlockUsage, 'output') || ~isempty(stBlockInfo.sParamValue);
end


%%
function astVars = i_getAllVars(stEnv, hSubsys)
ahVars = atgcv_m01_global_vars_get(stEnv, hSubsys, 'cal');

% WORKAROUND for SystemTests and UnitTests --> formerly the reverse order was returned
% in order to keep the test expectations stable, reverse the order of CALs here
if ~isempty(ahVars)
    ahVars = ahVars(end:-1:1);
end

nVars   = length(ahVars);
astVars = repmat(i_getInitVarInfo(), 1, nVars);
if ~isempty(astVars)
    abSelect = true(1, nVars);
    for i = 1:nVars
        % 1) remove vars that are structs, only accept elementary types or struct-components
        astVars(i).hVar = ahVars(i);
        if dsdd('Exist', 'Components', 'Parent', astVars(i).hVar)
            abSelect(i) = false;
            continue;
        end
        
        % 2) remove vars without reference in the model --> cannot access these during MIL simulations
        astVars(i).astBlockInfo = i_getCalibrationBlockInfo(stEnv, ahVars(i));
        if isempty(astVars(i).astBlockInfo)
            abSelect(i) = false;
        end
    end
    astVars = astVars(abSelect);
end
end


%%
function astVars = i_addVariableInfoAndMergeSameVars(stEnv, astVars)
jVarHash = java.util.HashMap();
abSelect = true(size(astVars));
nVars = length(astVars);
for i = 1:nVars
    astVars(i).stInfo = atgcv_m01_variable_info_get(stEnv, astVars(i).hVar);
    
    % filter out all struct types
    if strcmpi(astVars(i).stInfo.stVarType.sBase, 'Struct')
        abSelect(i) = false;
        continue;
    end
    
    sKey = i_getKeyFromVarInfo(astVars(i).stInfo);
    iIdx = jVarHash.get(sKey);
    if isempty(iIdx)
        jVarHash.put(sKey, i);
    else
        abSelect(i) = false;
        astVars(iIdx).astBlockInfo = i_addExtraBlockInfos(astVars(iIdx).astBlockInfo, astVars(i).astBlockInfo);
    end
end
astVars = astVars(abSelect);
end


%%
% get one scalar value from a structure that is unique for a variable
function sKey = i_getKeyFromVarInfo(stVarInfo)
sKey = [stVarInfo.sModuleName, '|', stVarInfo.sRootName, stVarInfo.sAccessPath];
end


%%
% add new block info only if it is not already part of the existing block info
function astBlockInfo = i_addExtraBlockInfos(astBlockInfo, astAddBlockInfo)
jInfoSet = java.util.HashSet();
for i = 1:length(astBlockInfo)
    jInfoSet.add(astBlockInfo(i).sTlPath);
end
for i = 1:length(astAddBlockInfo)
    if ~jInfoSet.contains(astAddBlockInfo(i).sTlPath)
        astBlockInfo(end + 1) = astAddBlockInfo(i); %#ok<AGROW>
    end
end
end


%%
function astVars = i_removeUnsupportedVars(stEnv, astVars, sMode, bAcceptMismatch)
nVars = length(astVars);

% get global CAL settings
stCalSettings = atgcv_cal_settings();

% filter out the vars we need: use either LimitedBlockset or ExplicitParam criteria
abSelect = false(size(astVars)); % per default select none of the CAL variables
if strcmpi(sMode, 'limited')
    for i = 1:nVars
        if i_isLimitedCal(stEnv, astVars(i))
            astVars(i).stCal.sKind = 'limited';
            abSelect(i) = true;
        end
    end
    
    % now check the SaturationLimitation:
    % both upper _and_ lower bound have to be limited CAL object
    ahInvalidVars = i_checkSaturationLimitation(stEnv, astVars(abSelect));
    if ~isempty(ahInvalidVars)
        for i = 1:nVars
            if (abSelect(i) && any(astVars(i).hVar == ahInvalidVars))
                abSelect(i) = false;
            end
        end
    end
else
    for i = 1:nVars
        stAccess = i_getAndCheckAccessInfo(stEnv, astVars(i));
        if ~stAccess.bIsValid
            continue;
        end
        
        if i_fallsUnderLutLimitation(stEnv, astVars(i))
            continue;
        end
        if i_shallBeIgnored(stEnv, astVars(i), stCalSettings)
            continue;
        end
        if i_fallsUnderIntegratorLimitation(stEnv, astVars(i))
            continue;
        end
        
        if i_fallsUnderNestedSFParamLimitation(astVars(i))
            continue;
        end
        
        abSelect(i) = true;
        astVars(i).stCal.sKind = 'explicit';
        astVars(i).stCal.sWorkspaceVar = stAccess.sWorkspaceVar;
        astVars(i).stCal.sPoolVarPath  = stAccess.sPoolVarPath;
        astVars(i).stCal.sNameTemplate = stAccess.sNameTemplate;
        astVars(i).stCal.sType         = stAccess.sWorkspaceType;
        
        if ~isempty(astVars(i).stCal.sWorkspaceVar)
            [stProps, bValid] = atgcv_m01_ws_var_info_get(astVars(i).stCal.sWorkspaceVar);
            if bValid
                astVars(i).stCal.sClass  = stProps.sClass;
                astVars(i).stCal.xValue  = stProps.xValue;
                astVars(i).stCal.aiWidth = stProps.aiWidth;
                astVars(i).stCal.sMin    = stProps.sMin;
                astVars(i).stCal.sMax    = stProps.sMax;
            end
            if ~bAcceptMismatch
                abSelect(i) = i_isTypeDefinitionConsistent(stEnv, astVars(i));
            end
        end
    end
end
astVars = astVars(abSelect);
astVars = i_checkParamMultiuse(stEnv, astVars);
end

%%
function bIsTypeDefinitionConsistent = i_isTypeDefinitionConsistent(stEnv, stVar)
bIsTypeDefinitionConsistent = true;
stCal = stVar.stCal;
stTypeInfo = ep_sl_type_info_get(stCal.sType);
if ~isempty(stTypeInfo) && stTypeInfo.bIsEnum && ~strcmp(stVar.stInfo.stVarType.sBase, 'Enum')
    bIsTypeDefinitionConsistent = false;
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:CAL_TYPE_INCONSISTENT', ...
        'calVar',  stVar.stInfo.sRootName, ...
        'mType',   stCal.sType, ...
        'cType',   stVar.stInfo.stVarType.sBase);
end
end

%%
function astVars = i_checkParamMultiuse(stEnv, astVars)
abSelect = true(size(astVars));
casWorkspace = cell(size(astVars));
for i = 1:length(astVars)
    casWorkspace{i} = astVars(i).stCal.sWorkspaceVar;
end
for i = 1:length(casWorkspace)
    if ~abSelect(i)
        continue;
    end
    sWorkspace = casWorkspace{i};
    if isempty(sWorkspace)
        continue;
    end
    
    aiIdx = find(strcmp(sWorkspace, casWorkspace));
    if (length(aiIdx) > 1)
        % ERROR SITUATION:
        % one single MIL variable influences different CAL object on Code level
        % --> currently not supported
        % --> SupportIdea: formulate a ModelAssumption!
        sParamValue = sWorkspace;
        
        iIdx = aiIdx(1);
        sVariables = [astVars(iIdx).stInfo.sRootName, astVars(iIdx).stInfo.sAccessPath];
        sBlockPaths = astVars(iIdx).astBlockInfo(1).sTlPath;
        abSelect(iIdx) = false;
        for k = 2:length(aiIdx)
            iIdx = aiIdx(k);
            
            sVarName = [astVars(iIdx).stInfo.sRootName, astVars(iIdx).stInfo.sAccessPath];
            sVariables = [sVariables, ', ', sVarName]; %#ok
            
            sBlockPaths = [sBlockPaths, ', ', astVars(iIdx).astBlockInfo(1).sTlPath]; %#ok
            abSelect(iIdx) = false;
        end
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:PARAMCHECK_MIL_MULTIUSE', ...
            'variables',  sVariables, ...
            'blockpaths', sBlockPaths, ...
            'paramvalue', sParamValue);
    end
end
astVars = astVars(abSelect);
end


%%
function stAccess = i_getAndCheckAccessInfo(stEnv, stVar)
stAccess = struct( ...
    'sWorkspaceVar',  '', ...
    'sWorkspaceType', '', ...
    'sPoolVarPath',   '', ...
    'sNameTemplate',  '', ...
    'bIsValid',       true);


% count the accesses via DD-Pool and via Workspace/Function
nPoolAccess = 0;
nWorkspaceAccess = 0;
nIllegalAccess = 0;

casParamValues = {};
for i = 1:length(stVar.astBlockInfo)
    stBlockInfo = stVar.astBlockInfo(i);
    
    sParamValue = strtrim(stBlockInfo.sParamValue);
    if any(strcmp(sParamValue, casParamValues))
        continue;
    end
    casParamValues{end + 1} = sParamValue; %#ok<AGROW>
    
    stInfo = atgcv_m01_expression_info_get(sParamValue, stBlockInfo.sTlPath, true);
    if (stInfo.bIsValid && ~isempty(stInfo.sExpression))
        if ~isempty(stInfo.sFuncName)
            if strcmp(stInfo.sFuncName, 'ddv')
                nPoolAccess = nPoolAccess + 1;
            else
                nIllegalAccess = nIllegalAccess + 1;
            end
        else
            if stInfo.bIsLValue
                nWorkspaceAccess = nWorkspaceAccess + 1;
                
                [bIsValid, sMilValueType] = i_checkMilValue(stEnv, stVar.hVar, stInfo.xValue);
                if bIsValid
                    stAccess.sWorkspaceVar  = stInfo.sExpression;
                    stAccess.sWorkspaceType = sMilValueType;
                end
            else
                nIllegalAccess = nIllegalAccess + 1;
            end
        end
    else
        nIllegalAccess = nIllegalAccess + 1;
    end
end

if (nWorkspaceAccess > 1)
    % FIRST ERROR SITUATION:
    % if there are multiple differnt MIL accesses via Workspace,
    % --> we cannot successfully manipulate the CAL Object in MIL
    stAccess.bIsValid = false;
    
    sVarName = [stVar.stInfo.sRootName, stVar.stInfo.sAccessPath];
    sBlockPaths = stVar.astBlockInfo(1).sTlPath;
    for i = 2:length(stVar.astBlockInfo)
        sBlockPaths = [sBlockPaths, '; ', stVar.astBlockInfo(i).sTlPath]; %#ok<AGROW>
    end
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:PARAMCHECK_MIL_INCONSISTENT', ...
        'variable',   sVarName, ...
        'blockpaths', sBlockPaths);
    return;
end

% Note: we need to have both infos individually
% 1) DD-Pool Path if there is any
% 2) is Pool-Var used via "ddv" in Model
bIsPoolVarUsed = (nPoolAccess > 0);
stAccess.sPoolVarPath = i_getPoolVarPath(stEnv, stVar.hVar);
if isempty(stAccess.sPoolVarPath)
    % actually this is probably an INTERNAL_ERROR!
    % MIL is using ddv('...') but we cannot find a DD PoolVar path
    % TODO: maybe throw an INTERNAL error here!
    bIsPoolVarUsed = false;
else
    stAccess.sNameTemplate = i_getNameTemplate(stEnv, stAccess.sPoolVarPath);
end

% fallback to default type "double"
if isempty(stAccess.sWorkspaceType)
    stAccess.sWorkspaceType = 'double';
end

% SECOND ERROR SITUATION:
% if there is
%   1) no accessible Workspace Variable AND
%   2) no access via DD Variable,
% --> we cannot successfully manipulate the CAL Object in MIL
if ((isempty(stAccess.sWorkspaceVar) && ~bIsPoolVarUsed) || (nIllegalAccess > 0))
    stAccess.bIsValid = false;
    
    % Note: ignore Variables with "coefficients"/"matrices" BlockUsage
    %       --> they are covered by a Limitation in ET and should not be presented to the User
    if ~any(strcmpi(stVar.astBlockInfo(1).sBlockUsage, {'coefficients', 'matrices'}))
        sVarName   = [stVar.stInfo.sRootName, stVar.stInfo.sAccessPath];
        sBlockPath = stVar.astBlockInfo(1).sTlPath;
        
        if ~isempty(stInfo.sExpression)
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:PARAMCHECK_MIL_READONLY', ...
                'variable',   sVarName, ...
                'blockpath',  sBlockPath, ...
                'paramvalue', stInfo.sExpression);
        else
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:PARAMCHECK_MIL_NOT_FOUND', ...
                'variable',   sVarName, ...
                'blockpath',  sBlockPath);
        end
    end
end
end


%%
function sNameTemplate = i_getNameTemplate(stEnv, sPoolVarPath)
sNameTemplate = '$D';
try %#ok<TRYNC>
    if dsdd('exist', sPoolVarPath, 'property', 'NameTemplate')
        sNameTemplate = atgcv_mxx_dsdd(stEnv, 'GetNameTemplate', sPoolVarPath);
    end
end
end


%%
function bIsLimitedCal = i_isLimitedCal(stEnv, stVar) %#ok stEnv not used (yet)
casSupportedBlocks = { ...
    'Stateflow', ...
    'TL_Constant', ...
    'TL_Gain', ...
    'TL_Relay', ...
    'TL_Saturate', ...
    'TL_Switch'};

% per default: variable is no LimitedCal
bIsLimitedCal = false;

nModelRefs = length(stVar.astBlockInfo);
for i = 1:nModelRefs
    sBlockKind = stVar.astBlockInfo(i).sBlockKind;
    if ~any(strcmpi(sBlockKind, casSupportedBlocks))
        return;
    end
end

% if all model references are supported, variable is LimitedCal
bIsLimitedCal = true;
end


%%
% AH TODO: find a more efficient algo!
function ahInvalidVars = i_checkSaturationLimitation(stEnv, astVars)

ahInvalidVars = [];

% Limitation1:
% only scalar values for bounds allowed
% Limitation2:
% Saturation block has _two_ calibrateable variables: lower and upper
% ==> if a TL Saturation block is mentioned only once, the corresponding
%     variable is invalid
astSat = repmat(struct('sPath', '', 'hVar', []), 0, 0);
nVars = length(astVars);
for i = 1:nVars
    nModelRefs = length(astVars(i).astBlockInfo);
    for j = 1:nModelRefs
        sBlockKind = astVars(i).astBlockInfo(j).sBlockKind;
        sBlockPath = astVars(i).astBlockInfo(j).sTlPath;
        if strcmpi(sBlockKind, 'TL_Saturate')
            iWidth = atgcv_mxx_dsdd(stEnv, 'GetWidth', astVars(i).hVar);
            if ~isempty(iWidth) && (iWidth > 1)
                ahInvalidVars(end + 1) = astVars(i).hVar; %#ok<AGROW>
                osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_SATURATE_CAL_ARRAYS', 'variable', sBlockPath);
                break;
            end
            
            astSat(end + 1) = struct( ...
                'sPath', sBlockPath, ...
                'hVar',  astVars(i).hVar); %#ok<AGROW>
        end
    end
end

% some invalid vars might be mentioned more than once
ahInvalidVars = unique(ahInvalidVars);
end


%%
function bIsLimited = i_fallsUnderLutLimitation(stEnv, stVar)
bIsLimited = false;

nModelRefs = length(stVar.astBlockInfo);
for j = 1:nModelRefs
    stBlockInfo = stVar.astBlockInfo(j);
    sBlockKind  = stBlockInfo.sBlockKind;
    
    if any(strcmpi(sBlockKind, {'TL_IndexSearch', 'TL_Interpolation', 'TL_Lookup1D', 'TL_Lookup2D'}))
        sLimitOption = i_checkLutLimitOptions(stEnv, sBlockKind, stBlockInfo.hBlock);
        if ~isempty(sLimitOption)
            bIsLimited = true;
            sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', stVar.hVar, 'name');
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_CAL_LUT', ...
                'variable',  sVarName, ...
                'lut_block', stBlockInfo.sTlPath, ...
                'option',    sLimitOption);
            break;
        end
    end
end
end


%%
function bIgnore = i_shallBeIgnored(stEnv, stVar, stCalSettings)
bIgnore = false;

if stCalSettings.ET_CAL_ignore_arrays
    iWidth = atgcv_mxx_dsdd(stEnv, 'GetWidth', stVar.hVar);
    if (~isempty(iWidth) && (prod(iWidth) > 1))
        bIgnore = true;
        
        i_addIgnoreNote(stEnv, stVar.hVar, stVar.astBlockInfo(1).sTlPath, 'ET_CAL_ignore_arrays');
        return;
    end
end

if (~stCalSettings.ET_CAL_ignore_LUT_axis && ...
        ~stCalSettings.ET_CAL_ignore_LUT_1D_values && ...
        ~stCalSettings.ET_CAL_ignore_LUT_2D_values && ...
        ~stCalSettings.ET_CAL_ignore_Interpolation_values)
    return;
end

nModelRefs = length(stVar.astBlockInfo);
for j = 1:nModelRefs
    stBlockInfo = stVar.astBlockInfo(j);
    sBlockKind  = stBlockInfo.sBlockKind;
    
    if any(strcmpi(sBlockKind, { ...
            'TL_IndexSearch', ...
            'TL_Interpolation', ...
            'TL_Lookup1D', ...
            'TL_Lookup2D'}))
        if stCalSettings.ET_CAL_ignore_LUT_axis
            if ~isempty(stBlockInfo.sRestriction)
                bIgnore = true;
                
                i_addIgnoreNote(stEnv, stVar.hVar, stBlockInfo.sTlPath, 'ET_CAL_ignore_LUT_axis');
                break;
            end
        end
        % all non-axis elements have _no_ restrictions
        if isempty(stBlockInfo.sRestriction)
            if stCalSettings.ET_CAL_ignore_LUT_2D_values
                if strcmpi(sBlockKind, 'TL_Lookup2D')
                    bIgnore = true;
                    
                    i_addIgnoreNote(stEnv, stVar.hVar, stBlockInfo.sTlPath, 'ET_CAL_ignore_LUT_2D_values');
                    break;
                end
            end
            if stCalSettings.ET_CAL_ignore_LUT_1D_values
                if strcmpi(sBlockKind, 'TL_Lookup1D')
                    bIgnore = true;
                    
                    i_addIgnoreNote(stEnv, stVar.hVar, stBlockInfo.sTlPath, 'ET_CAL_ignore_LUT_1D_values');
                    break;
                end
            end
            if stCalSettings.ET_CAL_ignore_Interpolation_values
                if any(strcmpi(sBlockKind, {'TL_IndexSearch', 'TL_Interpolation'}))
                    bIgnore = true;
                    
                    i_addIgnoreNote(stEnv, stVar.hVar, stBlockInfo.sTlPath, 'ET_CAL_ignore_Interpolation_values');
                    break;
                end
            end
        end
    end
end
end


%%
function i_addIgnoreNote(stEnv, hVar, sBlockPath, sSetting)
sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'name');
osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:IGNORE_CAL_BY_SETTING', ...
    'variable',  sVarName, ...
    'block',     sBlockPath, ...
    'setting',   sSetting);
end


%%
function bIsLimited = i_fallsUnderIntegratorLimitation(stEnv, stVar)
bIsLimited = false;

nModelRefs = length(stVar.astBlockInfo);
for j = 1:nModelRefs
    stBlockInfo = stVar.astBlockInfo(j);
    sBlockKind  = stBlockInfo.sBlockKind;
    
    if strcmpi(sBlockKind, 'TL_DiscreteIntegrator')
        bIsLimited = true;
        sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', stVar.hVar, 'name');
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_CAL_INTEGRATOR', ...
            'variable',  sVarName, ...
            'integrator_block', stBlockInfo.sTlPath);
        break;
    end
end
end

%%
function bIsLimited = i_fallsUnderNestedSFParamLimitation(stVar)
bIsLimited = false;
nModelRefs = length(stVar.astBlockInfo);
for j = 1:nModelRefs
    stBlockInfo = stVar.astBlockInfo(j);
    sBlockKind  = stBlockInfo.sBlockKind;
    sBlockUsage = stBlockInfo.sBlockUsage;
    if strcmp(sBlockKind, 'Stateflow') && strcmp(sBlockUsage, 'sf_parameter')
        sNestedPath = stBlockInfo.stSfInfo.sSfRelPath;
        if ~isempty(sNestedPath)
            bIsLimited = true;
        end
    end
end
end


%%
function sLimitOption = i_checkLutLimitOptions(stEnv, sBlockKind, hBlock)
sLimitOption = '';
if dsdd('exist', hBlock, 'property', 'BlockRef')
    %     hBlock = atgcv_mxx_dsdd(stEnv, 'GetBlockRef', hBlock);
    %     sBlockKind = atgcv_mxx_dsdd(stEnv, 'GetBlockType', hBlock);
    
    % LUT with DD objects create problems during MIL because their value is
    % not consistently syncronized with the DD
    sLimitOption = 'Data Dictionary Look-up table object';
    return;
end

switch lower(sBlockKind)
    case 'tl_interpolation'
        if (atgcv_mxx_dsdd(stEnv, ...
                'GetInterpolationValueDiffFitsIntoValueType', hBlock) == 1)
            sLimitOption = 'Distances between table entries less ...';
        end
        
    case 'tl_lookup1d'
        if (atgcv_mxx_dsdd(stEnv, ...
                'GetLookup1DValueDiffFitsIntoValueType', hBlock) == 1)
            sLimitOption = 'Distances between table entries less ...';
            
        elseif (atgcv_mxx_dsdd(stEnv, ...
                'GetLookup1DAddBoundaryPoints', hBlock) == 1)
            sLimitOption = 'Use boundary points';
            
        elseif strcmpi(atgcv_mxx_dsdd(stEnv, ...
                'GetLookup1DSearchMethod', hBlock), 'EquidistantAxis')
            sLimitOption = 'Equidistant with ...';
            
        end
        
    case 'tl_lookup2d'
        if (atgcv_mxx_dsdd(stEnv, ...
                'GetLookup2DValueDiffFitsIntoValueType', hBlock) == 1)
            sLimitOption = 'Distances between table entries less ...';
            
        elseif (atgcv_mxx_dsdd(stEnv, ...
                'GetLookup2DRowAddBoundaryPoints', hBlock) == 1)
            sLimitOption = 'Use boundary points';
            
        elseif strcmpi(atgcv_mxx_dsdd(stEnv, ...
                'GetLookup2DRowSearchMethod', hBlock), 'EquidistantAxis')
            sLimitOption = 'Equidistant with ...';
            
        elseif (atgcv_mxx_dsdd(stEnv, ...
                'GetLookup2DColAddBoundaryPoints', hBlock) == 1)
            sLimitOption = 'Use boundary points';
            
        elseif strcmpi(atgcv_mxx_dsdd(stEnv, ...
                'GetLookup2DColSearchMethod', hBlock), 'EquidistantAxis')
            sLimitOption = 'Equidistant with ...';
            
        end
    otherwise
        % just ignore for all other cases (tl_indexsearch)
end
end


%%
% perform three checks on MIL value
% 1) legal/valid type
% 2) same size as C-variable
function [bIsValid, sValueType] = i_checkMilValue(stEnv, hVar, xMilValue)
bIsValid = true;

[anValueSize, sValueType, bIsSimParam] = i_getSizeAndTypeOfValue(xMilValue);
if ~i_isMilValueTypeValid(sValueType)
    bIsValid = false;
    sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'Name');
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:VARCHECK_ILLEGAL_TYPE_WORKSPACE_VAR', ...
        'variable',  sVarName, ...
        'type',      sValueType);
    return;
end

% compare sizes on workspace an C level
anSize = atgcv_mxx_dsdd(stEnv, 'GetWidth', hVar);
if isempty(anSize)
    % take care: scalars do not have a width in DD
    anSize = 1;
else
    % if vector: just get length; don't care if row or col vector
    if any(anSize == 1)
        anSize = max(anSize);
    end
end

% if vector: just get length; don't care if row or col vector
if any(anValueSize == 1)
    anValueSize = max(anValueSize);
end

if ~isequal(anSize, anValueSize)
    bIsValid = false;
    sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'Name');
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:VARCHECK_SIZEDIFF_WORKSPACE_VAR', ...
        'variable',  sVarName, ...
        'size_c',    num2str(anSize), ...
        'size_m',    num2str(anValueSize));
end

% as a last step if variable was accepted, give a limitation note if we have a Simulink.Parameter
if (bIsValid && bIsSimParam)
    sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'Name');
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_SIMULINK_PARAM', 'param',  sVarName);
end
end


%%
function hPoolVar = i_getPoolVar(stEnv, hVar)
hPoolVar = [];
if dsdd('Exist', hVar, 'Property', {'Name', 'SrcRefs'})
    % TL-version < 3.1
    casSrcRefs = atgcv_mxx_dsdd(stEnv, 'GetSrcRefs', hVar);
    for i = 1:length(casSrcRefs)
        if ~isempty(strfind(casSrcRefs{i}, '/Pool/Variables'))
            hPoolVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', casSrcRefs{i}, 'hDDObject');
            break;
        end
    end
else
    % TL-version >= 3.1
    if dsdd('Exist', hVar, 'Property', {'Name', 'PoolRef'})
        hPoolVar = atgcv_mxx_dsdd(stEnv, 'GetPoolRefTarget', hVar);
    end
end
end


%%
function sPoolVarPath = i_getPoolVarPath(stEnv, hVar)
hPoolVar = i_getPoolVar(stEnv, hVar);
if ~isempty(hPoolVar)
    sPoolVarPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hPoolVar, 'path');
else
    sPoolVarPath = '';
end
end


%%
function astBlockInfo = i_getCalibrationBlockInfo(stEnv, hVar)
astBlockInfo = atgcv_m01_variable_block_info_get(stEnv, hVar, true);

bDataStoreUsed = false;

% remove blocks that cannot be used for calibration
abSelect = true(size(astBlockInfo));
for i = 1:length(astBlockInfo)
    sBlockKind = astBlockInfo(i).sBlockKind;
    switch lower(sBlockKind)
        case 'stateflow'
            % SF-Inputs/Outputs cannot be calibrated
            if any(strcmpi(astBlockInfo(i).stSfInfo.sSfScope, {'Input', 'Output'}))
                abSelect(i) = false;
            end
            
        case 'tl_datastorememory'
            % special treatment for DataStores (set flag for later handling)
            bDataStoreUsed = true;
            
        case 'tl_gain'
            % the BlockUsage may also be "output" additionally to "gain"
            % --> just accept "gain" to avoid artificial ModelLocations
            if ~strcmpi(astBlockInfo(i).sBlockUsage, 'gain')
                abSelect(i) = false;
            end
            
        case 'genericblock'
            % throw away block info for DataTypeConversion blocks --> they introduce artficial ModelLocations
            if strcmpi(astBlockInfo(i).sBlockType, 'DataTypeConversion')
                abSelect(i) = false;
            end
            
        case {'tl_inport', 'tl_outport'}
            % also Ports should not be taken into account (BTS/36097)
            abSelect(i) = false;
            
        case {'tl_customcode'}
            % Customcode-Inputs/Outputs/States cannot be calibrated
            if any(strcmpi(astBlockInfo(i).sBlockUsage, {'input', 'output', 'state'}))
                abSelect(i) = false;
            end
    end
end
astBlockInfo = astBlockInfo(abSelect);

if bDataStoreUsed
    astBlockInfo = i_adaptDataStoreMemoryInfo(astBlockInfo);
end
end


%%
% special case DataStoreMemory; do two things
% 1) transfer InitialOutput ParamValue for DataStoreMemory to DataStoreRead
% 2) remove all DataStoreMemory and DataStoreWrite blocks
function astBlockInfo = i_adaptDataStoreMemoryInfo(astBlockInfo)
bWriteAccessFound = false;

sParamValue = '';
abSelect = true(size(astBlockInfo));
for i = 1:length(astBlockInfo)
    if strcmpi(astBlockInfo(i).sBlockKind, 'TL_DataStoreMemory')
        sParamValue = astBlockInfo(i).sParamValue;
        abSelect(i) = false;
    elseif strcmpi(astBlockInfo(i).sBlockKind, 'TL_DataStoreWrite')
        abSelect(i) = false;
        bWriteAccessFound = true;
    end
end

% if a write access inside the model is detected, the variable cannot be used as a CAL
% also if we do not have a parameter value, the variable cannot be set for MIL
if (bWriteAccessFound || isempty(sParamValue))
    astBlockInfo = astBlockInfo(false(size(astBlockInfo)));
else
    astBlockInfo = astBlockInfo(abSelect);
end
if isempty(astBlockInfo)
    return;
end

if (atgcv_version_p_compare('TL4.2') >= 0)
    abSelect = false(size(astBlockInfo));
    for i = 1:length(astBlockInfo)
        if (strcmpi(astBlockInfo(i).sBlockKind, 'TL_DataStoreRead') ...
                && strcmpi(astBlockInfo(i).sBlockUsage, 'variable'))
            bIsLeafVariable = ~dsdd('Exist', 'variable', 'Parent', astBlockInfo(i).hBlockVar);
            if bIsLeafVariable
                astBlockInfo(i).sBlockUsage = 'output'; % fake an output usage
                astBlockInfo(i).sParamValue = sParamValue;
                abSelect(i) = true;
            end
        end
    end
    astBlockInfo = astBlockInfo(abSelect);
else
    for i = 1:length(astBlockInfo)
        if strcmpi(astBlockInfo(i).sBlockKind, 'TL_DataStoreRead')
            astBlockInfo(i).sBlockUsage = 'output';
            astBlockInfo(i).sParamValue = sParamValue;
        end
    end
end
end


%%
function [anValueSize, sValueType, bIsSimParam] = i_getSizeAndTypeOfValue(xValue)
bIsSimParam  = isa(xValue, 'Simulink.Parameter');
if bIsSimParam
    anValueSize = xValue.Dimensions;
    sValueType  = xValue.DataType;
    if strcmp(sValueType, 'auto')
        % if type not defined yet, use default type "double"
        sValueType = 'double';
    end
else
    anValueSize = size(xValue);
    sValueType  = class(xValue);
end
end


%%
% note: currently only based on a black-list (not white list)
function bIsLegal = i_isMilValueTypeValid(sType)
bIsLegal = true;

% safety check
if (~ischar(sType) || isempty(sType))
    bIsLegal = false;
end

% structs are illegal types for params
if strcmpi(sType, 'struct')
    bIsLegal = false;
end
end


%%
function bDoAccept = i_doAcceptMismatch()
bDoAccept = false;
try
    sFlag = atgcv_global_property_get('accept_inport_type_inconsistent');
    if any(strcmpi(sFlag, {'1', 'on', 'true', 'yes'}))
        bDoAccept = true;
    end
catch
end
end

function ep_create_architecture_constraint_files(stOpt, stModel)
% Create TargetLink, Simulink and C-Code Architecture Constraint files.
%
%   function ep_create_architecture_constraint_files(stOpt, stModel)
%
%   INPUT               DESCRIPTION
%      stOpt                 (struct)    argument struture with the following data
%        .sSlArchConstrFile  (string)      path to the SL Constraints output file
%        .sSlArchConstrFile  (string)      path to the TL Constraints output file
%        .sCArchConstrFile   (string)      path to the Code Constraints output file
%
%      stModel               (struct)    model info struct as produced by "ep_model_info_get"
%
%   OUTPUT              DESCRIPTION
%       -                      -
%

%%
% TL
sFile = i_getField(stOpt, 'sTlArchConstrFile');
if ~isempty(sFile)
    i_createConstraintFile(stModel, 'TL', sFile);
end

% Code
sFile = i_getField(stOpt, 'sCArchConstrFile');
if ~isempty(sFile)
    i_createConstraintFile(stModel, 'C', sFile);
end

% SL
if ~isempty(i_getField(stOpt, 'sSlModel'))
    sFile = i_getField(stOpt, 'sSlArchConstrFile');
    if ~isempty(sFile)
        i_createConstraintFile(stModel, 'SL', sFile);
    end
end
end


%%
function i_createConstraintFile(stModel, sArchType, sXmlFileName)
hConstRoot = mxx_xmltree('create', 'architectureConstraints');
xOnCleanupClose = onCleanup(@() mxx_xmltree('clear', hConstRoot));

% only look at scopes that are not hidden
abIsHidden = arrayfun(@i_isHidden, stModel.astSubsystems);

% iterate over the subsystems
switch upper(sArchType)
    case 'TL'
        astSubsystems = stModel.astSubsystems(~abIsHidden);
        casScopePaths = {astSubsystems(:).sTlPath};
        
    case 'SL'
        astSubsystems = stModel.astSubsystems(~abIsHidden);
        casScopePaths = {astSubsystems(:).sSlPath};
        
    case 'C'
        % Note: for the following function we need *all* subsystems inside the hierarchy ...
        casScopePaths = ep_scope_code_paths_get(stModel.astSubsystems);
        % ... only now we can filter out the hidden ones
        astSubsystems = stModel.astSubsystems(~abIsHidden);
        casScopePaths = casScopePaths(~abIsHidden);
        
    otherwise
        error('EP:MOD_ANA:UNEXPECTED_ARCH', 'Unexpected architecture "%s".', sArchType);
end

for i = 1:length(astSubsystems)
    stSubsystem = astSubsystems(i);
    
    sScopePath = casScopePaths{i};
    if isempty(sScopePath) % e.g. no corresponding C function
        continue;
    end
    
    astScopeCals = i_getScopeRelevantAndVisibleCals( ...
        stModel.astCalVars, ...
        stSubsystem.astCalRefs, ...
        sArchType, ...
        stModel.sTlRoot, ...
        stModel.sSlRoot);
    if ~isempty(astScopeCals)
        % add new Scope to the constraint file
        hScope = mxx_xmltree('add_node', hConstRoot, 'scope');
        if strcmp(sArchType, 'C')
            mxx_xmltree('set_attribute', hScope, 'path', sScopePath);
        else
            mxx_xmltree('set_attribute', hScope, 'path', i_removeModelPrefix(sScopePath));
        end
        
        nAss = i_addAssumptionsToScope(hScope, astScopeCals);
        if (nAss < 1)
            mxx_xmltree('delete_node', hScope);
        end
    end
end
mxx_xmltree('save', hConstRoot, sXmlFileName);
end


%%
function astScopeCals = i_getScopeRelevantAndVisibleCals(astCalVars, astScopeCalRefs, sArchType, sTlRoot, sSlRoot)
astReducedCalVars = i_getReducedCalVars(astCalVars, astScopeCalRefs);
astScopeCals = arrayfun(@(stCalVar) i_getScopeCal(stCalVar, sArchType, sTlRoot, sSlRoot), astReducedCalVars);
end


%%
function astReducedCalVars = i_getReducedCalVars(astCalVars, astScopeCalRefs)
astReducedCalVars = [];
if (isempty(astCalVars) ||isempty(astScopeCalRefs))
    return;
end

% select only the scope relevant calibrations
astReducedCalVars = astCalVars([astScopeCalRefs(:).iVarIdx]);

% remove the hidden ones
abIsHidden = arrayfun(@i_isHidden, astReducedCalVars);
astReducedCalVars = astReducedCalVars(~abIsHidden);
astScopeCalRefs = astScopeCalRefs(~abIsHidden);

% iterate on the reduced set and reduce the block references to the ones relevant for the scope
for k = 1:length(astScopeCalRefs)
    astReducedCalVars(k).astBlockInfo = astReducedCalVars(k).astBlockInfo(astScopeCalRefs(k).aiBlockIdx);
end
end


%%
function stScopeCal = i_getScopeCal(stCalVar, sArchType, sTlRoot, sSlRoot)
sFullName = i_getCalFullName(sArchType, stCalVar.astBlockInfo(1), stCalVar, sTlRoot, sSlRoot);
casSignals = i_get_signals(sFullName, stCalVar.stInfo.aiWidth, sArchType);

stScopeCal = struct( ...
    'sFullName',  sFullName, ...
    'casSignals', {casSignals}, ...
    'stCalVar',   stCalVar);
end


%%
function nAss = i_addAssumptionsToScope(hScope, astScopeCals)
nAss = 0;
if isempty(astScopeCals)
    return;
end

% iterate over all referenced calibrations of the scope
astScopeCalsToBeRechecked = repmat(astScopeCals(1), 1, 0);
for k = 1:length(astScopeCals)
    stScopeCal = astScopeCals(k);
    
    for m = 1:length(stScopeCal.stCalVar.astBlockInfo)
        stBlockInfo = stScopeCal.stCalVar.astBlockInfo(m);
        
        % skip not resticted calibrations
        if ~isfield(stBlockInfo, 'sRestriction') || isempty(stBlockInfo.sRestriction)
            continue;
        end
        
        % check block type to determine if signal-signal constraint shall be created after the local (signal-value)
        % constraints are created
        if any(strcmpi(stBlockInfo.sBlockKind, {'tl_saturate', 'tl_relay'}))
            % copy the scope cal to the ones to be re-checked and reduce the relevant blocks to the current one
            astScopeCalsToBeRechecked(end + 1) = stScopeCal; %#ok<AGROW>
            astScopeCalsToBeRechecked(end).stCalVar.astBlockInfo = stBlockInfo;
        else
            hAssumption = mxx_xmltree('add_node', hScope, 'assumptions');
            mxx_xmltree('set_attribute', hAssumption, 'origin', stBlockInfo.sRestriction);
            
            i_addBlockRestriction(hAssumption, stScopeCal, stBlockInfo);
            nAss = nAss + 1;
        end
    end
end

% Signal-Signal Constraint
% This must be done outside of the loop because the related constraints are typically different calibrations
if ~isempty(astScopeCalsToBeRechecked)
    nAss = nAss + i_addSignalSignalConstraints(hScope, astScopeCalsToBeRechecked);
end
end


%%
% Depending on the architecture type (TL/C-Code) the correct full qualified
% name of the calibration is determined.
%
function sFullName = i_getCalFullName(sArchType, stBlockInfo, stCalVar, sTlRoot, sSlRoot)
% short cut for C code architecture
if ~any(strcmp(sArchType, {'SL', 'TL'}))
    sFullName = [stCalVar.stInfo.sRootName, stCalVar.stInfo.sAccessPath];
    return;
end

if strcmp(stBlockInfo.sBlockKind, 'Stateflow')
    sParamValue = stBlockInfo.stSfInfo.sSfName;
    
elseif isempty(stCalVar.stCal.sWorkspaceVar)
    if strcmp(stCalVar.stCal.sKind, 'limited')
        sBlockUsage = i_getLimitedCalUsage(stBlockInfo);
        casParts = textscan(stBlockInfo.sTlPath, '%s', 'delimiter', '/');
        sBlockName = casParts{end};
        sParamValue = [sBlockName{end}, '[', sBlockUsage, ']'];
        
    else
        sParamValue = [stCalVar.stInfo.sRootName, stCalVar.stInfo.sAccessPath];
        % if we need to find the name via the Code variable try two different approaches
        % 1) try to get the name via DD path
        % 2) otherwise just use the variable name as provided (including the field access for struct variables)
        sDdPath = stCalVar.stCal.sPoolVarPath;
        if ~isempty(sDdPath) % do we have a DD path into the Pool area?
            sDdPathName = regexprep(sDdPath, '/Components/', '.');
            
            % get rid of DdPrefix //DD0/Pool/Variables/<VariableGroup1>/...
            % <==> everything before and including the last slash
            sDdName = regexprep(sDdPathName, '.*/', '');
            if ~isempty(sDdName)
                sParamValue = sDdName;
            end
        end
    end
else
    sParamValue = stBlockInfo.sParamValue;
end
if strcmp(sArchType, 'TL')
    sFullName = [stBlockInfo.sTlPath, '/', sParamValue];
else
    sSlPath = strrep(stBlockInfo.sTlPath, sTlRoot, sSlRoot);
    sFullName = [sSlPath, '/', sParamValue];
end
end


%%
% ASSUMPTION -- all provided scope cals have just *one* block reference!!
%
function oBlockpathToCalMap = i_getBlockpathToCalMap(astScopeCals)
oBlockpathToCalMap = containers.Map();
for k = 1:length(astScopeCals)
    sBlockPath = astScopeCals(k).stCalVar.astBlockInfo(1).sTlPath;
    if oBlockpathToCalMap.isKey(sBlockPath)
        oBlockpathToCalMap(sBlockPath) = [oBlockpathToCalMap(sBlockPath), astScopeCals(k)];
    else
        oBlockpathToCalMap(sBlockPath) = astScopeCals(k);
    end
end
end


%%
% Creates a signal to signal constraint between two calibration variables.
%
function nAss = i_addSignalSignalConstraints(hScope, astScopeCals)
nAss = 0;
if isempty(astScopeCals)
    return;
end

oBlockpathToCalMap = i_getBlockpathToCalMap(astScopeCals);

casBlockPaths = oBlockpathToCalMap.keys;
for i = 1:length(casBlockPaths)
    astScopeCals = oBlockpathToCalMap(casBlockPaths{i});
    
    nNumRelatedCals = numel(astScopeCals);
    if (nNumRelatedCals == 1)
        % only *one* calibration variable involved --> add a unary constraint
        nAss = nAss + i_addUnaryConstraint(hScope, astScopeCals);
        
    else
        if (nNumRelatedCals > 2)
            warning('EP:INTERNAL_ERROR:TOO_MANY_INTERRELATIONS', 'Unexptected: Number of related CALs exceeds two.');
            continue;
        end
        
        [stLowerScopeCal, stUpperScopeCal] = i_orderIntraScopeCals(astScopeCals);
        
        nElems = numel(stLowerScopeCal.casSignals);
        if (nElems ~= numel(stUpperScopeCal.casSignals))
            warning('EP:INTERNAL_ERROR:INCONSTENT_ELEM_INTERRELATIONS', ...
                'Numbers of elements inside the intra relation calibrations do not match.');
            continue;
        end
        
        sBlockType = lower(astScopeCals(1).stCalVar.astBlockInfo(1).sBlockKind);
        hAssumption = mxx_xmltree('add_node', hScope, 'assumptions');
        mxx_xmltree('set_attribute', hAssumption, 'origin', sBlockType);
        for k = 1:length(stLowerScopeCal.casSignals)
            hConst = mxx_xmltree('add_node', hAssumption, 'signalSignal');
            mxx_xmltree('set_attribute', hConst, 'relation', 'leq');
            mxx_xmltree('set_attribute', hConst, 'signal1',  stLowerScopeCal.casSignals{k});
            mxx_xmltree('set_attribute', hConst, 'signal2',  stUpperScopeCal.casSignals{k});
        end
        nAss = nAss + 1;
    end
end
end


%%
% ASSUMPTION: only *one* block reference inside provded scope calibrations
%
function [stLowerScopeCal, stUpperScopeCal] = i_orderIntraScopeCals(astScopeCals)
stLowerScopeCal = [];
stUpperScopeCal = [];
if isempty(astScopeCals)
    return;
end

stBlockInfo1 = astScopeCals(1).stCalVar.astBlockInfo(1);
stBlockInfo2 = astScopeCals(2).stCalVar.astBlockInfo(1);

sBlockKind = stBlockInfo1.sBlockKind;
if ~strcmp(sBlockKind, stBlockInfo2.sBlockKind)
    warning('EP:INTERNAL_ERROR:INCONSISTENT_INTRA_CONSTRAINT_TYPE', ...
        'Block types "%s" and "%s" do not match.', sBlockKind, stBlockInfo2.sBlockKind);
    return;
end

switch lower(sBlockKind)
    case 'tl_saturate'
        casRequiredOrder = {'tl_saturate:lowerlimit', 'tl_saturate:upperlimit'};
        
    case 'tl_relay'
        casRequiredOrder = {'tl_relay:offswitch',  'tl_relay:onswitch'};
        
    otherwise
        warning('EP:INTERNAL_ERROR:UNEXPECTED_INTRA_CONSTRAINT_TYPE', ...
            'Block type "%s" unexpected for intra assumption.', sBlockKind);
        return;
end

casBlockRestrictions = {stBlockInfo1.sRestriction, stBlockInfo2.sRestriction};
[~, aiOrderIdx] = ismember(casRequiredOrder, casBlockRestrictions);
if (all(aiOrderIdx > 0) && numel(unique(aiOrderIdx) == 2))
    stLowerScopeCal = astScopeCals(aiOrderIdx(1));
    stUpperScopeCal = astScopeCals(aiOrderIdx(2));
else
    warning('EP:INTERNAL_ERROR:INCONSISTENT_INTRA_CONSTRAINT_RESTRICTIONS', ...
        'Block type "%s" with inconsistent block restrictions "%s" and "%s".', ...
        sBlockKind, stBlockInfo1.sRestriction, stBlockInfo2.sRestriction);
end
end

%%
% ASSUMPTION: only *one* block reference inside provded scope calibration
%
function nAss = i_addUnaryConstraint(hScope, stScopeCal)
nAss = 0;

stBlockInfo = stScopeCal.stCalVar.astBlockInfo(1);
if isempty(stBlockInfo.sConstraintKind)
    % info cannot be produced here because the model might already be closed
    warning('EP:INTERNAL_ERROR:CONSTRAINT_VALUE_MISSING', ...
        'Cannot read out constraint value for "%s".', stScopeCal.sFullName);
    return;
end

adValues = i_getConstraintValues(stBlockInfo, numel(stScopeCal.casSignals));
if isempty(adValues)
    return;
end

hAssumption = mxx_xmltree('add_node', hScope, 'assumptions');
mxx_xmltree('set_attribute', hAssumption, 'origin', stBlockInfo.sRestriction);
for k = 1:length(stScopeCal.casSignals)
    hConst = mxx_xmltree('add_node', hAssumption, 'signalValue');
    mxx_xmltree('set_attribute', hConst, 'signal',   stScopeCal.casSignals{k});
    mxx_xmltree('set_attribute', hConst, 'relation', stBlockInfo.sConstraintKind);
    mxx_xmltree('set_attribute', hConst, 'value',    sprintf('%.16e', adValues(k)));
end
nAss = nAss + 1;
end


%%
function adValues = i_getConstraintValues(stBlockInfo, nElems)
dValue = stBlockInfo.xConstraintVal;

adValues = [];
if (nElems > 1)
    nModelElems = numel(dValue);
    if (nModelElems == nElems)
        adValues = dValue;
    else
        if (nModelElems == 1)
            adValues = repmat(dValue, 1, nElems);
        else
            warning('EP:MOD_ANA:INTERNAL_ERROR', 'Number of elements inconsistent for MIL and SIL.');
        end
    end
else
    adValues = dValue;
end
end


%%
% Creates restrictions depending on the block kind. Currently the
% TL_RateLimiter and monotonical increasing array values are implemented.
%
function i_addBlockRestriction(hAssumption, stScopeCal, stBlockInfo)
sBlockType = stBlockInfo.sBlockKind;
if strcmpi(sBlockType, 'tl_ratelimiter')
    % falling slewrate has to be non-positive double
    % rising  slewrate has to be non-negative double
    dValue = 0.0;
    if strcmpi(stBlockInfo.sRestriction, 'tl_ratelimiter:rslewrate')
        sRelation = 'geq';
    else
        % ASSUMPTION: sRestriction == 'tl_ratelimiter:fslewrate'
        sRelation = 'leq';
    end
    for i = 1:length(stScopeCal.casSignals)
        hConst = mxx_xmltree('add_node', hAssumption, 'signalValue');
        mxx_xmltree('set_attribute', hConst, 'signal', stScopeCal.casSignals{i});
        mxx_xmltree('set_attribute', hConst, 'relation', sRelation);
        mxx_xmltree('set_attribute', hConst, 'value', sprintf('%.16e', dValue));
    end
else
    for i = 2:length(stScopeCal.casSignals)
        hConst = mxx_xmltree('add_node', hAssumption, 'signalSignal');
        mxx_xmltree('set_attribute', hConst, 'signal1', stScopeCal.casSignals{i - 1});
        mxx_xmltree('set_attribute', hConst, 'relation', 'les');
        mxx_xmltree('set_attribute', hConst, 'signal2', stScopeCal.casSignals{i});
    end
end
end


%%
% Generates a sorted list of signal if the provided widths for a vector (n elements) or
% matrix (NxM elements). The resulting cell array is sorted by increasing indices.
% Brackets are '()' for TL and '[]' for C-Code.
% Indices are in 1, ..., n for TL and in 0, ..., n-1 for C-Code
%
% function [casSignals] = i_get_signals(sFullName, aiWidth, sArchitectureType)
%
%  INPUT PARAMETER(S)
%    sFullName          (string)    The full name of the calibration
%    aiWidth            (array)     An array of dimension sizes (e.g. '[3,4]')
%    sArchitectureType  (string)    The kind of the architecture
%                                   'TL' TargetLink architecture
%                                   'C' C-Code architecture
%
%  OUTPUT PARAMETERS(S)
%    casSignals         (cellarray) The list of signals
%                                   (e.g. m(1)(1), m(1)(2), ..., m(3)(4))
%
function [casSignals] = i_get_signals(sFullName, aiWidth, sArchitectureType)
casSignals = {};
bIsCCode = strcmp(sArchitectureType, 'C');
if ~bIsCCode
    sFullName = i_removeModelPrefix(sFullName);
end
if isempty(aiWidth)
    casSignals = {sFullName};
    return;
else
    
    if length(aiWidth)>1
        if aiWidth(2)>1
            casSignals = cell(1, aiWidth(1) * aiWidth(2));
            for i=1:aiWidth(2)
                if bIsCCode
                    sSuffixD1 = [sFullName, '[',num2str(i-1),']'];
                else
                    sSuffixD1 = [sFullName, '(',num2str(i),')'];
                end
                if aiWidth(1)>1
                    for j=1:aiWidth(1)
                        iTargetIdx = (i-1) * aiWidth(1) + j;
                        if bIsCCode
                            casSignals{iTargetIdx} = [sFullName, '[', num2str(j-1), '][',num2str(i-1),']'];
                        else
                            casSignals{iTargetIdx} = [sFullName, '(', num2str(j), ')(',num2str(i),')'];
                        end
                    end
                    if i==aiWidth(2)
                        casSignals = sort(casSignals);
                    end
                else
                    casSignals{i} = sSuffixD1;
                end
            end
        end
    else
        if (aiWidth(1) > 1)
            casSignals = cell(1, aiWidth(1));
            for i = 1:aiWidth(1)
                if bIsCCode
                    sSuffixD1 = [sFullName, '[',num2str(i-1),']'];
                else
                    sSuffixD1 = [sFullName, '(',num2str(i),')'];
                end
                casSignals{i} = sSuffixD1;
            end
        else
            if bIsCCode
                casSignals = {[sFullName, '[0]']};
            else
                casSignals = {sFullName};
            end
        end
    end
end
end


%%
function sUsage = i_getLimitedCalUsage(stBlockInfo)
sUsage = '';

sBlockType = stBlockInfo.sBlockKind;
switch lower(sBlockType)
    case 'tl_gain'
        sUsage = 'gain';
        
    case 'tl_constant'
        sUsage = 'const';
        
    case 'tl_saturate'
        switch lower(stBlockInfo.sBlockUsage)
            case 'upperlimit'
                sUsage = 'sat_upper';
                
            case 'lowerlimit'
                sUsage = 'sat_lower';
                
            otherwise
                warning('EP:MODEL_ANA:INTERNAL_ERROR', 'Wrong usage in TL_Saturate block info.');
        end
        
    case 'tl_switch'
        sUsage = 'switch_threshold';
        
    case 'tl_relay'
        switch lower(stBlockInfo.sBlockUsage)
            case 'offoutput'
                sUsage = 'relay_out_off';
                
            case 'onoutput'
                sUsage = 'relay_out_on';
                
            case 'offswitch'
                sUsage = 'relay_switch_off';
                
            case 'onswitch'
                sUsage = 'relay_switch_on';
                
            otherwise
                warning('EP:MODEL_ANA:INTERNAL_ERROR', 'Wrong usage in TL_Relay block info.');
        end
    case 'stateflow'
        sUsage = 'sf_const';
        
    otherwise
        warning('EP:MODEL_ANA:INTERNAL_ERROR', 'Unsupported block kind "%s".', sBlockType);
end
end


%%
function sPath = i_removeModelPrefix(sPath)
sPath = regexprep(sPath, '^([^/]|(//))*/', '');
end


%%
function bIsHidden = i_isHidden(stObject)
bIsHidden = i_getField(stObject, 'bIsHidden', false);
end


%%
function xValue = i_getField(stStruct, sField, xDefaultValue)
if isfield(stStruct, sField)
    xValue = stStruct.(sField);
else
    if (nargin > 2)
        xValue = xDefaultValue;
    else
        xValue = [];
    end
end
end




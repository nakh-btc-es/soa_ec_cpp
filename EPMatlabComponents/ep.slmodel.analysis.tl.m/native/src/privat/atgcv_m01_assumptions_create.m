function atgcv_m01_assumptions_create(stEnv, sModelAnaFile, sAssumpFile)
% Create InterfaceAssumptions from ModelAnalysis and CAL info.
%
%  atgcv_m01_assumptions_create(stEnv, sModelAnaFile, sAssumpFile)
%   INPUT           DESCRIPTION
%     sEnv            (struct)       environment struct
%     sModelAnaFile   (string)       path to ModelAnalysis.xml
%     sAssumpFile     (string)       path to desired output XML file
%                                    following InterfaceAssumptions.dtd
%
%   OUTPUT          DESCRIPTION
%
%   REMARKS
%
%   <et_copyright>

%% internal
%
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 207239 $
%   Last modified: $Date: 2015-12-11 14:14:21 +0100 (Fr, 11 Dez 2015) $
%   $Author: ahornste $
%

hAssRoot = mxx_xmltree('create', 'InterfaceAssumption');

hMaDoc   = mxx_xmltree('load', sModelAnaFile);
ahMaSubs = mxx_xmltree('get_nodes', hMaDoc, '/ma:ModelAnalysis/ma:Subsystem');
astMap = i_getModelRefMap(ahMaSubs);
for i = 1:length(ahMaSubs)
    hMaSub = ahMaSubs(i);
    sSubId = mxx_xmltree('get_attribute', hMaSub, 'id');
    
    ahRestrictions = mxx_xmltree('get_nodes', hMaSub, ...
        './ma:Interface/ma:Input/ma:Calibration/ma:ModelContext[@restriction]');
    nRestr = length(ahRestrictions);
    if (nRestr > 0)   
        hAssSub = mxx_xmltree('add_node', hAssRoot, 'Subsystem');
        mxx_xmltree('set_attribute', hAssSub, 'id', sSubId);
        
        abIsDualRestr = false(1, nRestr);
        for j = 1:nRestr
            hRestr = ahRestrictions(j);            
            sRestr = mxx_xmltree('get_attribute',  hRestr, 'restriction');
            sBlockType = regexprep(sRestr, ':.*$', '');
            if any(strcmpi(sBlockType, {'tl_saturate', 'tl_relay'}))
                abIsDualRestr(j) = true;
            else
                i_addUnaryAssumption(stEnv, hAssSub, hRestr, sRestr);
            end
        end
        ahDualRestrictions = ahRestrictions(abIsDualRestr);
        
        if ~isempty(ahDualRestrictions)
            i_handleDualAssumptions( ...
                stEnv, hAssSub, ahDualRestrictions, astMap);
        end                
    end
end
mxx_xmltree('clear', hMaDoc);

mxx_xmltree('save',  hAssRoot, sAssumpFile);
mxx_xmltree('clear', hAssRoot);
end




%% internal functions


%% i_getModelRefMap
function astMap = i_getModelRefMap(ahSubs)
astMap = repmat(struct( ...
    'sVirtualPath', '', ...
    'sRealPath', ''), 0, 0);
aiVirtPathLen = [];
for i = 1:length(ahSubs)
    hSub = ahSubs(i);
    stModelRef = mxx_xmltree('get_attributes', hSub, ...
        './ma:ModelReference[@kind="TL"]', 'path');
    if ~isempty(stModelRef)
        sVirtPath = mxx_xmltree('get_attribute', hSub, 'tlPath');
        astMap(end + 1) = struct( ...
            'sVirtualPath', sVirtPath, ...
            'sRealPath', stModelRef.path);
        aiVirtPathLen(end + 1) = length(sVirtPath);
    end
end

% now sort the map according to length of virtual path
% the longest at the beginning
if (length(astMap) > 1)
    [aiNotNeeded, aiSortedIdx] = sort(aiVirtPathLen);
    astMap = astMap(aiSortedIdx(end:-1:1));
end
end


%% i_getIfids
function casIfid = i_getIfids(stEnv, hModelContext)
casIfid = {};
astRes = mxx_xmltree('get_attributes', hModelContext, ...
    '../ma:Variable/ma:ifName', 'ifid');
if ~isempty(astRes)
    casIfid = {astRes(:).ifid};
end
end


%% i_getIfidsSmallestIdxFirst
function casIfid = i_getIfidsSmallestIdxFirst(stEnv, hModelContext)

% ASSUMPTION: only one-dim arrays
astRes = mxx_xmltree('get_attributes', hModelContext, ...
    '../ma:Variable/ma:ifName', 'ifid', 'index1');
if isempty(astRes)
    casIfid = {};
else
    nIf = length(astRes);
    if (nIf < 2)
        casIfid = {astRes.ifid};
    else
        % sort according to index1
        aiIndex1 = zeros(1, nIf);
        for i = 1:nIf
            aiIndex1(i) = str2double(astRes(i).index1);
        end
        [aiSortedIndex1, aiSortedIdx] = sort(aiIndex1);
        
        % get all ifid in the same order as the sorted index1
        casIfid = {astRes(aiSortedIdx).ifid};
    end
end
end


%% i_addSlewAssumption
% falling slewrate has to be non-positive double
% rising  slwerate has to be non-negative double
function i_addSlewAssumption(stEnv, hParent, hRestr, sRestr)
hAss = mxx_xmltree('add_node', hParent, 'Assumption');
mxx_xmltree('set_attribute', hAss, 'origin', sRestr);

if strcmpi(sRestr, 'tl_ratelimiter:rslewrate')
    sKind = 'GEQ';
else
    % ASSUMPTION: sRestr == 'tl_ratelimiter:fslewrate'
    sKind = 'LEQ';
end
casIfid = i_getIfids(stEnv, hRestr);
for i = 1:length(casIfid)
    hRel = mxx_xmltree('add_node', hAss, 'ConstRelation');
    mxx_xmltree('set_attribute', hRel, 'kind',       sKind);
    mxx_xmltree('set_attribute', hRel, 'leftIfid',   casIfid{i});
    mxx_xmltree('set_attribute', hRel, 'rightConst', '0.0');
end
end


%% i_addArrayRisingAssumption
% every element in the array has to be greater than the previous element
function i_addArrayRisingAssumption(stEnv, hParent, hRestr, sRestr)

casIfid = i_getIfidsSmallestIdxFirst(stEnv, hRestr);

% check that we have more than one element in array
nIf = length(casIfid);
if (nIf < 2)
    return;
end

hAss = mxx_xmltree('add_node', hParent, 'Assumption');
mxx_xmltree('set_attribute', hAss, 'origin', sRestr);

sKind = 'LES';
for i = 2:nIf    
    hRel = mxx_xmltree('add_node', hAss, 'IntraRelation');
    mxx_xmltree('set_attribute', hRel, 'kind',      sKind);
    mxx_xmltree('set_attribute', hRel, 'leftIfid',  casIfid{i - 1});
    mxx_xmltree('set_attribute', hRel, 'rightIfid', casIfid{i});
end
end


%% i_addUnaryAssumptions
function i_addUnaryAssumption(stEnv, hParent, hRestr, sRestr)
sBlockType = regexprep(sRestr, ':.*$', '');
if strcmpi(sBlockType, 'tl_ratelimiter')
    i_addSlewAssumption(stEnv, hParent, hRestr, sRestr);
else
    i_addArrayRisingAssumption(stEnv, hParent, hRestr, sRestr);
end
end


%% i_addSaturateIntraAssumption
function i_addSaturateIntraAssumption(stEnv, hParent, hRestr1, hRestr2)

sRestr1 = mxx_xmltree('get_attribute', hRestr1, 'restriction');
sRestr2 = mxx_xmltree('get_attribute', hRestr2, 'restriction');

if strcmpi(sRestr1, 'tl_saturate:lowerlimit')
    if ~strcmpi(sRestr2, 'tl_saturate:upperlimit')
        error('ATGCV:MOD_ANA:ERROR', ...
            'Debug: Unexpected restriction "%s" for tl_saturate assumption.', ...
            sRestr2);
    end
    casLowerIfid = i_getIfidsSmallestIdxFirst(stEnv, hRestr1);
    casUpperIfid = i_getIfidsSmallestIdxFirst(stEnv, hRestr2);
else
    if ~strcmpi(sRestr1, 'tl_saturate:upperlimit')
        error('ATGCV:MOD_ANA:ERROR', ...
            'Debug: Unknown restriction "%s" for tl_saturate assumption.', ...
            sRestr1);
    end
    if ~strcmpi(sRestr2, 'tl_saturate:lowerlimit')
        error('ATGCV:MOD_ANA:ERROR', ...
            'Debug: Unexpected restriction "%s" for tl_saturate assumption.', ...
            sRestr2);
    end
    casLowerIfid = i_getIfidsSmallestIdxFirst(stEnv, hRestr2);
    casUpperIfid = i_getIfidsSmallestIdxFirst(stEnv, hRestr1);
end

nIf = length(casLowerIfid);
if (nIf ~= length(casUpperIfid))
    error('ATGCV:MOD_ANA:ERROR', ...
        'Debug: Unexpected difference in length of IF objects (tl_saturate).');
end

hAss = mxx_xmltree('add_node', hParent, 'Assumption');
mxx_xmltree('set_attribute', hAss, 'origin', 'tl_saturate');

for i = 1:nIf
    hRel = mxx_xmltree('add_node', hAss, 'IntraRelation');
    mxx_xmltree('set_attribute', hRel, 'kind',       'LEQ');
    mxx_xmltree('set_attribute', hRel, 'leftIfid',   casLowerIfid{i});
    mxx_xmltree('set_attribute', hRel, 'rightIfid',  casUpperIfid{i});
end
end


%% i_addRelayIntraAssumption
function i_addRelayIntraAssumption(stEnv, hParent, hRestr1, hRestr2)

sRestr1 = mxx_xmltree('get_attribute', hRestr1, 'restriction');
sRestr2 = mxx_xmltree('get_attribute', hRestr2, 'restriction');

if strcmpi(sRestr1, 'tl_relay:offswitch')
    if ~strcmpi(sRestr2, 'tl_relay:onswitch')
        error('ATGCV:MOD_ANA:ERROR', ...
            'Debug: Unexpected restriction "%s" for tl_relay assumption.', ...
            sRestr2);
    end
    casOffIfid = i_getIfidsSmallestIdxFirst(stEnv, hRestr1);
    casOnIfid  = i_getIfidsSmallestIdxFirst(stEnv, hRestr2);
else
    if ~strcmpi(sRestr1, 'tl_relay:onswitch')
        error('ATGCV:MOD_ANA:ERROR', ...
            'Debug: Unknown restriction "%s" for tl_relay assumption.', ...
            sRestr1);
    end
    if ~strcmpi(sRestr2, 'tl_relay:offswitch')
        error('ATGCV:MOD_ANA:ERROR', ...
            'Debug: Unexpected restriction "%s" for tl_relay assumption.', ...
            sRestr2);
    end
    casOffIfid = i_getIfidsSmallestIdxFirst(stEnv, hRestr2);
    casOnIfid  = i_getIfidsSmallestIdxFirst(stEnv, hRestr1);
end

nIf = length(casOffIfid);
if (nIf ~= length(casOnIfid))
    error('ATGCV:MOD_ANA:ERROR', ...
        'Debug: Unexpected difference in length of IF objects (tl_relay).');
end

hAss = mxx_xmltree('add_node', hParent, 'Assumption');
mxx_xmltree('set_attribute', hAss, 'origin', 'tl_relay');

for i = 1:nIf
    hRel = mxx_xmltree('add_node', hAss, 'IntraRelation');
    mxx_xmltree('set_attribute', hRel, 'kind',       'LEQ');
    mxx_xmltree('set_attribute', hRel, 'leftIfid',   casOffIfid{i});
    mxx_xmltree('set_attribute', hRel, 'rightIfid',  casOnIfid{i});
end
end


%% i_addDualAssumption
function i_addDualAssumption(stEnv, hParent, hRestr1, hRestr2)
sRestr1 = mxx_xmltree('get_attribute', hRestr1, 'restriction');
sBlockType = regexprep(sRestr1, ':.*$', '');

if strcmpi(sBlockType, 'tl_saturate')
    i_addSaturateIntraAssumption(stEnv, hParent, hRestr1, hRestr2);
elseif strcmpi(sBlockType, 'tl_relay')
    i_addRelayIntraAssumption(stEnv, hParent, hRestr1, hRestr2);
else
    error('ATGCV:MOD_ANA:ERROR', ...
        'Debug: Unexpected block type "%s" for intra assumption.', ...
        sBlockType);
end
end


%% i_getValueFromModel
function dValue = i_getValueFromModel(stEnv, sBlockPath, sSrcRefName)
dValue = [];
try
    sValExpression = tl_get(sBlockPath, [sSrcRefName, '.value']);
    if ~isempty(sValExpression)
        try
             dValue = tl_resolve(sValExpression, sBlockPath);
        catch
            dValue = evalin('base', sValExpression);
        end
    end
catch
    % do not throw
end
end


%% i_handleIncompleteDualAssumption
function i_handleIncompleteDualAssumption(stEnv, hParent, hRestr, astPathMap)
sRestr     = mxx_xmltree('get_attribute', hRestr, 'restriction');
sBlockPath = mxx_xmltree('get_attribute', hRestr, 'tlPath');
if ~isempty(astPathMap)
    for i = 1:length(astPathMap)
        sMatcher = ['^', regexptranslate('escape', astPathMap(i).sVirtualPath)];
        if ~isempty(regexp(sBlockPath, sMatcher, 'once'))
            sBlockPath = regexprep(sBlockPath, sMatcher, ...
                astPathMap(i).sRealPath);
            break;
        end
    end
end
switch sRestr
    case 'tl_saturate:lowerlimit'
        sKind  = 'LEQ';
        dValue = i_getValueFromModel(stEnv, sBlockPath, 'upperlimit'); 
    case 'tl_saturate:upperlimit'
        sKind  = 'GEQ';
        dValue = i_getValueFromModel(stEnv, sBlockPath, 'lowerlimit'); 
    case 'tl_relay:offswitch'
        sKind  = 'LEQ';
        dValue = i_getValueFromModel(stEnv, sBlockPath, 'onswitch'); 
    case 'tl_relay:onswitch'
        sKind  = 'GEQ';
        dValue = i_getValueFromModel(stEnv, sBlockPath, 'offswitch'); 
    otherwise
        error('ATGCV:MOD_ANA:ERROR', ...
            'Debug: Unexpected restriction "%s" for dual assumption.', ...
            sRestr);
end

casIfid = i_getIfidsSmallestIdxFirst(stEnv, hRestr);
nIf = length(casIfid);
if (nIf ~= length(dValue))
    if (length(dValue) == 1)
        dValue = repmat(dValue, 1, nIf);
    else
        error('ATGCV:MOD_ANA:ERROR', ...
            'Debug: Mismatch in length "%s" "%s" for values in incomplete dual assumption.', ...
            sBlockPath, sRestr);
    end
end
if all(isfinite(dValue))
    hAss = mxx_xmltree('add_node', hParent, 'Assumption');
    mxx_xmltree('set_attribute', hAss, 'origin', sRestr);

    for i = 1:nIf
        hRel = mxx_xmltree('add_node', hAss, 'ConstRelation');
        mxx_xmltree('set_attribute', hRel, 'kind',       sKind);
        mxx_xmltree('set_attribute', hRel, 'leftIfid',   casIfid{i});
        mxx_xmltree('set_attribute', hRel, 'rightConst', ...
            sprintf('%.16e', dValue(i)));
    end
end
end


%% i_handleDualAssumptions
function i_handleDualAssumptions(stEnv, hParent, ahRestr, astPathMap)

% can handle dual assumptions only pairwise
nRestr = length(ahRestr);
if (nRestr < 2)
    ahNotHandled = ahRestr;
else
    casBlocks = cell(1, nRestr);
    for i = 1:nRestr
        casBlocks{i} = mxx_xmltree('get_attribute', ahRestr(i), 'tlPath');
    end
    [casBlocks, aiSortIdx] = sort(casBlocks);
    ahRestr = ahRestr(aiSortIdx);

    abIsIncomplete = false(1, nRestr);
    iLoop = 1;
    while (iLoop <= nRestr)
        sCurrent = casBlocks{iLoop};
        if (iLoop < nRestr)
            sNext = casBlocks{iLoop + 1};
            if strcmp(sCurrent, sNext)
                i_addDualAssumption(stEnv, hParent, ahRestr(iLoop), ...
                    ahRestr(iLoop + 1));
                iLoop = iLoop + 2;
            else
                abIsIncomplete(iLoop) = true;
                iLoop = iLoop + 1;
            end
        else
            abIsIncomplete(iLoop) = true;
            iLoop = iLoop + 1;
        end
    end
    ahNotHandled = ahRestr(abIsIncomplete);
end

for i = 1:length(ahNotHandled)
    i_handleIncompleteDualAssumption(...
        stEnv, hParent, ahNotHandled(i), astPathMap);
end
end

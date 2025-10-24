function stInfo = atgcv_m01_block_variable_info_get(stEnv, hBlockVar, bWithParamInfo)
% Get info about block_variable.
%
% function stInfo = atgcv_m01_blockvariable_info_get(stEnv, hBlockVar, bWithParamInfo)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)  error messenger environment
%     hBlockVar         (handle)  DD handle of block variable
%     bWithParamInfo    (bool)    optional: read out also Parameter properties (sParamValue, sRestriction)
%                                 (default ==> false)
%   
%
%   OUTPUT              DESCRIPTION
%      stInfo           (struct)   struct with following data
%        .hBlockVar      (handle)     DD handle of BlockVariable
%        .sSignalName    (string)     signal name for block (if any)
%        .hVariableRef   (handle)     reference to variable in C-code
%        .hBlock         (handle)     handle of corresponding block
%        .sTlPath        (string)     TL model path to block
%        .sBlockKind     (string)     TL block kind (often == MaskType)
%        .sBlockType     (string)     SL block type
%        .sBlockUsage    (string)     usage of variable inside the block
%        .stSfInfo       (struct)     struct with additional Stateflow info ---> atgcv_m01_sfblock_variable_info_get
%                                     (non-empty only for sBlockKind=="Stateflow")
%        .sParamValue    (string)     Matlab value inside the Block mask (empty if not available/set)
%                                     Note: only set if bWithParamInfo == true
%        .sRestriction   (string)     restriction ID for block variable (empty if not restricted)
%                                     Note: only set if bWithParamInfo == true
%


%% default output
stInfo = struct( ...
    'hBlockVar',        [], ...
    'sSignalName',      '', ...
    'hVariableRef',     [], ...
    'hBlock',           [],  ...
    'sTlPath',          '', ...
    'sBlockKind',       '', ...
    'sBlockType',       '', ...
    'sBlockUsage',      '', ...
    'stSfInfo',         [], ...
    'sParamValue',      '', ...
    'sRestriction',     '', ...
    'sConstraintKind',  '', ...
    'xConstraintVal',   []);

%% check inputs
% handle optional inputs
if (nargin < 3)
    bWithParamInfo = false;
end

% normalize block variable to handle
if ischar(hBlockVar)
    hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDObject');
end

% get info only for BlockVariable
sObjectKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'objectKind');
if ~strcmpi(sObjectKind, 'BlockVariable')
    % ??? issue warning here ???
    return;
end

%% info for block variable
stInfo.hBlockVar   = hBlockVar;
stInfo.sSignalName = i_getFullSignalName(stEnv, hBlockVar);
if dsdd('Exist', hBlockVar, 'property', {'name', 'VariableRef'})
    stInfo.hVariableRef = atgcv_mxx_dsdd(stEnv, 'GetVariableRef', hBlockVar);
end

%% info for block
[hBlock, sBlockKind] = i_getBlock(stEnv, hBlockVar);
stInfo.hBlock        = hBlock;
stInfo.sTlPath       = dsdd_get_block_path(hBlock);
stInfo.sBlockKind    = sBlockKind;
stInfo.sBlockType    = get_param(stInfo.sTlPath, 'BlockType');

%% additional info for Parameters
if strcmpi(sBlockKind, 'TL_DataStoreMemory')
    % special case: DataStore Memory
    stInfo.sBlockUsage = 'output';
    
    if bWithParamInfo
        stInfo.sParamValue = i_getOutputInitial(stInfo.sTlPath);
    end
    
elseif any(strcmpi(sBlockKind, {'Stateflow', 'MATLABFunction'}))
    stInfo.stSfInfo = atgcv_m01_sfblock_variable_info_get(stEnv, hBlockVar);
    
    if i_isValid(stInfo.stSfInfo)
        stInfo.sBlockUsage = ['sf_', lower(stInfo.stSfInfo.sSfScope)];

        if bWithParamInfo
            if strcmpi(stInfo.stSfInfo.sSfScope, 'Parameter')
                % SF parameter
                stInfo.sParamValue = stInfo.stSfInfo.sSfName;
            else
                % SF const
                stInfo.sParamValue = stInfo.stSfInfo.sInitValue;
            end
        end
    end
    
else
    sBlockUsage = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'name');
    [sBlockUsage, iUsageIdx] = i_getRemappedUsage(sBlockKind, sBlockUsage);

    stInfo.sBlockUsage = sBlockUsage;
    
    if bWithParamInfo
        stInfo.sParamValue = i_getParamValue(stInfo.sTlPath, sBlockUsage, iUsageIdx);

        % check for restrictions only for non-SF blocks and also not for TL_DataStoreMemory (there are none)
        stInfo.sRestriction = i_getRestriction(sBlockKind, sBlockUsage);
    end
end
[stInfo.xConstraintVal, stInfo.sConstraintKind] = i_getUnaryConstraint(stInfo.sTlPath, stInfo.sRestriction);
end


%%
function bIsValid = i_isValid(stSfInfo)
bIsValid = ~isempty(stSfInfo.sSfName);
end


%%
function [xValue, sKind] = i_getUnaryConstraint(sBlockPath, sRestriction)
xValue = [];
sKind  = '';
switch sRestriction
    case 'tl_saturate:lowerlimit'
        sKind  = 'leq';
        xValue = i_getConstraintValueFromModel(sBlockPath, 'upperlimit');
    case 'tl_saturate:upperlimit'
        sKind  = 'geq';
        xValue = i_getConstraintValueFromModel(sBlockPath, 'lowerlimit');
    case 'tl_relay:offswitch'
        sKind  = 'leq';
        xValue = i_getConstraintValueFromModel(sBlockPath, 'onswitch');
    case 'tl_relay:onswitch'
        sKind  = 'geq';
        xValue = i_getConstraintValueFromModel(sBlockPath, 'offswitch');
        
    otherwise
        % nothing to do
end
end


%%
function xValue = i_getConstraintValueFromModel(sBlockPath, sSrcRefName)
xValue = [];
try
    sValExpression = tl_get(sBlockPath, [sSrcRefName, '.value']);
    if ~isempty(sValExpression)
        try
             xValue = tl_resolve(sValExpression, sBlockPath);
        catch %#ok<CTCH>
             xValue = evalin('base', sValExpression);
        end
    end
catch oEx
    % do not throw
end
end


%%
function [sParamValue, iUsageIdx] = i_getParamValue(sModelPath, sBlockUsage, iUsageIdx)
sParamValue = '';
bIsTl = ds_isa(sModelPath, 'tlblock');
if bIsTl
    try
        stTlcg = get_tlcg_data(sModelPath);
        bFound = isfield(stTlcg, sBlockUsage);
%         if ~bFound
%             if strcmpi(sBlockUsage, 'coefficients')
%                 [sBlockUsage, iUsageIdx] = ...
%                     i_translateCoeffBlockUsage(sModelPath, stTlcg, iUsageIdx);
%                 bFound = isfield(stTlcg, sBlockUsage);
%             end
%         end
        
        if bFound
            astUsage = stTlcg.(sBlockUsage);
            if (length(astUsage) > 1)
                if (length(astUsage) <= iUsageIdx)
                    astUsage = astUsage(iUsageIdx);
                    iUsageIdx = 1;
                else
                    % actually the Else-case is an INTERNAL_ERROR:
                    % the UsageIdx is out-of-bounds --> idicates an error in
                    % the MappingFunction DD<-->Model
                    % TODO: maybe throw an exception here?                    
                end
            end
            
            if isfield(astUsage(1), 'value')
                sParamValue = astUsage(1).value;
            end
        end
    catch
    end
end
end


%%
% matching of coefficients (DD) and Num/Denom (Model):
%
% [coefficients, coefficients(#1), ..., coefficients(#end-1), coefficients(#end)]
% 
% [Denom(2), ..., Denom(end), Num(2), ..., Num(end), Num(1), Denom(1)]
%
% function [sBlockUsage, iUsageIdx] = i_translateCoeffBlockUsage(sModelPath, stTlcg, iUsageIdx)
% % get number of numerator and denominator elements
% nNum = numel(tl_resolve(stTlcg.num.value, sModelPath));
% nDenom = numel(tl_resolve(stTlcg.denom.value, sModelPath));
% 
% if (iUsageIdx == (nNum + nDenom))
%     % 'coefficients(#end)' is denominator (denom(1));
%     sBlockUsage = 'denom';
%     iUsageIdx = 1;
% 
% elseif (iUsageIdx < nDenom) && (nDenom > 1)
%     % 'coefficients' ... 'coefficients(#nDenom-1)' is denominator
%     % (denom(2)...denom(end))
%     sBlockUsage = 'denom';
%     iUsageIdx = iUsageIdx + 1;
% 
% elseif (iUsageIdx == (nNum + nDenom - 1))
%     % 'coefficients(#end-1) is numerator (num(1));
%     sBlockUsage = 'num';
%     iUsageIdx = 1;
% 
% else
%     %num(2)...num(end)
%     sBlockUsage = 'num';
%     iUsageIdx = iUsageIdx - (nDenom - 1) + 1;
% end
% end


%%
function sParamValue = i_getOutputInitial(sModelPath)
sParamValue = '';
bIsTl = ds_isa(sModelPath, 'tlblock');
if bIsTl
    try
        stTlcg = get_tlcg_data(sModelPath);
        if isfield(stTlcg, 'output')
            astUsage = stTlcg.output;
            if isfield(astUsage(1), 'initial')
                sParamValue = astUsage(1).initial;
            end
        end
    catch
    end
end
end


%%
function [hBlock, sBlockType] = i_getBlock(stEnv, hBlockVar)
while strcmpi(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'objectKind'), 'BlockVariable')
    hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDParent');
end
% kind should be Block here!
hBlock = hBlockVar;
sBlockType = atgcv_mxx_dsdd(stEnv, 'GetBlockType', hBlock);
end


%%
function sSignalName = i_getSignalName(stEnv, hBlockVar)
if dsdd('Exist', hBlockVar, 'property', {'name', 'SignalName'})
    sSignalName = atgcv_mxx_dsdd(stEnv, 'GetSignalName', hBlockVar);
else
    sSignalName = '';
end
end


%%
function sFullSignalName = i_getFullSignalName(stEnv, hBlockVar)
sFullSignalName = '';
while strcmpi(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'objectKind'), 'BlockVariable')
    sSignalName = i_getSignalName(stEnv, hBlockVar);
    if (isempty(sSignalName) && isempty(sFullSignalName))
        return;
    else
        if isempty(sFullSignalName)
            sFullSignalName = sSignalName;
        else
            sFullSignalName = [sSignalName, '.', sFullSignalName]; %#ok<AGROW>
        end
    end
    hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDParent');
end
end


%%
function sRestriction = i_getRestriction(sBlockKind, sBlockUsage)
persistent jKnownSet;

if isempty(jKnownSet)
    jKnownSet = i_initKnownRestrictions();
end

% 0) assume we have _no_ restriction
sRestriction = '';

% 1) check if block-kind is even a candidate for restricted usage
if jKnownSet.contains(lower(sBlockKind))
    % 2) now check specifically if the block-usage is restricted
    sPossibleRestriction = lower([sBlockKind, ':', sBlockUsage]); 
    if jKnownSet.contains(sPossibleRestriction)
        sRestriction = sPossibleRestriction;
    end
end
end


%%
function jSet = i_initKnownRestrictions()
jSet = java.util.HashSet(17);

% blocks with restrictions
jSet.add('tl_saturate');
jSet.add('tl_ratelimiter');
jSet.add('tl_relay');
jSet.add('tl_indexsearch');
jSet.add('tl_lookup1d');
jSet.add('tl_lookup2d');

% block-usages with restrictions
jSet.add('tl_saturate:upperlimit');
jSet.add('tl_saturate:lowerlimit');
jSet.add('tl_ratelimiter:rslewrate');
jSet.add('tl_ratelimiter:fslewrate');
jSet.add('tl_relay:onswitch');
jSet.add('tl_relay:offswitch');
jSet.add('tl_indexsearch:input');
jSet.add('tl_lookup1d:input');
jSet.add('tl_lookup2d:col');
jSet.add('tl_lookup2d:row');
end


%%
function [sUsage, iIdx] = i_getRemappedUsage(sBlockKind, sBlockUsage)
persistent jMap;

if isempty(jMap)
    jMap = i_initUsageMap();
end

sUsage = lower(sBlockUsage);
if sUsage(end) == ')'
    casParse = regexp(sUsage, '^([^\(]+)\(#(\d+)\)$', 'tokens', 'once');
    if ~isempty(casParse)
        sUsage = casParse{1};
        iIdx   = str2double(casParse{2});
    end
else
    iIdx = 1;
end

% special case: axis, axis_pts_x and axis_pts_y are mapped on different Usages
% depending on BlockKind
% --> filter out special case TL_Lookup2D
if strcmpi(sBlockKind, 'TL_Lookup2D')
    if strcmpi(sUsage, 'axis')
        if (iIdx < 2)
            sUsage = 'row';
        else
            % sBlockUsage == 'axis(#2)'
            sUsage = 'col';
            iIdx = 1;
        end
    elseif strcmpi(sUsage, 'axis_pts_x') % TL2.3
            sUsage = 'row';
    elseif strcmpi(sUsage, 'axis_pts_y') % TL2.3
            sUsage = 'col';
    end
end

sMappedUsage = char(jMap.get(sUsage));
if ~isempty(sMappedUsage)
    sUsage = sMappedUsage;
end
end


%%
function jMap = i_initUsageMap()
jMap = java.util.HashMap(13);

% TL_Ratelimiter
% funny bug in DD: rslwerate instead of rslewrate and 
% fslwerate instead of fslewrate (Rising/Falling Slew Rate)
jMap.put('rslwerate', 'rslewrate'); 
jMap.put('fslwerate', 'fslewrate'); 

% TL_IndexSearch, TL_Lookup1D
jMap.put('axis_pts_x', 'input');  % TL2.3
jMap.put('axis',       'input'); 

% TL_Lookup1D, TL_Lookup2D, TL_Interpolation
jMap.put('fnc_values', 'table');  % TL2.3

% TL_LookupNDDirect
jMap.put('tableparameter', 'table'); 

% TL_DiscreteTransferFcn
jMap.put('denom_i', 'denom'); 
end



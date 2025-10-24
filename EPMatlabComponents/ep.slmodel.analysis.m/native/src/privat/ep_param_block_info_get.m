function astBlockInfos = ep_param_block_info_get(xVar, casBlocks, sVirtualParent)
% Get info about the usage(s) of a variable inside a provided list of blocks.
%
% function astBlockInfos = ep_param_block_info_get(sVarName, casBlocks, sVirtualParent)
%
%   INPUT               DESCRIPTION
%     xVar              (string/struct)  name of the ML/SL variable or a struct with the fields
%                                        (.sRawName, .sSource, .sSourceType)
%     casBlocks         (cell)           block paths of the blocks where the usage will be evaluated
%     sVirtualParent    (string)         optional: if provided, this path will replace the model name inside the block
%                                        path whenever the virtual path of the block is requested 
%
%   OUTPUT              DESCRIPTION
%      astBlockInfos    (array)    array of structures, each containing the following fields
%        .sPath          (string)     real model path of the block
%        .sVirtualPath   (string)     virtual model path of the block (needed in context of model references)
%        .sBlockKind     (string)     block kind ( == get_param(<block>, 'MaskType')
%        .sBlockType     (string)     block kind ( == get_param(<block>, 'BlockType')
%        .stUsage        (struct)     the usage of the variable inside this particular block
%           .(<usage>)   (string)     note1: the usage is encoded in the name of the field while the usage expression
%                                     is held inside the value of this field
%                                     note2: there can be multiple fields/usages of a variable inside one block
%        .stConstraint   (struct)     the constraint that is induced on the variable by this particular usage
%           .sName       (string)     enum string: currently only "increasing" is supported
%           .sOrigin     (string)     the block usage that induces the constraint
%
%  NOTE: The "stConstraint" field of the return value(s) is currently only a preliminary solution that is adequate for
%  the current support of constraints. When more complex constraints will be supported, it may not be adequate anymore
%  and needs to be extended.



%%
if (nargin < 3)
    sVirtualParent = '';
end
casBlocks = cellstr(casBlocks);

stVar = i_normalizeVar(xVar);

astBlockInfos = i_getInfos(stVar, casBlocks, sVirtualParent);
astBlockInfos = i_splitMultiUsageIntoSeparateInfos(astBlockInfos);
for i = 1:numel(astBlockInfos)
    astBlockInfos(i).oConstraint = i_getConstraint(astBlockInfos(i));
end
end


%%
function stVar = i_normalizeVar(xVar)
if ischar(xVar)
    stVar = struct( ...
        'sName',       xVar, ...
        'sSource',     '', ...
        'sSourceType', '');
    
elseif isstruct(xVar)
    stVar = struct( ...
        'sName',        xVar.sRawName, ...
        'sSource',      xVar.sSource, ...
        'sSourceType',  xVar.sSourceType);

else
    error('EP:ANALYSIS:WRONG_USAGE', 'Unexpected variable class for xVar: %s', class(xVar));
end 
end


%%
function astBlockInfos = i_getInfos(stVar, casBlocks, sVirtualParent)
astBlockInfos = struct( ...
    'sPath',        reshape(casBlocks, 1, []), ...
    'sVirtualPath', '', ...
    'sBlockKind',   '', ...
    'sBlockType',   '', ...
    'stUsage',      [], ...
    'oConstraint',  []);

aiIgnoredBlocksIdx = [];
for i = 1:length(casBlocks)
    sBlock = casBlocks{i};
    
    % skip blocks that are not blocks (e.g. block_diagram)
    if ~strcmp(get_param(sBlock, 'type'), 'block')
        aiIgnoredBlocksIdx(end + 1) = i; %#ok<AGROW>
        continue;
    end
    
    sVirtualPath = i_getVirtualPath(sVirtualParent, sBlock);
   
    astBlockInfos(i).sBlockKind = get_param(sBlock, 'MaskType');
    astBlockInfos(i).sBlockType = get_param(sBlock, 'BlockType');    
    if strcmpi(astBlockInfos(i).sBlockType, 'ModelReference')
        if i_isDirectlyUsedInModelReferenceBlock(stVar, sBlock)
            astBlockInfos(i).sVirtualPath = sVirtualPath;
            bDoDemask = false;
            casIgnoreUsages = {'ParameterArgumentNames'};
            astBlockInfos(i).stUsage = i_findVariableInBlock(stVar.sName, sBlock, bDoDemask, casIgnoreUsages);            
        else
            % if the parameter is not used directly inside the model refrence block, we need to look deeper inside the
            % reference model --> in this case the reference block itself needs to be ignored
            aiIgnoredBlocksIdx(end + 1) = i; %#ok<AGROW>
            
            if strcmp(get_param(sBlock, 'ProtectedModel'), 'on')
                % do nothing for protected references
            else
                sReferencedModel = get_param(sBlock, 'ModelName');
                bSearchInModelRefs = false;
                aoVarUsages = i_findVarUsagesInModelContext(stVar, sReferencedModel, bSearchInModelRefs);
                if (numel(aoVarUsages) == 1)
                    astRefBlockInfos = i_getInfos(stVar, aoVarUsages.UsedByBlocks, sVirtualPath);
                    astBlockInfos = [astBlockInfos, astRefBlockInfos]; %#ok<AGROW>
                end
            end
        end        
    else
        astBlockInfos(i).sVirtualPath = sVirtualPath;
        if i_isStateflow(sBlock, astBlockInfos(i).sBlockType)
            astBlockInfos(i).stUsage = i_findVariableInChart(stVar.sName, sBlock);
        else
            bDoDemask = true;
            if strcmpi(astBlockInfos(i).sBlockType, 'S-Function')
                bDoDemask = false;
            elseif i_isPredefinedSimulinkBlock(sBlock)
                bDoDemask = false;
            end
            astBlockInfos(i).stUsage = i_findVariableInBlock(stVar.sName, sBlock, bDoDemask);
        end
    end
end
astBlockInfos(aiIgnoredBlocksIdx) = [];
end


%%
function bIsDirectlyUsed = i_isDirectlyUsedInModelReferenceBlock(stVar, sBlock)
bIsDirectlyUsed = false;

try %#ok<TRYNC>
    bSearchInModelRefs = true;
    aoUsages = i_findVarUsagesInModelContext(stVar, sBlock, bSearchInModelRefs);
    for i = 1:numel(aoUsages)
        if any(strcmp(sBlock, aoUsages(i).Users))
            bIsDirectlyUsed = true;
            return;
        end
    end
end
end


%%
function aoUsages = i_findVarUsagesInModelContext(stVar, sModelContext, bSearchInModelRefs)
casAddFilterArgs = {};
if strcmp(stVar.sSourceType, 'model workspace')
    casAddFilterArgs = horzcat(casAddFilterArgs, { ...
        'SourceType', stVar.sSourceType, ...
        'Source',     stVar.sSource});
end
if bSearchInModelRefs
    casAddFilterArgs = horzcat(casAddFilterArgs, { ...
        'SearchReferencedModels', 'on'});
end
aoUsages = Simulink.findVars(sModelContext, ...
    'Name',          stVar.sName, ...
    'SearchMethod',  'cached', ...
    casAddFilterArgs{:});
end


%%
% if a variable is used in different places of a block, split these usages into seperate block infos
function astBlockInfos = i_splitMultiUsageIntoSeparateInfos(astBlockInfos)
if isempty(astBlockInfos)
    return;
end

nInfos = length(astBlockInfos);
abReplaced = false(size(astBlockInfos));
for i = 1:nInfos
    stUsage = astBlockInfos(i).stUsage;
    casFields = fieldnames(stUsage);
    nFields = length(casFields);
    if (nFields > 1)
        astNewBlockInfo = repmat(astBlockInfos(i), 1, nFields);
        for k = 1:nFields
            stSplitUsage = struct( ...
                casFields{k}, stUsage.(casFields{k}));
            astNewBlockInfo(k).stUsage = stSplitUsage;
        end
        astBlockInfos = [astBlockInfos, astNewBlockInfo]; %#ok<AGROW>
        abReplaced(i) = true;
    end
end
astBlockInfos(abReplaced) = [];
end


%%
function bIsSF = i_isStateflow(sBlockPath, sBlockType)
bIsSF = strcmpi(sBlockType, 'SubSystem') && atgcv_sl_block_isa(sBlockPath, 'Stateflow');
end


%%
function bIsPredefSL = i_isPredefinedSimulinkBlock(xBlock)
bIsPredefSL = false;
try
    if strcmpi(get_param(xBlock, 'Mask'), 'on') 
        sRefBlock = get_param(xBlock, 'ReferenceBlock');
        if (~isempty(sRefBlock) && strncmpi(sRefBlock, 'simulink', 8))
            bIsPredefSL = true;
        end
    end
catch %#ok<CTCH>
    % just ignore for now
end
end


%%
function stUsage = i_findVariableInChart(sVarName, sBlock)
stUsage = struct();

hRoot  = sfroot;
hSfVar = hRoot.find( ...
    '-isa', 'Stateflow.Data', ...
    'Path',  sBlock, ...
    'Name',  sVarName);

% sometimes problems with newline --> replace with blank
if isempty(hSfVar)
    sBlock = regexprep(sBlock, '\n', ' ');
    hSfVar = hRoot.find( ...
        '-isa', 'Stateflow.Data', ...
        'Path',  sBlock, ...
        'Name',  sVarName);
end

if ~isempty(hSfVar)
    sScope = strrep(hSfVar.Scope, ' ', ''); % take care of "Data Store Memory" by replacing spaces
    if ~isempty(sScope)
        stUsage.(sScope) = sVarName;
    end
else
    % ! TODO replace Workaround: if Param is not found, assume a Const with InitValue set to VarName
    stUsage.Constant = sVarName;
end
end


%%
function sVirtualPath = i_getVirtualPath(sVirtualParent, sBlock)
if isempty(sVirtualParent)
    sVirtualPath = sBlock;
else
    [~, sRelBlock] = strtok(sBlock, '/');
    sVirtualPath = [sVirtualParent, sRelBlock];
end
end


%%
function stUsage = i_findVariableInBlock(sVarName, sBlockPath, bDoDemask, casIgnoreUsages)
if (nargin < 4)
    casIgnoreUsages = {};
end

stUsage = struct();
if (isempty(sVarName) || isempty(sBlockPath))
    return;
end

sPattern = ['\<', sVarName, '\>'];
stParams = i_getBlockDialogParameters(sBlockPath, bDoDemask);
casNames = fieldnames(stParams);
if ~isempty(casIgnoreUsages)
    casNames = setdiff(casNames, casIgnoreUsages);
end
for i = 1:length(casNames)
    sName = casNames{i};
    if (bDoDemask && strcmpi(sName, 'data'))
        % do not use TL Info from the "data" Property
        continue;
    end
    if strcmp(stParams.(sName).Type, 'string')
        if strcmp(sName, 'ModelName') && strcmp(get_param(sBlockPath, 'ProtectedModel'), 'on')
            [~, sExpr, ~] = fileparts(get_param(sBlockPath, 'ModelFile'));
        else
            sExpr = get_param(sBlockPath, sName);
        end
        if ~isempty(regexp(sExpr, sPattern, 'once'))
            stUsage.(sName) = sExpr;
        end
    end
end
if isempty(fieldnames(stUsage)) && strcmp(get_param(sBlockPath, 'BlockType'), 'SubSystem')
    sParamName = 'CompiledActiveChoiceControl';
    try
        sParamValue = get_param(sBlockPath, sParamName);
    catch
        sParamValue = [];
    end
    if ~isempty(sParamValue) && ~isempty(regexp(sParamValue, '==', 'once'))
        stUsage.(sParamName) = sParamValue;
    end
end
end


%%
function stParams = i_getBlockDialogParameters(sBlockPath, bDoDemask)
if bDoDemask
    stParams = get_param(sBlockPath, 'IntrinsicDialogParameters');
else
    stParams = get_param(sBlockPath, 'DialogParameters');
end
if ~isstruct(stParams)
    stParams = struct();
end
end


%%
function oConstraint = i_getConstraint(stBlockInfo)
casUsages = fieldnames(stBlockInfo.stUsage);
if isempty(casUsages)
    sUsage = '';
else
    sUsage = casUsages{1}; % assuming that we have only one single usage since they have been split apart
end
oConstraint = ep_sl.ParamConstraint.getForBlockProperty(stBlockInfo.sPath, sUsage);
end


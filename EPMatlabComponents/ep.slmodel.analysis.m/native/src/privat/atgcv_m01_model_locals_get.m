function astLocals = atgcv_m01_model_locals_get(~, stOpt)
% Returns the Locals of a Simulink model.
%
% function astLocals = atgcv_m01_model_locals_get(stEnv, stOpt)
%
%   INPUT               DESCRIPTION
%       stEnv              (struct)  Environment with Messenger handle
%       stOpt              (struct)  Options:
%         .sModelContext   (string)    either model name or block path
%
%   OUTPUT              DESCRIPTION
%       astLocals          (array)   structs with following info:
%         .sName           (string)    name of the Local's block
%         .sClass          (string)    class of the Local's block
%         .sPath           (string)    real model path of the Local's block
%         .sVirtualPath    (string)    the virtual model path of the Local's block
%                                      (Note: differs from the real path for blocks in referenced models)
%         .sSfRelPath      (string)    the relative subpath for Locals in SF-Charts
%         .aiPorts         (array)     port numbers of the Local's block that represent the Local signal
%                                      inside the model
%   REMARKS
%     Provided Model is assumed to be open.
%


%% check/set inputs
if (nargin < 2)
    stOpt = struct();
end
stOpt = i_checkSetOptions(stOpt);
astLocals = i_findLocals(stOpt);
if (numel(astLocals) > 1)
    astLocals = i_removeDuplicates(astLocals);
end

% Note: currently there is a limitation that nested SF locals are not supported --> filter them out
astLocals(arrayfun(@i_isNestedSfLocal, astLocals)) = [];
end


%%
function bIsNestedSfLocal = i_isNestedSfLocal(stLocal)
bIsNestedSfLocal = ~isempty(stLocal.sSfRelPath);
end


%%
function astLocals = i_removeDuplicates(astLocals)
aiDuplicatePos = [];
xMap = containers.Map();
for i = 1:length(astLocals)
    if numel(astLocals(i).aiPorts) > 1
        continue;
    end
    sKey = i_getUniqueKeyForLocal(astLocals(i));
    if isKey(xMap, sKey)
        aiDuplicatePos(end + 1) = i; %#ok<AGROW>
    else
        xMap(sKey) = true;
    end
end
astLocals(aiDuplicatePos) = [];
end


%%
function sKey = i_getUniqueKeyForLocal(stLocal)
sKey = sprintf('[%s] -:- [%d%s/%s]', stLocal.sVirtualPath, stLocal.aiPorts, stLocal.sSfRelPath, stLocal.sName);
end


%%
function stOpt = i_checkSetOptions(stOpt)
if (~isfield(stOpt, 'sModelContext') || isempty(stOpt.sModelContext))
    stOpt.sModelContext = bdroot(gcs());
else
    try
        get_param(stOpt.sModelContext, 'name');
    catch oEx
        error('ATGCV:MOD_ANA:ERROR', 'Model context "%s" is not available.\n%s', stOpt.sModelContext, oEx.message);
    end
end
end


%%
function astLocals = i_findLocals(stOpt)
astLocals = [ ...
    i_findLocalsOfThisModel(stOpt.sModelContext), ...
    i_findLocalsOfReferencedModels(stOpt.sModelContext)];
end


%%
function astLocals = i_findLocalsOfThisModel(xModelContext)
astLocals = [ ...
    i_findLocalsByTestPoint(xModelContext), ...
    i_findLocalsByDescription(xModelContext)] ;
end


%%
function astLocals = i_findLocalsByTestPoint(xModelContext)
ahLines = ep_find_system(xModelContext, ...
    'FindAll',        'on', ...
    'FollowLinks',    'on', ...
    'LookUnderMasks', 'all', ...
    'Type',           'line');

if ~isempty(ahLines) 
    % If the model contains just one line (an input connected to an output), get(ahLines, 'TestPoint')
    % will return 0 which is not a cell
    xTestPoint = get(ahLines, 'TestPoint');
    if ~iscell(xTestPoint)
        xTestPoint = {xTestPoint};
    end
    ahLines = ahLines(cell2mat(xTestPoint));
end
astLocals = [ ...
    reshape(i_getLocalsInfoFromSourceBlock(ahLines), 1, []), ...
    reshape(i_getLocalsFromCharts(xModelContext), 1, [])];
end


%%
function astLocals = i_getLocalsFromCharts(xModelContext)
astLocals = repmat(i_createLocal(), 1, 0);

if ischar(xModelContext)
    xModelContext = get_param(xModelContext, 'handle');
end
ahSfBlocks = ep_find_system(xModelContext, ...
    'FollowLinks',    'on', ...
    'LookUnderMasks', 'all', ...
    'MaskType',       'Stateflow');

for i = 1:numel(ahSfBlocks)
    hSfBlock = ahSfBlocks(i);
    sSfBlockPath = getfullname(hSfBlock);
    
    oSfBlock = atgcv_m01_sf_block_object_get(hSfBlock);
    if ~isempty(oSfBlock)
        aoObservableLocals = oSfBlock.find( ...
            '-isa',      'Stateflow.Data', ...
            'Scope',     'Local', ...
            'TestPoint', true);
        for k = 1:numel(aoObservableLocals)
            astLocals(end + 1) = i_createLocalForSfLocal(aoObservableLocals(k), sSfBlockPath); %#ok<AGROW>
        end
    end
end
end


%%
function astLocals = i_findLocalsByDescription(xModelContext)
if ischar(xModelContext)
    xModelContext = get_param(xModelContext, 'handle');
end
ahBlocks = ep_find_system(xModelContext, ...
    'FollowLinks',    'on', ...
    'LookUnderMasks', 'all', ...
    'Regexp',         'on', ...
    'Description',    'EV_DISP');
astLocals = i_getLocalsInfoFromBlockDescr(ahBlocks);
end


%%
function astLocals = i_getLocalsInfoFromBlockDescr(ahBlocks)
astLocals = repmat(i_createLocal(), 1, 0);
if ~isempty(ahBlocks)
    ahBlocks = reshape(ahBlocks, 1, []);
    astLocals = cell2mat(arrayfun(@(hBlock) i_createLocalsFromBlockDescr(hBlock), ahBlocks, 'UniformOutput', false));
end
end


%%
function astLocals = i_createLocalsFromBlockDescr(hBlock)
aiVisibleOutports = i_getVisibleOutports(hBlock);
if isempty(aiVisibleOutports)
    astLocals = repmat(i_createLocal(), 1, 0);
else
    astLocals = i_createLocalsForBlock(hBlock, aiVisibleOutports);
end
end


%%
function aiOutports = i_getVisibleOutports(hBlock)
nOutports = 0;
try %#ok<TRYNC>
    stPortHandles = get_param(hBlock, 'PortHandles');
    nOutports = length(stPortHandles.Outport);
end
sDescription = '';
try %#ok<TRYNC>
    sDescription = get_param(hBlock, 'Description');
end

sDispKeyword = 'EV_DISP';
sRegularExpr = [sDispKeyword, '(\[([0-9]+[ ,]*)*\])?'];

%  search the first DISP entry
[aStartPositions, aEndPositions] = regexp(sDescription, sRegularExpr, 'once');

aiOutports = [];
if ~isempty(aStartPositions)
    %  parse selected outport numbers
    iStartVector = aStartPositions(1) + length(sDispKeyword);
    iEndVector   = aEndPositions(1);
    
    %  check for array of outport numbers
    if (iEndVector - iStartVector) > 1
        %  yes, we have selected outport numbers
        try %#ok<TRYNC>
            sIndices = sDescription(iStartVector:iEndVector);
            aiOutports = eval(sIndices);
        end
    end
    
    %  normalize outport vector
    aiOutports = i_normalizeOutputNumbers(aiOutports, nOutports);
end
end


%%
function aiOutports = i_normalizeOutputNumbers(aiOutports, nOutports)
if isempty(aiOutports)
    aiOutports = 1:nOutports;
else
    aiOutports(aiOutports < 1) = [];
    aiOutports(aiOutports > nOutports) = [];
    aiOutports = sort(unique(aiOutports));
end
end


%%
function astLocals = i_findLocalsOfReferencedModels(xModelContext)
xModelContext = bdroot(xModelContext);
[casRefModels, casRefBlocks] = ep_find_mdlrefs(xModelContext, 'AllLevels', false);

astLocals = repmat(i_createLocal(), 1, 0);
if ~isempty(casRefBlocks)
    xModelLocalsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for i = 1:(length(casRefModels) - 1) % last refModel is this model itself
        sRefModel = casRefModels{i};
        stOpt = struct( ...
            'sModelContext', sRefModel);
        xModelLocalsMap(sRefModel) = atgcv_m01_model_locals_get(0, stOpt);
    end
    for i = 1:length(casRefBlocks)
        sRefBlock = casRefBlocks{i};
        if strcmp(get_param(sRefBlock, 'ProtectedModel'), 'on')
            %do not search any further within protected model reference
        else
            sRefModel = get_param(sRefBlock, 'ModelName');
            if xModelLocalsMap.isKey(sRefModel)
                astLocals = [astLocals, i_adaptVirtualPath(xModelLocalsMap(sRefModel), sRefModel, sRefBlock)]; %#ok<AGROW>
            end
        end
    end
end
end


%%
function astLocals = i_adaptVirtualPath(astLocals, sRefModel, sRefBlock)
sRegExp = ['^', regexptranslate('escape', sRefModel)];
for i = 1:length(astLocals)
    astLocals(i).sVirtualPath = regexprep(astLocals(i).sVirtualPath, sRegExp, sRefBlock, 'once');
end
end


%%
function astLocals = i_getLocalsInfoFromSourceBlock(ahLines)
astLocals = repmat(i_createLocal(), 1, 0);
if ~isempty(ahLines)
    ahBlockPorts = get(ahLines, 'SrcPortHandle');
    if iscell(ahBlockPorts)
        ahBlockPorts(cellfun(@isempty, ahBlockPorts)) = [];
        ahBlockPorts = cell2mat(ahBlockPorts);
    end
    if ~isempty(ahBlockPorts)
        ahBlockPorts = unique(ahBlockPorts);
        astLocals = cell2mat(arrayfun(@(hBlockPort) i_createLocal(hBlockPort), ahBlockPorts, 'UniformOutput', false));
    end
    astLocals = reshape(astLocals, 1, []);
end
end


%%
% Note: Function is also used without any arguments for creating an *empty* local struct. Be prepared for that!
function stLocal = i_createLocal(hPort)
stLocal = struct( ...
    'sName',        '', ...
    'sClass',       '', ...
    'sPath',        '', ...
    'sVirtualPath', '', ...
    'sSfRelPath',   '', ...
    'aiPorts',      []);
if (nargin < 1)
    return;
end

hBlock = get_param(hPort, 'Parent');
stLocal.sName        = get_param(hBlock, 'Name');
stLocal.sClass       = class(get_param(hBlock, 'Object'));
stLocal.sPath        = getfullname(hBlock);
stLocal.sVirtualPath = stLocal.sPath;
stLocal.aiPorts      = get_param(hPort, 'PortNumber');
end


%%
function astLocals = i_createLocalsForBlock(hBlock, aiPorts)
stLocal = struct( ...
    'sName',        get_param(hBlock, 'Name'), ...
    'sClass',       class(get_param(hBlock, 'Object')), ...
    'sPath',        getfullname(hBlock), ...
    'sVirtualPath', getfullname(hBlock), ...
    'sSfRelPath',   '', ...
    'aiPorts',      []);

astLocals = repmat(stLocal, 1, length(aiPorts));
for i = 1:length(aiPorts)
    astLocals(i).aiPorts = aiPorts(i);
end
end


%%
function stLocal = i_createLocalForSfLocal(oSfLocal, sSfBlockPath)
stInfo = atgcv_m01_sf_data_info_get(oSfLocal);

stLocal = struct( ...
    'sName',        stInfo.sName, ...
    'sClass',       class(stInfo.hSfBlock), ...
    'sPath',        sSfBlockPath, ...
    'sVirtualPath', sSfBlockPath, ...
    'sSfRelPath',   stInfo.sRelPath, ...
    'aiPorts',      []);
end

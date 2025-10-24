function stResult = ep_model_reduced_info_get(sModelAnalysis, sFileList, sConstantsFile)
% Returns reduced information of the model.
%
% function stResult = ep_model_reduced_info_get(sModelAnalysis, sFileList)
%
%   INPUT                DESCRIPTION
%   - sModelAnalysis       (String) Full path to the model analysis
%   - sFileList            (String) Full path to the file list
%   - sConstantsFile       (String) Full path to ConstantsFile
%
%  OUTPUT            DESCRIPTION
%  - stResult                   (Struct)     The result structure
%      .stResultParameter       (Struct)     The result of the parameters.
%        .casName               (cell array) Names of the variables
%        .casClass              (cell array) Classes of the variables
%        .casType               (cell array) Types of the variables
%      .stSubsystemHierarchy    (Struct)     The subsystem hierarchy result.
%        .caSubsystems          (cell array) Entities of subsystem nodes
%           .path               (String)     Path of a subsystem
%           .sFctName           (String)     C-Code function name
%           .caSubsystems       (cell array) Entities of subsystem nodes
%           .bIsDummy           (logical)    TRUE if subsystem is a dummy subsystem
%      .astFileList             (cell array) Structs of file nodes
%        .sPath                 (String)     Path to the file
%        .sName                 (String)     Name of the file
%


%%
if (nargin < 2)
    sFileList = '';
end

stArchInfo = i_getArchitectureInfo(sModelAnalysis);
stResult = i_extract_reduced_info(stArchInfo, sFileList, sConstantsFile);
end


%%
function stResult = i_extract_reduced_info(stInputStruct, sFileList,...
    sConstantsFile)

stResult = struct(...
    'stResultParameter',    [], ...
    'stSubsystemHierarchy', [], ...
    'astFileList',          []);

% extract parameter information
stParamResult = struct ( ...
    'casName',  [] , ...
    'casClass', [], ...
    'casType',  [], ...
    'casPath',  []) ;
for i = 1:length(stInputStruct.astParams)
    stParamResult.casName{end+1} = stInputStruct.astParams(i).sName;
    stParamResult.casType{end+1} = stInputStruct.astParams(i).sType;
    stParamResult.casPath{end+1} = stInputStruct.astParams(i).astLocations(1).sPath;
    if (isempty(stInputStruct.astParams(i).sSize1) && isempty(stInputStruct.astParams(i).sSize2))
        stParamResult.casClass{end+1} = 'Simple(1x1)';
    elseif (~isempty(stInputStruct.astParams(i).sSize1) && ~isempty(stInputStruct.astParams(i).sSize2))
        stParamResult.casClass{end+1} = ['Matrix(',stInputStruct.astParams(i).sSize1,'x', ...
            stInputStruct.astParams(i).sSize2 ,')'];
    elseif (isempty(stInputStruct.astParams(i).sSize1) && ~isempty(stInputStruct.astParams(i).sSize2))
        stParamResult.casClass{end+1} = ['Array(1x',stInputStruct.astParams(i).sSize2 ,')'];
    else
        stParamResult.casClass{end+1} = ['Array(',stInputStruct.astParams(i).sSize1,'x1)'];
    end
end
stResult.stResultParameter = stParamResult;

% extract subsystem information
stSubResult =  struct( ...
    'caSubsystems', []);
for i = 1:length(stInputStruct.astScopes)
    if (isempty(stInputStruct.astScopes(i).sParentId ))
        stSubResult.caSubsystems{end+1} = ...
            i_get_subsystems_from_model(stInputStruct.astScopes(i), stInputStruct.astScopes);
    end
end
stResult.stSubsystemHierarchy = stSubResult;

% extract information about the SUT files.
if ~isempty(sFileList)
    hFileListHandle = mxx_xmltree('load', sFileList);
    ahFileNode = mxx_xmltree('get_nodes', hFileListHandle, '//cg:File[@annotate="yes"]');
    nFiles = numel(ahFileNode);
    astFileList = repmat(struct( ...
            'sName', '', ...
            'sPath', ''), 1, nFiles);
    for i = 1:nFiles
        astFileList(i).sName = mxx_xmltree('get_attribute', ahFileNode(i),'name');
        astFileList(i).sPath = mxx_xmltree('get_attribute', ahFileNode(i),'path');
    end
    mxx_xmltree('clear', hFileListHandle);
else
    astFileList = [];
end
stResult.astFileList = astFileList;
stResult.sConstantsFile = sConstantsFile;
end


%%
function stRes = i_get_subsystems_from_model(stScope, astScopes)
stRes = struct('sPath', stScope.sPath, 'sFctName', stScope.sFunc, 'bIsDummy', stScope.bIsDummy);
for i=1:length(astScopes)
    if strcmp(astScopes(i).sParentId, stScope.sId)
        if ~isfield(stRes, 'caSubsystems')
            stRes.caSubsystems = [];
        end
        stRes.caSubsystems{end+1} = i_get_subsystems_from_model(astScopes(i), astScopes);
    end
end
end


%%
function stInfo = i_getArchitectureInfo(sModelAnalysis)
stInfo = struct( ...
    'astScopes', [], ...
    'astParams', []);

if ~isempty(sModelAnalysis)
    [stInfo.astScopes, stInfo.astParams] = i_getModelAnaInfo(sModelAnalysis);
end
end


%%
function [astScopes, astParams] = i_getModelAnaInfo(sModelAna)
hDoc = mxx_xmltree('load', sModelAna);
try
    astScopes = i_getScopes(hDoc);
    astParams = i_getParams(hDoc);

    mxx_xmltree('clear', hDoc);
catch oEx
    mxx_xmltree('clear', hDoc);
    rethrow(oEx);
end
end


%%
function astScopes = i_getScopes(hDoc)
stScope = struct( ...
    'sId', '', ...
    'sParentId', '', ...
    'sName', '', ...
    'sFunc', '', ...
    'sPath', '', ...
    'bIsDummy', '');

ahSubs = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem');
nSubs = length(ahSubs);
astScopes = repmat(stScope, 1, nSubs);
for i = 1:nSubs
    hSub = ahSubs(i);

    astScopes(i).sId       = mxx_xmltree('get_attribute', hSub, 'id');
    astScopes(i).sPath     = mxx_xmltree('get_attribute', hSub, 'tlPath');
    astScopes(i).sFunc     = mxx_xmltree('get_attribute', hSub, 'stepFct');
    astScopes(i).bIsDummy  = strcmp(mxx_xmltree('get_attribute', hSub, 'isDummy'), 'yes');
    % TODO: find something better; there will be issues if Name contains slashes
    [~, sName] = fileparts(astScopes(i).sPath);
    astScopes(i).sName     = sName;
    astScopes(i).sParentId = i_getParentId(hSub);
end
end


%%
function sParentId = i_getParentId(hSub)
sParentId = '';

astRes = mxx_xmltree('get_attributes', hSub, './ma:Parents/ma:SubsystemRef', 'refID');
if ~isempty(astRes)
    sParentId = astRes(1).refID;
end
end


%%
function astInterfaces = i_getParams(hDoc)
stIf = struct( ...
    'sName',        '', ...
    'sCodeName',    '', ...
    'sSize1',       '', ...
    'sSize2',       '', ...
    'sType',        '', ...
    'bIsStruct',    false, ...
    'astLocations', []);

ahIfNodes = mxx_xmltree('get_nodes', hDoc, '//ma:Calibration');
nIfMax = length(ahIfNodes);
astInterfaces = repmat(stIf, 1, nIfMax);

jSet = java.util.HashSet(nIfMax);
iIf = 0;
for i = 1:nIfMax
    hIfNode = ahIfNodes(i);

    sName = i_getParamName(hIfNode);
    if (jSet.add(sName))
        iIf = iIf + 1;
        astInterfaces(iIf).sName = sName;
        astInterfaces(iIf).sCodeName = i_getParamCodeName(hIfNode);
        astInterfaces(iIf).astLocations = i_getInterfaceLocations(hIfNode);
        [astInterfaces(iIf).sSize1, astInterfaces(iIf).sSize2] = i_getInterfaceSize(hIfNode);
        astInterfaces(iIf).sType = i_getParamType(hIfNode);
    end
end
astInterfaces = astInterfaces(1:iIf);
end


%%
function sName = i_getParamName(hCalNode)
% get the first variable reference; if there are more they should be the same
sName = mxx_xmltree('get_attribute', hCalNode, 'name');
if isempty(sName)
    astAttr = mxx_xmltree('get_attributes', hCalNode, './ma:Variable', 'globalName');
    sName = astAttr(1).globalName;
end
end


%%
function sName = i_getParamCodeName(hCalNode)
% get the first variable reference; if there are more they should be the same
ahVars = mxx_xmltree('get_nodes', hCalNode, './ma:Variable');
hVar = ahVars(1); % currently only use the first Variable found
sRootName = mxx_xmltree('get_attribute', hVar, 'globalName');

astRes = mxx_xmltree('get_attributes', hVar, './ma:ifName', 'accessPath');
sAccessPath = astRes(1).accessPath;
if isempty(sAccessPath)
    sName = sRootName;
else
    % remove the trailing Array access braces [...] for C-Variables
    % example access=='[2].d->x[4][8]' --> '[2].d->x'
    sAccessPath = regexprep(sAccessPath, '[0-9,\[,\]]+$', '');
    if ~isempty(sAccessPath)
        sName = strtrim([sRootName, sAccessPath]);
    else
        sName = sRootName;
    end
end
end


%%
function sType = i_getParamType(hIfNode)
% get the first variable reference; if there are more they should be the same
astAttr = mxx_xmltree('get_attributes', hIfNode, './ma:Variable/ma:ifName/ma:DataType', 'tlTypeName');
sType = astAttr(1).tlTypeName;
end


%%
function [sSize1, sSize2] = i_getInterfaceSize(hIfNode)
sSize1 = '';
sSize2 = '';
% get the first variable reference; if there are more they should be the same
astAttr = mxx_xmltree('get_attributes', hIfNode, './ma:Variable', 'width1', 'width2');
if ~isempty(astAttr(1).width1)
    sSize1 = astAttr(1).width1;
    % note: there can only be a width2 if there is a width1
    if ~isempty(astAttr(1).width2)
        sSize2 = astAttr(1).width2;
    end
end
end


%%
function astLocations = i_getInterfaceLocations(hIfNode)
stLocation = struct( ...
    'sPath',       '', ...
    'sBlockType',  '', ...
    'sBlockUsage', '');
ahModelContext = mxx_xmltree('get_nodes', hIfNode, './ma:ModelContext');
if isempty(ahModelContext)
    % for DISP there are no ModelContexts
    astLocations = stLocation;
    astLocations.sPath = mxx_xmltree('get_attribute', hIfNode, 'tlBlockPath');
else
    nLocs = length(ahModelContext);
    astLocations = repmat(stLocation, 1, nLocs);
    for i = 1:nLocs
        hContext = ahModelContext(i);

        astLocations(i).sPath = mxx_xmltree('get_attribute', hContext, 'tlPath');
        astLocations(i).sBlockType = mxx_xmltree('get_attribute', hContext, 'blockType');
        astLocations(i).sBlockUsage = mxx_xmltree('get_attribute', hContext, 'blockUsage');
    end
end
end

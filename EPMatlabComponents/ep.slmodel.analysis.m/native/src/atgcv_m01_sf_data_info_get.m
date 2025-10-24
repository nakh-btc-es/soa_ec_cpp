function astInfos = atgcv_m01_sf_data_info_get(varargin)
% Returns info about SF data objects.
%
% (Usage_1) astInfos = atgcv_m01_sf_data_info_get(sSfBlockPath, casProps)
%
%     OR
%
% (Usage_2) function astInfos = atgcv_m01_sf_data_info_get(ahSfDatas)
%
%
%   INPUT               DESCRIPTION
%     (1) sChartPath           (string)     model path to SF block (Chart or ML function block)
%     (1) casProps             (cell)       key value pairs describing the properties of the Stateflow.Data object(s)
%                                           (e.g. 'Name', 'Path', ...)
%
%     (2) ahSfDatas            (array)      Stateflow.Data objects
%
%   OUTPUT              DESCRIPTION
%     astInfos             (struct)     array of info data
%       .hSfBlock             (string)     SF-handle of the SF owner (Chart, EMChart, ...)
%       .hSfData              (string)     SF-handle of the found SF data
%       .sName                (string)     name
%       .sPath                (string)     path
%       .sRelPath             (string)     relative path (similar to path but starting from Chart path as root path)
%       .sScope               (string)     scope
%                                          ('Input' | 'Output' | 'Local' | 'Constant' | 'Data Store Memory', ...)
%       .iFirstIdx            (integer)    first index (needed for arrays)
%       .sInitValue           (string)     initial value (might be empty)
%


%%
xArg = varargin{1};
if isa(xArg, 'Stateflow.Data')
    hSfBlock = [];
    ahSfDatas = xArg;
else
    sSfBlockPath = xArg;
    if (nargin < 2)
        casProps = {};
    else
        casProps = varargin{2};
    end
    
    sSfBlockPathValid = i_getValidBlockPath(sSfBlockPath);
    hSfBlock = i_findSfBlock(sSfBlockPathValid);
    if ~isempty(hSfBlock)
        if ~strcmpi(sSfBlockPathValid, sSfBlockPath)
            casProps = i_adaptPathInProperties(casProps, sSfBlockPath, sSfBlockPathValid);
        end
        
        ahSfDatas = i_findSfObjects(hSfBlock, {'Data'}, casProps);
        if isempty(ahSfDatas)
            casProps = i_preparePathInProperties(casProps);
            ahSfDatas = i_findSfObjects(hSfBlock, {'Data'}, casProps);
        end
    else
        ahSfDatas = [];
    end
end

astInfos = arrayfun(@(x) i_getDataInfo(hSfBlock, x), ahSfDatas);
end


%%
function casProps = i_adaptPathInProperties(casProps, sSfBlockPath, sSfBlockPathValid)
for i = 1:2:numel(casProps)
    sProp = casProps{i};
    if strcmpi(sProp, 'Path')
        casProps{i + 1} = i_adaptSfRootPath(casProps{i + 1}, sSfBlockPath, sSfBlockPathValid);
        break;
    end
end
end


%%
function sSfPath =  i_adaptSfRootPath(sSfPath, sOldRootPath, sNewRootPath)
sPattern = ['^', regexptranslate('escape', sOldRootPath)];
sSfPath = regexprep(sSfPath, sPattern, sNewRootPath);
end


%%
function casProps = i_preparePathInProperties(casProps)
for i = 1:2:numel(casProps)
    sProp = casProps{i};
    if strcmpi(sProp, 'Path')
        casProps{i + 1} = i_prepareSfPath(casProps{i + 1});
        break;
    end
end
end


%%
function sBlockPath = i_getValidBlockPath(sBlockPath)
% take care of library links
try
    sRefBlock = get_param(sBlockPath, 'ReferenceBlock');
    if ~isempty(sRefBlock)
        sBlockPath = sRefBlock;
    end
catch
end
end


%%
function hSfBlock = i_findSfBlock(sBlockPath)
casBlockClasses = { ...
    'Chart', ...
    'EMChart'};

hRoot = sfroot;

hSfBlock = i_findSfObjects(hRoot, casBlockClasses, {'Path', sBlockPath});
if isempty(hSfBlock)
    % sometimes problems with newline --> replace with blank
    sBlockPath = i_prepareSfPath(sBlockPath);
    hSfBlock = i_findSfObjects(hRoot, casBlockClasses, {'Path', sBlockPath});
end
end


%%
% in SF linefeeds get transformed into whitespaces
function sSfPath = i_prepareSfPath(sSfPath)
sSfPath = regexprep(sSfPath, '\n', ' ');
end


%%
function ahSfObjects = i_findSfObjects(hSfContext, casSfClasses, casProperties)
if (nargin < 2)
    casProperties = {};
end

casClassRequest = i_getClassRequest(casSfClasses);

ahSfObjects = find(hSfContext, casClassRequest, casProperties{:});
end


%%
function casRequest = i_getClassRequest(casSfClasses)
casRequest = {};
if ~isempty(casSfClasses)
    casRequest = {'-isa', sprintf('Stateflow.%s', casSfClasses{1})};
    for i = 2:numel(casSfClasses)
        casRequest = [casRequest, {'-or', '-isa', sprintf('Stateflow.%s', casSfClasses{i})}]; %#ok<AGROW>
    end
end
end


%%
function stInfo = i_getDataInfo(hSfBlock, hSfData)
if isempty(hSfBlock)
    hSfBlock = i_getParentBlock(hSfData);
end

stInfo = struct( ...
    'hSfBlock',      hSfBlock, ...
    'hSfData',       hSfData, ...
    'sName',         '', ...
    'sPath',         '', ...
    'sRelPath',      '', ...
    'sScope',        '', ...
    'iFirstIndex',   [], ...
    'sInitValue',    '');

if ~isempty(hSfData)
    stInfo.sName  = hSfData.Name;
    stInfo.sPath  = hSfData.Path;
    
    sRootPath = hSfBlock.Path;
    nRootLen = length(sRootPath);
    if (length(stInfo.sPath) > (nRootLen + 1))
        stInfo.sRelPath = stInfo.sPath(nRootLen + 2:end);
    end
    
    stInfo.sScope = hSfData.Scope;
    try
        stInfo.sInitValue = hSfData.getPropValue('Props.InitialValue');
    catch
    end
    
    sFirstIndex = hSfData.Props.Array.FirstIndex;
    if ~isempty(sFirstIndex)
        stInfo.iFirstIndex = eval(sFirstIndex);
    else
        stInfo.iFirstIndex = 0; % SF starts per default with zero (TODO: this is only? true for C-based SF Charts)
    end
end
end


%%
function hSfBlock = i_getParentBlock(hSfData)
hSfBlock = hSfData;

hParent = hSfBlock.getParent;
while ~isempty(regexp(class(hParent), '^Stateflow', 'once'))
    hSfBlock = hParent;
    hParent = hSfBlock.getParent;
end
end

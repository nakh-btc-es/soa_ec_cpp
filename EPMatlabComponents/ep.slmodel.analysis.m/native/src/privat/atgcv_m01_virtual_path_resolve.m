function casBlockPaths = atgcv_m01_virtual_path_resolve(sVirtualBlockPath)
% Return the chain of real model paths of a block provided as a virtual path.
%
% function casBlockPaths = atgcv_m01_virtual_path_resolve(sVirtualBlockPath)
%
%   INPUT                  DESCRIPTION
%     sVirtualBlockPath      (string)         the virtual path of a block
%
%   OUTPUT                 DESCRIPTION
%     casBlockPaths          (cell)           the chain of real model paths of the block
%                                             (or empty if not found, see also the Note below)
%
%   REMARKS
%     All corresponding models and referenced models are expected to be open and available.
%
%     Note: The returned chain of block paths cotains only the block paths of model reference blocks. 
%           Only the very last element is the real model block path itself.
%
%   <et_copyright>



%%
casBlockPaths = {};

%% check inputs
if ~ischar(sVirtualBlockPath)
    error('ATGCV:ERROR', 'Expecting a string argument as virtual path.');
end
if isempty(sVirtualBlockPath)
    return;
end

casParts = i_splitPath(sVirtualBlockPath);

sTryBlockPath = casParts{1};
hTryBlock = i_getBlockHandle(sTryBlockPath);
for i = 2:numel(casParts)
    if isempty(hTryBlock)
        casBlockPaths = {};
        return;
    end
    if i_isModelReferenceBlock(hTryBlock)
        casBlockPaths{end + 1} = getfullname(hTryBlock); %#ok<AGROW>
        sModelName = get_param(hTryBlock, 'ModelName');
        sTryBlockPath = sModelName;
    end
    sTryBlockPath = [sTryBlockPath, '/', casParts{i}]; %#ok<AGROW>
    hTryBlock = i_getBlockHandle(sTryBlockPath);
end
if isempty(hTryBlock)
    casBlockPaths = {};
else
    casBlockPaths{end + 1} = getfullname(hTryBlock);
end
end


%%
function casParts = i_splitPath(sPath)
aiSeparator = regexp(sPath, '[^/]/[^/]') + 1;
aiSeparator(end + 1) = length(sPath) + 1; % add a fake separator position at the end of the path + 1

nParts = numel(aiSeparator);
casParts = cell(1, nParts);

iStart = 1;
for i = 1:nParts
    iEnd = aiSeparator(i) - 1;
    casParts{i} = sPath(iStart:iEnd);
    
    iStart = iEnd + 2;
end
end


%%
function bIsModelRef = i_isModelReferenceBlock(hBlock)
bIsModelRef = ...
    strcmpi(get_param(hBlock, 'Type'), 'block') ...
    && strcmpi(get_param(hBlock, 'BlockType'), 'ModelReference');
end


%%
function hBlock = i_getBlockHandle(sBlock)
try
    hBlock = get_param(sBlock, 'handle');
catch
    hBlock = [];
end
end

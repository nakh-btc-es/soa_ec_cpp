function astTree = atgcv_m01_model_tree_get(xModelContext, sVirtualPath)
% Starting from a model context (block or model) returns the tree of all used models.
%
% function astTree = atgcv_m01_model_tree_get(xModelContext, sVirtualPath)
%
%   INPUT               DESCRIPTION
%       xModelContext      (handle/string)   handle or path of the model context block
%       sVirtualPath       (string)          the virtual path for the model context
%                                            (default == '' --> meaning that the model context is not considered for 
%                                            extending with virtual information, i.e. real path == virtual path)
%
%   OUTPUT              DESCRIPTION
%       astTree            (array)   structs with following info:
%         .sPath           (string)    the path of the model context block or model inside the tree
%         .sVirtualPath    (string)    the virtual path of the model context block or model inside the tree
%
%   REMARKS
%     Provided Model is assumed to be open.
%


%%
if (nargin < 1)
    xModelContext = bdroot(gcs);
end

%%
sContextRoot = getfullname(xModelContext);
if (nargin < 2) || isempty(sVirtualPath)
    sVirtualPath = sContextRoot;
end

astTree = struct( ...
    'sPath',        sContextRoot, ...
    'sVirtualPath', sVirtualPath);

[~, casRefBlocks] = ep_find_mdlrefs(bdroot(xModelContext), 'AllLevels', false);
for i = 1:length(casRefBlocks)
    sRefBlock = casRefBlocks{i};
    try
        [~,~,sF] = fileparts(get_param(sRefBlock, 'ModelFile'));
        if strcmp(sF,'.slxp') || strcmp(sF, '.mdlp')
            continue;
        end
        
    catch
    end
    if i_startsWith(sRefBlock, sContextRoot)
        if strcmp(sContextRoot, sVirtualPath)
            sVirtualRefBlock = sRefBlock;
        else
            sVirtualRefBlock = i_getVirtualPath(sRefBlock, sVirtualPath);
        end

        sRefModel = get_param(sRefBlock, 'ModelName');
        astTree = [astTree, atgcv_m01_model_tree_get(sRefModel, sVirtualRefBlock)]; %#ok<AGROW>
    end
end
end


%%
function bStartsWith = i_startsWith(sString, sPrefix)
sRegExp = ['^', regexptranslate('escape', sPrefix)];
bStartsWith = ~isempty(regexp(sString, sRegExp, 'once'));
end


%%
% replace the root part of the path by the virtual root
function sVirtualPath = i_getVirtualPath(sPath, sVirtualRoot)
sRoot = bdroot(sPath);
sRegExp = ['^', regexptranslate('escape', sRoot)];
sVirtualPath = regexprep(sPath, sRegExp, sVirtualRoot, 'once');
end

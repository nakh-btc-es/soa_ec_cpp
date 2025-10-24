function stReducedModel = ep_sl_model_reduced_info_get(stModel)
% Reduces the amount of info contained in SL model data to a subset suitable for UI workflow.
%
% function stResult = ep_sl_model_reduced_info_get(stModel)
%
%   INPUT               DESCRIPTION
%     stModel             (struct)  SL model data
%
%   OUTPUT              DESCRIPTION
%     stModel             (struct)  reduced version of the SL model data
%
%

%%
if ~isempty(stModel)
    astParams     = stModel.astParams;
    astSubsystems = stModel.astSubsystems;
else
    astParams     = [];
    astSubsystems = [];
end
stReducedModel = struct(...
    'stResultParameter',    i_getReducedParams(astParams), ...
    'stSubsystemHierarchy', i_transformToSubsystemTree(astSubsystems));
end


%%
function stTreeSubsystems = i_transformToSubsystemTree(astFlatSubsystems)
stTreeSubsystems = struct( ...
    'caSubsystems', []);
for i = 1:length(astFlatSubsystems)
    if isempty(astFlatSubsystems(i).iParentID)
        stTreeSubsystems.caSubsystems{end + 1} = i_getReducedSub(astFlatSubsystems(i), astFlatSubsystems);
    end
end
end


%%
function stReducedSub = i_getReducedSub(stSubsystem, astSubsystems)
stReducedSub = struct( ...
    'sPath',        stSubsystem.sVirtualPath, ...
    'sFctName',     '', ...
    'bIsDummy',     stSubsystem.bIsDummy, ...
    'caSubsystems', {{}});

iSubID = stSubsystem.iID;
for i = 1:length(astSubsystems)
    if (astSubsystems(i).iParentID == iSubID)
        stReducedSub.caSubsystems{end + 1} = i_getReducedSub(astSubsystems(i), astSubsystems);
    end
end
end


%%
function stReducedParams = i_getReducedParams(astParams)
stReducedParams = struct ( ...
    'casName',  [] , ...
    'casClass', [], ...
    'casType',  [], ...
    'casPath',  []) ;
for i = 1:length(astParams)
    stReducedParams.casName{end + 1}  = astParams(i).sName;
    stReducedParams.casType{end + 1}  = astParams(i).sType;
    stReducedParams.casPath{end + 1}  = astParams(i).astBlockInfo(1).sVirtualPath;
    stReducedParams.casClass{end + 1} = i_getStructureKind(astParams(i));
end
end


%%
function sStructureKind = i_getStructureKind(stParam)
aiWidth = stParam.aiWidth;
if (aiWidth(1) == 1 && aiWidth(2) == 1)
    sClassKind = 'Simple';
elseif (aiWidth(1) > 1 && aiWidth(2) > 1)
    sClassKind = 'Matrix';
else
    sClassKind = 'Array';
end
sStructureKind = sprintf('%s(%dx%d)', sClassKind, aiWidth(1), aiWidth(2));
end

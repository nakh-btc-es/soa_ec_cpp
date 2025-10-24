function astSubsystems = atgcv_m01_model_subsystems_get(stEnv, stOpt)
% Returns the Subsystems of a Simulink model. 
%
% function astSubsystems = atgcv_m01_model_subsystems_get(stEnv, stOpt)
%
%   INPUT               DESCRIPTION
%       stEnv              (struct)  Environment with Messenger handle
%       stOpt              (struct)  Options:
%         .sModelContext   (string)    name of the model or block
%         .bUseRoot        (boolean)   the toplevel shall not be skipped
%         .hSubsystemFilter (handle)  Optional callback function for filtering subsystems. If not given, a default
%                                     filter will be used                   
%
%   OUTPUT              DESCRIPTION
%       astSubsystems      (array)   structs with following info:
%         .sName           (string)    name of the Local's block
%         .iParentID       (number)    ID number of the parent scope (might be empty for root subsystems)
%         .iID             (number)    ID number
%         .sClass          (string)    class of the subsystem block
%         .sSFClass        (string)    SF-class of the subsystem block
%         .sPath           (string)    real model path of the Local's block
%         .sVirtualPath    (string)    the virtual model path of the Local's block
%
%   REMARKS
%     Provided Model is assumed to be open.
%
%   <et_copyright>

%%
if (nargin < 2)
    if (nargin < 1)
        stEnv = 0;
    end
    stOpt = struct();
end
stOpt = i_checkSetOptions(stOpt);
astSubsystems = i_getSubsystems(stEnv, stOpt);
end


%%
function astSubsystems = i_getSubsystems(stEnv, stOpt)
i_getNewID('reset');

[stReadout, stRootEntity] = i_getEntityTree(stEnv, stOpt.sModelContext, stOpt.hSubsystemFilter);
bIsRootEntity = true;
astSubsystems = i_transformEntityTreeToSubs(stReadout, stRootEntity, [], bIsRootEntity, stOpt.bUseRoot);

% add iParentIdx
aiIDs = [astSubsystems.iID];
for i = 1:length(astSubsystems)
    iParentID = astSubsystems(i).iParentID;
    if ~isempty(iParentID)
        astSubsystems(i).iParentIdx = find(iParentID == aiIDs);
    else
        astSubsystems(i).iParentIdx = [];
    end
end
end


%%
function [stReadout, stRootEntity] = i_getEntityTree(stEnv, sModelContext, hSubsystemFilter)
[bSuccess, sErrMessage, stReadout] = ep_simulink_hierarchy_reader(sModelContext, 'CallBack', hSubsystemFilter);
if ~bSuccess
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:INTERNAL_ERROR', ...
        'script', 'ep_simulink_hierarchy_reader', ...
        'text',   sErrMessage);
    osc_throw(stErr);
end

stRootEntity = stReadout.caComponents{stReadout.iMainComponent}.caModelEntities{1};
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
if ~isfield(stOpt, 'hSubsystemFilter') || isempty(stOpt.hSubsystemFilter)
    stOpt.hSubsystemFilter = @atgcv_m01_subsys_filter;
end
end


%%
function astSubs = i_transformEntityTreeToSubs(stReadout, stEntity, iParentID, bIsRootEntity, bUseRoot)
if (nargin < 4)
    bIsRootEntity = false;
end
if (nargin < 5)
    bUseRoot = false;
end
bSkipModelRef = false;
if stEntity.bSkipModelRef
    bSkipModelRef = true;
end
% if the Entity is referencing a model, it is a ModelReference block
% --> we need to skip this referencing level and enter into analysing the referenced model for more info
if (stEntity.ModelRefId > 0)
    stEntity = stReadout.caComponents{stEntity.ModelRefId}.caModelEntities{1};
    bIsRootEntity = false; % since we explicitly skip one level, we definitely do not have the root entity
end
 

% Note: special treatment for the root entity and skippable model references
if ((~bUseRoot && bIsRootEntity && i_canRootEntityBeSkipped(stEntity)) || bSkipModelRef)
    astSubs = repmat(i_createSub(), 1, 0);
elseif ~bIsRootEntity && i_isSimulinkFunction(stEntity)
    astSubs = repmat(i_createSub(), 1, 0);
else
    astSubs = i_transformEntityToSub(stEntity, iParentID);
    iParentID = astSubs.iID;
end


% recursively transform the child entities in the same way (note: provide the current parent ID)
for i = 1:length(stEntity.Children)
    stChild = stEntity.Children{i};
    astSubs = [astSubs, i_transformEntityTreeToSubs(stReadout, stChild, iParentID)]; %#ok<AGROW>
end
end


%%
% an entity can be skipped if it is 
%     1) representing a model 
% AND 2) has one toplevel scope (SF-Chart or Subsystem) 
% AND 3) has no root level Inports/Outport or has at least one root level Inport acting as a Fcn-Call-Port
function bCanBeSkipped = i_canRootEntityBeSkipped(stEntity)
bCanBeSkipped = ...
    i_isModelEntity(stEntity)  ...
    && i_hasOneChild(stEntity) ...
    && (~i_hasRootIO(stEntity) || i_hasFcnCallRootInport(stEntity));
end


%%
function bIsModel = i_isModelEntity(stEntity)
bIsModel = strcmp(stEntity.Class, 'Simulink.BlockDiagram');
end


%%
function bHasOneChild = i_hasOneChild(stEntity)
bHasOneChild = (numel(stEntity.Children) == 1);
end

%%
function bIsSimulinkFunction = i_isSimulinkFunction(stEntity)
    bIsSimulinkFunction = ~isempty(ep_find_system(stEntity.Path, ...
        'SearchDepth',        0, ...
        'isSimulinkFunction', 'on'));
end

%%
function bHasRootIO = i_hasRootIO(stEntity)
bHasRootIO = numel(ep_find_system(stEntity.Path, ...
    'SearchDepth', 1, ...
    'RegExp',      'on', ...
    'BlockType',   '^(In|Out)port$')) > 0;
end



%%
function bHasRootFcnCall = i_hasFcnCallRootInport(stEntity)
bHasRootFcnCall = numel(ep_find_system(stEntity.Path, ...
    'SearchDepth',        1, ...
    'BlockType',          'Inport', ...
    'OutputFunctionCall', 'on')) > 0;
end


%%
function varargout = i_getNewID(sCmd)
persistent p_iCount;

if (nargin > 0)
    if ((nargout < 1) && strcmpi(sCmd, 'reset'))
        p_iCount = 0;
    else
        error('ATGCV:MODEL_ANA:INTERNAL_ERROR', 'Resetting the ID was not correctly initiated.');
    end
else
    if isempty(p_iCount)
        error('ATGCV:MODEL_ANA:INTERNAL_ERROR', 'Resetting the ID was not correctly initiated.');
    end
    p_iCount = p_iCount + 1;
    varargout{1} = p_iCount;
end
end


%%
function stSub = i_transformEntityToSub(stEntity, iParentID)
stSub = i_createSub(stEntity, i_getNewID(), iParentID);
end


%%
function stSub = i_createSub(stEntity, iCount, iParentID)
if (nargin < 3)
    stSub = struct( ...
        'sName',        '', ...
        'iParentID',    [], ...
        'sClass',       '', ...
        'sSFClass',     '', ...
        'iID',          [], ...
        'sPath',        '', ...
        'sVirtualPath', '', ...
        'bIsDummy',     false);
else
    stSub = struct( ...
        'sName',        stEntity.Name, ...
        'iParentID',    iParentID, ...
        'sClass',       stEntity.Class, ...
        'sSFClass',     stEntity.StateflowClass, ...
        'iID',          iCount, ...
        'sPath',        stEntity.Path, ...
        'sVirtualPath', stEntity.VirtualPath, ...
        'bIsDummy',     false);
end
end




%  Simulink Hierarchy Reader.
%
%  This function reads the subsystem hierarchy from a Simulink model. In case of success
%  the model hierarchy and its subsystem hierarchy is returned. For fine tuning the result
%  a user defined callback function can be assigned in the inpput parameters. This function
%  is called for every visited subsystem (or Stateflow chart). It has to return two if the
%  search result shall include this subsystem and if the contents of this subsystem shall
%  be included into the result. The internal default function includes all subsystems and
%  also enables the search for its children. The default search will continue on referenced
%  models in case of model reference blocks. In this case the result will hold more than
%  one single model hierarchy - also the referenced model are included.
%
%  PARAMETER(S)
%    block
%      Simulink model or Subsystem or ModelReference Block of an opened model.
%      Allowed data types: Simulink handle, or Simulink object, or Simulink path (string).
%
%  OPTIONAL PARAMETER(S)
%    'SearchDepth' depth (double)
%       The search depth (equal to the maximum hierarchy level).
%    'CallBack' callbackfcn (function)
%       The callback function must have the following signature:
%       [bLookInside, bIgnoreEntity, caAdditionalData] = callbackfcn(hEntity)
%       The input parameter hEntity is a Simulink handle to the Simulink block under consideration.
%       The function needs to defined this two output parameters:
%       - bLookInside      : true if the search shall continue with the children of the subsystem,
%       - bIgnoreEntity    : true if the subsystem itself shall be included to the result.
%       - caAdditionalData : optional parameter, a cell array of structs with fields 'Name' and 'Value' of type string.
%                            If bIgnoreEntity is false then all elements of this array are inserted into the resulting
%                            struct of the corresponding model entity.
%    'BlockFilter' blockfilterfcn (function)
%       Callback filter function for search of relevant blocks. The default filter looks for blocks
%       with class 'Simulink.SubSystem', 'Stateflow.Chart', 'Stateflow.StateTransitionTableChart',
%       'Stateflow.TruthTableChart', 'Stateflow.LinkChart', 'Simulink.Reference', and 'Simulink.ModelReference'.
%       The callback function must have the following signature:
%       bHandleBlock = blockfilterfcn(hEntity)
%       The input parameter hEntity is a Simulink handle to the Simulink block under consideration.
%
%  OUTPUT
%    bSuccess Resulting status. 1 on success and 0 on failure.
%    sMessage Empty string on success, otherwise it holds an error message.
%    stResult The model hierarchy on success, empty on failure.
%
%  The result is a structure with the following fields:
%    .iMainComponent  (double)      Index to the main component (model) corresponding to the input block.
%    .caComponents    (cell array)  Array of components (model and all referenced models).
%  A component represents a model (and referenced models) and is a structure with the following fields:
%    .Name:           (string)      Name of the model.
%    .Root:           (string)      Simulink path to the root block (as given in input parameter).
%    .iUid:           (double)      Unique component ID. Used for model references.
%    .caModelInfo     (cell array)  Array of model properties (name, file, author, date).
%    .caModelEntities (cell array)  Array of model entities (subsystems / charts).
%  A model info represents a named model property and is a structure with the following fields:
%    .Name            (string)      Name of the property. Currently supported properties:
%                                   'File Name', 'Model Version', 'Created', 'Last Modified'.
%    .Value           (string)      The value of the property.
%  A model entity represents a hierarchical Simulink subsystem / Stateflow chart. The structure contains:
%    .Name            (string)      Name of the entity.
%    .Path            (string)      Simulink path of the entity.
%    .Class           (string)      Class of the entity (e.g. 'Simulink.BlockDiagram', 'Simulink.SubSystem')
%    .VirtualPath     (string)      Path relative to the starting block.
%    .MaskType        (string)      Mask type of the entity.
%    .StateflowClass  (string)      Stateflow class for Stateflow subsystem, empty otherwise.
%    .ModelRefId      (double)      Reference to the model component for model reference blocks; 0 otherwise.
%    .Children        (cell array)  Cell array of children (model entities).
%
%  AUTHOR(S):
%    Rainer.Lochmann@btc-es.de
% $$$COPYRIGHT$$$-2013
%
function [bSuccess, sMessage, stResult] = ep_simulink_hierarchy_reader(block, varargin)

%  check parameters
if nargin == 0
    %  at least the block parameter is needed
    bSuccess = 0;
    sMessage = 'Not enough input arguments.';
    stResult = [];
    
elseif mod(nargin, 2) == 0
    %  the number of arguments needs to be odd (block + arbitrary number of key/value pairs)
    bSuccess = 0;
    sMessage = 'Odd number of parameters expected.';
    stResult = [];
    
else
    [bSuccess, sMessage, stResult] = i_simulink_hierarchy_reader(block, varargin{:});
end
end


%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                           ***
%                                                                           ***
%******************************************************************************


%******************************************************************************
%  Hold internal result data.
%******************************************************************************
function varargout = i_result(sCmd, varargin)

persistent stHierarchy;

switch sCmd
    case 'init'
        %  initialization (create/clear the data structure)
        stHierarchy.iMainComponent = 0;
        stHierarchy.caComponents   = {};
        varargout{1} = 1;
    case 'get'
        varargout{1} = stHierarchy;
        clear('stHierarchy');
    case 'addComponent'
        stHierarchy.caComponents{end + 1} = varargin{1};
    case 'addMainComponentIndex'
        stHierarchy.iMainComponent = varargin{1};
end

end


%******************************************************************************
%  Get a unique number.
%******************************************************************************
function iUid = i_get_uid(varargin)

persistent iCnt;

if nargin == 1
    iCnt = 0;
else
    iCnt = iCnt + 1;
end

iUid = iCnt;
end


%******************************************************************************
%  Concat string, separate them by delimiter (if both strings are not empty).
%******************************************************************************
function sConcat = i_concat(sString1, sString2, sDelim)

if isempty(sString1)
    sConcat = sString2;
else
    sConcat = [sString1, sDelim, sString2];
end

end

%******************************************************************************
%  Get optional parameters
%******************************************************************************
function [bSuccess, sMessage, stOptions] = i_get_optional_parameters(caOptParams)

sMessage = '';

%  default options
stOptions = struct( ...
    'SearchDepth', Inf, ...
    'Progress', [], ...
    'ErrorReporter', [], ...
    'CallBack', @i_default_callback, ...
    'BlockFilter', [] ...
    );

k = 1;
while k < length(caOptParams) && isempty(sMessage)
    sParameterName = caOptParams{k};
    k = k + 1;
    
    if ~ischar(sParameterName)
        sMessage = 'Error in specification of object or property name and value pairs.';
    else
        parameterValue = caOptParams{k};
        k = k + 1;
        
        switch sParameterName
            case 'SearchDepth'
                %  value needs to be a scalar positive integer
                if isnumeric(parameterValue) && isscalar(parameterValue) && parameterValue && ...
                        floor(parameterValue) == parameterValue && parameterValue >= 1
                    stOptions.SearchDepth = parameterValue;
                else
                    sMessage = 'Invalid value for property ''SearchDepth''.';
                end
            case 'Progress'
                sMessage  = 'Property ''Progress'' not yet supported.';
            case 'ErrorReporter'
                sMessage  = 'Property ''ErrorReporter'' not yet supported.';
            case 'CallBack'
                if isa(parameterValue, 'function_handle')
                    stOptions.CallBack = parameterValue;
                else
                    sMessage = 'Invalid value for property ''CallBack''.';
                end
            case 'BlockFilter'
                if isa(parameterValue, 'function_handle')
                    stOptions.BlockFilter = parameterValue;
                else
                    sMessage = 'Invalid value for property ''BlockFilter''.';
                end
            otherwise
                sMessage  = ['Unkown property ''', sParameterName, '''.'];
        end
    end
end

%  check for error message
if isempty(sMessage)
    bSuccess = 1;
else
    bSuccess  = 0;
    stOptions = [];
end
end

%******************************************************************************
%  Convert block parameter (string, handle, object) to Simulink handle.
%  Returns a handle if the block could be found, -1 otherwise.
%******************************************************************************
function hHandle = i_block_handle_get(block)

hHandle = -1;

try %#ok<TRYNC>
    sClass = class(block);
    switch sClass
        case 'double'
            %  could be a handle
            if isscalar(block) && ishandle(block)
                hHandle = block;
            end
        case 'char'
            %  could be a Simulink block path
            hHandle = get_param(block, 'Handle');
        case 'Simulink.BlockDiagram'
            %  a Simulink model
            hHandle = block.Handle;
        case 'Simulink.SubSystem'
            %  a Simulink Subsystem (or Stateflow chart)
            hHandle = block.Handle;
        case 'Simulink.ModelReference'
            %  a Simulink Model reference
            hHandle = block.Handle;
    end
catch %#ok<CTCH>
    hHandle = -1;
end
end


%******************************************************************************
%  Internal main function. All exceptions are catched.
%******************************************************************************
function [bSuccess, sMessage, stResult] = i_simulink_hierarchy_reader(block, varargin)

bSuccess = 0;
stResult = [];

try
    %  get options
    [bSuccess, sMessage, stOptions] = i_get_optional_parameters(varargin);
    
    if bSuccess
        %  convert block to a Simulink handle
        hHandle = i_block_handle_get(block);
        if hHandle == -1
            bSuccess = 0;
            sMessage = 'First parameter does not denote a valid Simulink block or Simulink model.';
        else
            %  start the model investigation
            hModel             = bdroot(hHandle);
            sModel             = getfullname(hModel);
            sRootPath          = getfullname(hHandle);
            %                 sVirtualPath       = strrep(get_param(hHandle, 'Name'), '/', '//');
            sVirtualPath       = getfullname(hHandle);
            sVirtualParentPath = '';
            
            %  initialize module data
            i_result('init');
            i_get_uid('init');
            
            [bSuccess, sMessage, iUid] = ...
                i_get_component(sModel, sRootPath, sVirtualPath, sVirtualParentPath, stOptions);
            if bSuccess
                i_result('addMainComponentIndex', iUid);
                stResult = i_result('get');
            end
        end
    end
catch %#ok<CTCH>
    sMessage = ['Exception occured in ', mfilename, ':', 10, lasterr]; %#ok<LERR>
end

end


%******************************************************************************
%  Analyze one model component (mdl-file).
%******************************************************************************
function [bSuccess, sMessage, iUid] = i_get_component(sModel, sRootPath, sVirtualPath, sVirtualParentPath, stOptions)

stComponent.Name = sModel;
stComponent.Root = sRootPath;
stComponent.caModelEntities = {};

[bSuccess, sMessage, caModelEntities] = i_get_model_entity(sRootPath, sVirtualPath, sVirtualParentPath, stOptions);

if bSuccess
    iUid = i_get_uid;
    stComponent.iUid = iUid;
    stComponent.caModelEntities = caModelEntities;
    stComponent.caModelInfo = {};
    
    %  get model info
    
    try %#ok<TRYNC>
        sFileName = get_param(sModel, 'FileName');
        stComponent.caModelInfo{end + 1} = struct('Name', 'File Name', 'Value', sFileName);
    end
    
    try %#ok<TRYNC>
        sModelVersion = get_param(sModel, 'ModelVersion');
        stComponent.caModelInfo{end + 1} = struct('Name', 'Model Version', 'Value', sModelVersion);
    end
    
    try  %#ok<TRYNC>
        sCreated = get_param(sModel, 'Created');
        stComponent.caModelInfo{end + 1} = struct('Name', 'Created', 'Value', sCreated);
    end
    
    try %#ok<TRYNC>
        sModified = get_param(sModel, 'LastModifiedDate');
        stComponent.caModelInfo{end + 1} = struct('Name', 'Last Modified', 'Value', sModified);
    end
    
    i_result('addComponent', stComponent);
else
    iUid = 0;
end

end


%******************************************************************************
%  Get information on a model entity (subsystem).
%******************************************************************************
function [bSuccess, sMessage, caModelEntities] = i_get_model_entity(sPath, sVirtualPath, sVirtualParentPath, stOptions)

caModelEntities = {};

%  check search depth
if ~isinf(stOptions.SearchDepth)
    stOptions.SearchDepth = stOptions.SearchDepth - 1;
    if stOptions.SearchDepth <= 0
        bSuccess = 1;
        sMessage = '';
        return
    end
end

%  call the user-defined or default callback function to decide if this entity should be handled
hHandle = i_block_handle_get(sPath);

[bSuccess, sMessage, bLookInside, bIgnoreEntity, caAdditionalData] = i_call_callback(hHandle, stOptions);

%  return immediately if not successful
if ~bSuccess
    return
end

%  return immediately if the block and its children shall not be included
if bIgnoreEntity && ~bLookInside
    return
end

oEntity = get_param(hHandle, 'Object');
caChildEntities = {};
iUid = 0;
bSkipModelReference = false;
if isa(oEntity, 'Simulink.ModelReference')
    %  handle model references
    if bLookInside
        if bIgnoreEntity
            bSkipModelReference = true;
        end
        [bSuccess, sMessage, iUid] = ...
            i_get_modelref_entity(oEntity, sVirtualPath, sVirtualParentPath, stOptions);
    end
elseif bLookInside
    [bSuccess, sMessage, caChildEntities] = ...
        i_get_child_entities(oEntity, sPath, sVirtualPath, stOptions);
end

%  on success perform entry for current entity, else generate an error message
if ~bSuccess
    sMessage = i_concat(['Problems encoutered when looking inside ''', sPath, '''.'], sMessage, 10);
else
    if bIgnoreEntity && ~isa(oEntity, 'Simulink.ModelReference')
        %  ignore this level and return all children instead
        caModelEntities = caChildEntities;
    else
        %  create a new level for this entity
        
        %  get the mask type (if available)
        sMaskType = '';
        sStateflowClass = '';
        
        if isa(oEntity, 'Simulink.SubSystem')
            sMaskType  = oEntity.MaskType;
            sStateflowClass = i_get_stateflow_class(oEntity);
        end
        
        stModelEntity.Name           = oEntity.Name;
        stModelEntity.Path           = getfullname(oEntity.Handle);
        stModelEntity.Class          = class(oEntity);
        stModelEntity.VirtualPath    = sVirtualPath;
        stModelEntity.MaskType       = sMaskType;
        stModelEntity.StateflowClass = sStateflowClass;
        stModelEntity.ModelRefId     = iUid;
        stModelEntity.Children       = caChildEntities;
        stModelEntity.Data           = caAdditionalData;
        stModelEntity.bSkipModelRef  = bSkipModelReference;
        
        caModelEntities{1} = stModelEntity;
    end
end
end


%******************************************************************************
%  Get all relevant children of a subsystem.
%******************************************************************************
function aoChildren = i_get_children(oSubsystem, fBlockFilter)

aoChildren = oSubsystem.getChildren;

if isempty(fBlockFilter)
    %  default block filter (mainly Subsytems, Charts and Model References)
    for iChild = length(aoChildren):-1:1
        oChild  = aoChildren(iChild);
        sClass  = class(oChild);
        
        switch sClass
            case {  'Simulink.SubSystem', ...
                    'Stateflow.Chart', ...
                    'Stateflow.StateTransitionTableChart', ...
                    'Stateflow.TruthTableChart', ...
                    'Stateflow.LinkChart', ...
                    'Simulink.Reference', ...
                    'Simulink.ModelReference'}
                bDeleteChild = 0;
            otherwise
                bDeleteChild = 1;
        end
        if bDeleteChild
            aoChildren(iChild) = [];
        end
    end
else
    %  custom block filter
    for iChild = length(aoChildren):-1:1
        oChild  = aoChildren(iChild);
        bDeleteBlock = 1;
        try  %#ok<TRYNC>
            sClass = class(oChild);
            switch sClass
                case {  'Stateflow.Chart', ...
                        'Stateflow.StateTransitionTableChart', ...
                        'Stateflow.TruthTableChart', ...
                        'Stateflow.LinkChart'}
                    hBlock = get_param(oChild.Path, 'Handle');
                otherwise
                    hBlock = oChild.Handle;
            end
            bUseBlock = feval(fBlockFilter, hBlock);
            bDeleteBlock = ~bUseBlock;
        end
        if bDeleteBlock
            aoChildren(iChild) = [];
        end
    end
end
end


%******************************************************************************
%  Get information on a model reference.
%******************************************************************************
function [bSuccess, sMessage, iUid] = i_get_modelref_entity(oModelRef, sVirtualPath, sVirtualParentPath, stOptions)

%  get referenced model name
sRefModelName = oModelRef.ModelName;

%  check if the referenced model is loaded
caLoadedSystems = find_system('SearchDepth', 0);
bRefModelWasLoaded = any(strcmp(caLoadedSystems, sRefModelName));

%  if not loaded then try to load
bRefModelIsLoaded = 1;
if ~bRefModelWasLoaded
    try
        load_system(sRefModelName);
    catch %#ok<CTCH>
        bRefModelIsLoaded = 0;
    end
end

%  now the referenced model should be loaded
if bRefModelIsLoaded
    [bSuccess, sMessage, iUid] = ...
        i_get_component(sRefModelName, sRefModelName, sVirtualPath, sVirtualParentPath, stOptions);
    %  if the referenced model wasn't open before then close it again
    if ~bRefModelWasLoaded
        close_system(sRefModelName, 0);
    end
else
    bSuccess = 0;
    sMessage = ['Referenced model ''', sRefModelName, ''' could not be loaded.'];
    iUid = 0;
end

end


%******************************************************************************
%  Get entities for all children.
%******************************************************************************
function [bSuccess, sMessage, caChildEntities] = i_get_child_entities(oEntity, sPath, sVirtualPath, stOptions)

bSuccess = 1;
sMessage = '';
caChildEntities = {};

aoChildren = i_get_children(oEntity, stOptions.BlockFilter);

for iChild = 1:length(aoChildren)
    
    oChild = aoChildren(iChild);
    sChildName = strrep(oChild.Name, '/', '//');
    
    sChildPath        = i_concat(sPath, sChildName, '/');
    sChildVirtualPath = i_concat(sVirtualPath, sChildName, '/');
    
    [bChildSuccess, sChildMessage, caEntities] = ...
        i_get_model_entity(sChildPath, sChildVirtualPath, sVirtualPath, stOptions);
    
    if bChildSuccess
        caChildEntities = [caChildEntities, caEntities]; %#ok<AGROW>
    else
        bSuccess = 0;
        sMessage = i_concat(sMessage, sChildMessage, 10);
    end
end
end

%******************************************************************************
%  Call user-defined callback function on specific model entity.
%******************************************************************************
function [bSuccess, sMessage, bLookInside, bIgnoreEntity, caAdditionalData] = i_call_callback(hEntity, stOptions)

bSuccess         = 1;
sMessage         = '';
bLookInside      = 0;
bIgnoreEntity    = 1;
caAdditionalData = {};

fCallBack = stOptions.CallBack;

%  check the number of output arguments (at least two, maybe three with additional data)
nOutputs = nargout(fCallBack);

%  return immediately if the number of outputs is too small
if nOutputs == 0 || nOutputs == 1
    bSuccess = 0;
    sMessage = 'User defined callback function must return at least two output arguments.';
    return
end

if nOutputs == 2
    %  user defined callback just constantly returns two parameters
    try
        [bLookInside, bIgnoreEntity] = feval(fCallBack, hEntity);
        caAdditionalData = {};
    catch %#ok<CTCH>
        bSuccess = 0;
    end
elseif nOutputs >= 3
    %  user defined callback constantly returns at least three parameters including additional data
    try
        [bLookInside, bIgnoreEntity, caAdditionalData] = feval(fCallBack, hEntity);
    catch %#ok<CTCH>
        bSuccess = 0;
    end
else
    %  nOutputs is negative, so the function uses varargout
    try
        %  try to get additional data
        [bLookInside, bIgnoreEntity, caAdditionalData] = feval(fCallBack, hEntity);
    catch %#ok<CTCH>
        %  this was not successful: try with the two mandatory outputs
        try
            [bLookInside, bIgnoreEntity] = feval(fCallBack, hEntity);
            caAdditionalData = {};
        catch %#ok<CTCH>
            bSuccess = 0;
        end
    end
end

if ~bSuccess
    sMessage = ['Error occured in execution of callback function ''', ...
        func2str(fCallBack), ''':', 10, lasterr]; %#ok<LERR>
    return
end

%  never look into Stateflow charts: correct the flag if set by user function
if bLookInside
    
    oEntity = get_param(hEntity, 'Object');
    
    if isa(oEntity, 'Simulink.SubSystem')
        oStateflow = i_get_stateflow_object(oEntity);
        if ~isempty(oStateflow)
            bLookInside = 0;
        end
    end
end

%  normalize output data: if bIgnoreEntity is true delete all additional data
if bIgnoreEntity
    caAdditionalData = {};
end
end


%******************************************************************************
%  Get Stateflow class (with dereferenced Stateflow.LinkChart - if possible)
%******************************************************************************
function sStateflowClass = i_get_stateflow_class(oSubsystem)

sStateflowClass = '';

oStateflow = i_get_stateflow_object(oSubsystem);
if ~isempty(oStateflow)
    sStateflowClass = class(oStateflow);
    if isa(oStateflow, 'Stateflow.LinkChart')
        %  get the object of the referenced library stateflow subsystem (if loaded)
        try %#ok<TRYNC>
            sReferenceBlock = oSubsystem.ReferenceBlock;
            oReferenceBlock = get_param(sReferenceBlock, 'Object');
            sStateflowClass = i_get_stateflow_class(oReferenceBlock);
        end
    end
end

end


%******************************************************************************
%  Get corresponding Stateflow object for Subsystem object.
%******************************************************************************
function oStateflow = i_get_stateflow_object(oSubsystem)

oStateflow = oSubsystem.find( ...
    '-property', 'Id', ...
    '-property', 'Machine', ...
    '-depth',     1);
end


%******************************************************************************
%  The default callback function on specific model entity.
%******************************************************************************
function [bLookInside, bIgnoreEntity] = i_default_callback(hEntity)

%  set defaults
bLookInside = 0;
bIgnoreEntity = 1;

oEntity = get_param(hEntity, 'Object');

switch class(oEntity)
    case 'Simulink.BlockDiagram'
        %  always look inside models, include the model itself
        bLookInside = 1;
        bIgnoreEntity = 0;
    case 'Simulink.SubSystem'
        %  a Simulink Subsystem (or Stateflow chart)
        sStateflowClass = i_get_stateflow_class(oEntity);
        switch sStateflowClass
            case 'Stateflow.Chart'
                bLookInside = 0;
            otherwise
                %  look inside normal SubSystems
                bLookInside = 1;
        end
        bIgnoreEntity = 0;
    case 'Simulink.ModelReference'
        %  include model references but avoid to look inside
        bLookInside = 1;
        bIgnoreEntity = 0;
end

end


%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

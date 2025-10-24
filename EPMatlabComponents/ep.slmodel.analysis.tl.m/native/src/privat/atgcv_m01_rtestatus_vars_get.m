function astVars = atgcv_m01_rtestatus_vars_get(stEnv, hSubsys, sMode)
% get all RTE-Status variables of provided subsystem
%
% function ahVars = atgcv_m01_rtestatus_vars_get(stEnv, hSubsys)
%
%   INPUT           DESCRIPTION
%     stEnv             (struct)       environment structure
%     hSubsys           (handle)       DD handle to a current subsystem
%                                      (DD->Subsystems->"TopLevelName")
%     sMode             (string)       optional: kind of DSM
%                                      'read'  == Signal Injection (<-- default)
%                                      'write' == Signal Tunnelling
%
%   OUTPUT          DESCRIPTION
%     ahVars            (array)        DD variables of the specified kind
%
%   REMARKS
%
% Note: function makes heavily use of "tl_collect_framegen_data.m" of TL3.5


%% check inputs
if (nargin < 3)
    sMode = 'read';
end

%% main
% first find all TargetLink top subsystems (including model references)
ahSubs = atgcv_m01_involved_subsystems_get(stEnv, hSubsys);

% now get the needed variables from these subsystems
astVars = [];
for i = 1:length(ahSubs)
    astVars = [astVars, i_getSubsystemGlobalVars(stEnv, ahSubs(i), sMode)]; %#ok<AGROW>
end
end




%% i_getSubsystemGlobalVars
function astVars = i_getSubsystemGlobalVars(stEnv, hSubsys, sMode)
astVars = i_getRteVars(stEnv, hSubsys, sMode);
astVars = i_removeInvalidVars(stEnv, hSubsys, astVars);
end


%% i_removeInvalidVars
function astVars = i_removeInvalidVars(stEnv, hSubsys, astVars)
if isempty(astVars)
    return;
end
ahOrigVars = [astVars(:).hVar];

% some vars are inactive due to data variants
% ! can only be done _before_ we filter out any variables at all; otherwise
%   we would lose the needed info !
ahVars = i_removeInactiveDataVariantVars(stEnv, hSubsys, ahOrigVars);

% remove variables with local scope
abSelect = false(size(ahVars));
for i = 1:length(ahVars)
    abSelect(i) = ~i_isLocalScope(stEnv, ahVars(i));
end
ahVars = ahVars(abSelect);

% remove the Variable structs that were not selected
[ahNotSelectedVars, aiNotSelectedIdx] = setdiff(ahOrigVars, ahVars); %#ok<ASGLU>
astVars(aiNotSelectedIdx) = [];
end


%% i_getRteVars
function astVars = i_getRteVars(stEnv, hDdSubsystem, sMode)
hDdBlockGroup = atgcv_mxx_dsdd(stEnv, 'GetModelView', hDdSubsystem);

% Init values
rteStatusFeedbackDataList = [];

if strcmpi(sMode, 'read')        
    % Now iterate the receiver and sender com spec blocks
    hDdReceieverComSpecBlockList = ...
        dsdd('Find', hDdBlockGroup, 'ObjectKind', 'Block',...
        'Property', {'Name', 'BlockType', 'Value', 'TL_ReceiverComSpec'});
    for m = 1:numel(hDdReceieverComSpecBlockList)
        rteStatusFeedbackData     = FcnGetComSpecBlockData(hDdReceieverComSpecBlockList(m), 1);
        rteStatusFeedbackDataList = [rteStatusFeedbackDataList rteStatusFeedbackData];
    end

    hDdSenderComSpecBlockList = ...
        dsdd('Find', hDdBlockGroup, 'ObjectKind', 'Block',...
        'Property', {'Name', 'BlockType', 'Value', 'TL_SenderComSpec'});
    for m = 1:numel(hDdSenderComSpecBlockList)
        rteStatusFeedbackData     = FcnGetComSpecBlockData(hDdSenderComSpecBlockList(m), 0);
        rteStatusFeedbackDataList = [rteStatusFeedbackDataList rteStatusFeedbackData];
    end

    % ...and the e2epw subsystems 
%     hSlE2epwReadBlockList  = FcnGetE2epwBlocks(hDdBlockGroup,'E2EPW_Read2');
%     for m = 1:numel(hSlE2epwReadBlockList)
%         rteStatusFeedbackData     = FcnGetE2epwBlockData(hSlE2epwReadBlockList(m), hDdSubsystem);
%         rteStatusFeedbackDataList = [rteStatusFeedbackDataList rteStatusFeedbackData];
%     end
%     hSlE2epwWriteBlockList = FcnGetE2epwBlocks(hDdBlockGroup,'E2EPW_Write1');
%     for m = 1:numel(hSlE2epwWriteBlockList)
%         rteStatusFeedbackData     = FcnGetE2epwBlockData(hSlE2epwWriteBlockList(m), hDdSubsystem);
%         rteStatusFeedbackDataList = [rteStatusFeedbackDataList rteStatusFeedbackData];
%     end
end

nVars = length(rteStatusFeedbackDataList);
astVars = repmat(struct( ...
    'hVar',       [], ...
    'signalName', ''), 1, nVars);
for i = 1:nVars
    astVars(i).hVar = rteStatusFeedbackDataList(i).hVariable;
    astVars(i).signalName = ...
        i_getCleanSignalName(rteStatusFeedbackDataList(i).simulinkSignalName);
end
end


%%
function sCleanName = i_getCleanSignalName(sName)
sCleanName = '';
if ~isempty(sName)
    % remove leading and trailing double-quotes
    sCleanName = strtrim(regexprep(sName, '"', ''));
end
end


%%
function e2epwErrorData = FcnGetE2epwBlockData(hSlE2ePwBlock, hDDSubsystem)

% Init values
e2epwErrorData = [];

% First get AUTOSAR block data
blockData = tl_get_e2epw_block_data(hSlE2ePwBlock);
if isempty(blockData) || isempty(blockData.statusSignalName)
    % Data Store Read block does not exist
    return;
end
if strcmp(blockData.maskType, 'E2EPW_Read2')
    errorVarName = ['e2epw_' blockData.swcName '_' blockData.portName '_' blockData.dataElementName '_r_err'];
else
    errorVarName = ['e2epw_' blockData.swcName '_' blockData.portName '_' blockData.dataElementName '_w_err'];
end

% Ok, status signal lable and variable found, get the variable data
hDdType = dsdd('Find',hDDSubsystem, 'Name','uint32','Property', {'Name','BaseType','Value','UInt32'});
if isempty(hDdType)
    % UInt32
   return;
end

e2epwErrorData                          = FcnInitInterfaceVariableStruct(1);
e2epwErrorData.name                     = errorVarName;
e2epwErrorData.hType                    = hDdType(1);
e2epwErrorData.hParentStructType        = hDdType(1);
e2epwErrorData.usageEnum                = 'VKE_RTE_STATUS';
e2epwErrorData.simulinkSignalName            = ['"' blockData.statusSignalName '"'];
e2epwErrorData.rootPortData.portNumber  = 0; 
e2epwErrorData.rootPortData.portElement = -1; 
e2epwErrorData.ownPort                  = 0;
e2epwErrorData.width                    = 1;
e2epwErrorData.scaling.LSB              = 1;
e2epwErrorData.scaling.Offset           = 0;
e2epwErrorData.variableName             = errorVarName;
e2epwErrorData.actualVariableName       = errorVarName;
e2epwErrorData.moduleName               = ['e2epw_' blockData.swcName];
end


%%
function hSlE2epwBlockList = FcnGetE2epwBlocks(hDdRunnableBlockGroup, blockMaskType)

% Init values
hSlE2epwBlockList = [];
bCloseSystem      = false;

% Get the Sl subsystem described by the current BlockGroup object
runnableSysPath = dsdd_get_block_path(hDdRunnableBlockGroup);

% Check if the runnable system exist and is open
[runnableSysPath, bOK] = ds_check_value(runnableSysPath, 'Simulink system');
if ~bOK
    % Maybe runnableSysPath is a ref. Modell, that must be open?
    % In case BlockGroup hDdRunnableBlockGroup is marked as a root system,
    % we check if it describe a reference model. In this case the model
    % must be loaded before find_system is called.
    bIsRootSystem = dsdd('GetGroupInfoIsRootSystem',hDdRunnableBlockGroup);
    if bIsRootSystem
        hDDParentSubsystem = dsdd('GetAttribute', hDdRunnableBlockGroup, 'hDDParent');
        if strcmpi(dsdd_get_creator_options(hDDParentSubsystem,'CodeGenForModel'),'on')
            try
                load_system(runnableSysPath);
                bCloseSystem = true;
            catch %#ok<CTCH>
            end
        end
    end
    if ~bCloseSystem
        return;
    end
end

% Get the handle of the function subsystem 
% NOTE: the function subsystem 
hRunnableSystem = get_param(runnableSysPath, 'Handle');

% Find all E2E blocks within current TL subsystems
hSlE2epwBlockList = ep_find_system(hRunnableSystem,...
    'FollowLinks',          'on', ...
    'LookUnderMasks',       'all', ...
    'MaskType',             blockMaskType);
if bCloseSystem
    close_system(runnableSysPath,0);
end
end


%%
function objNameOut = FcnGetBaseObjectName(objNameIn)

% init value
objNameOut = objNameIn;

% convert the input name to double value
doublePatern = double(objNameIn);
if doublePatern(end) == 41,
    % 41 = ')'
    % 40 = '('
    % 35 = '#'
    % 48-57 = '0' - '9'
    idx = find(doublePatern == 40);
    if doublePatern(idx + 1) == 35
        objNameOut = objNameIn(1:idx-1);
    end
end
end

%%
function [variableName, ...
          ddRelativePathToRootStruct, ....
          hRootVariableHandle] = FcnGetVariableFullName(hWorkVariable, hSearchParentStruct)

% init values
variableName               = dsdd('GetAttribute', hWorkVariable, 'name');
variableName               = FcnGetBaseObjectName(variableName);
ddRelativePathToRootStruct = '';
hRootVariableHandle        = hWorkVariable; 
if nargin == 1
    hSearchParentStruct = -1;
end

hParentVariable     = dsdd('GetAttribute', hWorkVariable, 'hDDParent');
previousName        = variableName;
while ~isempty(hParentVariable) && hParentVariable ~= hSearchParentStruct
   kind = dsdd('GetAttribute', hParentVariable, 'ObjectKind'); % if hWorkVariable = interfaceVariableData.hVariable
   name = dsdd('GetAttribute', hParentVariable, 'name');
   name = FcnGetBaseObjectName(name); % remove the autorename index, is any
   if strcmp(kind,'VariableGroup') || strcmp(name, 'InterfaceVariables'),
      break;
   end
   ddRelativePathToRootStruct = ['/' previousName ddRelativePathToRootStruct]; %#ok<AGROW>
  
   if strncmp(name, 'Components',10),
      idx = name(13:end-1);
      if ~isempty(idx),
         variableName = ['[' idx ']' variableName]; %#ok<AGROW>
      end
   else
      variableName = [name '.' variableName]; %#ok<AGROW>
   end
   hRootVariableHandle = hParentVariable;
   previousName        = name;
   hParentVariable     = dsdd('GetAttribute', hParentVariable, 'hDDParent');
end
end

%%
function interfaceVariableData = FcnGetInterfaceVariableNameAndType(interfaceVariableData, hWorkVariable)

% if variable is structure component full variable name
% must be found
% NOTE: hWorkVariable = interfaceVariableData.hVariable or
% hWorkVariable = interfaceVariableData.hInterfaceVariable if interfaceVariableData.hVariable is empty
[interfaceVariableData.variableName, ddRelativePathToRootStruct, hParentStruct] ...
    = FcnGetVariableFullName(hWorkVariable); 

% Get the typedef of the parented structure; if variable is not
% structur component, parented structure is identical with the variable
% itself.
% NOTE: found parent is a pointer, as a type the pointer destination must be taken
% In S-Function and PFC file for pointer variable always corresponding
% destination types will be created
% NOTE: if the hWorkVariable is an InterfaceVariable object representing a 
% componenten of a structure put to the function via pointer to struct, hParentStructure may refer
% to the InterfaceVariable representing the pointer to struct, In this case GetTypeTarget property
% returns an errorCode
if (hWorkVariable ~= hParentStruct)
    % current interface variable is structure component
    parentStructObjektKind = dsdd('GetAttribute', hParentStruct, 'ObjectKind');
    if strcmp(parentStructObjektKind, 'InterfaceVariable'),
        hParentStruct = dsdd('GetVariableTarget', hParentStruct);
    end
end
[hType, errorCode]    = dsdd('GetTypeTarget', hParentStruct);
if FcnCheckGetTargetError(errorCode, hParentStruct, 'Type'), return; end
[baseType, errorCode] = dsdd('GetBaseType', hType);
if dsdd_check_msg(errorCode), return, end
if strcmpi(baseType, 'Pointer'),
   [interfaceVariableData.hParentStructType, errorCode] = dsdd('GetPointerDestTypeTarget', hType);
   if FcnCheckGetTargetError(errorCode, hType, 'PointerDestType'), return; end
else
   interfaceVariableData.hParentStructType = hType;
end

% per default actual variable name is equal variable name as long as not other is decided
interfaceVariableData.actualVariableName = interfaceVariableData.variableName;
end


%%
function interfaceVariableData = FcnGetInterfaceVariableScaling(interfaceVariableData)


if ~isempty(interfaceVariableData.hVariable)                                               ,
   hVariable = interfaceVariableData.hVariable;
   bGetWidth = 1;
else
   % for function return and OSEK messages no variable object exist in DD.
   % Therefore scaling data are read directly
   % from the interface variable object
   hVariable = interfaceVariableData.hInterfaceVariable;
   bGetWidth = 0;
end
end

%%
function bReturn = FcnCheckGetTargetError(errCode, hObject, propertyName)

% init value
bReturn = 0;

if errCode == 5040,
   ds_error_msg({...
         'Error while attempt to access the data dictionary.',...
         ['The DD object pointed at by the reference property ''' propertyName ''''],...
         ['of ''' dsdd('GetAttribute',hObject,'path') ''' does not exist.'];},...
         'Title','Internal error',...
         'ObjectKind','DDObject',...
         'ObjectHandle',hObject);
   bReturn = 1;  
elseif errCode ~= 0,
   dsdd_check_msg(errCode);
   bReturn = 1;
end
end

%%
function rteStatusFeedbackData = FcnGetComSpecBlockData(hDdBlock, bReceiverComSpec)

% Init values
rteStatusFeedbackData = [];

if bReceiverComSpec
    % With the RecieverComSpec block only Rte Status signals may be associated
    % If a rte status should be modifiable during SIL/PIL simulation depend on the
    % associated DataRecieverComSpec resp. EventReceiverCompSpec
    hRecieverComSpecChildObj = dsdd('GetReceiverComSpec', hDdBlock);
    if isempty(hRecieverComSpecChildObj)
        % With current ReceiverComSpecBlock not ReceiverComSpec is associated,
        % it means no DataReceiverComSpec resp. EventReceiverComSpec objects exists
        % Nothing more to do
        return;
    end
    % Get the handle of the DataReceiverComSpec resp. EventReceiverComSpec
    hReceiverComSpec = dsdd('GetReceiverComSpecDataReceiverComSpecRefTarget', hDdBlock);
    if isempty(hReceiverComSpec)
        % Maybe event ComSpec has been set ?
        hReceiverComSpec = dsdd('GetReceiverComSpecEventReceiverComSpecRefTarget', hDdBlock);
    end
    if isempty(hReceiverComSpec)
        % Neither DataReceiverComSpec nor EventReceiverComSpec objects exists
        % nothing to do
        return;
    end
    rteStatusFeedbackData = FcnGetStatusFeedbackSignalData(hDdBlock, 'status', hReceiverComSpec);
else
    % With the SenderComSpec block Rte Status and/or Rte Feedback signals may be associated
    % If a rte status resp. rte feedback should be modifiable during SIL/PIL simulation depend on the
    % associated DataRecieverComSpec resp. EventReceiverCompSpec
    hSenderComSpecChildObj = dsdd('GetSenderComSpec', hDdBlock);
    if isempty(hSenderComSpecChildObj)
        % With current SenderComSpecBlock not SenderComSpec is associated,
        % it means no DataSenderComSpec resp. EventSenderComSpec objects exists
        % Nothing more to do
        return;
    end
    % Get the handle of the DataReceiverComSpec resp. EventReceiverComSpec
    hSenderComSpec = dsdd('GetSenderComSpecDataSenderComSpecRefTarget', hDdBlock);
    if isempty(hSenderComSpec)
        % Maybe event ComSpec has been set ?
        hSenderComSpec = dsdd('GetSenderComSpecEventSenderComSpecRefTarget', hDdBlock);
    end
    if isempty(hSenderComSpec)
        % Neither DataReceiverComSpec nor EventReceiverComSpec objects exists
        % nothing to do
        return;
    end
    rteStatusData   = FcnGetStatusFeedbackSignalData(hDdBlock, 'status', hSenderComSpec);
    rteFeedbackData = FcnGetStatusFeedbackSignalData(hDdBlock, 'feedback', hSenderComSpec);
    if isempty(rteStatusData) && isempty(rteFeedbackData)
        return;
    end
    rteStatusFeedbackData = FcnInitInterfaceVariableStruct(1);
    m = 1;
    if ~isempty(rteStatusData)
        rteStatusFeedbackData(m) = rteStatusData;
        m = m + 1;
    end
    if ~isempty(rteFeedbackData)
         rteStatusFeedbackData(m) = rteFeedbackData;
    end
end
end


%%
function interfaceVariableData = FcnInitInterfaceVariableStruct(numElems)

interfaceVariableData.name               = '';
interfaceVariableData.hInterfaceVariable = [];
interfaceVariableData.hAccessPoint       = [];
interfaceVariableData.hVariable          = [];
interfaceVariableData.hBlockVariable     = [];
interfaceVariableData.blockPortElement   = 1;
interfaceVariableData.value              = [];
interfaceVariableData.scaling            = [];
interfaceVariableData.width              = [];
interfaceVariableData.path               = '';
interfaceVariableData.hClass             = [];
interfaceVariableData.hType              = [];
interfaceVariableData.hScaling           = [];
interfaceVariableData.element            = [];
interfaceVariableData.kind               = ''; 
interfaceVariableData.hParentStructType  = []; % only for structure components
interfaceVariableData.variableName       = ''; % name obtained from DD
interfaceVariableData.actualVariableName = ''; % name used in production code frame
interfaceVariableData.typeName           = ''; 
interfaceVariableData.usageEnum          = 'VKE_INPUT';
interfaceVariableData.bIsOSEKMessage     = 0;
interfaceVariableData.bIsPointer         = 0;
interfaceVariableData.bIsBitField        = 0;
interfaceVariableData.bIsScalar          = 0;
interfaceVariableData.compiledDataType   = 'SS_DOUBLE';
% AUTOSAR
interfaceVariableData.bIsRteFrameVariable = 0;
% Infos related to variables accessible duriong simulation 
% by means of Simulink.Signal objects.
% They are variables representing RTE status and RTE feedback signals 
% and variables with SimulationValueSource and SimulationValueDestination
% property set
interfaceVariableData.bIsAccessibleDuringSimulation    = 0;
interfaceVariableData.simulinkSignalName               = 'NULL';
interfaceVariableData.simulinkSignalDataTypeID         = 'SS_DOUBLE';
interfaceVariableData.bSimulinkSignalNameSetAtVariable = 1;
% root connection info
interfaceVariableData.ownPort            = [];
interfaceVariableData.portInfoId         = '';
interfaceVariableData.rootPortData       = [];
interfaceVariableData.bCheckForUnconnectedBlockVariables = 0;
interfaceVariableData.blockName                          = '';
interfaceVariableData.blockType                          = '';
interfaceVariableData.hParentBlock                       = [];
interfaceVariableData.bIsTriggerPort                     = 0;
interfaceVariableData.bIsActualParameter                 = 0;  
interfaceVariableData.bIsSystemTime                      = 0;  
% E2EPW
interfaceVariableData.moduleName = '';

if numElems == 0
    % An empty structure is to be created
    interfaceVariableData(1) = [];
else
    interfaceVariableData(numElems) = interfaceVariableData;
end
end


%%
function rteStatusFeedbackData = FcnGetStatusFeedbackSignalData(hDdBlock,...
    rteSignalKind, hDdComSpec)


% Init values
rteStatusFeedbackData = [];

% Check if the required signal label has been set
rteSignalLabel = dsdd(['Get' rteSignalKind 'SignalLabel'], hDdComSpec);
if isempty(rteSignalLabel)
    % nothing to do
    return;
end

% Get the Variable associated with the rte signal
signalBlockVariablePath = [dsdd('GetAttribute', hDdBlock, 'path') '/' rteSignalKind 'Signal'];
hDdRteSignalVariable    = dsdd('GetVariableRefTarget', signalBlockVariablePath);
if isempty(hDdRteSignalVariable)
    % Variable not found, probably it was optimised. Suitable Warning 2082
    % was removed (see PR142729)
    return;
end
% Ok, status signal label and variable found, get the variable data
rteStatusFeedbackData = FcnGetDataOfVariableWithSimulinkSignal(hDdRteSignalVariable,...
    rteSignalLabel, ['VKE_RTE_' upper(rteSignalKind)]);
end


function variableData = FcnGetDataOfVariableWithSimulinkSignal(hDdVariable,...
    simulinkSignalLabel, usageEnum)


% Init values
variableData = FcnInitInterfaceVariableStruct(1);

variableData.hVariable                          = hDdVariable; 
variableData.name                               = dsdd('GetAttribute', hDdVariable, 'name');
variableData.usageEnum                          = usageEnum;
variableData.simulinkSignalName                 = ['"' simulinkSignalLabel '"'];
variableData.bIsAccessibleDuringSimulation      = 1;

% Check the datatype of the simulink signal
try
    simSignalDataType = evalin('base', [simulinkSignalLabel '.DataType']);
catch %#ok<CTCH>
    % Datatype could not be obtained.
    % Assume the double Datatype 
    simSignalDataType = 'double';
end
switch simSignalDataType
    case 'double'
        variableData.simulinkSignalDataTypeID = 'SS_DOUBLE';
    case 'single'
        variableData.simulinkSignalDataTypeID = 'SS_SINGLE';
    case 'int8'
        variableData.simulinkSignalDataTypeID = 'SS_INT8';
    case 'uint8'
        variableData.simulinkSignalDataTypeID = 'SS_UINT8';
    case 'int16'
        variableData.simulinkSignalDataTypeID = 'SS_INT16';
    case 'uint16'
        variableData.simulinkSignalDataTypeID = 'SS_UINT16';
    case 'int32'
        variableData.simulinkSignalDataTypeID = 'SS_INT32';
    case 'uint32'
        variableData.simulinkSignalDataTypeID = 'SS_UINT32';
    case 'boolean'
        variableData.simulinkSignalDataTypeID = 'SS_BOOLEAN';
    otherwise
        fprintf('\n');
        ds_error_msg(['Only built-in Simulink data types are supported for the Simulink.Signal objects ',...
            'used to simulate the RTE status and RTE feedback signals, ',...
            'but the data type of object ',...
            '''' simulinkSignalLabel ''' is ' '''' simSignalDataType '''.'],...
            'Title','Rte status/feedback signal simulation not possible',...
            'MessageNumber', 2093);
        return;
end
        
[variableData.hType, errorCode] = dsdd('GetTypeTarget', hDdVariable);
if FcnCheckGetTargetError(errorCode, hDdVariable, 'Type'), 
    return;
end

variableData = FcnGetInterfaceVariableScaling(variableData);
if ds_error_check, 
    return;
end

variableData = FcnGetInterfaceVariableNameAndType(variableData, hDdVariable);
if ds_error_check, 
    return;
end

% Set the root connection data
for m = 1:variableData.width
    variableData.rootPortData(m).portNumber     = 0;
    variableData.rootPortData(m).portElement    = -1;
end
variableData.ownPort                            = 0;
variableData.bCheckForUnconnectedBlockVariables = 0;
end


%% i_removeInactiveDataVariantVars
function ahReducedVars = i_removeInactiveDataVariantVars(stEnv, hSubsys, ahVars)
% shortcut if no DataVariant is active
stConfig = atgcv_m01_variant_config_get(stEnv);
if ~isfield(stConfig, 'astDataVariants')
    ahReducedVars = ahVars;
    return;
end

% set_A: all our vars ahVars

% set_B: all DV vars 
ahDvVars = atgcv_mxx_dsdd(stEnv, 'Find', hSubsys, ...
    'objectKind', 'Variable', ...
    'Property', {'name', 'DataVariantName'});

% all active DV vars (set_C)
ahActiveDvVars = atgcv_m01_active_dv_vars_get(stEnv, hSubsys);

% set_D = intersect(set_A, set_B): all our vars which are dependent on DV
ahDvVarsPart = intersect(ahVars, ahDvVars); 

% set_E = set_D - set_C: all inactive vars in our original set_A
ahInactiveDvVarsPart = setdiff(ahDvVarsPart, ahActiveDvVars);

% set_D = set_A - set_E:  return value == all vars minus the inactive ones
ahReducedVars = setdiff(ahVars, ahInactiveDvVarsPart);
end


%%
function bIsLocal = i_isLocalScope(stEnv, hVar)
stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
bIsLocal = isempty(stInfo.hClass) || strcmpi(stInfo.sScope, 'local');
end


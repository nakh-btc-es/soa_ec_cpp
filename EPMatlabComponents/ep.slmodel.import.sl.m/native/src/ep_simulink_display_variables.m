%  Handle display variables for Simulink models. NOTE: Used *only* by SL UI menue!
%
%  Install and initialize the context menu in Simulink.
%  [bSuccess, sMessage] = ep_simulink_display_variables('initContextMenu', ...)
%  INPUT PARAMETER(S) AS KEY/VALUE PAIRS
%    'MenuTitle'    (string)   The menu title for the Simulink Tools menu.
%    'BlockFilter'  (function) This function is called on all selected blocks and returns
%                              if the block can be applied for visibility. The default block
%                              filter enables all blocks with port capabilities.
%                              [bEnableForVisibility] = blockfiltercallback(hBlockHandle)
%  OUTPUT PARAMETERS(S)
%    bSuccess       (double)   1 on success, 0 otherwise
%    sMessage       (string)   Error message if bSuccess == 0, empty string otherwise.
%
%  Get all blocks marked as visible.
%  [bSuccess, sMessage, stResult] = ep_simulink_display_variables('getDisp')
%  INPUT PARAMETER(S) AS KEY/VALUE PAIRS
%    'Path'         (string)   The model name (or Subsystem path) to investigate.
%                              The model needs to be be open.
%  OUTPUT PARAMETERS(S)
%    bSuccess       (double)   1 on success, 0 otherwise
%    sMessage       (string)   Error message if bSuccess == 0, empty string otherwise.
%    stResult       (struct)   Result structure from ep_simulink_hierarchy_reader.
%                              The result contains the following model entitites:
%                              - the model (and all referenced models)
%                              - all blocks with display settings (these blocks contain additional data
%                                information in field .Data. Data is a cell array of structs with fields 'Name' and
%                                'Value'. Name is constantly 'PortNumbers'. Value contains an array of port numbers
%                                as string (e.g. '[1 5 6]').
%
%  AUTHOR(S):
%    Rainer.Lochmann@btc-es.de
% $$$COPYRIGHT$$$-2013
%
function [bSuccess, sMessage, stResult] = ep_simulink_display_variables(sCmd, varargin)

%  pessimistic default
bSuccess = 0;
sMessage = 'Internal error in ep_simulink_display_variables.';
stResult = [];

%  prevent persistent data from being cleared
mlock;

if nargin == 0
    %  we need at least the command parameter
    sMessage = 'Not enough input arguments.';
elseif mod(nargin, 2) ~= 1
    %  the number of additional parameters needs to be odd (command + additional key/value pairs)
    sMessage = 'Error in specification of property name and value pairs.';
else
    %  all parameters with odd position need to be strings
    bOk = 1;
    for k=1:2:length(varargin)
        sParameterName = varargin{k};
        if ~ischar(sParameterName)
            sMessage = ['Parameter ', int2str(k + 1), ' is not a key name.'];
            bOk = 0;
            break
        end
    end
    
    if bOk
        %  command dispatcher
        try %#ok<TRYNC>
            fFunction = [];
            switch sCmd
                case 'initContextMenu'
                    fFunction = @i_init_context_menu;
                case 'exitContextMenu'
                    fFunction = @i_exit_context_menu;
                case 'getContextMenuItems'
                    fFunction = @i_get_context_menu_items;
                case 'getDisp'
                    fFunction = @i_get_disp;
                case 'unitTest'
                    fFunction = @i_unit_test;
                case 'unlock'
                    munlock;
                otherwise
                    sMessage = ['Unknown command ''', sCmd, '''.'];
            end
            %  call the internal function
            if ~isempty(fFunction)
                if isempty(varargin)
                    [bSuccess, sMessage, stResult] = feval(fFunction);
                else
                    [bSuccess, sMessage, stResult] = feval(fFunction, varargin{:});
                end
            end
        end
    end
end
end


%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                           ***
%                                                                           ***
%******************************************************************************

%******************************************************************************
%  Return the context menu schema
%******************************************************************************
function [bSuccess, sMessage, schema] = i_get_context_menu_items(sParamName, callbackInfo)
if strcmp(sParamName, 'CallbackInfo')
    bSuccess = 1;
    sMessage = [];
    schema = i_getMenu(callbackInfo);
else
    bSuccess = 0;
    sMessage = ['Unknown parameter ', sParamName];
    schema = [];
end
end

%******************************************************************************
%  Load and save the initial options (needed for access from Simulink callbacks).
%******************************************************************************
function varargout = i_options(varargin)

persistent stOptions;

if nargin == 0
    varargout{1} = stOptions;
else
    stOptions = varargin{1};
end
end


%******************************************************************************
%  Initialize the context menu.
%******************************************************************************
function [bSuccess, sMessage, stResult] = i_init_context_menu(varargin)

%  defaults
bSuccess = 1;
sMessage = '';
stResult = [];

%  default parameter values
stOptions.sMenuTitle = 'BTC EP Simulink Only';

%  parse parameters
for k=1:2:nargin
    sParameterName = varargin{k};
    switch sParameterName
        case 'MenuTitle'
            stOptions.sMenuTitle = varargin{k+1};
            if ~ischar(stOptions.sMenuTitle) || isempty(stOptions.sMenuTitle)
                sMessage = 'Value for parameter ''MenuTitle'' is invalid.';
                bSuccess = 0;
            end
        otherwise
            sMessage = ['Unknown parameter key name ''', sParameterName, '''.'];
            bSuccess = 0;
    end
end

if bSuccess
    %  store the options
    i_options(stOptions);
    
    %  suppress the warning if the context menu is already installed
    status = warning('off', 'all');
    
    try %#ok<TRYNC>
        %  add the context menu
        oCustomMgr = DAStudio.CustomizationManager;
        oCustomMgr.addCustomMenuFcn('Simulink:ContextMenu', @i_getMyContextMenuItems);
        oCustomMgr.updateEditors;
    end
    
    %  reset warning mode
    warning(status);
end
end


%******************************************************************************
%  Exit the context menu.
%******************************************************************************
function [bSuccess, sMessage, stResult] = i_exit_context_menu(varargin)

bSuccess = 0;
sMessage = 'Not yet implemented.';
stResult = [];

end


%******************************************************************************
%  Callback function for Simulink (called on right click and before showing the menu).
%  OUTPUT PARAMETERS
%    schemaFcns (cell array of functions) Callback functions which returns a cell array with
%                                         the callback function which defines the tool menu.
%******************************************************************************
function schemaFcns = i_getMyContextMenuItems(varargin)

schemaFcns = {@i_getMenu};

end


%******************************************************************************
%  Instantiate context menu items (in Simulink callback before showing the menu).
%  INPUT PARAMETERS
%    callbackInfo (DAStudio.CallbackInfo) Given by Simulink and hold the selection.
%  OUTPUT_PARAMETERS
%    schema (DAStudio.ContainerSchema) Menu item with submenu items.
%******************************************************************************
function schema = i_getMenu(callbackInfo)

%  get the previously saved menu title
stOptions = i_options();
if isempty(stOptions)
    sMenuTitel = 'Matlab Simulink';
else
    sMenuTitel = stOptions.sMenuTitle;
end

%  initialize return value
schema = sl_container_schema;
schema.label = sMenuTitel;
schema.state = 'Disabled';

caChildrenFcns = {};

ahSelected = callbackInfo.getSelection;
bIsSingleSelection = length(ahSelected) == 1;

%  filter for Simulink blocks
for k=length(ahSelected):-1:1
    if ~i_check_block(ahSelected(k).Handle)
        ahSelected(k) = [];
    end
end

%  if nothing is left after filtering return immediately
if isempty(ahSelected)
    return
end

%  check for single selection and blocks with more than one output
bSelectOutports = 0;
if bIsSingleSelection
    %  check current selection
    hBlock = ahSelected(1).Handle;
    nOutports = i_get_number_of_outports(hBlock);
    if nOutports > 1
        bSelectOutports = 1;
    end
end

%  selection mode:
%  1.)  single selection with block which has more than one outport
%  2.)  otherwise: select/deselect all outports of all selected blocks

if bSelectOutports
    
    hBlock = ahSelected(1).Handle;
    nOutports = i_get_number_of_outports(hBlock);
    
    [bSuccess, bIsVisible, aOutports] = i_block_disp_get(hBlock); %#ok<ASGLU>
    if bSuccess
        
        stData.Handle = hBlock;
        stData.NumberOfOutports = nOutports;
        stData.VisibleOutports  = aOutports;
        stData.EnableAll   = 0;
        stData.DisableAll  = 0;
        stData.EnablePort  = 0;
        stData.DisablePort = 0;
        stData.Titel       = '';
        stData.Checked     = 'off';
        
        caChildrenFcns{end + 1} = 'separator';
        
        if length(aOutports) < nOutports
            %  not all outports are selected: enable menu 'Mark all outports as visible'
            stData.EnableAll = 1;
            stData.Titel     = 'Mark all outports as visible';
            caChildrenFcns{end + 1} = {@i_menu_outports_disp, stData};
            stData.EnableAll = 0;
        end
        
        if ~isempty(aOutports)
            %  at least one outport is selected: enable menu 'Mark all outports as invisible'
            stData.DisableAll = 1;
            stData.Titel      = 'Mark all outports as invisible';
            caChildrenFcns{end + 1} = {@i_menu_outports_disp, stData};
            stData.DisableAll = 0;
        end
        
        caChildrenFcns{end + 1} = 'separator';
        
        for iOutport=1:nOutports
            if any(aOutports == iOutport)
                %  port iOutport is already selected
                stData.Titel = ['Mark outport ', int2str(iOutport), ' as invisible'];
                stData.EnablePort  = 0;
                stData.DisablePort = iOutport;
                stData.Checked = 'Checked';
            else
                %  port iOutport is not selected
                stData.Titel = ['Mark outport ', int2str(iOutport), ' as visible'];
                stData.EnablePort  = iOutport;
                stData.DisablePort = 0;
                stData.Checked = 'Unchecked';
            end
            caChildrenFcns{end + 1} = {@i_menu_outports_disp, stData}; %#ok<AGROW>
        end
        
        schema.childrenFcns = caChildrenFcns;
        schema.state = 'Enabled';
    end
    
else
    %  this was a multi-selection, do not offer port number view
    [bAddSet, sItemSet, bAddUnset, sItemUnset] = i_check_menu_disp(ahSelected);
    
    if bAddSet || bAddUnset
        caChildrenFcns{end + 1} = 'separator';
        if bAddSet
            data = {1, sItemSet, 1};
            caChildrenFcns{end + 1} = {@i_menu_disp, data};
        end
        if bAddUnset
            data = {1, sItemUnset, 0};
            caChildrenFcns{end + 1} = {@i_menu_disp, data};
        end
        schema.childrenFcns = caChildrenFcns;
        schema.state = 'Enabled';
    end
end
end


%******************************************************************************
%  Check which menu items to show for multi-selection and blocks with one outport.
%  INPUT PARAMETERS
%    ahSelected (array of handles) Array of selected Simulink object handles.
%  OUTPUT PARAMETERS
%    bAddSet    (double) Add the 'Mark block as visible' item
%    sItemSet   (string) Menu item string ('Mark block as visible'/'Mark selected blocks as visible')
%    bAddUnset  (double) Add the 'Mark block as invisible' item
%    sItemUnset (string) Menu item string ('Mark block as invisible'/'Mark selected blocks as invisible')
%******************************************************************************
function [bAddSet, sItemSet, bAddUnset, sItemUnset] = i_check_menu_disp(ahSelected)

bAddSet = 0;
sItemSet = [];
bAddUnset = 0;
sItemUnset = [];

nSelected = length(ahSelected);
if nSelected == 0; return; end %  nothing selected

abDisp = zeros(1, nSelected);
for k=1:nSelected
    hHandle = ahSelected(k).Handle;
    [bSuccess, abDisp(k)] = i_block_disp_get(hHandle);
    if ~bSuccess; break; end
end

if nSelected == 1
    sItemSet   = 'Mark block as visible';
    sItemUnset = 'Mark block as invisible';
else
    sItemSet   = 'Mark selected blocks as visible';
    sItemUnset = 'Mark selected blocks as invisible';
end

bAddSet   = 0;
bAddUnset = 0;
if bSuccess
    %  all blocks support EV visibility
    if all(abDisp)
        bAddUnset = 1;
    elseif ~any(abDisp)
        bAddSet   = 1;
    else
        bAddSet   = 1;
        bAddUnset = 1;
    end
end

end


%******************************************************************************
%  Define activity of main menu item (with tool title) for block with a single output.
%  INPUT PARAMETERS
%    callbackInfo (DAStudio.CallbackInfo) Given by Simulink and holds additional data of the menu entry.
%  OUTPUT PARAMETERS
%    schema (DAStudio.ActionSchema) with menu item attributes.
%******************************************************************************
function schema = i_menu_disp(callbackInfo)

schema = sl_action_schema;

data = callbackInfo.userdata;

if data{1}
    sState = 'Enabled';
else
    sState = 'Disabled';
end

sLabel  = data{2};
bEnable = data{3};

schema.label    = sLabel;
schema.state    = sState;
schema.userdata = bEnable;
schema.callback = @i_menu_block_exec;
end


%******************************************************************************
%  Define activity of main menu item (with tool title) for blocks with more than one output.
%  INPUT PARAMETERS
%    callbackInfo (DAStudio.CallbackInfo) Given by Simulink and holds additional data of the menu entry.
%  OUTPUT PARAMETERS
%    schema (DAStudio.ActionSchema | DAStudio.ToggleSchema) with menu item attributes.
%******************************************************************************
function schema = i_menu_outports_disp(callbackInfo)

stData = callbackInfo.userdata;

switch stData.Checked
    case 'off'
        schema = sl_action_schema;
    case 'Checked'
        schema = sl_toggle_schema;
        schema.checked = 'Checked';
    case 'Unchecked'
        schema = sl_toggle_schema;
end

schema.label    = stData.Titel;
schema.state    = 'Enabled';
schema.userdata = stData;
schema.callback = @i_menu_outports_exec;
end


%******************************************************************************
%  Execute choosen menu item for context menu with outport selection.
%  INPUT PARAMETERS
%    callbackInfo (DAStudio.CallbackInfo) Callback info of the choosen menu item.
%******************************************************************************
function i_menu_outports_exec(callbackInfo)

stData = callbackInfo.userdata;

hBlock = stData.Handle;

if stData.EnableAll
    %  select all outports
    i_block_disp_set(hBlock, []);
elseif stData.DisableAll
    %  deselect all outports
    i_block_disp_unset(hBlock, []);
elseif stData.EnablePort ~= 0
    i_block_disp_set(hBlock, stData.EnablePort);
else  % if stData.DisablePort ~= 0
    i_block_disp_unset(hBlock, stData.DisablePort);
end

end


%******************************************************************************
%  Callback function called by Simulink after menu item has been choosen.
%  INPUT PARAMETERS
%    callbackInfo (DAStudio.CallbackInfo) Given by Simulink and hold the selection.
%******************************************************************************
function i_menu_block_exec(callbackInfo)

try %#ok<TRYNC>
    ahSelected = callbackInfo.getSelection;
    
    %  filter blocks
    for k=length(ahSelected):-1:1
        if ~i_check_block(ahSelected(k).Handle)
            ahSelected(k) = [];
        end
    end
    
    bEnable = callbackInfo.userdata;
    
    for k=1:length(ahSelected)
        hBlock = ahSelected(k).Handle;
        aSelectedOutports = []; %  empty means all
        
        if bEnable
            i_block_disp_set(hBlock, aSelectedOutports);
        else
            i_block_disp_unset(hBlock, aSelectedOutports);
        end
        
    end
end
end


%*****************************************************************************
%  Check the block potentially supports visibility of outputs.
%  INPUT PARAMETERS
%  - hBlock (handle)  Simulink handle of the block.
%  OUTPUT PARAMETERS
%  - bOk    (double)  1 if the block potentially supports visibility, 0 otherwise.
%*****************************************************************************
function bOk = i_check_block(hBlock)

%  check for blocks with outports and description
bOk = 0;
try %#ok<TRYNC>
    stPortHandles = get_param(hBlock, 'PortHandles');
    if ~isempty(stPortHandles.Outport)
        %  we have outport, do we also have a desription field to mark the block ?
        get_param(hBlock, 'Description');
        %  still no exception here: accept the block
        bOk = 1;
    end
end

end


%*****************************************************************************
%  Block filter function for model traversion for function ep_simulink_hierarchy_reader.
%  INPUT PARAMETERS
%    hBlock (handle) Simulink block handle.
%  OUTPUT PARAMETERS
%    bOk    (double) 1 if block potentially supports outports, 0 otherwise.
%*****************************************************************************
function bOk = i_blockfilter(hBlock)

%  check for blocks with description parameter
bOk = 0;
try %#ok<TRYNC>
    %  include all subsystems
    oBlock = get_param(hBlock, 'Object');
    sClass = class(oBlock);
    switch sClass
        case {  'Simulink.SubSystem', ...
                'Stateflow.Chart', ...
                'Stateflow.LinkChart', ...
                'Simulink.Reference', ...
                'Simulink.ModelReference'}
            bOk = 1;
        otherwise
            %  add those blocks with PortHandles and Description
            oBlock.PortHandles;
            oBlock.Description;
            %  still no exception ? then this block is ok
            bOk = 1;
    end
end
end


%******************************************************************************
%  Get the number of outports for a Simulink block.
%  INPUT PARAMETERS
%  - hBlock    (handle) Simulink block handle.
%  OUTPUT PARAMETERS
%  - nOutports (double) Number of outports. 0 on internal error.
%******************************************************************************
function nOutports = i_get_number_of_outports(hBlock)

nOutports = 0;
try %#ok<TRYNC>
    stPortHandles = get_param(hBlock, 'PortHandles');
    nOutports = length(stPortHandles.Outport);
end

end


%******************************************************************************
%  Parameterize the simulink hierarchy reader to find all marked blocks.
%  INPUT PARAMETERS
%    varargin (cell array) Optional parmeters as key value pairs.
%  OUTPUT PARAMETERS
%    bSuccess (double) Success status of operation.
%    sMessage (string) Error message in case of failure.
%    stResult (struct) Resulting struct from call to ep_simulink_hierarchy_reader in case of success.
%******************************************************************************
function [bSuccess, sMessage, stResult] = i_get_disp(varargin)

%  pessimistic defaults
bSuccess = 0;
stResult = [];
sMessage = '';

sPath = '';

%  check parameters
for k=1:2:length(varargin)
    sParameterName = varargin{k};
    parameterValue = varargin{k + 1};
    switch sParameterName
        case 'Path'
            sPath = parameterValue;
        otherwise
            sMessage = ['Unknown parameter key name ''', sParameterName, '''.'];
    end
end

if isempty(sMessage)
    %  check path
    try
        sPath = getfullname(sPath);
    catch %#ok<CTCH>
        sMessage = 'Value for parameter ''Path'' is invalid.';
    end
    
    if isempty(sMessage)
        [bSuccess, sMessage, stResult] = ep_simulink_hierarchy_reader( ...
            sPath, ...
            'CallBack', @i_callbackfcn, ...
            'BlockFilter', @i_blockfilter);
    end
end
end


%******************************************************************************
%  Callback function for ep_simulink_hierarchy_reader to navigate and filter all relevant blocks.
%  INPUT PARAMETERS
%    hEntity (handle) Simulink block handle.
%  OUTPUT PARAMETERS
%    bLookInside      (double) Continue search for children (1) or do consider children (0).
%    bIgnoreEntity    (double) Ignore block in result (1) or add block to result (1).
%    caAdditionalData (cell of structs) The selection ist returned as port number array in the additional data.
%******************************************************************************
function [bLookInside, bIgnoreEntity, caAdditionalData] = i_callbackfcn(hEntity)

%  always run recursively for its children if the entity can be found (active and not out-commented)
bLookInside = i_canBeFound(hEntity);

%  ignore this entity by default
bIgnoreEntity = 1;
caAdditionalData = {};

if ~bLookInside
    return;
end

%  check for model references (always included)
try %#ok<TRYNC>
    sBlockType = get_param(hEntity, 'BlockType');
    if strcmp(sBlockType, 'ModelReference')
        bIgnoreEntity = 0;
    end
end

try %#ok<TRYNC>
    [bSuccess, bIsVisible, aOutports] = i_block_disp_get(hEntity);
    if bSuccess && bIsVisible
        %  this block is marked for visibility
        bIgnoreEntity = 0;
        sOutports = mat2str(aOutports);
        caAdditionalData{1}.Name  = 'PortNumbers';
        caAdditionalData{1}.Value = sOutports;
    end
end

end


%%
function bCanBeFound = i_canBeFound(hEntity)
if atgcv_verLessThan('ML8.0')
    casAddProps = {};
else
    casAddProps = {'IncludeCommented', 'off'};
end

if atgcv_verLessThan('ML9.10')
    caxVariantFilter = {'Variants', 'ActiveVariants'};
else
    % new Variant filter for ML2021a and higher
    caxVariantFilter = {'MatchFilter', @Simulink.match.activeVariants};
end

% check for deactivated variants our commented (out/through) subsystems
hParent = get_param(hEntity, 'Parent');
if isempty(hParent)
    bCanBeFound = true;
else
    ahFoundObjects = find_system(hParent, ...
        'SearchDepth',      1, ...
        'FollowLinks',      'on', ...
        'LookUnderMasks',   'all', ...
        caxVariantFilter{:}, ...
        casAddProps{:},     ...
        'Name',             get_param(hEntity, 'Name'));
    bCanBeFound = ~isempty(ahFoundObjects);
end
end

%******************************************************************************
%  Helper function: remove all display keyword from text.
%  INPUT PARAMETERS
%    sText         (string)  The text to examine.
%  OUTPUT PARAMETERS
%    sText         (string)  The text without display keywords.
%******************************************************************************
function sText = i_remove_disp_keywords(sText)

sDispKeyword = 'EV_DISP';
sRegularExpr = [sDispKeyword, '(\[([0-9]+[ ,]*)*\])?'];

[aStartPositions, aEndPositions] = regexp(sText, sRegularExpr);
if ~isempty(aStartPositions)
    for k=length(aStartPositions):-1:1
        sText(aStartPositions(k):aEndPositions(k)) = [];
    end
end

end


%******************************************************************************
%  Helper function: append display keyword to text.
%  INPUT PARAMETERS
%    sText         (string)       The text.
%    aOutports     (double array) The outport numbers (empty means all outports).
%    nOutports     (double)       Maximum port number.
%  OUTPUT PARAMETERS
%    sText         (string)       The text with added display keyword.
%******************************************************************************
function sText = i_add_disp_keywords(sText, aOutports, nOutports)

sDispKeyword = 'EV_DISP';

switch length(aOutports)
    case 0
        sDispMark = sDispKeyword;
    case 1
        if nOutports == 1
            %  for blocks with just one output just generate 'EV_DISP' without port numbers
            sDispMark = sDispKeyword;
        else
            %  generate 'EV_DISP[<port number>]', e.g. EV_DISP[2]
            sDispMark = [sDispKeyword, '[', mat2str(aOutports), ']'];
        end
    otherwise
        %  generate EV_DISP[<array of port numbers>], e.g. EV_DISP[2 3 5]
        sDispMark = [sDispKeyword, mat2str(aOutports)];
end

%  check if we should add a line break
if isempty(sText)
    sText = sDispMark;
elseif sText(end) == 10
    sText = [sText, sDispMark];
else
    sText = [sText, 10, sDispMark];
end

end


%******************************************************************************
%  Helper function: get (first) display keyword from text.
%  INPUT PARAMETERS
%    sText         (string)       The text.
%    nOutports     (double)       Maximum for outport numbers.
%  OUTPUT PARAMETERS
%    bIsDisp       (boolean)      If the disp keyword was found.
%    aOutports     (double array) The outport numbers (empty means all outports).
%******************************************************************************
function [bIsDisp, aOutports] = i_get_disp_keywords(sText, nOutports)

bIsDisp = 0;
aOutports = [];

sDispKeyword = 'EV_DISP';
sRegularExpr = [sDispKeyword, '(\[([0-9]+[ ,]*)*\])?'];

%  search the first DISP entry
[aStartPositions, aEndPositions] = regexp(sText, sRegularExpr, 'once');

if ~isempty(aStartPositions)
    
    %  parse selected outport numbers
    iStartVector = aStartPositions(1) + length(sDispKeyword);
    iEndVector   = aEndPositions(1);
    
    %  check for array of outport numbers
    if iEndVector - iStartVector > 1
        %  yes, we have selected outport numbers
        try %#ok<TRYNC>
            sIndices = sText(iStartVector:iEndVector);
            aOutports = eval(sIndices);
        end
    end
    
    %  normalize outport vector
    aOutports = i_normalize_outport_numbers(aOutports, nOutports);
    bIsDisp = 1;
end
end


%******************************************************************************
%  Set display information in a block description.
%  INPUT PARAMETERS
%    hBlock     (handle) Handle of the Simulink block.
%    aOutports  (array of double) Selected port numbers. If empty all outports are selected.
%******************************************************************************
function i_block_disp_set(hBlock, aOutports)

%  get number of outports; without outports nothing is to do
nOutports = i_get_number_of_outports(hBlock);
if nOutports ~= 0
    %  normalize the deselection of outports
    aOutports = i_normalize_outport_numbers(aOutports, nOutports);
    
    %  get display information from Simulink block comment
    [bSuccess, sDescription] = i_get_blockcomment(hBlock);
    if bSuccess
        [bIsVisible, aCurrentOutports] = i_get_disp_keywords(sDescription, nOutports);
        if bIsVisible
            %  remove all display marks
            sDescription = i_remove_disp_keywords(sDescription);
            %  add selection to the current mark
            aOutports = union(aOutports, aCurrentOutports);
        end
        %  add the new display mark if something is left to mark
        sDescription = i_add_disp_keywords(sDescription, aOutports, nOutports);
        
        %  and store the description
        i_set_blockcomment(hBlock, sDescription);
    end
end
end


%******************************************************************************
%  Unset/deselect display information in block description.
%  INPUT PARAMETERS
%    hBlock    (handle)          Handle of the Simulink block.
%    aOutports (array of double) Port numbers to deselect.
%                                If empty all outports are deselected.
%******************************************************************************
function i_block_disp_unset(hBlock, aOutports)

%  get number of outports; without outports nothing is to do
nOutports = i_get_number_of_outports(hBlock);
if nOutports ~= 0
    %  normalize the deselection of outports
    aOutports = i_normalize_outport_numbers(aOutports, nOutports);
    
    %  get display information from Simulink block comment
    [bSuccess, sDescription] = i_get_blockcomment(hBlock);
    if bSuccess
        [bIsVisible, aCurrentOutports] = i_get_disp_keywords(sDescription, nOutports);
        if bIsVisible
            %  remove selection from the current mark
            aSelectedOutports = setdiff(aCurrentOutports, aOutports);
            
            %  remove all display marks
            sDescription = i_remove_disp_keywords(sDescription);
            
            if ~isempty(aSelectedOutports)
                %  add the new display mark if something is left to mark
                sDescription = i_add_disp_keywords(sDescription, aSelectedOutports, nOutports);
            end
            
            %  and store the description
            i_set_blockcomment(hBlock, sDescription);
        end
    end
end
end


%******************************************************************************
%  Get display information from a block description.
%  INPUT PARAMETERS
%    hBlock     (handle) Handle of the Simulink block.
%  OUTPUT PARAMETERS
%    bSuccess   (double) Success of function call.
%    bIsVisible (double) 1 if the block or some of the block´s outports are marked as visible.
%    aOutports  (array of double) (Ordered) port numbers of selected outports (e.g. [1 3 4 7])
%******************************************************************************
function [bSuccess, bIsVisible, aOutports] = i_block_disp_get(hBlock)

bSuccess   = 1;
bIsVisible = 0;
aOutports  = [];

%  get the current block and the number of its outports and its description
nOutports = i_get_number_of_outports(hBlock);

%  check for block outputs
if nOutports > 0
    [bSuccess, sDescription] = i_get_blockcomment(hBlock);
    if bSuccess
        %  get display information from comment
        [bIsVisible, aOutports] = i_get_disp_keywords(sDescription, nOutports);
    end
end
end


%******************************************************************************
%  Get block comment.
%  INPUT PARAMETERS
%  - hBlock         (handle)   Simulink block handle.
%  OUTPUT PARAMETERS
%  - bSuccess       (double) 1 if block comment could be read, 0 otherwise.
%  - sBlockComment  (string) The block comment on success, empty otherwise.
%******************************************************************************
function [bSuccess, sBlockComment] = i_get_blockcomment(hBlock)

bSuccess = 0;
sBlockComment = '';

if i_use_targetlink_api(hBlock)
    %  use TL API for TL version less than 3.0 on TargetLink blocks
    try %#ok<TRYNC>
        [sResult, iError] = tl_get(hBlock, 'blockcomment');
        if iError == 0
            bSuccess = 1;
            sBlockComment = sResult;
        end
    end
else
    %  use Simulink API
    try %#ok<TRYNC>
        sBlockComment = get_param(hBlock, 'Description');
        bSuccess = 1;
    end
end

end


%******************************************************************************
%  Set block comment in block.
%  INPUT PARAMETERS
%  - hBlock         (handle)  Simulink block handle.
%  - sBlockComment  (string)  The block comment to be set.
%  OUTPUT PARAMETERS
%  - bSuccess       (double)  1 if block comment could be set, 0 otherwise.
%******************************************************************************
function bSuccess = i_set_blockcomment(hBlock, sBlockComment)

bSuccess = 0;

if i_use_targetlink_api(hBlock)
    %  use TL API for TL version less than 3.0 on TargetLink blocks
    try %#ok<TRYNC>
        bSuccess = tl_set(hBlock, 'blockcomment', sBlockComment) == 0;
    end
else
    %  use Simulink API
    try %#ok<TRYNC>
        set_param(hBlock, 'Description', sBlockComment);
        bSuccess = 1;
    end
end

end


%******************************************************************************
%  Normalize and sort array of outport number.
%  The numbers are sorted, the array elements are saturated by [1,nOutputs],
%  Double elements are eleminated.
%  INPUT PARAMETERS
%    aOutports (array of double) Array of outport numbers.
%    nOutports (double)          Maximal outport number.
%  OUTPUTS PARAMETERS
%    aOutports (array of double) Normalized array of outport numbers.
%******************************************************************************
function aOutports = i_normalize_outport_numbers(aOutports, nOutports)

if isempty(aOutports)
    aOutports = 1:nOutports;
else
    aOutports(aOutports < 1) = [];
    aOutports(aOutports > nOutports) = [];
    aOutports = sort(unique(aOutports));
end
end


%******************************************************************************
%  Internal switch: use TL API or use Simulink API.
%  The TL API is needed only for TargetLink versions less than version 3.0.
%  For these versions, TargetLink has an own attribute for block comments.
%  In all known later version, TargetLink uses the Simulink block description.
%  INPUT PARAMETERS:
%    hBlock     (handle) Simulink block handle
%  OUTPUT PARAMETERS:
%    bUseTlApi (double)  1 if TargetLink block comment API should be used
%                        0 otherwise
%******************************************************************************
function bUseTlApi = i_use_targetlink_api(hBlock)

bUseTlApi = 0;

%  don't compute more than one time
persistent iMajorVersion;
if isempty(iMajorVersion)
    iMajorVersion = 0;
    try %#ok<TRYNC>
        stVersion = ver('Tl');
        if ~isempty(stVersion)
            sVersion = stVersion.Version;
            iResult = sscanf(sVersion, '%d');
            if ~isempty(iResult)
                iMajorVersion = iResult;
            end
        end
    end
end

if iMajorVersion ~= 0
    %  TargetLink is installed
    if iMajorVersion < 3
        %  the TargetLink version is less than TL 3
        try %#ok<TRYNC>
            %  check if the block is a TargetLink block
            sMaskType = get_param(hBlock, 'MaskType');
            bUseTlApi = strncmp(sMaskType, 'TL_', 3);
        end
    end
end

end


%******************************************************************************
%  Return function handles of local functions for unit testing of Simulink callbacks.
%******************************************************************************
function [bSuccess, sMessage, stResult] = i_unit_test()

bSuccess = 1;
sMessage = '';
stResult = struct( ...
    'i_getMyContextMenuItems', @i_getMyContextMenuItems, ...
    'i_getMenu', @i_getMenu, ...
    'i_menu_disp', @i_menu_disp, ...
    'i_menu_outports_disp', @i_menu_outports_disp, ...
    'i_menu_block_exec', @i_menu_block_exec, ...
    'i_menu_outports_exec', @i_menu_outports_exec);
end

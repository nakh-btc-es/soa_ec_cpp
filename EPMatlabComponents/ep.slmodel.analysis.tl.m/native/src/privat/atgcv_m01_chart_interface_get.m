function stInterface = atgcv_m01_chart_interface_get(stEnv, hChart)
% Get the interface of a chart in DD.
%
% function stInterface = atgcv_m01_chart_interface_get(stEnv, hChart)
%
%   INPUT           DESCRIPTION
%     stEnv            (struct)    error environment
%     hChart           (handle)    DD handle of SF-Chart block
%
%   OUTPUT          DESCRIPTION
%     stInterface         (struct)    interface of subsystem
%        .astInports      (array)     array of structs with inport info
%        .astOutports     (array)     array of structs with outport info
%        .bHasEventInputs (bool)      true if Chart has Event Inputs from the outside; otherwise false
%
%   both arrays have following structure:
%     stPort              (struct)    info for single port
%        .iPortNumber     (integer)     port number in model
%        .sSlPortPath     (string)      model path to Simulink port
%        .sBlockType      (string)      kind of Port
%        .hBlock          (handle)      DD handle of Port
%        .astSignals      (array)       structs describing the individual signals of the port
%


%% default port info
stPort = struct( ...
    'iPortNumber',  [],  ...
    'sSlPortPath',  '',  ...
    'sSfName',      '',  ... 
    'sBlockType',   'Stateflow',  ...
    'hBlock',       hChart,  ...
    'astSignals',   []);


%% get model handle of subsystem
hChartModel = i_getChartModelHandle(hChart);
[astInports, astOutports] = i_getChartPorts(hChartModel, stPort);


%% get stateflow nodes from chart
hSfNodes = atgcv_mxx_dsdd(stEnv, 'GetStateflowNodes', hChart);

%% info inputs
casVarNames = {};
[bExist, hSfInputs] = dsdd('Exist', 'Inputs', 'Parent', hSfNodes);
if bExist
    casVarNames = atgcv_mxx_dsdd(stEnv, 'GetPropertyNames', hSfInputs);
end
nInputs = length(astInports);
for i = 1:nInputs
    hBlockVar = i_getChartBlockVarIO(hChart, 'input', astInports(i).iPortNumber);
    if isempty(hBlockVar)
        sSfName = astInports(i).sSfName;    
        if any(strcmp(sSfName, casVarNames));
            hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetInputRefTarget', hSfNodes, sSfName);
        end
    end
    if i_isUsableInputBlockVar(hBlockVar)
        astInports(i).astSignals = i_getSfSignal(stEnv, hBlockVar);
        continue;
    end
    
    % if interface var not found, try if src var is a usable global variable
    hSrcBlockVar = i_getUsableSrcVar(stEnv, hChart, astInports(i).iPortNumber);
    if ~isempty(hSrcBlockVar)
        astInports(i).astSignals = i_getSfSignal(stEnv, hSrcBlockVar);
    else
        % seems to be a dummy var, so use the original block var
        if ~isempty(hBlockVar)
            astInports(i).astSignals = i_getSfSignal(stEnv, hBlockVar);
        else
            sErrMsg = sprintf('Could not find code variable for input "%s".', astInports(i).sSlPortPath);
            stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sErrMsg);
            osc_throw(stErr);
        end
    end
end


%% info outputs
nOutputs = length(astOutports);
for i = 1:nOutputs
    hBlockVar = i_getChartBlockVarIO(hChart, 'output', astOutports(i).iPortNumber);
    if ~isempty(hBlockVar)
        astOutports(i).astSignals = i_getSfSignal(stEnv, hBlockVar);
    else
        sErrMsg = sprintf('Could not find code variable for output "%s".', astOutports(i).sSlPortPath);
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sErrMsg);
    end
end

stInterface = struct( ...
    'astInports',      astInports, ...
    'astOutports',     astOutports, ...
    'bHasEventInputs', i_checkEventInputs(hChartModel));
end


%%
function bIsUsable = i_isUsableInputBlockVar(hBlockVar)
bIsUsable = ~isempty(hBlockVar) && ...
    (dsdd('Exist', hBlockVar, 'property', {'name', 'VariableRef'}) || i_hasChildren(hBlockVar));
end


%%
function bHasChildren = i_hasChildren(hObjDD)
bHasChildren = ~isempty(dsdd('GetChildren', hObjDD));
end


%%
% sKind == 'input' | 'output'
function hBlockVar = i_getChartBlockVarIO(hChart, sKind, iPortNum)
sBlockVarName = lower(sKind);
if (iPortNum > 1)
    sBlockVarName = sprintf('%s(#%i)', sBlockVarName, iPortNum);
end
[~, hBlockVar] = dsdd('Exist', sBlockVarName, 'Parent', hChart);
end



%% 
function hChartModel = i_getChartModelHandle(hChart)
hChartModel = get_param(dsdd_get_block_path(hChart), 'handle');
end


%% 
function bHasEventInputs = i_checkEventInputs(hChartModel)
ahInports = ep_find_system(hChartModel, ...
    'LookUnderMasks',   'all', ...
    'FollowLinks',      'on', ...
    'SearchDepth',      1, ...
    'BlockType',        'TriggerPort');
bHasEventInputs = ~isempty(ahInports);
end


%%
function [astInports, astOutports] = i_getChartPorts(hChartModel, stPort)
ahInports = ep_find_system(hChartModel, ...
    'LookUnderMasks',   'all', ...
    'FollowLinks',      'on', ...
    'SearchDepth',      1, ...
    'BlockType',        'Inport');

nIn = length(ahInports);
astInports = repmat(stPort, 1, nIn);
for i = 1:nIn
    astInports(i).iPortNumber = str2double(get_param(ahInports(i), 'Port'));
    astInports(i).sSfName     = get_param(ahInports(i), 'Name');
    astInports(i).sSlPortPath = getfullname(ahInports(i));
end

ahOutports = ep_find_system(hChartModel, ...
    'LookUnderMasks',   'all', ...
    'FollowLinks',      'on', ...
    'SearchDepth',      1, ...
    'BlockType',        'Outport');

nOut = length(ahOutports);
astOutports = repmat(stPort, 1, nOut);
for i = 1:nOut
    astOutports(i).iPortNumber = str2double(get_param(ahOutports(i), 'Port'));
    astOutports(i).sSfName     = get_param(ahOutports(i), 'Name');
    astOutports(i).sSlPortPath = getfullname(ahOutports(i));
end
end


%%
function stSignal = i_getSfSignal(stEnv, hBlockVar)
stSignal = atgcv_m01_blockvar_signals_get(stEnv, hBlockVar, true);
end


%%
function hSrcBlockVar = i_getUsableSrcVar(stEnv, hChart, iInPort)
hSrcBlockVar = [];
sSrcBlock = 'SourceSignal';
if (iInPort > 1)
    sSrcBlock = sprintf('%s(#%i)', sSrcBlock, iInPort);
end
[bExist, hSrcBlock] = dsdd('Exist', sSrcBlock, 'Parent', hChart);    
if bExist
    if dsdd('Exist', hSrcBlock, 'property', {'name', 'BlockVariableRef'})
        if (atgcv_version_compare('TL3.5') >= 0)
            hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', hSrcBlock, 0);        
        else
            hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', hSrcBlock);
        end
        
        % check if variable is usable; return empty src block var if not
        if dsdd('Exist', hSrcBlockVar, 'property', {'name', 'VariableRef'})
            hVar = atgcv_mxx_dsdd(stEnv, 'GetVariableRef', hSrcBlockVar);
            
            if ~i_isVarUsableGlobal(stEnv, hVar)
                hSrcBlockVar = [];
            end
        end
    end
end
end
    

%%
function bIsUsable = i_isVarUsableGlobal(stEnv, hVar)
bIsUsable = false;

% 1) var is only usable for us if we have a global var and _not_ a MACRO
% ignore const for now
[sScope, ~, bIsMacro] = i_getVarScopeConstMacro(stEnv, hVar);
if (~strcmpi(sScope, 'global') || bIsMacro)
    return;
end

% 2) var only usable if the module is valid/accessible
bIsUsable = i_checkModule(stEnv, hVar);
end


%%
function [sScope, bIsConst, bIsMacro] = i_getVarScopeConstMacro(stEnv, hVar)
try
    stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
    sScope   = stInfo.sScope;
    bIsConst = stInfo.bIsConst;
    bIsMacro = stInfo.bIsMacro;
catch
    sScope   = '';
    bIsConst = true;
    bIsMacro = false;
end
end


%%
function bIsModuleValid = i_checkModule(stEnv, hVar)
% init values
bIsModuleValid = false;

sPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
iFind = regexp(sPath, '/Variables/', 'once');
if isempty(iFind)
    % Variable handle is not inside a Module (maybe in Pool area of DD)
    return;
end

sModulePath = sPath(1:iFind-1);
bIsModuleValid = atgcv_m01_module_check(stEnv, sModulePath);
end


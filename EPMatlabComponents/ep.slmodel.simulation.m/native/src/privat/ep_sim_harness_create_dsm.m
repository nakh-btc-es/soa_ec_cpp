function [hDsmIn, hDsmOut] = ep_sim_harness_create_dsm(hExtrModel, xSubsystem, bTlModel)
% This function creates the DSM interfaces
%
% [hDsmIn, hDsmOut] = ep_sim_harness_create_dsm(xEnv, hExtrModel, xSubsystem)
%
%  INPUT              DESCRIPTION
%   - xEnv              (object)  Environment
%   - hSub              (handle)  Handle of the extraction model
%   - xSubsystem        (string)  XML node holding information about the DSM ports

% DSM Inputs
hDsmIn = i_create_dsm_inports(hExtrModel, xSubsystem, bTlModel);

% DSM Outputs
hDsmOut = i_create_dsm_outputs(hExtrModel, xSubsystem, bTlModel);
end


%%
function hDsmIn = i_create_dsm_inports(hExtrModel, xSubsystem, bTlModel)
ahDSMRead = ep_em_entity_find(xSubsystem, 'child::DataStoreRead');
if isempty(ahDSMRead)
    hDsmIn = [];
    return;
end

% create the Subsystem that contains all DSM write blocks
hDsmIn = add_block('built-in/Subsystem', [getfullname(hExtrModel), '/', 'DsmInports']);

for iNum = 1:length(ahDSMRead)
    % Create inport and set position
    hInport = add_block('built-in/Inport', [getfullname( hDsmIn ),'/',['DSMIn',num2str(iNum)]]);
    nOffset = 10 + ((iNum-1) * 50);
    set_param(hInport, 'Position',  [50, nOffset-10, 100, nOffset+10]);
    set_param(hInport, 'BackgroundColor', 'Yellow');
    
    
    % create DSM write block and set position
    hDsmWrite = add_block('built-in/DataStoreWrite', [getfullname(hDsmIn), '/', ['btc_dsm_', num2str(iNum)]]);
    sWorkspaceSignal = ep_em_entity_attribute_get(ahDSMRead{iNum}, 'signal');
    set_param(hDsmWrite, 'DataStoreName', sWorkspaceSignal);
    anOutPos = [325, nOffset-12, 400, nOffset+12];
    set_param(hDsmWrite, 'Position', anOutPos);
    
    % Connect blocks
    atgcv_m13_connect_blocks(hInport, hDsmWrite);
    
    if bTlModel
        i_addHookForEnsuringSignalObject(hDsmWrite, sWorkspaceSignal);
    end
end
end


%%
function hDsmOut = i_create_dsm_outputs(hExtrModel, xSubsystem, bTlModel)
ahDSMWrite = ep_em_entity_find(xSubsystem, 'child::DataStoreWrite');
if isempty(ahDSMWrite)
    hDsmOut = [];
    return;
end

% create the subsystem that contains all DSM read blocks
hDsmOut = add_block('built-in/Subsystem', [getfullname(hExtrModel), '/', 'DsmOut']);

for iNum = 1:length(ahDSMWrite)
    % create DSM read block and set position
    hDsmRead = add_block('built-in/DataStoreRead', [getfullname(hDsmOut), '/', ['btc_dsm_', num2str(iNum)]]);
    sWorkspaceSignal = ep_em_entity_attribute_get(ahDSMWrite{iNum}, 'signal');
    set_param(hDsmRead, 'DataStoreName', sWorkspaceSignal);
    nOffset = 10 + ((iNum-1) * 30);
    set_param(hDsmRead, 'Position', [50, nOffset-12, 75, nOffset+12]);

    % create outport and set position
    hOutport = add_block('built-in/Outport', [getfullname( hDsmOut ),'/',['DSMOut',num2str(iNum)]]);
    anPosition =  [250, nOffset-10, 300, nOffset+10];
    set_param(hOutport, 'Position', anPosition);
    set_param(hOutport, 'BackgroundColor', 'Yellow');
    
    % connect blocks
    atgcv_m13_connect_blocks(hDsmRead, hOutport);
    
    if bTlModel
        i_addHookForEnsuringSignalObject(hDsmRead, sWorkspaceSignal);
    end
end
end


%% TODO: needed for the TL use case
function i_addHookForEnsuringSignalObject(hBlock, sSignalObjName)
set_param(hBlock, 'Mask', 'on');
set_param(hBlock, 'MaskType', 'Signal Injection');
set_param(hBlock, 'MaskDescription', 'Write signal values as input of SUT.');
set_param(hBlock, 'MaskInitialization', ...
    ['bExist = evalin(''base'', ''exist(''''', sSignalObjName, ''''', ''''var'''')'');', ...
    'if ~bExist, ', ...
    'xTmpObj=Simulink.Signal;', ...
    'xTmpObj.SamplingMode=''Sample based'';', ...
    'xTmpObj.DataType=''double'';', ...
    'xTmpObj.Complexity=''real'';', ...
    'xTmpObj.Dimensions=1;', ...
    'assignin(''base'', ''', sSignalObjName, ''', xTmpObj);', ...
    'end;']);
end
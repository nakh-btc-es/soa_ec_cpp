function ep_sim_add_expected_values(stEnv, hBlock, hSFct)
% Enhances the debug model for showing expected values.
%
% function ep_sim_add_expected_values(stEnv, hBlock, hSFct)
%
%   INPUT               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%   hBlock               (handle)    Block which needs to be masked for the expected values
%   hSFct                (handle)    Block having the outputs to be shown
%
%   OUTPUT              DESCRIPTION
%   -
%%

try
    sHarnessFile = i_get_harness_file(hSFct);
    hDebugModel = mxx_xmltree('load', sHarnessFile);
    xOncleanup = onCleanup(@() mxx_xmltree('clear', hDebugModel));
    ahScalarRefNodes = mxx_xmltree('get_nodes', hDebugModel, '//ScalarRef');
    
    sBlockHandle = getfullname(hBlock);
    ahPorts = get_param(getfullname(hSFct), 'PortHandles');
    casSignalNames = cell(1,length(ahScalarRefNodes));
    casScopeHandles = cell(1,length(ahScalarRefNodes));
    
    for i=1:length(ahScalarRefNodes)
        sSignalName = mxx_xmltree('get_attribute', ahScalarRefNodes(i), 'displayName');
        anPos = get_param(ahPorts.Outport(i), 'Position');
        
        % Demux
        sDemux = ['demux', sSignalName];
        hDemux = add_block('built-in/Demux', [sBlockHandle, '/', sDemux]);
        set_param(hDemux, 'Outputs', '2');
        set_param(hDemux, 'Position',  [anPos(1)+50 anPos(2)-15 anPos(1)+55 anPos(2)+15]);
        
        % Mux
        sMux = ['mux', sSignalName];
        hMux = add_block('built-in/Mux', [sBlockHandle, '/', sMux]);
        set_param(hMux, 'Inputs', '2');
        set_param(hMux, 'Position',  [anPos(1)+100 anPos(2)-15 anPos(1)+105 anPos(2)+15]);
    
        % Scope
        hScope = add_block('built-in/Scope', [sBlockHandle, '/', sSignalName]);
        set_param(hScope, 'Position', [anPos(1)+150 anPos(2)-15 anPos(1)+170 anPos(2)+15]);
        
        % Connect
        add_line(getfullname(hBlock), [get_param(hSFct, 'name'),'/', num2str(i)], [get_param(hDemux, 'name'),'/1']);
        hSimSig = add_line(getfullname(hBlock), [get_param(hDemux, 'name'),'/1'], [get_param(hMux, 'name'),'/1']);
        hExpSig =add_line(getfullname(hBlock), [get_param(hDemux, 'name'),'/2'], [get_param(hMux, 'name'),'/2']);
        set_param(hSimSig, 'Name', 'simulated');
        set_param(hExpSig, 'Name', 'expected');
        add_line(getfullname(hBlock), [get_param(hMux, 'name'),'/1'], [get_param(hScope, 'name'),'/1']);

        casSignalNames{i} = sSignalName;
        casScopeHandles{i} = getfullname(hScope);
    end
    
    i_mask_block(hBlock, casSignalNames, casScopeHandles);
catch exception
    osc_messenger_add(stEnv, ...
        'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
        'step', 'expected value enhancement', ...
        'descr', exception.message );
end
end


%% 
function i_mask_block(hBlock, casSignalNames, casScopeHandles)
set_param(hBlock, 'Mask', 'on');

sPromptString = i_create_variables_string(casSignalNames);
set_param(hBlock, 'MaskPromptString', sPromptString);
sCheckbox = 'checkbox,';
sStyleString = repmat(sCheckbox, 1, length(casSignalNames));
if ~isempty(sStyleString)
    sStyleString = sStyleString(1:end-1);
end
sOff = 'off|';
sOffs = repmat(sOff, 1, length(casSignalNames));
if ~isempty(sOffs)
    sOffs = sOffs(1:end-1);
end
set_param(hBlock, 'BackgroundColor', 'Yellow');
set_param(hBlock, 'MaskStyleString', sStyleString);
set_param(hBlock, 'MaskValueString', sOffs);
set_param(hBlock, 'MaskDisplay', 'disp(''Double-click to select\nsignals for comparison'')');
set_param(hBlock, 'MaskType', 'Signal Selection');
set_param(hBlock, 'MaskDescription', ...
    'Select signals for comparison. For each selected signal a Scope plot is opened when a simulation is started');

sStartFcn = i_create_fcn_string(hBlock, casScopeHandles, 'on', 'open');
set_param(hBlock, 'StartFcn', sStartFcn);

sInitialization = i_create_fcn_string(hBlock, casScopeHandles, 'off', 'close');
set_param(hBlock, 'MaskInitialization', sInitialization);

oMask = Simulink.Mask.get(hBlock);
oCtrl = oMask.getDialogControl('ParameterGroupVar');
if ~isempty(oCtrl)
    oCtrl.Prompt = '';
end
end


%%
function sFcn = i_create_fcn_string(hBlock, casScopeHandles, sValue, sCmd)
sFcn = '';
casMaskNames = get_param(hBlock, 'MaskNames');
for i=1:length(casScopeHandles)
    sScopeHandle = casScopeHandles{i};
    sScopePart = sprintf('if strcmp(get_param(''%s'', ''%s''), ''%s'') %s_system(''%s''); end;', ...
        hBlock, casMaskNames{i}, sValue, sCmd, sScopeHandle);
    sFcn = [sFcn, sScopePart]; %#ok<AGROW>
end
end


%%
function sPromptString = i_create_variables_string(casSignalNames)
sPromptString = '';
for i=1:length(casSignalNames)
    sSignalName = casSignalNames{i};
    sPromptString = [sPromptString, sSignalName, '|']; %#ok<AGROW>
end
%delete last '|' from PromptString
if ~isempty(sPromptString)
    sPromptString = sPromptString(1:end-1);
end
end


%%
function sHarnessFile = i_get_harness_file(hSFct)
sParams = get_param(hSFct, 'Parameters');
jArg = java.lang.String(sParams);
jasSplits = jArg.split(',');
sHarnessFile = char(jasSplits(1).replace('''', ' ').trim());
end
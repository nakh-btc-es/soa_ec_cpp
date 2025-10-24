function  hSubsys = ep_ec_aa_wrapper_workaround_block_create(sPath, dLeftX, dLeftY)
% Creates generic workaround block that will prevent MIL crashes in Matlab 2023b.
% It has no effect on the signal and is not present in the generated code.
%
%  function ep_ec_aa_wrapper_workaround_block_create(sPath, dLeftX, dLeftY)
%
%  INPUT                        DESCRIPTION
%   - sPath                 Path of the subsystem, in which the workaround block is created.
%   - dLeftX                The name of the wrapper model
%   - dLeftX                The name of the wrapper model
%
%  OUTPUT                       DESCRIPTION
%    - hSubsys              (double/handle) Handle of the created workaround block.

%%
dScaling = 55;
dHeight = dScaling - dScaling*0.2;
dRightX = dLeftX + dScaling;
dOffset = dScaling + dScaling*0.8;

% add subsystem block
hSubsys = add_block('simulink/Commonly Used Blocks/Subsystem', ...
    [sPath  '/' 'BTC Workaround'], ...
    'MakeNameUnique', 'on', ...
    'Position', [dLeftX dLeftY 1.2*dRightX (dLeftY + dHeight)]);
Simulink.SubSystem.deleteContents(hSubsys);
sPath = [sPath '/' get_param(hSubsys, 'Name')];

% add inport block
hInport = add_block('simulink/Commonly Used Blocks/In1', ...
    [sPath  '/' 'Input'], ...
    'MakeNameUnique', 'on', ...
    'Position', [dLeftX (dLeftY - dOffset) dRightX ((dLeftY + dHeight/2) - dOffset)]);

% add constant block
hConstant = add_block('simulink/Sources/Constant', ...
    [sPath  '/' 'Constant'], ...
    'MakeNameUnique', 'on', ...
    'Position', [dLeftX dLeftY dRightX (dLeftY + dHeight)]);

% add switch block
hSwitch = add_block('simulink/Signal Routing/Switch', ...
    [sPath  '/' 'Switch'], ...
    'MakeNameUnique', 'on', ...
    'Position', [(dLeftX + 3*dOffset) dLeftY (dRightX + 3*dOffset) (dLeftY + dHeight)]);

% add terminator block
hTerminator = add_block('simulink/Commonly Used Blocks/Terminator', ...
    [sPath  '/' 'Terminator'], ...
    'MakeNameUnique', 'on', ...
    'Position', [(dLeftX + 4*dOffset) dLeftY (dRightX + 4*dOffset) (dLeftY + dHeight)]);


% configure ports
set_param(hConstant, 'Value', '1');
set_param(hSwitch, 'Threshold', '0')

% add lines
stInputPorts = get_param(hInport, 'PortHandles');
stConstantPorts = get_param(hConstant, 'PortHandles');
stSwitchPorts = get_param(hSwitch, 'PortHandles');
stTermPorts = get_param(hTerminator, 'PortHandles');

add_line(sPath, stInputPorts.Outport, stSwitchPorts.Inport(1), 'autorouting', 'on');
add_line(sPath, stInputPorts.Outport, stSwitchPorts.Inport(3), 'autorouting', 'on');
add_line(sPath, stSwitchPorts.Outport, stTermPorts.Inport, 'autorouting', 'on');
add_line(sPath, stConstantPorts.Outport, stSwitchPorts.Inport(2), 'autorouting', 'on');

% create mask
i_createMILWorkaroundMask(hSubsys);
end

%%
function i_createMILWorkaroundMask(hBlock)
oMask = Simulink.Mask.create(hBlock);

oMask.addDialogControl( ...
    'Name',    'DescGroupVar', ...
    'Type',    'group', ...
    'Prompt',  'BTC Embedded Systems MIL stabilizer');
oMask.addDialogControl( ...
    'Name',    'DescTextVar', ...
    'Type',    'text', ...
    'Prompt',  ['The BTC Embedded Systems MIL stabilizer prevents a known Matlab 2023b issue that results in a crash.'...
    ' It has no effect on the signal. Do not edit its contents.'], ...
    'Container', 'DescGroupVar');

oMask.Display = 'disp(''\color[rgb]{0.11,0.34,0.51}\bf MIL stabilizer'', ''texmode'', ''on'');';

set_param(hBlock, 'OpenFcn', 'open_system(gcb, ''mask'');');
set_param(hBlock, 'showname', 'off');
end




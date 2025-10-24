function model = util_generate_model(mname, ninputs, noutputs, label)
% Build a TargetLink/EV model.
%
% function model = util_generate_model(mname, ninputs, noutputs)
%
% This function builds up a TargetLink/EV model with customizable numbers of
% Inports and Outport. Within the TargetLink subsystem a Stateflow chart is
% built with the corresponding number of inouts and outputs and is connected to
% the subsystem´s ports.
%
%   PARAMETER(S)    DESCRIPTION
%   - mname    Model name
%   - ninputs  Number of InPorts of TargetLink subsystem.
%   - noutputs Number of OutPorts of TargetLink subsystem.
%   - label    Label of the Stateflow state.
%
%   OUTPUT
%   - model    Structure with model information.
%
% AUTHOR(S):
%   Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$-2003
%
% $Revision: 1355 $ Last modified: $Date: 2005-08-02 15:02:53 +0200 (Di, 02 Aug 2005) $ $Author: lochman $ 


%  generate defaults for input parameters
switch nargin
    case 0
        mname    = 'Model';
        ninputs  = 1;
        noutputs = 1;
        label    = 'STATE';
    case 1
        ninputs  = 1;
        noutputs = 1;
        label    = 'STATE';
    case 2
        noutputs = 1;
        label    = 'STATE';
    case 3
        label    = 'STATE';
end
        
%*******************************************
%  1. Step : Create the model
%*******************************************
try
    hModel = ep_new_model_create(mname);
catch
    close_system(mname, 0);
    hModel = ep_new_model_create(mname);
end    
open_system(hModel);

%  set simulation parameters
set_param( hModel, ...
    'fixedstep', '1', ...
    'solver', 'fixedstepdiscrete', ...
    'StartTime', '0',...
    'StopTime',  '10');

try
    open_system('simulink');
catch
    MU_FAIL('Can´t open simulink library.');
end

%*******************************************
%  2. Step : Create a TargetLink subsystem
%*******************************************
try
    load_system('tllib');
    %  set dspace data dictionary
    if ~isempty(which('dsdd'))
        dd = [mname, '.dd'];
        if exist(dd, 'file')
            delete(dd);
        end
        dsdd_manage_project('Open', fullfile(getenv('DSPACE_ROOT'),'dsdd','config','dsdd_master_advanced.dd'));
        dsdd_manage_project('SaveAs',dd);
        dsdd('load',dd);
        dsdd_manage_project('SetProjectFile',dd,mname);
    elseif ~strcmp(tl_get_project, 'default')
        tl_set_project('default');
    end
catch
    MU_FAIL('Can´t open TargetLink library.');
end

%  add a TargetLink subsystem
hTlss = add_block('tllib/Subsystem', [mname, '/TLSubSys']);
set_param([mname, '/TLSubSys'], 'Position', [200 150 300 210+40*max(ninputs,noutputs)]);
sTlss = [mname, '/TLSubSys/Subsystem/TLSubSys'];

%  add a TargetLink Main Dialog
add_block('tllib/TargetLink Main Dialog', [mname, '/TargetLink Main Dialog']);
set_param([mname, '/TargetLink Main Dialog'], 'Position', [200 40 300 70]);

%  delete default inports and outports
delete_line(sTlss, 'in./1',  'InPort/1');
delete_block([sTlss, '/in.']);
delete_block([sTlss, '/InPort']);
delete_line(sTlss, 'OutPort/1', 'out./1');
delete_block([sTlss, '/out.']);
delete_block([sTlss, '/OutPort']);

siminport = {};
tlinport  = {};
for i=1:ninputs
    inport = [sTlss, '/in', int2str(i)];
    try
        add_block('simulink/Sources/In1', inport);
    catch
        add_block('simulink/Connections/In1', inport);
    end
    set_param(inport, 'Position', [25 38+30*(i-1) 55 52+30*(i-1)]);
    set_param(inport, 'SampleTime', '1');
    set_param(inport, 'PortWidth', '1');
    tlinport{i}  = [sTlss, '/InPort', int2str(i)];
    add_block('tllib/InPort', tlinport{i});
    set_param(tlinport{i}, 'Position', [85 35+30*(i-1) 125 55+30*(i-1)]);
    add_line(sTlss, ['in', int2str(i), '/1'], ['InPort', int2str(i), '/1']);
end
simoutport = {};
tloutport  = {};
for i=1:noutputs
    simoutport{i} = [sTlss, '/out', int2str(i)];
    try
        add_block('simulink/Sinks/Out1', simoutport{i});
    catch
        add_block('simulink/Connections/Out1', simoutport{i});
    end        
    set_param(simoutport{i}, 'Position', [675 38+30*(i-1) 705 52+30*(i-1)]);
    tloutport{i}  = [sTlss, '/OutPort', int2str(i)];
    add_block('tllib/OutPort', tloutport{i});
    set_param(tloutport{i}, 'Position', [585 35+30*(i-1) 625 55+30*(i-1)]);
    add_line(sTlss, ['OutPort', int2str(i), '/1'], ['out', int2str(i), '/1']);
end

%  make sure that TargetLink updates knowlegde about new ports
if verLessThan('tl', '5.2')
    tl_check_ports(sTlss, 1);
else
    tl_check_ports(sTlss);
end

%  create inputs and terminators
for i=1:ninputs
    siminport{i} = [mname, '/In', int2str(i)];
    try
        add_block('simulink/Sources/In1', siminport{i});
    catch
        add_block('simulink/Connections/In1', siminport{i});
    end        
    set_param(siminport{i}, 'Position', [100 160+40*(i-1) 125 180+40*(i-1)]);
    set_param(siminport{i}, 'DataType', 'int16');
    set_param(siminport{i}, 'PortWidth', '1');
    add_line(mname, ['In', int2str(i), '/1'], ['TLSubSys/', int2str(i)]);
end
for i=1:noutputs
    terminator = [mname, '/Terminator', int2str(i)];
    try
        add_block('simulink/Sinks/Terminator', terminator);
    catch
        add_block('simulink/Connections/Terminator', terminator);
    end
    set_param(terminator, 'Position', [400 160+40*(i-1) 425 180+40*(i-1)]);
    add_line(mname, ['TLSubSys/', int2str(i)], ['Terminator', int2str(i), '/1']);
end

%  make sure that TargetLink updates knowegde about new ports
tl_check_ports(sTlss, 1);


%  /HS, add EV
% try
%     load_system('evlib');
% catch
%     MU_FAIL('Can´t open EmbeddedValidator library.');
% end
% add_block(['evlib/Simulink//Stateflow', 10, 'Verification Environment'], [mname, '/EV2']);
% set_param([mname, '/EV2'], 'Position',[40 40 170 70]);

%  close libs
close_system('tllib');
close_system('simulink');
% /HS close_system('evlib');


%*******************************************
%  3. Step : Create a Stateflow Chart
%*******************************************
try
    load_system('sflib');
catch
    MU_FAIL('Can´t open stateflow library.');
end

slc = [mname, '/TLSubSys/Subsystem/TLSubSys/SFChart'];
add_block('sflib/Chart', slc);
set_param(slc,'Position', [300, 10, 400, 10+50+30*max(ninputs,noutputs)]);
close_system('sflib');

sfm = find(sfroot, '-isa', 'Stateflow.Machine', 'Name', mname);
sfc = find(sfm, '-isa', 'Stateflow.Chart');
%  select that chart with name SFChart
for i=1:length(sfc)
    name  = get(sfc(i), 'Name');
    [p,n] = fileparts(name);
    if strcmp(n, 'SFChart')
        sfc = sfc(i);
        break;
    end
end

%  set strong data typing with simulink for TL 2.x
%  reason : TL13 is casting all simulink types to double
%           TL2  is virtual and does not change the simulink type
%if osc_is_tl13
    sfc.StrongDataTypingWithSimulink = 0;
% else
%     sfc.StrongDataTypingWithSimulink = 1;
% end

sfin = {};
for i=1:ninputs
    %  create a SF Input
    name             = sprintf('sfin%d', i);
    sfin{i}          = Stateflow.Data(sfc);
    sfin{i}.Scope    = 'Input';
    sfin{i}.Name     = name;
    sfin{i}.DataType = 'int16';
    tl_set(sfin{i}.Id, ...
        'class', 'NOPT_GLOBAL', ...
        'name',   name);
%     if ~osc_is_tl13 
%         tl_set(sfin{i}.Id, 'type',  'Int16');
%     end
    %  connect input to targetlink port
    add_line(sTlss, sprintf('InPort%d/1', i),  sprintf('SFChart/%d', i));
end

sfout = {};
for i=1:noutputs
    %  create a SF Output
    name              =  sprintf('sfout%d', i);
    sfout{i}          =  Stateflow.Data(sfc);
    sfout{i}.Scope    = 'Output';
    sfout{i}.Name     =  name;
    sfout{i}.DataType = 'int16';
    tl_set(sfout{i}.Id, ...
        'class', 'NOPT_GLOBAL', ...
        'name',   name);
%     if ~osc_is_tl13 
%         tl_set(sfout{i}.Id, 'type',  'Int16');
%     end

    %  connect output to targetlink port
    add_line(sTlss, sprintf('SFChart/%d', i), sprintf('OutPort%d/1', i));
end    
        

%*******************************************
%  Create a state with default transition
%*******************************************
sfstateA = Stateflow.State(sfc);
sfstateA.Name = 'STATE';
sfstateA.Position = [20 20 600 400];
sfstateA.label = label;
sftrans_default = Stateflow.Transition(sfc);
sftrans_default.Destination=sfstateA;

%  hide Stateflow chart editor
sfc.Visible=0;

%  save system
save_system(mname);

model = struct( ...
    'name',     mname, ...
    'handle',   hModel, ...
    'sfchart',  sfc, ...
    'inports',  struct('path',tlinport,  'slin',  siminport,  'sfin',  sfin), ...
    'outports', struct('path',tloutport, 'slout', simoutport, 'sfout', sfout) ...
    );

return;
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

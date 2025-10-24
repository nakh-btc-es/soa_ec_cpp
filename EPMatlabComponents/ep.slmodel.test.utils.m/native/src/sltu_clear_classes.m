% this is explicitly not a function, but a script. This is needed in order
% to run the clear command in the correct workspace.


%%
sltu_coverage_backup('save');

fprintf('[INFO:%s:SLTU_CLEAR_CLASSES] %s\n', datestr(now, 'HH:MM:SS'), 'executing "clear classes" in base workspace');
evalin('base', 'clear classes');

sltu_coverage_backup('load_and_delete');


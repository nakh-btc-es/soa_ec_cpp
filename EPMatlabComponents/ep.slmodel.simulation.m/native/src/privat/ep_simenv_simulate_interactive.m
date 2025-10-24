function ep_simenv_simulate_interactive(sSimModelName)
% skip interactive simulation for ML2018a/b - EP-2027
if verLessThan('matlab', '9.6')
    sSimCommand = sprintf('sim(''%s'');', sSimModelName);
    evalin('base', sSimCommand);
    return;
end

% enableLogging
sLogFile = fullfile(tempdir(), sprintf('%s.log', datestr(now, 30))); %#ok<TNOW1,DATST>
oOnCleanupDisableLogging = i_enableSimulationLogging(sLogFile); %#ok onCleaup object for reverting the logging state

i_simulate(sSimModelName);

% process logging data
set_param(sSimModelName, 'SimulationCommand', 'WriteDataLogs');
i_processSimulationLogging(sLogFile);
end


%%
function i_simulate(sSimModelName)
% simulate, but use different command on Linux if no display mode is active. See EPDEV-73498
if isunix && ~usejava('desktop')
    sSimCommand = sprintf('sim(''%s'');', sSimModelName);
    evalin('base', sSimCommand);
else
    set_param(sSimModelName, 'SimulationCommand', 'start');
end

while any(strcmp(get_param(sSimModelName, 'SimulationStatus'), {'paused', 'running'}))
    pause(0.005);
end
end


%%
function i_cleanup()
sldiagviewer.diary('off');
end


%%
function oOnCleanupDisableLogging = i_enableSimulationLogging(sLogFile)
sldiagviewer.diary('off');
try
    sldiagviewer.diary(sLogFile)
    sldiagviewer.diary('on');
catch
    % ok
end
oOnCleanupDisableLogging = onCleanup(@() i_cleanup());
end


%%
function  i_processSimulationLogging(sLogFile)
hFin = fopen(sLogFile);
oOnCleanupClose = onCleanup(@() fclose(hFin));

try
    bErrorStateEntered = false;
    sLine = fgetl(hFin);
    while ischar(sLine)
        sLine = strtrim(sLine);

        % if we are in an error state
        if bErrorStateEntered
            % as long as we are in the error state, we want to skip the lines starting with "caused" and throw an error
            % with the following line as message
            if isempty(regexp(sLine, '^Caused by:', 'once'))
                throwAsCaller(MException('EP:SIM_INTERACTIVE:FAILED', sLine));
            end
        else
            if ~isempty(regexp(sLine, '^Error:', 'once'))
                sLine = strrep(sLine, 'Error:', '');
                if ~isempty(sLine)
                    throwAsCaller(MException('EP:SIM_INTERACTIVE:FAILED', sLine));
                end
                bErrorStateEntered = true;
            end
        end
        sLine = fgetl(hFin);
    end
catch oEx
    throwAsCaller(oEx);
end
end

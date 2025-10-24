function ep_simenv_close(xEnv, sSimEnvModel)
% Closes the simenv and do the cleanup. (Model open is assumed)
%
% function ep_simenv_close(xEnv, sSimEnvModel)
%
%   INPUT               DESCRIPTION
%     xEnv                Environment object.
%     sSimEnvModel        File path to simulation model - loaded assumed.
%
%   OUTPUT              DESCRIPTION
%


%%  main internal functionality
try
    %  we have to cd into model directory
    [~, sSimModelName] = fileparts(sSimEnvModel);
     
    sSimulationStatus = get_param(sSimModelName, 'SimulationStatus');
    
    if ~strcmp(sSimulationStatus, 'stopped')
        set_param(sSimModelName, 'SimulationCommand', 'stop');
    end
      
catch oEx
    xEnv.rethrowException(oEx);
end
end

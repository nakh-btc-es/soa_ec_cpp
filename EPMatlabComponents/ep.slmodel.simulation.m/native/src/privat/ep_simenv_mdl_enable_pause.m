function ep_simenv_mdl_enable_pause(xEnv,sSimEnvModel)
% Enable ep_simenv_mdl_enable_pause(xEnv,sSimEnvModel)
%
% function ep_simenv_mdl_enable_pause(xEnv,sSimEnvModel)
%
%   INPUT               DESCRIPTION
%     xEnv                Environment settings.
%     sSimEnvModel        File path to simulation model - loaded assumed.
%
%
%   OUTPUT              DESCRIPTION
%


%%
% get current path (to cd later back to)
curPath = cd;

%%  main internal functionality
try
    %  we have to cd into model directory
    [simModelPath, simModelName] = fileparts(sSimEnvModel);
    cd(simModelPath);
    
    sConstantName = 'Pause Enabled';
    sWSBlockPath = [simModelName,'/', sConstantName];
    casBlocks = ep_find_system(simModelName,'Name',sConstantName,...
        'Parent',simModelName);
    if( isempty(casBlocks) ) % if not, is already available
        hConstant = add_block('built-in/Constant', sWSBlockPath);
        
        % set the properties of the FromWorkspace block.
        set_param( hConstant, 'Value', '0');
        
        
        sAssertName = 'Simulation Controller';
        sAssertBlockPath = [simModelName,'/', sAssertName];
        hAssertion = add_block('built-in/Assertion', sAssertBlockPath );
        
        % set the properties of the Asserion block.
        set_param( hAssertion, 'AssertionFailFcn','ep_simenv_pause');
        set_param( hAssertion, 'StopWhenAssertionFail','off');
        
        
        % position and lines
        anPosition =  [10 50 60 75];
        set_param( hConstant, 'Position', anPosition);
        set_param( hConstant, 'BackgroundColor', 'Yellow');
        
        anPosition =  [100 50 150 75];
        set_param( hAssertion, 'Position', anPosition);
        set_param( hAssertion, 'BackgroundColor', 'Yellow');
        
        add_line(simModelName,[sConstantName,'/1'],[sAssertName,'/1']);
    end
catch exception
    cd(curPath);
    xEnv.rethrowException(exception);
end

cd(curPath);
end


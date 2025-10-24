function ep_simenv_derive(xEnv, sSimEnvModel, sLoggingAnalysisFile, castLoggedSubsystems)
% Simulates the model in the previous defined simulation kind.
%
% function ep_simenv_derive(xEnv, sSimEnvModel, sLoggingAnalysisFile, castLoggedSubsystems)
%
%   INPUT               DESCRIPTION
%     xEnv                   Environment settings.
%     sSimEnvModel           File path to simulation model - loaded and
%                            init assumed.
%     sLoggingAnalysisFile   Logging analysis file
%     castLoggedSubsystems   cell of Subsystems to be logged
%   OUTPUT              DESCRIPTION
%


%%
sCurPath = cd;
oOnCleanupReturnHere = onCleanup(@() cd(sCurPath));


%%
try
    [sSimModelPath, sSimModelName] = fileparts(sSimEnvModel);
    cd(sSimModelPath);
        
    xEnv.setProgress(10, 100, 'Simulate Model');
    
    [nLength, sVecName] = i_getVectorInfo(sLoggingAnalysisFile);
    
    bInteractiveSimulation = false;
    oSimException = ep_simulate(xEnv, sSimEnvModel, nLength, bInteractiveSimulation);
    ep_simenv_eval_exception(xEnv, oSimException, sSimModelName, sVecName);    
    
    %% evaluate the simulation results
    if ~isempty(castLoggedSubsystems)
        ep_sim_write_derived_values(xEnv, sLoggingAnalysisFile, castLoggedSubsystems, nLength);
    else
        sTempDir = xEnv.getTempDirectory();
        ep_simenv_logging_evaluate(xEnv, sTempDir, sLoggingAnalysisFile);
    end
    
    xEnv.setProgress(100, 100, 'Simulate Model');
    
    
catch oEx
    xEnv.rethrowException(oEx);
end
end


%%
function [nLength, sVecName] = i_getVectorInfo(sLoggingAnalysisFile)
hLoggingAnalysisDoc = mxx_xmltree('load', sLoggingAnalysisFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hLoggingAnalysisDoc));

hLoggingAnalysisRoot = mxx_xmltree('get_root', hLoggingAnalysisDoc);

sLength = mxx_xmltree('get_attribute', hLoggingAnalysisRoot, 'length');
nLength = str2double(sLength);
sVecName = mxx_xmltree('get_attribute', hLoggingAnalysisRoot, 'name');
end

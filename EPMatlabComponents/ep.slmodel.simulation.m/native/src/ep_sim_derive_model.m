function ep_sim_derive_model(varargin)
% This function simulates the provided model (this can be a TargetLink or
% Simulink model). It is assumed that the model is already open.
%
% function ep_sim_derive_model(varargin)
%
%  INPUT              DESCRIPTION
%   - varargin           ([Key, Value]*)  Key-value pairs with the following 
%                                       possibles values. Inputs marked with (*)
%                                       are mandatory.
%    Key(string):            Meaning of the Value:
%         ModelFile*              Path to the TargetLink/Simulink model
%                                 file (.mdl|.slx). 
%         LoggingAnalysisFile*    Path to the result vector XML File. The
%                                 file contain the expected output
%                                 interfaces fpr different scopes.(see LoggingAnalysis.xsd)
%         MessageFile             The absoulte path to the message file for
%                                 recording errors/warnings/info messages.
%         LoggedSubsystems        Subsystems to be logged.
%
%         Progress     (object)   Progress object for progress information.
%  OUTPUT            DESCRIPTION
%


%%
xEnv = EPEnvironment();
sMessageFile = '';
try
    % args eval
    [sModelFile, sLoggingAnalysisFile, sMessageFile, castLoggedSubsystems] = i_evalArgs(xEnv, varargin{:});    
    [~, sModelName] = fileparts(sModelFile);
    
    % main call
    tic;
    ep_simenv_derive(xEnv, sModelFile, sLoggingAnalysisFile, castLoggedSubsystems);
    
    fprintf('### Derive Model "%s" Time :\n', sModelName);
    toc;
    
    % message handling
    xEnv.attachMessages(sMessageFile);
    xEnv.exportMessages(sMessageFile);
    xEnv.clear();
    
catch oEx   
    EPEnvironment.cleanAndThrowException(xEnv, oEx, sMessageFile);
end
end


%%
function [sModelFile, sLoggingAnalysisFile, sMessageFile, castLoggedSubsystems] = i_evalArgs(xEnv, varargin)
casValidKeys = { ...
    'ModelFile', ...
    'MessageFile', ...
    'Progress', ...
    'LoggingAnalysisFile', ...
    'LoggedSubsystems'};
stArgs = ep_core_transform_args(varargin, casValidKeys);

ep_sim_argcheck('ModelFile', stArgs, 'obligatory', {'class', 'char'});
ep_sim_argcheck('ModelFile', stArgs, 'file');
ep_sim_argcheck('LoggingAnalysisFile', stArgs, 'obligatory', {'class', 'char'});
ep_sim_argcheck('LoggingAnalysisFile', stArgs, 'file');
ep_sim_argcheck('LoggingAnalysisFile', stArgs, {'xsdvalid', 'LoggingAnalysis.xsd'});
ep_sim_argcheck('MessageFile', stArgs, {'class', 'char'});
ep_sim_argcheck('LoggedSubsystems', stArgs, {'class', 'cell'});
ep_sim_argcheck('Progress', stArgs, {'class','ep.core.ipc.matlab.server.progress.Progress'});

% obligatory
sModelFile = stArgs.ModelFile;
sLoggingAnalysisFile = stArgs.LoggingAnalysisFile;

% optional
sMessageFile = '';
if isfield(stArgs, 'MessageFile')
    sMessageFile = stArgs.MessageFile;
end

if isfield(stArgs, 'Progress')
    xEnv.attachProgress(stArgs.Progress);
end

castLoggedSubsystems = [];
if isfield(stArgs, 'LoggedSubsystems')
    castLoggedSubsystems = stArgs.LoggedSubsystems;
end
end


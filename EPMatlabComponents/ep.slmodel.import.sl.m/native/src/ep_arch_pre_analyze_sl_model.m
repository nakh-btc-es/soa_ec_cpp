function stResult = ep_arch_pre_analyze_sl_model(varargin)
% The pre-analysis returns information about the Simulink model's subsystem hierarchy and potential model parameters.
% For this, the given model is opened, analyzed and closed.
%
% function stResult = ep_arch_pre_analyze_sl_model(varargin)
%
%  INPUT              DESCRIPTION
%    varargin           ([Key, Value]*)  Key-value pairs with the following
%                                        possibles values
%
%    Key(string):            Meaning of the Value:
%    - SlModelFile             (String)*   The absolute path to the
%                                          Simulink model.
%    - SlInitScript            (String)    The absolute path to the
%                                          init script of the Simulink
%                                          model.
%    - ParameterHandling       (String)    ('Off' | {'ExplicitParam'}
%                                          ---------------- 'Off' ---------------------
%                                          Only regular inputs in the interface of
%                                          subsystems are observed.
%                                          ------------ 'ExplicitParam' ---------------
%                                          Parameter variables are regarded as
%                                          additional inputs to subsystems. Their value
%                                          is set once during the initial phase of the
%                                          simulation and is held constant thereafter.
%                                          (default is 'ExplicitParam')
%    - MessageFile              (String)   The absoulte path to the message file. If empty,
%                                          no messages are returned.
%    - Progress                 (object)   Progress object for progress information.
%
%  OUTPUT            DESCRIPTION
%  - stResult                   (Struct)     The result structure
%      .stResultParameter       (Struct)     The result of the potential parameters.
%        .casName               (cell array) Names of the variables
%        .casClass              (cell array) Classes of the variables
%        .casType               (cell array) Types of the variables
%      .stSubsystemHierarchy    (Struct)     The subsystem hierarchy result.
%        .caSubsystems          (cell array) Entities of subsystem nodes
%           .path               (String)     Path of a subsystem
%           .caSubsystems       (cell array) Entities of subsystem nodes
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

%% Parse arguments
try
    %% Init variables
    stSlOpen = [];
    xEnv = [];
    sPwd = pwd;
    stArgs = struct();
    
    % Parse arguments
    stArgs = i_parse_input_arguments(varargin{:});
    
    %% Create env
    xEnv = EPEnvironment(stArgs.hProgress);
    
    %% Go to model directory
    [sPath, sModelName] = fileparts(stArgs.sSlModelFile);
    cd(sPath);
    xEnv.setProgress(0,100,'Opening Model');
    
    %% open the model
    stModelOpenArgs = struct(...
        'sModelFile', stArgs.sSlModelFile, ...
        'caInitScripts', {{stArgs.sSlInitScript}}, ...
        'bIsTL', false, ...
        'bCheck', true, ...
        'bActivateMil', false, ...
        'bIgnoreInitScriptFail', false, ...
        'bIgnoreAssertModelKind', true, ...
        'bEnableBusObjectLabelMismatch', true);
    stSlOpen = ep_core_model_open(xEnv, stModelOpenArgs);
    xEnv.setProgress(20,100,'Analyzing Model');
    
    %% analyze the model
    stResult = struct();
    if strcmp(stArgs.sParameterHandling, 'ExplicitParam')
        stResult.stResultParameter = ep_arch_get_sl_parameters(xEnv, sModelName);
    else
        stResult.stResultParameter = [];
    end
    stResult.stSubsystemHierarchy = ep_arch_get_sl_subsystem_hierarchy(xEnv, sModelName);
    
    %% close the model
    xEnv.setProgress(80,100,'Analyzing Model');
    
    ep_core_model_close(xEnv, stSlOpen);
    xEnv.setProgress(100,100,'Analyzing Model');
    xEnv.exportMessages(stArgs.sMessageFile);
    xEnv.clear;
    cd(sPwd);
catch exception
    %% clean up
    if ~isempty(stSlOpen)
        ep_core_model_close(xEnv, stSlOpen);
    end
    cd(sPwd);
    sMessageFile = [];
    if (isfield(stArgs, 'sMessageFile'))
        sMessageFile = stArgs.sMessageFile;
    end
    EPEnvironment.cleanAndThrowException(xEnv, exception, sMessageFile);
end
end




%%
% Verifies the input arguments and sets defaults if necessary
%
%   PARAMETER(S)    DESCRIPTION
%   -  varargin      ([Key, Value]*)  Key-value pairs to be transformed.
%   OUTPUT
%   - stArgs         (struct)         The parsed inputs
%
function stArgs = i_parse_input_arguments(varargin)
% Definition of the return value (stArgs) with default values.
stArgs = struct( ...
    'sSlModelFile',         '', ...
    'sSlInitScript',        '', ...
    'sParameterHandling',   'ExplicitParam', ...
    'sMessageFile',         '', ...
    'hProgress',            []);

stArgs = i_fill_arguments(stArgs, varargin{:});
if ~isempty(stArgs.sSlModelFile)
    [~, stArgs.sSlModel] = fileparts(stArgs.sSlModelFile);
end

% loop over all input arguments which must be handled explicitly.
casKeys = fieldnames(stArgs);
nLen = length(casKeys);
for i = 1:nLen
    sKey   = casKeys{i};
    sValue = stArgs.(sKey);
    switch sKey
        case 'sParameterHandling'
            switch lower(sValue)
                case 'off'
                    stArgs.sParameterHandling = 'Off';
                case 'explicitparam'
                    stArgs.sParameterHandling = 'ExplicitParam';
                otherwise
                    throw(MException('EP:INTERNAL:ERROR', 'Unknown paramter mode: %s', sValue));
            end
        otherwise
            % just ignore arguments that are not interesting
    end
end
end


%%
function stArgs = i_fill_arguments(stArgs, varargin)
% Parse inputs from main function
casValidKeys = {'SlModelFile', 'SlInitScript', 'ParameterHandling', 'TestMode', 'MessageFile', 'Progress'};
stArgsTmp = ep_core_transform_args(varargin, casValidKeys);

% mainly a re-mapping to new fields
stKeyMap = struct( ...
    'SlModelFile',        'sSlModelFile', ...
    'SlInitScript',       'sSlInitScript', ...
    'ParameterHandling',  'sParameterHandling', ...
    'TestMode',           'sTestMode', ...
    'MessageFile',        'sMessageFile', ...
    'Progress',           'hProgress');

casKnownKeys = fieldnames(stKeyMap);
for i = 1:length(casKnownKeys)
    sKey = casKnownKeys{i};
    if isfield(stArgsTmp, sKey)
        stArgs.(stKeyMap.(sKey)) = stArgsTmp.(sKey);
    end
end
end

function varargout = ep_sl_args_eval(varargin)
% Checking provided options for validity.
%
%    Allowed Keys:            Meaning of the Value:
%    - ModelFile                (string)*   The absolute path to the Simulink model.
%    - InitScriptFile           (string)*   The absolute path to the init script of the Simulink model. (can be empty)
%    - AddModelInfoFile         (string)    The absolute path to additional model information.
%                                           The format is described by the AddModelInfo.dtd.
%
%    - FixedStepSolver          (string)    'yes' | 'no'
%                                           Handling when a non-fixed-step solver is ecountered: If 'yes', the solver
%                                           is automatically set to fixed-step. Otherwise an error is issued.
%                                           (default == 'no')
%    - ParameterHandling        (string)    'Off' | 'ExplicitParam'
%                                           Shall parameters be taken into account. (default == 'ExplicitParam')
%    - TestMode                 (string)    'BlackBox' | 'GreyBox'
%                                           Shall locals be taken into account. (default == 'GreyBox')
%    - bDSReadWriteObservable   (boolean)   If true datastores with read/write access within a scope are considered as
%                                           writers
%    - SlArchFile               (string)*   Location where the SL architecture file shall be placed.
%    - SlConstrFile             (string)*   Location where the SL constraint file shall be placed.
%    - CompilerFile             (string)*   Location where the Compiler file shall be placed.
%    - MessageFile              (string)*   Location where the Message file shall be placed.
%    - Progress                 (object)    Object for tracking progress, e.g. UI workflow.
%

%%
casValidKeys = {...
    'ModelFile', ...
    'InitScriptFile', ...
    'AddModelInfoFile', ...
    'FixedStepSolver', ...
    'ParameterHandling', ...
    'TestMode', ...
    'DSReadWriteObservable',...
    'SlArchFile', ...
    'SlConstrFile', ...
    'CompilerFile', ...
    'MessageFile', ...
    'Progress'};
if (nargin < 1)
    varargout{1} = casValidKeys;
else
    varargout{1} = i_evalArgs(casValidKeys, varargin{:});   
end
end


%%
function stArgs = i_evalArgs(casValidKeys, varargin)
stArgs = ep_core_transform_args(varargin, casValidKeys);

ep_core_check_args({'ModelFile'}, stArgs, 'obligatory', 'file');
ep_core_check_args({'InitScriptFile'}, stArgs, 'file');
ep_core_check_args({'AddModelInfoFile'}, stArgs, 'file');
ep_core_check_args({'ParameterHandling'}, stArgs, {'class', 'char'}, {'keyvalue_i', {'ExplicitParam', 'Off'}});
ep_core_check_args({'TestMode'}, stArgs, {'class', 'char'}, {'keyvalue_i', {'GreyBox', 'BlackBox'}});
ep_core_check_args({'DSReadWriteObservable'}, stArgs, {'class', 'logical'});
ep_core_check_args({'FixedStepSolver'}, stArgs, {'class', 'char'}, {'keyvalue_i', {'yes', 'no'}});

% normalize all file arguments
casFiles = { ...
    'ModelFile', ...
    'InitScriptFile', ...
    'AddModelInfoFile', ...
    'SlArchFile', ...
    'SlConstrFile', ...
    'CompilerFile', ...
    'MessageFile'};
for i = 1:numel(casFiles)
    sOutFile = casFiles{i};
    
    if (isfield(stArgs, sOutFile) && ~isempty(stArgs.(sOutFile)))
        stArgs.(sOutFile) = ep_core_canonical_path(stArgs.(sOutFile), pwd);
    end
end

% fill optional arguments with defaults
stDefaults = struct ( ...
    'InitScriptFile',          '', ...
    'ParameterHandling',       'ExplicitParam', ...
    'TestMode',                'GreyBox', ...
    'FixedStepSolver',         'no', ...
    'DSReadWriteObservable',   false, ...
    'AddModelInfoFile',        '', ...
    'AddModelInfoIsGenerated', 'no', ...
    'Progress',                []);

% TODO: remove when feature is finished
% warning('EP:DEV', 'Using temporaray feature toggles.');
%stDefaults.ToggledFeatures = {'ALLOW_ARRAY_OF_BUSES_PORTS'};

casOptionalArgs = fieldnames(stDefaults);
for i = 1:numel(casOptionalArgs)
    sOptArg = casOptionalArgs{i};
    
    if ~isfield(stArgs, sOptArg)
        stArgs.(sOptArg) = stDefaults.(sOptArg);
    end
end

% fill out derived arguments
[~, stArgs.Model] = fileparts(stArgs.ModelFile);
stArgs.ResultDir = fileparts(stArgs.SlArchFile); % TODO: ... find a better way (more explicit)!
end




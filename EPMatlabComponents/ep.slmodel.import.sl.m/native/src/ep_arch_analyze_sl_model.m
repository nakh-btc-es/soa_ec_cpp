function [stResult, stArgs] = ep_arch_analyze_sl_model(varargin)
% This function analyzes a given Simulink model and saves the architecture information in a proper XML-Format.
% For this, the given Simulink model is opened, analyzed and closed.
% The resulting xml-format is described in a simulink_architecture.xsd
%
% [stResult] = function ep_arch_analyze_sl_model(varargin)
%
%  INPUT              DESCRIPTION
%    varargin           ([Key, Value]*)    Key-value pairs with the following
%                                          possibles values. Parameters with *
%                                          are mandatory.
%
%    Key(string):            Meaning of the Value:
%    - SlModelFile             (String)*   The absolute path to the Simulink model.
%    - SlInitScript            (String)    The absolute path to the init script of the Simulink model.
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
%    - TestMode                (String)    ('BlackBox' | {'GreyBox'})
%                                          If set to 'GreyBox', local variables are
%                                          regarded as additional outputs of subystems.
%                                          For BlackBox-Testing only the regular
%                                          outputs in the interfaces of subsystems are
%                                          observed.
%                                          (default is 'GreyBox')
%   - FixedStepSolver          (String)    ('yes' | {'no'})
%                                          ----------------- 'yes' --------------------------------------------------
%                                          The analyzed Simulink model will be set to the fixed-step solver type
%                                          automatically. The usage of the EmbeddedPlatform requires a
%                                          fixed-step solver. If the model is open and the fixed-step solver
%                                          is not already set, this might lead to a modified model.
%                                          ----------------- 'no' ---------------------------------------------------
%                                          The analyzed Simulink model will not be set to the
%                                          fixed-step solver automatically. If the fixed-step solver is not already set
%                                          in the model, the method return with state of a non fixed-step solver.
%                                          In order to proceed the user has to set the
%                                          fixed-step solver manually in the simulation settings.
%                                          ---------------------------------------------------------------------------
%                                          Note: The option is ignored if the model is currently not in an
%                                          open/loaded state. In this case it has no visible side-effect.
%                                          ---------------------------------------------------------------------------
%    - DSReadWriteObservable  (boolean)   If set to true, Data Stores used as both DSRead and DSWrite are used as an 
%                                          output instead of rejecting them.            
%                                          ---------------------------------------------------------------------------
%    - AddModelInfo            (string)*   The absolute path to additional model information.
%                                          The format is described by the AddModelInfo.dtd.
%    - AddModelInfoIsGenerated (boolean)*  Indicates if the add model info
%                                          file is generated
%    - SlResultFile            (String)*   The absolute path to the Simulink output file.
%    - MessageFile             (String)*   The absolute path to the message file.
%    - CompilerFile            (String)*   The absolute path to the compiler file.
%    - Progress                (object)    Progress object for progress information.
%
%  OUTPUT            DESCRIPTION
%  - stResult                   (Struct)
%      .bFixedStepSolver        (boolean)  Indicates if the model uses a fixed-step solver type. True, means a
%                                          fixed-step solver is used. Otherwise, false is returned.
%   - stArgs                    (struct)   Import Arguments
%     .sSlModelFile             (String)   Full path to Simulinkink Model File
%                                          (Argument is obligatory)
%     .sAddModelInfo            (String)   Full path to Additional Model Information.
%                                          (Argument is obligatory)
%     .AddModelInfoIsGenerated  (boolean)* Indicates if the add model info
%                                          file is generated
%     .sSlInitScript            (String)   Path to Simulink InitScript (optional)
%     .sParameterHandling       (String)   ('Off' | {'ExplicitParam'}
%     .sTestMode                (String)   ('BlackBox' | {'GreyBox'})
%     .bFixedStepSolver         (String)   ('yes' | {'no'})
%     .sMessageFile             (String)   The absolute path to the message file.
%     .sSlResultFile            (String)   The absolute path to the Simulink output file.
%     .sCompilerFile            (String)   The absolute path to the compiler file.
%     .astSlModules
%       .stModule
%         .sKind                (string)   model | library | model_ref
%         .sFile                (string)   full path to model/lib file
%         .sVersion             (string)   version of model/lib file
%         .sCreated             (string)   creation date of model/lib file
%         .sModified            (string)   last modification date of model/lib file
%         .sIsModified          (string)   'yes'|'no' depending on modified
%                                          state of model/lib
%     .hProgress
%

%%
% Transform args
stArgs = i_parseArgs(varargin{:});
if isfield(stArgs, 'sSlModelFile') && ~isempty(stArgs.sSlModelFile)
    stArgs.sSlModelFile = ep_core_canonical_path(stArgs.sSlModelFile, pwd);
end
if isfield(stArgs, 'sSlInitScript') && ~isempty(stArgs.sSlInitScript)
    stArgs.sSlInitScript = ep_core_canonical_path(stArgs.sSlInitScript, pwd);
end
if isfield(stArgs, 'sAddModelInfo') && ~isempty(stArgs.sAddModelInfo)
    stArgs.sAddModelInfo = ep_core_canonical_path(stArgs.sAddModelInfo, pwd);
end
if isfield(stArgs, 'sMappingFile') && ~isempty(stArgs.sMappingFile)
    stArgs.sMappingFile = ep_core_canonical_path(stArgs.sMappingFile, pwd);
end
casAnaArgs = i_translateArgs(stArgs);
stAnaRes = ep_sl_model_analyze(casAnaArgs{:});

stResult = struct('bFixedStepSolver', stAnaRes.bFixedStepSolver);
if stAnaRes.bIsValid
    stArgs.astSlModules = stAnaRes.astModules;
end
end



%%
function casAnaArgs = i_translateArgs(stArgs)
if (stArgs.bFixedStepSolver)
    stArgs.sFixedStepSolver = 'yes';
else
    stArgs.sFixedStepSolver = 'no';
end
stTranslate = struct( ...
    'sSlModelFile',             'ModelFile', ...
    'sSlInitScript',            'InitScriptFile', ...
    'sAddModelInfo',            'AddModelInfoFile', ...
    'sFixedStepSolver',         'FixedStepSolver', ...
    'bDSReadWriteObservable',   'DSReadWriteObservable',...
    'sParameterHandling',       'ParameterHandling', ...
    'sTestMode',                'TestMode', ...
    'sSlResultFile',            'SlArchFile',...,
    'sCompilerFile',            'CompilerFile', ...
    'sMessageFile',             'MessageFile', ...,
    'hProgress',                'Progress');

casAnaArgs = {};
casArgsToTranslate = fieldnames(stTranslate);
for i = 1:numel(casArgsToTranslate)
    sArgName = casArgsToTranslate{i};
    
    if isfield(stArgs, sArgName) && ~isempty(stArgs.(sArgName))
        casAnaArgs{end + 1} = stTranslate.(sArgName);         %#ok<AGROW>
        casAnaArgs{end + 1} = stArgs.(sArgName); %#ok<AGROW>
    end
end
end


%%
function stArgs = i_parseArgs(varargin)
% Definition of the return value (stArgs) with default values.
stArgs = struct( ...
    'sSlModelFile',  '', ...
    'sSlInitScript',             '', ...
    'sParameterHandling',        'ExplicitParam', ...
    'sTestMode',                 'GreyBox', ...
    'sAddModelInfo',             '', ...
    'AddModelInfoIsGenerated',   false, ...
    'bFixedStepSolver',          false, ...
    'DSReadWriteObservable',     false,...
    'sMessageFile',              '', ...,
    'sSlResultFile',             '',...,
    'hProgress',                 [],...
    'sCompilerFile',             '', ...
    'sMappingFile',              '');

% Parse inputs from main function
casValidKeys = { ...
    'SlModelFile', ...
    'SlInitScript', ...
    'ParameterHandling', ...
    'TestMode', ...
    'AddModelInfo', ...
    'AddModelInfoIsGenerated', ...
    'FixedStepSolver', ...
    'DSReadWriteObservable',...
    'MessageFile', ...
    'SlResultFile', ...
    'Progress', ...
    'CompilerFile', ...
    'MappingFile'};
stArgsTmp = ep_core_transform_args(varargin, casValidKeys);

ep_core_check_args({'SlModelFile'}, stArgsTmp, 'obligatory', 'file');
ep_core_check_args({'SlInitScript', 'AddModelInfo', 'MappingFile'}, stArgsTmp, 'file');
ep_core_check_args({'TestMode'}, stArgsTmp, {'class', 'char'}, {'keyvalue_i', {'GreyBox', 'BlackBox'}});
ep_core_check_args({'FixedStepSolver'}, stArgsTmp, {'class', 'char'}, {'keyvalue_i', {'yes', 'no'}});
ep_core_check_args({'DSReadWriteObservable'}, stArgs, {'class', 'logical'});
ep_core_check_args({'ParameterHandling'}, stArgsTmp, {'class', 'char'}, {'keyvalue_i', {'ExplicitParam', 'Off'}});
ep_core_check_args({'MessageFile', 'SlResultFile', 'CompilerFile'}, stArgsTmp, {'class', 'char'});

% mainly a re-mapping to new fields
stKeyMap = struct('SlModelFile',  'sSlModelFile', ...
    'SlInitScript',               'sSlInitScript', ...
    'ParameterSupport',           'sParameterSupport', ...
    'TestMode',                   'sTestMode', ...
    'AddModelInfo',               'sAddModelInfo', ...
    'AddModelInfoIsGenerated',    'AddModelInfoIsGenerated', ...
    'MessageFile',                'sMessageFile', ...
    'SlResultFile',               'sSlResultFile', ...
    'CompilerFile',               'sCompilerFile', ...
    'Progress',                   'hProgress', ...
    'DSReadWriteObservable',      'bDSReadWriteObservable',...
    'MappingFile',                'sMappingFile');

casKnownKeys = fieldnames(stKeyMap);
for i = 1:length(casKnownKeys)
    sKey = casKnownKeys{i};
    if isfield(stArgsTmp, sKey)
        stArgs.(stKeyMap.(sKey)) = stArgsTmp.(sKey);
    end
end


if isfield(stArgs, 'sSlModelFile') && ~isempty(stArgs.sSlModelFile)
    [p, stArgs.sSlModel] = fileparts(stArgs.sSlModelFile); %#ok
else
    throw(MException('EP:API:KEY_OBLIGATORY','Parameter key ''SlModelFile'' is obligatory but not defined.'));
end

% loop over all input arguments which must be handled explicitly.
casKeys = fieldnames(stArgsTmp);
nLen = length(casKeys);
for i = 1:nLen
    sKey   = casKeys{i};
    sValue = stArgsTmp.(sKey);
    switch lower(sKey)
        case 'testmode'
            if strcmpi(sValue, 'blackbox')
                stArgs.sTestMode = 'BlackBox';
            elseif strcmpi(sValue, 'greybox')
                stArgs.sTestMode = 'GreyBox';
            else
                error('EP:INTERNAL:ERROR', 'Unknown test mode: %s', sValue);
            end
        case 'fixedstepsolver'
            if strcmpi(sValue, 'yes')
                stArgs.bFixedStepSolver = true;
            else
                stArgs.bFixedStepSolver = false;
            end
        case 'parameterhandling'
            switch lower(sValue)
                case 'off'
                    stArgs.sParameterHandling = 'Off';
                case 'explicitparam'
                    stArgs.sParameterHandling = 'ExplicitParam';
                otherwise
                    error('EP:INTERNAL:ERROR', 'Unknown parameter mode: %s', sValue);
            end
        otherwise
            % just ignore arguments that are not interesting
    end
end
end

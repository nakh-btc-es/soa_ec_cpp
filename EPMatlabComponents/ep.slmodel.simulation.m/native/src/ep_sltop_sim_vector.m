function [stExtractInfo, stExtractOpenInfo, bSimSuccessful] = ep_sltop_sim_vector(varargin)
% Helper function to simulate an extraction model (created or stored) with the given information.
%
% function [stExtractInfo, stExtractOpenInfo] = ep_sl_sim_vector(varargin)
%  INPUT             DESCRIPTION
%  -varargin           ([Key, Value]*)  Key-value pairs with the following
%                                       possibles values. Inputs marked with (*)
%                                       are mandatory.
%
%    Key(string):            Meaning of the Value:
%
%    OPTIONS ORIGINAL MODEL
%
%         ModelFile*              Path to the TargetLink/Simulink model file (.mdl|.slx).
%
%         InitScript              Script defining all parameters needed for initializing the TL/SL-model.
%                                 If not provided, the TL/SL-model is assumed to be selfcontained.
%
%         InitModel    (boolean)  TRUE if model should be initialized (default: true)
%         ActivateMil  (boolean)  TRUE if MIL mode should be activated permanently (default: true) 
%                                 the model file is already loaded.
%
%    EXTRACTION MODEL OPTIONS
%
%         ExtractionModelFile     Path to the extraction model XML file. When the file is not defined it is
%                                 expected that the the extraction model file and script file is defined.
%         ExtractionMessageFile   The absoulte path to the message file for recording errors/warnings/info messages.
%                                 Only required when extraction model will be generated.
%         ExtractionModel         Path to the extraction model file. This file will be used for simulation when
%                                 given by the user. No extraction model will be generated through the extraction
%                                 model file.
%         ExtractionScript        Path to the extraction model script file.
%         Name                    Name of the extraction model.
%         EnableCalibration
%                      (boolean)  Calibration should be enabled (Default: true)
%         EnableLogging(boolean)  Logging should be enabled (Default: true)
%         BreakLinks   (boolean)  Break Links to Libraries (Default: true)
%         PreserveLibLinks
%                    (cell-array) Defines a list of library names for which the links must not be broken.
%                                 For some libraries it is possible that a link break leads to an invalid
%                                 extraction model. E.g (SimScape). Hence no simulation is possible.
%                                 Only active if 'BreakLinks' is true. (Default : empty list)
%         ModelRefMode  (int)     Model Reference Mode (0- Keep refs | 1- Copy refs | 2- Break refs)
%         MIL_RND_METH  (string)  {{'Nearest', 'Zero', 'Round', 'Simplest',
%                                 'Convergent', 'Ceiling', 'Floor'}}
%                                 Default : ''
%         TL_HOOK_MODE (boolean)  When true, internal TL hooks in the
%                                 extraction model will be generated.
%                                 Default : false
%         REUSE_MODEL_CALLBACKS   {'PreLoadFcn', 'PostLoadFcn', 'InitFcn',
%                       (cell)     'StartFcn', 'PauseFcn', 'ContinueFcn',
%                                  'StopFcn', 'PreSaveFcn', 'PostSaveFcn',
%                                  'CloseFcn'}
%                                 Default : {}
%         OriginalSimulationMode  Defines the original simulation mode
%                                 ('TL MIL' | 'TL MIL (EV)' | 'SL MIL' | 'PIL' | 'TL ClosedLoop SIL', 'TL SIL' | 'SL SIL')
%    EXTRACTION MODEL SIMULATUION OPTIONS
%         Mode*        (string)   (MIL|SIL|PIL) kind of model, (SIL and PIL
%                                 for TargetLink models)
%         SimulationMode (string) Simulink Simulation Mode {normal,
%                                 accelerator, rapid or external}
%                                 (default: normal)
%         PILConfig    (string)   PIL board config (default: Default config
%                                 will be evaluated)
%         PILTimeout   (integer)  Timeout in [s] for downloading
%                                 code to PIL board. When PIL timout is
%                                 reached an exception is thrown and the
%                                 download process will be aborted.
%                                 [Default 0s, download process will not
%                                 be aborted]
%         UseTldsStubs (logical)  Use TLDS stubs for stubbing TL license
%                                 checks (default: false)
%         InteractiveSimulation   Simulation is interactive
%                                 ('SimulationCommand'-based) (default: false)
%                      (logical)
%      EnableCleanCode (boolean)  Use Clean Code (default: false)
%     GENERAL OPTIONS
%         OpenExtractionModel     Open the extraction model (Default
%                                 : true) In case of false, make sure
%                                 that extraction model is open for simulation.
%         KeepExtractionModelOpen Keeps the extraction model open (Default
%                                 : false)
%         InitVectorFile*         Path to the init vector XML File (see
%                                 InitVector.xsd)
%         ResultVectorFile*       Path to the result vector XML File. The
%                                 file contain the expected output
%                                 interface.(see TestVector.xsd)
%         MessageFile*            The absoulte path to the message file for
%                                 recording errors/warnings/info messages.
%         Progress     (object)   Progress object for progress information.
%  OUTPUT            DESCRIPTION
%  - stExtractInfo       (struct)  Information about the extraction model
%    .ExtractionModel    (string)  Full path to the extraction model file
%    .InitScript         (string)  Full path to the initialize script for
%                                 the extraction model.
%    .TopLevelSubsystem  (string)  Top level subsystem of the extraction
%                                  model file.
%
% - stExtractOpenInfo    (struct) Contains information about the open
%                                 extraction model, this is only filled
%                                 when option 'KeepExtractionModelOpen' is
%                                 set to true. It is the responsible of
%                                 the user to close the extraction model
%                                 with the given information.
%                                 ep_sim_close_model(stExtractOpenInfo)
%


%%
bSimSuccessful = false;

stExtractInfo = [];
stExtractOpenInfo = [];

stArgs = i_evalArgs(varargin{:});

% create extraction model if needed
if ~isempty(stArgs.ExtractionModelFile)
    stExtractInfo = i_extractModel(stArgs);
    
    stArgs.ExtractionModel  = stExtractInfo.ExtractionModel;
    stArgs.ExtractionScript = stExtractInfo.InitScript;
end

% simulate if possible
if stArgs.ValidVector
    [stExtractOpenInfo, bSimSuccessful] = i_simulateVector(stArgs);
end
end


%%
function stExtractInfo = i_extractModel(stArgs)
try
    stOpenInfo = [];
    
    casInitScripts = {};
    if ~isempty(stArgs.InitScript)
        casInitScripts{end + 1} = stArgs.InitScript;
    end
    
    stOpenInfo = ep_sim_open_model( ...
        'ModelFile',   stArgs.ModelFile, ...
        'InitScripts', casInitScripts,...
        'InitModel',   stArgs.InitModel, ...
        'ActivateMil', stArgs.ActivateMil, ...
        'MessageFile', stArgs.ExtractionMessageFile, ...
        'Progress',    stArgs.Progress );% TODO add right progress
    
    
    % now it is assumed that the extraction model XML file is defined
    
    stExtractInfo = ep_sim_extract_sl_toplevel_model(...
        'ModelFile',              stArgs.ModelFile,...
        'InitScriptFile',         stArgs.InitScript, ...
        'OriginalSimulationMode', stArgs.OriginalSimulationMode, ...
        'ExtractionModelFile',    stArgs.ExtractionModelFile,...
        'Name',                   stArgs.Name, ...
        'Mode',                   stArgs.Mode, ...
        'EnableCalibration',      stArgs.EnableCalibration, ...
        'EnableLogging',          stArgs.EnableLogging, ...
        'BreakLinks',             stArgs.BreakLinks, ...
        'PreserveLibLinks',       stArgs.PreserveLibLinks, ...
        'ModelRefMode',           stArgs.ModelRefMode, ...
        'SutAsModelRef',          stArgs.SutAsModelRef, ...
        'MIL_RND_METH',           stArgs.MIL_RND_METH, ...
        'TL_HOOK_MODE',           stArgs.TL_HOOK_MODE, ...
        'REUSE_MODEL_CALLBACKS',  stArgs.REUSE_MODEL_CALLBACKS, ...
        'MessageFile',            stArgs.ExtractionMessageFile, ...
        'HarnessModelFileIn',     stArgs.HarnessModelFileIn, ...
        'HarnessModelFileOut',    stArgs.HarnessModelFileOut, ...
        'Progress',               stArgs.Progress);% TODO add right progress
    
    
    ep_sim_close_model(stOpenInfo, 'MessageFile', stArgs.ExtractionMessageFile);
    
catch exception
    i_cleanupClose(stOpenInfo);
    EPEnvironment.cleanAndThrowException(EPEnvironment(), exception, stArgs.ExtractionMessageFile);
    
    % should never be executed if exception is thrown as expected
    stExtractInfo = [];
end
end


%%
function [stExtractOpenInfo, bSimSuccessful] = i_simulateVector(stArgs)
bSimSuccessful = false;

try
    oSimulationHook = stArgs.SimulationHook;
    stExtractOpenInfo = [];
    if stArgs.OpenExtractionModel
        casInitScripts = {};
        if ~isempty(stArgs.InitScript)
            casInitScripts{end + 1} = stArgs.InitScript;
        end
        if ~isempty(stArgs.ExtractionScript)
            casInitScripts{end + 1} = stArgs.ExtractionScript;
        end
        
        stExtractOpenInfo = ep_sim_open_model(...
            'ModelFile',   stArgs.ExtractionModel, ...
            'InitScripts', casInitScripts, ...
            'InitModel',   false, ...
            'AddPaths',    {fileparts(stArgs.ModelFile)}, ...
            'ActivateMil', false, ...
            'MessageFile', stArgs.MessageFile, ...
            'Progress',    stArgs.Progress ); % TODO add right progress
        % add original scope path
        stExtractOpenInfo.OriginalScopePath=stArgs.OriginalScopePath;
    end
    ep_sim_init_sl_model(...
        'ModelFile',         stArgs.ExtractionModel, ...
        'Mode',              stArgs.Mode, ...
        'SimulationMode',    stArgs.SimulationMode ,...
        'InitVectorFile',    stArgs.InitVectorFile, ...
        'MessageFile',       stArgs.MessageFile, ...
        'InputsVectorFile',  stArgs.InputsVectorFile, ...
        'ParamsVectorFile',  stArgs.ParamsVectorFile, ...
        'OutputsVectorFile', stArgs.OutputsVectorFile, ...
        'Progress',          stArgs.Progress); % TODO add right progress
    
    %% execute simulation hook
    i_executePreSimulationHook(oSimulationHook, stArgs);
    
    ep_sim_exec_model(...
        'ModelFile',             stArgs.ExtractionModel, ...
        'ResultVectorFile',      stArgs.ResultVectorFile,...
        'MessageFile',           stArgs.MessageFile, ...
        'ExecutionMode',         stArgs.OriginalSimulationMode, ...
        'OriginalScopePath',     stArgs.OriginalScopePath, ...
        'PhysicalScopePath',     stArgs.PhysicalScopePath, ...
        'TestCaseName',          stArgs.VectorName, ...
        'InteractiveSimulation', stArgs.InteractiveSimulation,...
        'LocalsVectorFile',      stArgs.LocalsVectorFile, ...
        'Progress',              stArgs.Progress);  % TODO add right progress
    
    if ~stArgs.KeepExtractionModelOpen
        if ~isempty(stExtractOpenInfo)
            i_executePostSimulationHook(oSimulationHook,stArgs);
            ep_sim_close_model(stExtractOpenInfo, 'MessageFile', stArgs.MessageFile);
        end
        stExtractOpenInfo = []; % explicit clean
    end
    
    bSimSuccessful = true;
catch exception
    i_cleanupClose(stExtractOpenInfo);
    stExtractOpenInfo = [];
    EPEnvironment.cleanAndAddException(EPEnvironment(), exception, stArgs.MessageFile);
end
end


%%
function i_executePreSimulationHook(oSimulationHook,stArgs)
if ~isempty(oSimulationHook)
    oSimulationHook.executePreSimulationHook(struct('ExtractionModel',stArgs.ExtractionModel,'OriginalScopePath',stArgs.OriginalScopePath,'PhysicalScopePath',stArgs.PhysicalScopePath));
end
end


%%
function i_executePostSimulationHook(oSimulationHook,stArgs)
if ~isempty(oSimulationHook)
    oSimulationHook.executePostSimulationHook(struct('ExtractionModel',stArgs.ExtractionModel,'OriginalScopePath',stArgs.OriginalScopePath,'PhysicalScopePath',stArgs.PhysicalScopePath));
end
end


%%
function i_cleanupClose(stInfo)
if ~isempty(stInfo)
    try ep_sim_close_model(stInfo); catch end %#ok
end
end


%%
function stArgs = i_evalArgs(varargin)
stArgs = i_checkArgs(varargin{:});
stArgs = i_enhanceWithDefaults(stArgs);
end


%%
function stArgs = i_checkArgs(varargin)
casValidKeys = { ...
    'ModelFile', 'InitScript', ...
    'ActivateMil', 'InitModel', 'MessageFile', ...
    'ExtractionModelFile', 'ExtractionModel', 'ExtractionScript',...
    'Name', 'Mode', 'EnableCalibration', ...
    'EnableLogging', 'BreakLinks', 'PreserveLibLinks', 'UseTldsStubs', ...
    'ModelRefMode', 'InitVectorFile', 'ValidVector', ...
    'ResultVectorFile', 'SimulationMode', ...
    'PILConfig', 'PILTimeout', 'ExtractionMessageFile', ...
    'KeepExtractionModelOpen', 'OpenExtractionModel', ...
    'EvalStacktrace', 'MIL_RND_METH', ...
    'TL_HOOK_MODE', 'REUSE_MODEL_CALLBACKS', 'OriginalSimulationMode', 'Progress', ...
    'EnableCleanCode','SimulationHook','OriginalScopePath', 'PhysicalScopePath', 'VectorName',...
    'InteractiveSimulation', 'HarnessModelFileIn', 'HarnessModelFileOut', 'SutAsModelRef', 'InputsVectorFile', ...
    'ParamsVectorFile', 'OutputsVectorFile', 'LocalsVectorFile'};

stArgs = ep_core_transform_args(varargin, casValidKeys);

ep_sim_argcheck('OriginalSimulationMode', stArgs, {'class', 'char'}, ...
    {'keyvalue_i', {'SL MIL (Toplevel)'}});
ep_sim_argcheck('ModelFile', stArgs, 'obligatory', {'class', 'char'});
ep_sim_argcheck('ModelFile', stArgs, 'file');
ep_sim_argcheck('InitScript', stArgs, {'class', 'char'});
ep_sim_argcheck('InitModel', stArgs, {'class', 'logical'});
ep_sim_argcheck('ActivateMil', stArgs, {'class', 'logical'});
ep_sim_argcheck('KeepExtractionModelOpen', stArgs, {'class', 'logical'});
ep_sim_argcheck('OpenExtractionModel', stArgs, {'class', 'logical'});

ep_sim_argcheck('ExtractionModelFile', stArgs, {'class', 'char'});

ep_sim_argcheck('ExtractionModel', stArgs, {'class', 'char'});

ep_sim_argcheck('ExtractionScript', stArgs, {'class', 'char'});


ep_sim_argcheck('Name', stArgs, {'class', 'char'});
ep_sim_argcheck('Mode', stArgs, 'obligatory', {'class', 'char'})
ep_sim_argcheck('Mode', stArgs, {'class', 'char'}, {'keyvalue_i', {'MIL', 'PIL', 'SIL'}});
ep_sim_argcheck('EnableCalibration', stArgs, {'class', 'logical'});
ep_sim_argcheck('EnableLogging', stArgs, {'class', 'logical'});
ep_sim_argcheck('BreakLinks', stArgs, {'class', 'logical'});
ep_sim_argcheck('PreserveLibLinks', stArgs, {'class', 'cell'});
ep_sim_argcheck('ModelRefMode', stArgs, {'class', 'double'});

ep_sim_argcheck('SimulationMode', stArgs, {'class', 'char'}, ...
    {'keyvalue_i', {'normal', 'accelerator', 'rapid' ,'external'}});

ep_sim_argcheck('InitVectorFile', stArgs, 'obligatory', {'class', 'char'});
ep_sim_argcheck('InitVectorFile', stArgs, 'file');
ep_sim_argcheck('InitVectorFile', stArgs, {'xsdvalid', 'InitVector.xsd'});
ep_sim_argcheck('ValidVector', stArgs, {'class', 'logical'});

ep_sim_argcheck('PILConfig', stArgs, {'class', 'char'});
ep_sim_argcheck('PILTimeout', stArgs, {'class', 'integer'});
ep_sim_argcheck('UseTldsStubs', stArgs, {'class', 'logical'});
ep_sim_argcheck('Progress', stArgs, {'class','ep.core.ipc.matlab.server.progress.Progress'});

ep_sim_argcheck('ResultVectorFile', stArgs, 'obligatory', {'class', 'char'});
ep_sim_argcheck('ResultVectorFile', stArgs, 'file');
ep_sim_argcheck('ResultVectorFile', stArgs, {'xsdvalid', 'TestVector.xsd'});

ep_sim_argcheck('EvalStacktrace', stArgs, {'class', 'logical'});
ep_sim_argcheck('MessageFile', stArgs, 'obligatory', {'class', 'char'});
ep_sim_argcheck('ExtractionMessageFile', stArgs, {'class', 'char'});

ep_sim_argcheck('MIL_RND_METH', stArgs, {'class', 'char'}, ...
    {'keyvalue', {'Nearest', 'Zero', 'Round', 'Simplest', 'Convergent', 'Ceiling', 'Floor'}});
ep_sim_argcheck('TL_HOOK_MODE', stArgs, {'class', 'logical'});
ep_sim_argcheck('REUSE_MODEL_CALLBACKS', stArgs, {'class', 'cell'});

ep_sim_argcheck('EnableCleanCode', stArgs, {'class', 'logical'});
ep_sim_argcheck('SimulationHook',stArgs,{'class','EPSimulationHook'});
ep_sim_argcheck('OriginalScopePath',stArgs,{'class','char'});
ep_sim_argcheck('PhysicalScopePath',stArgs,{'class','char'});
ep_sim_argcheck('VectorName', stArgs, {'class', 'char'});
ep_sim_argcheck('InteractiveSimulation',stArgs,{'class','logical'});

if isfield(stArgs, 'HarnessModelFileIn') && ~isempty(stArgs.HarnessModelFileIn)
    ep_sim_argcheck('HarnessModelFileIn', stArgs, {'class', 'char'});
    ep_sim_argcheck('HarnessModelFileIn', stArgs, 'file');
    ep_sim_argcheck('HarnessModelFileIn', stArgs, {'xsdvalid', 'MilHarnessSFunc.xsd'});
end

if isfield(stArgs, 'HarnessModelFileOut') && ~isempty(stArgs.HarnessModelFileOut)
    ep_sim_argcheck('HarnessModelFileOut', stArgs, {'class', 'char'});
    ep_sim_argcheck('HarnessModelFileOut', stArgs, 'file');
    ep_sim_argcheck('HarnessModelFileOut', stArgs, {'xsdvalid', 'MilHarnessSFunc.xsd'});
end
if isfield(stArgs, 'SutAsModelRef')
    ep_sim_argcheck('SutAsModelRef',stArgs,{'class','logical'});
end
end


%%
function stArgs = i_enhanceWithDefaults(stArgs)
if ~isfield(stArgs, 'EvalStacktrace')
    stArgs.EvalStacktrace = false;
end

if ~isfield(stArgs, 'ValidVector')
    stArgs.ValidVector = true;
end

if ~isfield(stArgs, 'InitScript')
    stArgs.InitScript = '';
end

if ~isfield(stArgs, 'InitModel')
    stArgs.InitModel = true;
end

if ~isfield(stArgs, 'ActivateMil')
    stArgs.ActivateMil = true;
end

if (~isfield(stArgs, 'ExtractionModelFile') || isempty(stArgs.ExtractionModelFile))
    stArgs.ExtractionModelFile = '';
else
    ep_sim_argcheck('ExtractionModelFile', stArgs, 'file');
end

if (~isfield(stArgs, 'ExtractionModel') || isempty(stArgs.ExtractionModel))
    stArgs.ExtractionModel = '';
else
    ep_sim_argcheck('ExtractionModel', stArgs, 'file');
end

if (~isfield(stArgs, 'ExtractionScript') || isempty(stArgs.ExtractionScript))
    stArgs.ExtractionScript = '';
else
    ep_sim_argcheck('ExtractionScript', stArgs, 'file');
end

if ~isfield(stArgs, 'Name')
    stArgs.Name = '';
end

if ~isfield(stArgs, 'Mode')
    stArgs.Mode = 'MIL';
else
    stArgs.Mode = upper(stArgs.Mode);
end
if strcmp(stArgs.Mode, 'PIL')
    sReplacementPil = getenv('EP_API_REPLACEMENT_PIL');
    if ~isempty(sReplacementPil)
        stArgs.Mode = upper(sReplacementPil);
    end
end

if ~isfield(stArgs, 'EnableCalibration')
    stArgs.EnableCalibration = true;
end

if ~isfield(stArgs, 'EnableLogging')
    stArgs.EnableLogging = true;
end

if ~isfield(stArgs, 'BreakLinks')
    stArgs.BreakLinks = true;
end

if ~isfield(stArgs, 'PreserveLibLinks')
    stArgs.PreserveLibLinks = {};
end

if ~isfield(stArgs, 'ModelRefMode')
    stArgs.ModelRefMode = ep_sl.Constants.KEEP_REFS;
end

if ~isfield(stArgs, 'SimulationMode')
    stArgs.SimulationMode = 'normal';
end

if ~isfield(stArgs, 'PILConfig')
    stArgs.PILConfig = '';
end

if ~isfield(stArgs, 'PILTimeout')
    stArgs.PILTimeout = int64(0);
end

if ~isfield(stArgs, 'UseTldsStubs')
    stArgs.UseTldsStubs = false;
end

if ~isfield(stArgs, 'Progress')
    stArgs.Progress = ep.core.ipc.matlab.server.progress.impl.ProgressImpl();
end

if ~isfield( stArgs, 'ExtractionMessageFile')
    stArgs.ExtractionMessageFile = stArgs.MessageFile;
end

if ~isfield(stArgs, 'KeepExtractionModelOpen')
    stArgs.KeepExtractionModelOpen = false;
end

if ~isfield(stArgs, 'OpenExtractionModel')
    stArgs.OpenExtractionModel = true;
end

if ~isfield(stArgs, 'REUSE_MODEL_CALLBACKS')
    stArgs.REUSE_MODEL_CALLBACKS = {};
end

if ~isfield(stArgs, 'MIL_RND_METH')
    stArgs.MIL_RND_METH = '';
end

if ~isfield(stArgs, 'TL_HOOK_MODE')
    stArgs.TL_HOOK_MODE = false;
end

if ~isfield(stArgs, 'OriginalSimulationMode')
    stArgs.OriginalSimulationMode = '';
end

if ~isfield(stArgs, 'EnableCleanCode')
    stArgs.EnableCleanCode = false;
end
if ~isfield(stArgs, 'SimulationHook')
    stArgs.SimulationHook=[];
end
if ~isfield(stArgs, 'OriginalScopePath')
    stArgs.OriginalScopePath='';
end
if ~isfield(stArgs,'InteractiveSimulation')
    stArgs.InteractiveSimulation=false;
end
if ~isfield(stArgs, 'PhysicalScopePath')
    stArgs.PhysicalScopePath='';
end
if ~isfield(stArgs, 'VectorName')
    stArgs.VectorName='';
end
if (~isfield(stArgs, 'HarnessModelFileIn'))
    stArgs.HarnessModelFileIn = '';
end
if (~isfield(stArgs, 'HarnessModelFileOut'))
    stArgs.HarnessModelFileOut = '';
end
if ~isfield(stArgs, 'SutAsModelRef')
    stArgs.SutAsModelRef = false;
end
if (~isfield(stArgs, 'InputsVectorFile'))
    stArgs.InputsVectorFile = '';
end
if (~isfield(stArgs, 'ParamsVectorFile'))
    stArgs.ParamsVectorFile = '';
end
if (~isfield(stArgs, 'OutputsVectorFile'))
    stArgs.OutputsVectorFile = '';
end
if (~isfield(stArgs, 'LocalsVectorFile'))
    stArgs.LocalsVectorFile = '';
end
end

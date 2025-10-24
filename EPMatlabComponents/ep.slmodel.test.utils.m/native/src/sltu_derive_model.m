function [xOnCleanUpCloseModel, stSimulationResult] = sltu_derive_model(stTestData, stExtractionInfo, varargin)
% Utility function to perform derivation

stArgs = i_evalArgs(stTestData, stExtractionInfo, varargin{:});

stExtractOpenInfo = ep_sim_open_model(...
    'Kind',        stArgs.Kind,...
    'ModelFile',   stArgs.ModelFile, ...
    'InitScripts', stArgs.casInitScripts, ...
    'InitModel',   false, ...
    'AddPaths',    {fileparts(stTestData.sModelFile)}, ...
    'ActivateMil', false, ...
    'MessageFile', stArgs.MessageFile, ...
    'Progress',    stArgs.Progress ); % TODO add right progress
xOnCleanUpCloseModel = onCleanup(@() ep_sim_close_model(stExtractOpenInfo));

if strcmpi(stArgs.Kind, 'TL')
    ep_sim_init_tl_model(...
        'ModelFile',         stArgs.ModelFile, ...
        'Mode',              stArgs.Mode, ...
        'SimulationKind',    stArgs.SimulationKind, ...
        'PILConfig',         stArgs.PILConfig, ...
        'PILTimeout',        stArgs.PILTimeout, ...
        'UseTldsStubs',      stArgs.UseTldsStubs, ...
        'SimulationMode',    stArgs.SimulationMode ,...
        'InitVectorFile',    stArgs.InitVectorFile, ...
        'MessageFile',       stArgs.MessageFile, ...
        'EnableCleanCode',   stArgs.EnableCleanCode, ...
        'InputsVectorFile',  stArgs.InputsVectorFile,...
        'ParamsVectorFile',  stArgs.ParamsVectorFile,...
        'OutputsVectorFile', stArgs.OutputsVectorFile,...
        'Progress',          stArgs.Progress); % TODO add right progress
else
    ep_sim_init_sl_model(...
        'ModelFile',         stArgs.ModelFile, ...
        'Mode',              stArgs.Mode, ...
        'SimulationKind',    stArgs.SimulationKind, ...
        'SimulationMode',    stArgs.SimulationMode ,...
        'InitVectorFile',    stArgs.InitVectorFile, ...
        'MessageFile',       stArgs.MessageFile, ...
        'InputsVectorFile',  stArgs.InputsVectorFile,...
        'ParamsVectorFile',  stArgs.ParamsVectorFile,...
        'OutputsVectorFile', stArgs.OutputsVectorFile,...
        'Progress',          stArgs.Progress); % TODO add right progress
end

ep_sim_derive_model(...
    'ModelFile',           stArgs.ModelFile,...
    'LoggingAnalysisFile', stArgs.LoggingAnalysisFile,...
    'MessageFile',         stArgs.MessageFile,...
    'LoggedSubsystems',    stArgs.LoggedSubsystems);

[~, sName] = fileparts(stExtractionInfo.ExtractionModel);
stSimulationResult = struct( ...
    'sModelName',       sName, ...
    'sSimulatedVector', stArgs.ResultVectorFile);
end


%%
function stArgs = i_evalArgs(stModelInfo, stExtractionInfo, varargin)
casValidKeys = { ...
    'Kind','ModelFile', 'InitScripts', 'AddPaths','ActivateMil', 'InitModel', 'MessageFile', 'Progress', ...
    'Mode', 'ModelFile', 'InitVectorFile', 'SimulationMode', 'MessageFile', 'PILConfig', 'UseTldsStubs', ...
    'PILTimeout', 'EnableCleanCode','SimulationKind', 'StimuliVectorFile', 'ResultVectorFile', ...
    'ExecutionMode', 'OriginalScopePath', 'PhysicalScopePath', ...
    'TestCaseName', 'InteractiveSimulation', 'OutputsVectorFile', 'LoggedSubsystems'};

stArgs = ep_core_transform_args(varargin, casValidKeys);
stArgs = i_enhanceWithDefaults(stModelInfo, stExtractionInfo, stArgs);

stArgs.casInitScripts = {};
if ~isempty(stModelInfo.sInitScriptFile)
    stArgs.casInitScripts{end + 1} = stModelInfo.sInitScriptFile;
end
if ~isempty(stExtractionInfo.InitScript)
    stArgs.casInitScripts{end + 1} = stExtractionInfo.InitScript;
end

[sPath, sName] = fileparts(stArgs.ModelFile);
stArgs.LoggingAnalysisFile = fullfile(sPath,[sName,'_logging.xml']);

hTestVec = mxx_xmltree('load', stArgs.ResultVectorFile);
xOnCleanupStimVec = onCleanup(@() mxx_xmltree('clear', hTestVec));
hLogVec = mxx_xmltree('load', stArgs.LoggingAnalysisFile);
xOnCleanupLogVec = onCleanup(@() mxx_xmltree('clear', hLogVec));
hTestVecNode = mxx_xmltree('get_nodes', hTestVec, '//TestVector');
hLoggingNode = mxx_xmltree('get_nodes', hLogVec, '//LoggingAnalysis');
mxx_xmltree('set_attribute',hLoggingNode, 'name', mxx_xmltree('get_attribute', hTestVecNode, 'name'));
mxx_xmltree('set_attribute',hLoggingNode, 'length', mxx_xmltree('get_attribute', hTestVecNode, 'length'));
mxx_xmltree('save', hLoggingNode, stArgs.LoggingAnalysisFile);
end


%%
function stArgs = i_enhanceWithDefaults(stTestData, stExtractionInfo, stArgs)
if ~isfield(stArgs, 'ExecutionMode')
    error('ExecutionMode is not given.')
end

if ~isfield(stArgs, 'ModelFile')
    stArgs.ModelFile = stExtractionInfo.ExtractionModel;
end

if ~isfield(stArgs, 'Kind')
    if strcmp(stArgs.ExecutionMode, 'SL MIL')
        stArgs.Kind = 'SL';
    elseif strcmp(stArgs.ExecutionMode, 'SL SIL')
        stArgs.Kind = 'SL';
    elseif strcmp(stArgs.ExecutionMode, 'TL MIL')
        stArgs.Kind = 'TL';
    elseif strcmp(stArgs.ExecutionMode, 'TL ClosedLoop SIL')
        stArgs.Kind = 'TL';
    else
        error('Match for exection mode mode not implemented yet.')
    end
end

if ~isfield(stArgs, 'SimulationKind')
    stArgs.SimulationKind = stArgs.ExecutionMode;
end


if ~isfield(stArgs, 'InitModel')
    stArgs.InitModel = true;
end

if ~isfield(stArgs, 'ActivateMil')
    stArgs.ActivateMil = false;
end

if ~isfield(stArgs, 'PILConfig')
    stArgs.PILConfig = '';
end

if ~isfield(stArgs, 'PILTimeout')
    stArgs.PILTimeout = '';
end

if ~isfield(stArgs, 'UseTldsStubs')
    stArgs.UseTldsStubs = false;
end

if ~isfield(stArgs, 'EnableCleanCode')
    stArgs.EnableCleanCode = false;
end

if ~isfield(stArgs, 'Mode')
    if strcmp(stArgs.ExecutionMode, 'SL MIL')
        stArgs.Mode = 'MIL';
    elseif strcmp(stArgs.ExecutionMode, 'SL SIL')
        stArgs.Mode = 'MIL';
    elseif strcmp(stArgs.ExecutionMode, 'TL MIL')
        stArgs.Mode = 'MIL';
    elseif strcmp(stArgs.ExecutionMode, 'TL ClosedLoop SIL')
        stArgs.Mode = 'SIL';
    else
        error('Match for execution mode not implemented yet.')
    end
end

if ~isfield(stArgs, 'SimulationMode')
    stArgs.SimulationMode = 'normal';
end

if ~isfield(stArgs, 'MessageFile')
    stArgs.MessageFile = stTestData.sMessageFile;
end

if ~isfield(stArgs, 'Progress')
    stArgs.Progress =  ep.core.ipc.matlab.server.progress.impl.ProgressImpl();
end

if ~isfield(stArgs, 'ResultVectorFile')
    stArgs.ResultVectorFile = stTestData.sResultVectorFile;
end

if ~isfield(stArgs, 'InputsVectorFile')
    stArgs.InputsVectorFile = stTestData.sInputsVectorFile;
end

if ~isfield(stArgs, 'ParamsVectorFile')
    stArgs.ParamsVectorFile = stTestData.sParamsVectorFile;
end

if ~isfield(stArgs, 'OutputsVectorFile')
    stArgs.OutputsVectorFile = stTestData.sOutputsVectorFile;
end

if ~isfield(stArgs, 'InitVectorFile')
    stArgs.InitVectorFile = stTestData.sInitVectorFile;
end

if ~isfield(stArgs, 'InteractiveSimulation')
    stArgs.InteractiveSimulation = false;
end

if ~isfield(stArgs, 'LoggedSubsystems')
    stArgs.LoggedSubsystems = stTestData.castLoggedSubsystems;
end
end
function stExtractInfo = sltu_extract_model(stTestData, varargin)
% Utility function to perform the model extraction

%%
stArgs = i_evalArgs(stTestData, varargin{:});

stOpenInfo = ep_sim_open_model( ...
    'Kind',        stArgs.Kind, ...
    'ModelFile',   stArgs.ModelFile, ...
    'InitScripts', stArgs.casInitScripts,...
    'InitModel',   stArgs.InitModel, ...
    'ActivateMil', stArgs.ActivateMil, ...
    'MessageFile', stArgs.MessageFile, ...
    'Progress',    stArgs.Progress );% TODO add right progress

if strcmpi(stArgs.Kind, 'tl')
    stExtractInfo = ep_sim_extract_tl_model(...
        'ModelFile',              stArgs.ModelFile,...
        'InitScriptFile',         stArgs.InitScriptFile, ...
        'OriginalSimulationMode', stArgs.OriginalSimulationMode, ...
        'ExtractionModelFile',    stArgs.ExtractionModelFile,...
        'Name',                   stArgs.Name, ...
        'Mode',                   stArgs.Mode, ...
        'ExportPath',             stArgs.ExportPath, ...
        'EnableCalibration',      stArgs.EnableCalibration, ...
        'EnableLogging',          stArgs.EnableLogging, ...
        'EnableDebugUseCase',     stArgs.EnableDebugUseCase, ...
        'BreakLinks',             stArgs.BreakLinks, ...
        'PreserveLibLinks',       stArgs.PreserveLibLinks, ...
        'ModelRefMode',           stArgs.ModelRefMode, ...
        'MIL_RND_METH',           stArgs.MIL_RND_METH, ...
        'TL_HOOK_MODE',           stArgs.TL_HOOK_MODE, ...
        'REUSE_MODEL_CALLBACKS',  stArgs.REUSE_MODEL_CALLBACKS, ...
        'MessageFile',            stArgs.MessageFile, ...
        'HarnessModelFileIn',     stArgs.HarnessModelFileIn, ...
        'HarnessModelFileOut',    stArgs.HarnessModelFileOut, ...
        'SutAsModelRef',          stArgs.SutAsModelRef, ...
        'EnableSubsystemLogging', stArgs.EnableSubsystemLogging, ...
        'Progress',               stArgs.Progress);% TODO add right progress
else 
    stExtractInfo = ep_sim_extract_sl_model(...
        'ModelFile',              stArgs.ModelFile,...
        'InitScriptFile',         stArgs.InitScriptFile, ...
        'OriginalSimulationMode', stArgs.OriginalSimulationMode, ...
        'ExtractionModelFile',    stArgs.ExtractionModelFile,...
        'HarnessModelFileIn',     stArgs.HarnessModelFileIn,...
        'HarnessModelFileOut',    stArgs.HarnessModelFileOut,...
        'Name',                   stArgs.Name, ...
        'Mode',                   stArgs.Mode, ...
        'ExportPath',             stArgs.ExportPath, ...
        'EnableCalibration',      stArgs.EnableCalibration, ...
        'EnableLogging',          stArgs.EnableLogging, ...
        'EnableDebugUseCase',     stArgs.EnableDebugUseCase, ...
        'BreakLinks',             stArgs.BreakLinks, ...
        'PreserveLibLinks',       stArgs.PreserveLibLinks, ...
        'ModelRefMode',           stArgs.ModelRefMode, ...
        'MIL_RND_METH',           stArgs.MIL_RND_METH, ...
        'TL_HOOK_MODE',           stArgs.TL_HOOK_MODE, ...
        'REUSE_MODEL_CALLBACKS',  stArgs.REUSE_MODEL_CALLBACKS, ...
        'MessageFile',            stArgs.MessageFile, ...
        'SutAsModelRef',          stArgs.SutAsModelRef, ...
        'EnableSubsystemLogging', stArgs.EnableSubsystemLogging, ...
        'Progress',               stArgs.Progress);% TODO add right progress
end

ep_sim_close_model(stOpenInfo, 'MessageFile', stArgs.MessageFile);
end

%%
function stArgs = i_evalArgs(stTestData, varargin)
casValidKeys = { ...
        'Kind','ModelFile', 'InitScripts', 'AddPaths', 'ActivateMil', 'InitModel', ...
        'ModelFile', 'InitScriptFile', 'ExtractionModelFile', 'HarnessModelFileIn', 'HarnessModelFileOut',...
        'MessageFile', 'Name', 'Mode', 'EnableCalibration', 'EnableLogging', 'EnableSubsystemLogging', ...
        'EnableDebugUseCase', 'BreakLinks', 'PreserveLibLinks', 'ModelRefMode', 'UseFromWS', 'MIL_RND_METH', ...
        'OriginalSimulationMode', 'TL_HOOK_MODE', 'REUSE_MODEL_CALLBACKS','Progress', 'ExportPath', 'SutAsModelRef'};

stArgs = ep_core_transform_args(varargin, casValidKeys);
stArgs = i_enhanceWithDefaults(stTestData, stArgs);

stArgs.casInitScripts = {};
if ~isempty(stArgs.InitScriptFile)
    stArgs.casInitScripts{end + 1} = stArgs.InitScriptFile;
end
end


%%
function sMode = i_deriveMode(sOriginalSimulationMode)
switch sOriginalSimulationMode
    case {'SL MIL', 'SL MIL (Toplevel)', 'SL SIL', 'TL MIL'}
        sMode = 'MIL';
        
    case {'TL SIL', 'TL ClosedLoop SIL'}
        sMode = 'SIL';
        
    otherwise
        error('SLTU:ERROR', 'Match for original simulation model "%s" not implemented yet.', sOriginalSimulationMode);
end
end


%%
function stArgs = i_enhanceWithDefaults(stTestData, stArgs)
if ~isfield(stArgs, 'Mode') || isempty(stArgs.Mode)
    stArgs.Mode = i_deriveMode(stArgs.OriginalSimulationMode);
end
stModeArgs = i_getDefaultValuesByMode(stArgs.Mode, stArgs.OriginalSimulationMode);

if ~isfield(stArgs, 'ModelFile')
    stArgs.ModelFile = stTestData.sModelFile;
end

if ~isfield(stArgs, 'ExtractionModelFile')
    stArgs.ExtractionModelFile = stTestData.sExtractionModelFile;
end

if ~isfield(stArgs, 'HarnessModelFileIn')
    stArgs.HarnessModelFileIn = stTestData.sInputHarnessFile;
end

if ~isfield(stArgs, 'HarnessModelFileOut')
    stArgs.HarnessModelFileOut = stTestData.sOutputHarnessFile;
end

if ~isfield(stArgs, 'InitScriptFile')
    stArgs.InitScriptFile = stTestData.sInitScriptFile;
end

if ~isfield(stArgs, 'MessageFile')
    stArgs.MessageFile = stTestData.sMessageFile;
end

if ~isfield(stArgs, 'Progress')
    stArgs.Progress = ep.core.ipc.matlab.server.progress.impl.ProgressImpl();
end

if ~isfield(stArgs, 'Kind')
    stArgs.Kind = stTestData.sModelKind;
end

if ~isfield(stArgs, 'InitModel')
    stArgs.InitModel = true;
end

if ~isfield(stArgs, 'ActivateMil')
    stArgs.ActivateMil = false;
end

if ~isfield(stArgs, 'Name')
    stArgs.Name = '';
end

if ~isfield(stArgs, 'ExportPath')
    stArgs.ExportPath = pwd;
end

if ~isfield(stArgs, 'EnableCalibration')
    stArgs.EnableCalibration = true;
end

if ~isfield(stArgs, 'EnableLogging')
    stArgs.EnableLogging = true;
end

if ~isfield(stArgs, 'EnableSubsystemLogging')
    stArgs.EnableSubsystemLogging = false;
end

if ~isfield(stArgs, 'EnableDebugUseCase')
    stArgs.EnableDebugUseCase = false;
end

if ~isfield(stArgs, 'BreakLinks')
    stArgs.BreakLinks = stModeArgs.BreakLinks;
end

if ~isfield(stArgs, 'PreserveLibLinks')
    stArgs.PreserveLibLinks = {};
end

if ~isfield(stArgs, 'ModelRefMode')
    stArgs.ModelRefMode = stModeArgs.ModelRefMode;
end

if ~isfield(stArgs, 'UseFromWS')
    stArgs.UseFromWS = false;
end

if ~isfield(stArgs, 'MIL_RND_METH')
    stArgs.MIL_RND_METH = '';
end

if ~isfield(stArgs, 'TL_HOOK_MODE')
    stArgs.TL_HOOK_MODE = false;
end

if ~isfield(stArgs, 'MIL_RND_METH')
    stArgs.MIL_RND_METH = '';
end

if ~isfield(stArgs, 'REUSE_MODEL_CALLBACKS')
    stArgs.REUSE_MODEL_CALLBACKS = {};
end

if ~isfield(stArgs, 'SutAsModelRef')
    stArgs.SutAsModelRef = false;
end
end


%%
function stArgs = i_getDefaultValuesByMode(sMode, sOriginalSimMode)
stArgs = struct( ...
    'ModelRefMode', ep_sl.Constants.BREAK_REFS, ...
    'BreakLinks',   true);

switch sMode
    case 'SIL'
        stArgs.ModelRefMode = ep_sl.Constants.KEEP_REFS;
        stArgs.BreakLinks   = false;
        
    case 'MIL'
        switch sOriginalSimMode
            case 'SL MIL (Toplevel)'
                stArgs.ModelRefMode = ep_sl.Constants.KEEP_REFS;
                stArgs.BreakLinks   = false;
            case 'SL MIL'
                if verLessThan('matlab', '9.3')
                    stArgs.ModelRefMode = ep_sl.Constants.BREAK_REFS; % ML2015b
                else
                    stArgs.ModelRefMode = ep_sl.Constants.COPY_REFS;
                end
            otherwise
                % just keep the defaults
        end
    otherwise
        % use the defaults
end
end

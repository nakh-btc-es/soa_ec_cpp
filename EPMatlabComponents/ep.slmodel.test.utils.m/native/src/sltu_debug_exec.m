function stResult = sltu_debug_exec(stTestData, varargin)
% Testing creation of TL MIL debug model by executing the model in requested mode(s): MIL, SIL.
%

%%
stArgs = i_evalArgs(varargin{:});
bIsTL = strcmpi(stTestData.sModelKind, 'TL');
if bIsTL
    stArgs.OriginalSimulationMode = 'TL MIL';
else
    stArgs.OriginalSimulationMode = 'SL MIL';
end

%%
if (stArgs.SelfContainedModel)
    bBreakLinks = true;
    if bIsTL
        iModelRefMode = ep_sl.Constants.BREAK_REFS;
    else
        if verLessThan('matlab', '9.3')
            iModelRefMode = ep_sl.Constants.BREAK_REFS;
        else
            iModelRefMode = ep_sl.Constants.COPY_REFS;
        end
    end
else
    bBreakLinks = false;
    iModelRefMode = ep_sl.Constants.KEEP_REFS;
end
sltu_extract_model( ...
    stTestData, ...
    'BreakLinks',             bBreakLinks, ...
    'ModelRefMode',           iModelRefMode, ...
    'ExportPath',             stTestData.sTestRootDebugExec, ...
    'OriginalSimulationMode', stArgs.OriginalSimulationMode, ...
    'Name',                   stArgs.ModelName, ...
    'EnableDebugUseCase',     true);

sMessageFile = fullfile(pwd, 'Messages.xml');
hProgress = ep.core.ipc.matlab.server.progress.impl.ProgressImpl();

stDebugRes = ep_sim_debug_model(...
    'ExportDir',          stTestData.sTestRootDebugExec, ...
    'DebugVectorFiles',   stTestData.casDebugVectorFiles, ...
    'DebugModelFile',     stTestData.sDebugModelFile, ...
    'ModelName',          [stArgs.ModelName, '.slx'], ...
    'InitScript',         stTestData.sInitScriptFile, ...
    'Paths',              stArgs.Paths, ...
    'Mode',               'MIL', ...
    'IsTlModel',          bIsTL, ...
    'AutomaticStart',     false, ...
    'HiddenMode',         stArgs.HiddenMode, ...
    'SelfContainedModel', stArgs.SelfContainedModel, ...
    'ShowExpectedValues', stArgs.ShowExpectedValues, ...
    'Progress',           hProgress, ...
    'MessageFile',        sMessageFile);

[casOutputMDF, caoSimException] = i_simulateDebugModel( ...
    stArgs.DebugSimModes, ...
    stTestData.sModelKind, ...
    stDebugRes.sModelFile, ...
    stDebugRes.sInitScript);

stResult = struct( ...
    'sModelFile',           stDebugRes.sModelFile, ...
    'sInitScript',          stDebugRes.sInitScript, ...
    'sMessageFile',         sMessageFile, ...
    'casSimDebugOutputMDF', {casOutputMDF}, ...
    'caoSimDebugException', {caoSimException});
end


%%
function [casOutputMDF, caoExceptions] = i_simulateDebugModel(casDebugSimModes, sKind, sDebugModelFile, sDebugInitScript)
nSims = numel(casDebugSimModes);
casOutputMDF  = cell(1, nSims);
caoExceptions = cell(1, nSims);

sPwd = pwd();
oOnCleanupReturn = onCleanup(@() cd(sPwd));

sModelDir = fileparts(sDebugModelFile);
cd(sModelDir);

try
    stOpen = ep_sim_open_model( ...
        'Kind',        sKind, ...
        'ModelFile',   sDebugModelFile, ...
        'InitScripts', {sDebugInitScript});
    oOnCleanupCloseModel = onCleanup(@() ep_sim_close_model(stOpen));
    
catch oException
    caoExceptions = mat2cell(repmat(oException, 1, nSims), 1, nSims);
    return;
end

sModelName = get_param(stOpen.hModel, 'name');
for i = 1:nSims
    [casOutputMDF{i}, caoExceptions{i}] = i_simulateDebugModelInMode(sModelName, sKind, casDebugSimModes{i});
end
end


%%
function [sOutputMDF, oException] = i_simulateDebugModelInMode(sModelName, sKind, sDebugSimMode)
sOutputMDF = '';
oException = [];

sDebugSimMDF = fullfile(pwd(), 'outputs.mdf');
if exist(sDebugSimMDF, 'file')
    delete(sDebugSimMDF);
end

bIsTL = strcmpi(sKind, 'TL');

% make sure we get no error popups during simulation
if bIsTL
    tl_error_set('BatchMode','on');
    oOnCleanupResetBatchMode = onCleanup(@() tl_error_set('BatchMode','off'));
end

if strcmp(sDebugSimMode, 'MIL')
    try
        if bIsTL
            tl_set_sim_mode('Model', sModelName, 'SimMode', 'TL_BLOCKS_HOST'); % ensure MIL mode
        end
        sim(sModelName);
        
    catch oException
        return;
    end
elseif strcmp(sDebugSimMode, 'SIL')
    try
        if bIsTL
            tl_build_host(...
                'Model',                  sModelName,  ...
                'IncludeSubItems',        'on', ...
                'AllCodeGenerationUnits', 'on');
            tl_sim(sModelName);
        else
            error('SLTU:FRAMEWORK:UnsupportedMode', 'SIL mode is not supported for SL models.');
        end
        
    catch oException
        return;
    end
else
    error('USAGE:ERROR', 'Debug sim mode "%s" not supported.', sDebugSimMode);
end

sDebugSimMDF = fullfile(pwd(), 'outputs.mdf');
if exist(sDebugSimMDF, 'file')
    [p, f, e] = fileparts(sDebugSimMDF);
    sOutputMDF = fullfile(p, [f, '_', lower(sDebugSimMode), e]);
    movefile(sDebugSimMDF, sOutputMDF);
end
end


%%
function stArgs = i_evalArgs(varargin)
stDefaults = struct( ...
    'DebugSimModes',          {{'MIL'}}, ...
    'Paths',                  {{}}, ...
    'HiddenMode',             false, ...
    'SelfContainedModel',     true, ...
    'ShowExpectedValues',     true, ...
    'ModelName',              'mdebug', ... 
    'OriginalSimulationMode', '');
stUserArgs = ep_core_transform_args(varargin, fieldnames(stDefaults));
stArgs = i_mergeByOverride(stDefaults, stUserArgs);

stArgs.DebugSimModes = cellstr(stArgs.DebugSimModes); % make sure that we have a cell array of modes
end


%%
function stMerge = i_mergeByOverride(stStruct1, stStruct2)
stMerge = stStruct1;

casFields = fieldnames(stStruct2);
for i = 1:numel(casFields)
    stMerge.(casFields{i}) = stStruct2.(casFields{i});
end
end

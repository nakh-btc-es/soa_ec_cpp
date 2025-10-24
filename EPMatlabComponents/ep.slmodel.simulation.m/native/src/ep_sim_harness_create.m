function stResult = ep_sim_harness_create(varargin)
% This function extracts from the provided model an new model and builds a simulation harness.
% It is assumed that the model is already open.
%
% function stResult = ep_sim_harness_create(varargin)
%
%  INPUT              DESCRIPTION
%   - varargin                 ([Key, Value]*)  Key-value pairs with the following
%                                               possibles values. Inputs marked with (*)
%                                               are mandatory.
%    Key(string):                 Meaning of the Value:
%
%         ModelFile*              (String)     Path to the original TargetLink/Simulink model file (.mdl|.slx).
%                                              It is assmed that the model file is already loaded.
%
%         ExtractionModelFile*    (String)     Path to the extraction model XML File(see
%                                              extraction_model.xsd)
%
%         ExportPath              (String)     Path where the extraction model is created. If not given a tmp
%                                              dir is created.
%
%         OriginalSimulationMode* (String)     Defines the original simulation mode
%                                              ('TL MIL' | 'SL MIL' | 'PIL' | 'TL ClosedLoop SIL', 'TL SIL' | 'SL SIL')
%
%         InitScriptFile          (String)     Path to the original init script file
%
%         Name                    (String)     Name of the extraction model
%
%         EnableCalibration       (boolean)    Calibration should be enabled (Default: true)
%
%         EnableLogging           (boolean)    Logging should be enabled (Default : true)
%
%         EnableSubsystemLogging  (boolean)    Logging should be enabled (Default : false)
%
%         BreakLinks              (boolean)    Break Links to Libraries (Default : true)
%
%         isToplevelProfile  (boolean)    Copy the enum and bus type definitions to the according objects in the
%                                              workspace. (Default : false)
%
%         PreserveLibLinks        (cell-array) Defines a list of library names for which the links must not be broken.
%                                              For some libraries it is possible that a link break leads to an invalid
%                                              extraction model. E.g (SimScape). Hence no simulation is possible.
%                                              Only active if 'BreakLinks' is true. (Default : empty list)
%         ModelRefMode            (int)        Model Reference Mode (0- Keep refs | 1- Copy refs | 2- Break refs)
%
%         UseFromWS               (boolean)    When true, use inputs from WS block instead from FromFile block
%
%         MIL_RND_METH  (string)               {'Nearest','Zero','Round','Simplest','Convergent','Ceiling','Floor'}
%                                              Default : ''
%
%         REUSE_MODEL_CALLBACKS   (cell-array) {'PreLoadFcn', 'PostLoadFcn', 'InitFcn', 'StartFcn', 'PauseFcn',
%                                               'ContinueFcn', 'StopFcn', 'PreSaveFcn', 'PostSaveFcn', 'CloseFcn'}
%                                              Default : {}
%
%         MessageFile             (String)     The absoulte path to the message file for recording
%                                              errors/warnings/info messages.
%
%         SutAsModelRef           (boolean)    When true, the system under test will be a model reference
%
%         Progress                (object)     Progress object for progress information.
%
%  OUTPUT            DESCRIPTION
%  - stExtractInfo                (struct)  Information about the extraction model
%    .ExtractionModel               (string)  Full path to the extraction model file
%    .InitScript                    (string)  Full path to the initialize script for the extraction model.
%    .TopLevelSubsystem             (string)  Top level subsystem of the extraction model file.
%    .ModuleName                    (string)  TL Model, the module name of the extraction model (for SL models is '')
%

%%
try
    % Prepare Environment
    stArgs = [];
    stResult = [];
    sPwd = pwd;
    bIsEnumLoaded = false;
    xEnv = EPEnvironment();
    xOnCleanUp = onCleanup(@() xEnv.clear());
    stArgs = i_parse_input_args(varargin{:});
    if isfield(stArgs, 'Progress')
        xEnv.attachProgress(stArgs.Progress);
    end

    cd(stArgs.ExportPath);
    xEnv.setProgress(5,100,'Extract Model');
    tic;

    % Set global settings
    i_set_global_settings(stArgs.MIL_RND_METH, stArgs.REUSE_MODEL_CALLBACKS);
    if isfield(stArgs, 'SetGlobalSettingsTL') && ~isempty(stArgs.SetGlobalSettingsTL)
        [sConfigDir, sVal] = feval(stArgs.SetGlobalSettingsTL, xEnv, stArgs.ModelFile, stArgs.TL_HOOK_MODE);
    end
    % Get source model information
    stSrcModelInfo = i_get_source_model_info(xEnv, stArgs.ModelFile, stArgs.ExtractionModelFile);

    if ~i_isModelInValidState(stSrcModelInfo.sModelName)
        xEnv.throwException(xEnv.addMessage('EP:SIM:DIRTY_MODEL', ...
            'model', fullfile(stSrcModelInfo.sModelPath, stSrcModelInfo.sModelName)));
    end
    if isfield(stArgs, 'TLChecks') && ~isempty(stArgs.TLChecks)
        feval(stArgs.TLChecks, xEnv, stSrcModelInfo);
    end

    % Create empty extraction model
    stExtrModelInfo = i_createEmptyExtractionModel(stArgs.Name, stArgs.ExportPath, stSrcModelInfo.sSampleTime);

    % Copy into WS the params defined in DD
    sDefineDDEnumInWSScript = '';
    sClearDDEnumInWSScript = '';
    if ~stArgs.isToplevelProfile
        [sDefineDDEnumInWSScript, sClearDDEnumInWSScript] = ...
            ep_simenv_callbacks_gen(xEnv, get_param(stSrcModelInfo.hModel, 'Name'), stExtrModelInfo.sName);
    end

    % Update the harness model with complete information for virtual and nested buses
    [sBusInitScriptName, astBusInfo, bVirtualBusCreationFallback] = ep_sim_harness_prepare_bus_info(...
        stSrcModelInfo, stArgs.HarnessModelFileIn, stArgs.HarnessModelFileOut, ...
        stArgs.ExtractionModelFile);

    % Create in WS the enum types defined in DD
    oOnCleanupRevertClosingModel = [];
    if ~stArgs.isToplevelProfile
        oOnCleanupRevertClosingModel = ...
            ep_sim_harness_prepare_ws(stSrcModelInfo.sModelName, sDefineDDEnumInWSScript);
        bIsEnumLoaded = true;
    end

    % If types are not copied into workspace, take the types from the
    % original SLDD. Copy the path to original SLDD to extraction model.
    bUseBussesInHarnessSLDD = false;
    if stArgs.isToplevelProfile
        bUseBussesInHarnessSLDD = i_copyPathToSLDD(stSrcModelInfo, stExtrModelInfo, sBusInitScriptName);
    end

    % Create s-function blocks (compile-mode)
    [hSFunctionIn, hSFunctionOut] = ep_sim_harness_create_sfunc(stExtrModelInfo, ...
        stArgs.HarnessModelFileIn, stArgs.HarnessModelFileOut, astBusInfo, bVirtualBusCreationFallback);

    % Create DSM interface
    [hDsmIn, hDsmOut] = ep_sim_harness_create_dsm(stExtrModelInfo.hModel, stSrcModelInfo.xSubsys, ...
        stSrcModelInfo.bIsTlModel);

    % Extract subsystem from original model
    if ~isempty(oOnCleanupRevertClosingModel)
        clear('oOnCleanupRevertClosingModel');
        stSrcModelInfo.hModel = get_param(stSrcModelInfo.sModelName, 'Handle');
    end
    stOpt = i_get_extraction_options(stArgs);
    stExtrResult = feval(stArgs.FuncExtractSUT, xEnv, stSrcModelInfo, stExtrModelInfo, stOpt);

    stExtrModelInfo = stExtrResult.stExtrModelInfo;

    % Copy Simulink functions to the toplevel extraction scope.
    casSLFunctionPaths = i_copy_simulink_functions(stExtrModelInfo, stSrcModelInfo);

    % add TL main dialog
    if isfield(stArgs, 'AddTLMainDialog') && ~isempty(stArgs.AddTLMainDialog)
        feval(stArgs.AddTLMainDialog, xEnv, stSrcModelInfo, stExtrModelInfo);
    end

    % Append bus init script file
    if (~isempty(sBusInitScriptName) && ~bUseBussesInHarnessSLDD)
        i_prepend_callback(stExtrModelInfo.sName, 'PreLoadFcn', sBusInitScriptName);
    end

    if(stArgs.isToplevelProfile)
        i_formatSUTBlock(stExtrResult.hSubsystem);
    end

    % Set layout
    i_set_block_locations(hSFunctionIn, hSFunctionOut, stExtrResult, hDsmIn, hDsmOut, casSLFunctionPaths);

    % Connect blocks
    i_connect_blocks(stExtrModelInfo.sName, stExtrResult, hSFunctionIn, hSFunctionOut, hDsmIn, hDsmOut);
    % Set OutputAsBus
    if bVirtualBusCreationFallback
        i_setOutputAsBusOnBusSelectors(hSFunctionOut);
    end

    % Set block priorities
    i_set_block_priorities(hSFunctionIn, hSFunctionOut, stExtrResult.hSubsystem, hDsmIn, hDsmOut);

    % Set bus element name on line if the harness is *directly* connected to the SUT
    if stExtrResult.bHasDirectHarnessConnection
        i_set_line_name(stExtrModelInfo.hModel, stSrcModelInfo.sSubsysPathPhysical, stExtrResult.hSubsystem);
    end
    % Converting SUT to model reference
    if stArgs.SutAsModelRef
        [stExtrResult.hSubsystem, iSub2RefConversion, stSrcModelInfo] = i_convertSutToModelRef(xEnv, stExtrResult.hSubsystem, ...
            stSrcModelInfo, stExtrModelInfo, stArgs, sDefineDDEnumInWSScript);
    else
        iSub2RefConversion = 0;
    end
    stExtrResult.sNewSubsysPath = i_remap_main_sut_block_location(stExtrResult.sNewSubsysPath, iSub2RefConversion);

    % TODO: hack-solution passing on the new location of the SUT main subsystem
    %       --> for better maintenance try to remove this implicit passing of info inside the XML tree from memory
    ep_em_entity_attribute_set(stSrcModelInfo.xSubsys, 'mappingPath', stExtrResult.sNewSubsysPath);
    i_addReplacedModelRefInfo(stSrcModelInfo.xSubsys, stExtrResult.sNewSubsysPath);
    sResultExtractionModelFile = fullfile(stArgs.ExportPath, 'ExtractionModel_result.xml');
    mxx_xmltree('save', stSrcModelInfo.xSubsys, sResultExtractionModelFile);

    % Enable calibration
    if isfield(stArgs, 'EnableCalibrationFunc') && ~isempty(stArgs.EnableCalibrationFunc)
        feval(stArgs.EnableCalibrationFunc, xEnv, stSrcModelInfo, stExtrModelInfo, stArgs);
    end

    % Enable logging
    if isfield(stArgs, 'EnableLoggingFunc') && ~isempty(stArgs.EnableLoggingFunc)
        feval(stArgs.EnableLoggingFunc, xEnv, stSrcModelInfo, stExtrModelInfo, stArgs);
    end

    % SL SIL
    if ~isempty(stArgs.OriginalSimulationMode) && strcmp(stArgs.OriginalSimulationMode, 'SL SIL')
        ep_sim_harness_sl_sil_prepare(stExtrModelInfo.sName, stExtrResult.hSubsystem, stSrcModelInfo.sModelName, ...
            stArgs.EnableLogging);
    end

    % TL usecase settings before save
    if isfield(stArgs, 'TLAdaptations') && ~isempty(stArgs.TLAdaptations)
        feval(stArgs.TLAdaptations, stExtrModelInfo.sName, any(strcmp(stArgs.Mode, {'PIL', 'SIL'})), stExtrModelInfo.sPath, ...
            stSrcModelInfo.sModelPath);
    end

    %reset global settings
    if isfield(stArgs, 'ResetGlobalSettingsTL') && ~isempty(stArgs.ResetGlobalSettingsTL)
        feval(stArgs.ResetGlobalSettingsTL, sConfigDir, sVal);
    end

    % Schedule Editor
    if stSrcModelInfo.bIsScheduleEditorNeeded
        i_createNewPartitions(hDsmOut, hSFunctionOut); 
        i_updateScheduleEditor(stExtrModelInfo.hModel, stExtrModelInfo.sName, stSrcModelInfo.sModelName, hDsmOut, sDefineDDEnumInWSScript);
    end

    % save model
    i_saveAndCloseExtrMdl(stExtrModelInfo.sName, stArgs.SutAsModelRef, stOpt.ModelRefMode, sClearDDEnumInWSScript);

    % Prepare result
    xEnv.setProgress(100, 100, 'Extract Model');
    disp(['### Extract Model ', stExtrModelInfo.sName, ' Time :']);
    toc;
    stResult = i_get_result(stExtrResult);

    % Call hooks
    ep_sim_exec_post_extr_hook(xEnv, stArgs, stResult);

    % Finalize
    xEnv.attachMessages(stArgs.MessageFile);
    xEnv.exportMessages(stArgs.MessageFile);
    xEnv.clear();
    cd(sPwd);

catch oEx
    if exist('stExtrModelInfo', 'var') == 1
        i_closeExtractionModelIfStillOpen(stExtrModelInfo.sName);
    end
    if bIsEnumLoaded && ~verLessThan('matlab', '9.5')
        i_cleanupEnumState(stExtrModelInfo.sPath);
    end
    cd(sPwd);
    sMessageFile = [];
    if (isfield(stArgs, 'MessageFile'))
        sMessageFile = stArgs.MessageFile;
    end
    EPEnvironment.cleanAndThrowException(xEnv, oEx, sMessageFile);
end
end


%%
function i_updateScheduleEditor(hModel, sModelName, sWrapperModelName, hDsmOut, sDefineDDEnumInWSScript)
sOrigModelName = sWrapperModelName(length('Wrapper_')+1 : length(sWrapperModelName));
set_param(hModel, 'AutoInsertRateTranBlk', 'on');
% this is needed, because some of the enums are cleared after loading the original model at line 145 when clearing oOnCleanupRevertClosingModel
% also this function cannot be moved before clearing oOnCleanupRevertClosingModel
% since this function is called just before closing the extraction model, no explicit clearing of the enums is done here
% this means it does not have an impact on the original model initialization
i_prepareUpdateDiagram(hModel, sWrapperModelName, sModelName, sDefineDDEnumInWSScript);
set_param(hModel, 'SimulationCommand','Update');

casAllMdlRefs =  ep_find_mdlrefs(hModel);
abFound = strncmp(casAllMdlRefs, ['W_integ_', sOrigModelName], length(['W_integ_', sOrigModelName]));
sIntModel = casAllMdlRefs{abFound};
casFctCalls = ep_find_system(sIntModel, ...
    'FollowLinks',                      'on',...
    'LookUnderMasks',                   'all', ...
    'BlockType',                        'Inport', ...
    'OutputFunctionCall', 'on');
oActualSchedule = get_param(sModelName, 'Schedule');
aoEvents = oActualSchedule.Events;
casEventNames = {aoEvents.Name};
casRowNames = oActualSchedule.Order.Properties.RowNames;

% transfer the order from stateflow chart
casSfChartPath = ep_find_system(sWrapperModelName, 'SearchDepth', 2, 'SFBlockType', 'Chart');
oSfChart = find(sfroot, "-isa", "Stateflow.Chart", 'Path', casSfChartPath{1});
aoStates = find(oSfChart, '-isa', 'Stateflow.State');
casAllScheduledEvents = [];
for i=1:numel(aoStates)
    sEntryAction = aoStates(i).EntryAction;
    sCharsToRemove = {'send', ';', '(', ')'};
    sEntryAction = regexprep(sEntryAction, sCharsToRemove, '');
    casSplitStr = strsplit(sEntryAction, '\n');
    casTrimmedStr = strtrim(casSplitStr);
    casAllScheduledEvents = [casAllScheduledEvents casTrimmedStr(~cellfun('isempty', casTrimmedStr))]; %#ok
end

% TODO : enhance for multiple rates <-> multiple implicit partitions
iD1 = 0;
if any(strcmp(casRowNames, 'D1'))
    oActualSchedule.Order('D1', :).Index = 1;
    iD1 = 1;
end

iIdx = numel(casRowNames);
oActualSchedule.Order('BTCHarnessOUT', :).Index = iIdx;
if ~isempty(hDsmOut)
    iIdx = iIdx-1;
    oActualSchedule.Order('DsmOut', :).Index = iIdx;
end

for i=1:numel(casAllScheduledEvents)
    sFctCallName = casAllScheduledEvents{i};
    if any(endsWith(casRowNames, sFctCallName))
        sStepFctPartitionName = casRowNames{endsWith(casRowNames, sFctCallName)};
        oActualSchedule.Order(sStepFctPartitionName, :).Index = i + iD1;
    end
end

% making sure the partitions are linked to the events
for i=1:numel(casFctCalls)
    sFctCallName = get_param(casFctCalls{i}, 'Name');
    sStepFctPartitionName = casRowNames{endsWith(casRowNames, sFctCallName)};
    if strcmp(oActualSchedule.Order(sStepFctPartitionName, :).Trigger, '')
        sEventName = ['ev_', sFctCallName];
        abFound = cellfun(@(x) endsWith(x, sEventName), casEventNames);
        if any(abFound)
            casNeededEventName = casEventNames(abFound);
            oActualSchedule.Order(sStepFctPartitionName, :).Trigger = casNeededEventName{1};
        end
    end
end

aoEvents = oActualSchedule.Events;
sBtcEvent = '';
for i=1:numel(aoEvents)
    oEvent = aoEvents(i);
    if endsWith(oEvent.Name, 'ev_btc')
        sBtcEvent = oEvent.Name;
        break;
    end
end
if ~isempty(sBtcEvent)
    if ~isempty(hDsmOut)
        oActualSchedule.Order('DsmOut', :).Trigger = sBtcEvent;
    end
    oActualSchedule.Order('BTCHarnessOUT', :).Trigger = sBtcEvent;
end

set_param(sModelName, 'Schedule', oActualSchedule);
end


%%
function i_prepareUpdateDiagram(hModel, sWrapperModelName, sModelName, sDefineDDEnumInWSScript)
% since we do not simulate on the original model (anymore), the extraction model needs also the events we add during wrapper creation
% Adds events and enums needed for the extraction model initialization
oActualSchedule = get_param(sModelName, 'Schedule');
oWrapperScheduler = get_param(sWrapperModelName, 'Schedule');
% events
aoEvents = oActualSchedule.Events;
for i=1:numel(oWrapperScheduler.Events)
    oEvent = oWrapperScheduler.Events(i);
    if startsWith(oEvent.Name, 'ev_')
        aoEvents = [aoEvents; i_createEvent(oEvent.Name)];%#ok
    end
end
if ~isempty(aoEvents)
    oActualSchedule.Events = aoEvents;
    set_param(hModel, 'Schedule', oActualSchedule);
end
% enums
if ~isempty(sDefineDDEnumInWSScript) && exist(sDefineDDEnumInWSScript, 'file')
    fid = fopen('btc_define_enums.m', 'r');
    fileContent = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);
    fileContent = fileContent{1};
    initialFileContent = fileContent;
    sSearchString = 'evalin(''base'', ''clear all'');';
    for i = 1:length(fileContent)
        if contains(fileContent{i}, sSearchString)
            fileContent{i} = ['%' fileContent{i}]; % Comment the line
            break;
        end
    end
    fid = fopen('btc_define_enums.m', 'w');
    fprintf(fid, '%s\n', fileContent{:});
    fclose(fid);
    warning('off');
    run('btc_define_enums.m');
    warning('on');
    fid = fopen('btc_define_enums.m', 'w');
    fprintf(fid, '%s\n', initialFileContent{:});
    fclose(fid);
end
end


%%
function oSchEvent = i_createEvent(sEventName)
oSchEvent = simulink.schedule.Event;
oSchEvent.Name = sEventName;
end

%%
function i_createNewPartitions(hDsmOut, hSFunctionOut)
set_param(hDsmOut, 'TreatAsAtomicUnit', 'on', 'ScheduleAs', 'Aperiodic partition', 'PartitionName', 'DsmOut');
set_param(hSFunctionOut, 'TreatAsAtomicUnit', 'on', 'ScheduleAs', 'Aperiodic partition','PartitionName', 'BTCHarnessOUT');
ahAllReceive = ep_find_system(hSFunctionOut, ...
    'FollowLinks',                      'on',...
    'LookUnderMasks',                   'all', ...
    'BlockType',                        'Receive');
for i=1:numel(ahAllReceive)
    set_param(ahAllReceive(i), 'UseInternalQueue', 'off')
end
end


%%
function bIsStateValid = i_isModelInValidState(sModel)
bIsStateValid = ~i_hasDirtySubsystemReferences(sModel);
end


%%
function i_closeExtractionModelIfStillOpen(sName)
casLoadedModels = cellstr(get_param(Simulink.allBlockDiagrams(), 'Name'));
abFound = cellfun(@(s) strcmp(sName, s), casLoadedModels);
if any(abFound)
    atgcv_m13_close_model(sName);
end
end


%%
function bIsSystemDirty = i_hasDirtySubsystemReferences(sModel)
bIsSystemDirty = false;
if ~verLessThan('matlab', '9.7')
    casAllSubsystem = ep_find_system(sModel, ...
        'FollowLinks',                      'on',...
        'LookUnderMasks',                   'all', ...
        'LookUnderReadProtectedSubsystems', 'on', ...
        'BlockType',                        'SubSystem');
    for i = 1:numel(casAllSubsystem)
        sReferencedSubsystem = get_param(casAllSubsystem{i}, 'ReferencedSubsystem');
        if ~isempty(sReferencedSubsystem)
            if bdIsDirty(sReferencedSubsystem)
                bIsSystemDirty = true;
                return;
            end
        end
    end
end
end


%%
function i_cleanupEnumState(sModelDir)
try %#ok<TRYNC>
    Simulink.data.dictionary.closeAll('-discard');
end
% call clear enums script
sClearEnumsScript = ep_core_canonical_path(fullfile(sModelDir, 'btc_clear_enums.m'));
if exist(sClearEnumsScript, 'file')
    run(sClearEnumsScript);
end
end


%%
function bUseBussesInHarnessSLDD = i_copyPathToSLDD(stSrcModelInfo, stExtrModelInfo, sBusInitScriptName)
bUseBussesInHarnessSLDD = false;

sSlddFile = get_param(stSrcModelInfo.hModel, 'DataDictionary');
if ~isempty(sSlddFile)
    [~, f, e] = fileparts(sSlddFile);
    sSlddRef = [f, e];
    sHarnessSlddName = [stExtrModelInfo.sName, '.sldd'];
    sHarnessSlddFile = fullfile(stExtrModelInfo.sPath,sHarnessSlddName);
    oHarnessSldd = Simulink.data.dictionary.create(sHarnessSlddFile);
    oHarnessSldd.addDataSource(sSlddRef);
    if ~isempty(sBusInitScriptName)
        Simulink.Bus.cellToObject(feval(sBusInitScriptName, false), oHarnessSldd);
        bUseBussesInHarnessSLDD = true;
    end
    oHarnessSldd.saveChanges();
    set_param(stExtrModelInfo.hModel, 'DataDictionary', sHarnessSlddName);
end
end


%%
% Copies the simulink functions to the SUT subsystem of the extraction model. Also considering the model workspace of
% the SL function which (potentially) needs to be available in the extraction model.
%
function casSLFunctionPaths = i_copy_simulink_functions(stExtrModelInfo, stSrcModelInfo)
jHandledModels = java.util.HashSet;
jHandledFunctions = java.util.HashSet;
astSLFunctionCaller = mxx_xmltree('get_nodes', stSrcModelInfo.xSubsys, './SLFunctionCaller');

sTargetParentPath = stExtrModelInfo.sName;
hTargetModel = get_param(bdroot(sTargetParentPath), 'handle');
for i = 1:length(astSLFunctionCaller)
    sSLFunctionPath = mxx_xmltree('get_attribute', astSLFunctionCaller(i), 'pathFunction');

    % Every SL function only needs to be copied once.
    if jHandledFunctions.contains(sSLFunctionPath)
        continue;
    end
    jHandledFunctions.add(sSLFunctionPath);

    sFunctionName = get_param(sSLFunctionPath, 'Name');
    sValidName = i_find_unused_name(sTargetParentPath, sFunctionName);
    sTargetPath = [sTargetParentPath, '/', sValidName];

    % copying the original SL function to the extraction model
    add_block(sSLFunctionPath, sTargetPath);

    % copying the model workspace of the parent model where the SL function resides to the extraction model
    sSourceModel = bdroot(sSLFunctionPath);
    if jHandledModels.contains(sSourceModel)
        continue;
    end
    jHandledModels.add(sSourceModel);

    atgcv_m13_mdlbase_copy(get_param(sSourceModel, 'handle'), hTargetModel);
end

jaoHandledFunctions = jHandledFunctions.toArray;
iCount = numel(jaoHandledFunctions);
casSLFunctionPaths = cell(1, iCount);
for i = 1:iCount
    [~, sFuncName] = fileparts(jaoHandledFunctions(i));
    casSLFunctionPaths{i} = [sTargetParentPath '/' sFuncName];
end

end


%%
% Returns a name, which does not yet exist in the model.
% The name is derived from the given name. If necessary a counter
% is incremented as long as necessary to find the unused name.
function sUnusedName = i_find_unused_name(sParentPath, sName)
nCnt = 1;
sUnusedName = sName;
sSearchPath = [sParentPath, '/', sUnusedName];
while i_block_exists(sSearchPath)
    nCnt = nCnt + 1;
    sUnusedName = [sName, string(nCnt)];
    sSearchPath = [sParentPath, '/', sUnusedName];
end
end


%%
% Returns true, if the given path already exists in the model.
function bBlockExists = i_block_exists(sPath)
handle = getSimulinkBlockHandle(sPath);
bBlockExists = (handle ~= -1);
end


%%
function sLocationSUT = i_remap_main_sut_block_location(sLocationSUT, iSub2RefConversion)
switch iSub2RefConversion
    case 0
        % do nothing special
    case 1
        sExtrModelName = strtok(sLocationSUT, '/');
        sLocationSUT = strcat(sExtrModelName, '_ref');
    case 2
        [sExtrModelName, sScopePath] = strtok(sLocationSUT, '/');
        sLocationSUT = strcat(sExtrModelName, '_ref', sScopePath);
    otherwise
        error('INTERNAL:ERROR', 'Unknown enum number %d of Sub2RefConversion.', iSub2RefConversion);
end
end


%%
function stModelInfo = i_get_source_model_info(xEnv, sModelFile, sExtractionModelFile)
[sP, sF, sExt] = fileparts(sModelFile);
[xSubsys, xOnCleanUpCloseFile] = i_open_extraction_model_file(sExtractionModelFile);

xRoot = mxx_xmltree('get_root', xSubsys);
bIsTlModel = ~strcmp(mxx_xmltree('get_attribute', xRoot, 'type'), 'SimulinkArchitecture');

sSampleTime = mxx_xmltree('get_attribute', xSubsys, 'sampleTime');


sSubsysPath = atgcv_m13_path_get( xSubsys );
hSubBlock = get_param( sSubsysPath, 'handle' );
atgcv_m13_check_interface( xEnv, xSubsys, hSubBlock );

sSubsystemName = mxx_xmltree('get_attribute', xSubsys, 'name');
sSubsystemPath = mxx_xmltree('get_attribute', xSubsys, 'path');
sSubsystemPathPhysical = mxx_xmltree('get_attribute', xSubsys, 'physicalPath');
if isempty(sSubsystemPathPhysical)
    sSubsystemPathPhysical = sSubsysPath;
end
bSubsystemIsOrigModel = strcmp(sF, sSubsystemPath);

bIsScheduleEditorNeeded = false;
if (strncmp(sF, 'Wrapper_', length('Wrapper_')))
    sOrigModelName = sF(length('Wrapper_')+1 : length(sF));
    casModels = ep_find_mdlrefs(sF);
    if any(strcmp(casModels, sOrigModelName))
        try
            sIntModelName = ['W_integ_', sOrigModelName];
            casEnhModel = ep_find_system([sF, '/', sIntModelName, '/', sIntModelName], 'BlockType','ModelReference');
            hEnhModel = get_param(casEnhModel{1}, 'Handle');
            if strcmp(get(hEnhModel, 'ScheduleRatesWith'), 'Schedule Editor')
                bIsScheduleEditorNeeded = true;
            end
        catch
        end
    end
end

stModelInfo = struct(...
    'sModelPath', sP, ...
    'sModelName', sF, ...
    'sModelExtension', sExt, ...
    'hModel', get_param(sF, 'handle'), ...
    'bIsTlModel', bIsTlModel, ...
    'nUsage', i_getUsage(bIsTlModel),...
    'sSampleTime', sSampleTime, ...
    'xSubsys', xSubsys, ...
    'bSubsysIsRootModel', bSubsystemIsOrigModel, ...
    'sSubsysPath', sSubsystemPath, ...
    'sSubsystemName', sSubsystemName, ...
    'sSubsysPathPhysical', sSubsystemPathPhysical, ...
    'onCleanUp', xOnCleanUpCloseFile, ...
    'sExtractionModelFile', sExtractionModelFile, ...
    'bIsScheduleEditorNeeded', bIsScheduleEditorNeeded);
end


%%
function [hSubsystem, xOnCleanUpCloseFile] = i_open_extraction_model_file(sExtractionModelFile)
hDoc = mxx_xmltree('load', sExtractionModelFile );
xOnCleanUpCloseFile = onCleanup(@() mxx_xmltree('clear', hDoc));
xModelAnalysis = mxx_xmltree('get_root', hDoc);
sUid = mxx_xmltree('get_attribute', xModelAnalysis, 'ref');
hSubsystem = mxx_xmltree('get_nodes', xModelAnalysis, sprintf('//Scope[@uid="%s"]', sUid));
end


%%
function i_set_global_settings(sMilRndMeth, casReuseModelCallbacks)
if ~isempty(sMilRndMeth)
    atgcv_sim_settings('MIL_RND_METH', upper(sMilRndMeth));
end

sReuseModelCallbacks = i_mergeToMultiValue(casReuseModelCallbacks);
atgcv_sim_settings('REUSE_MODEL_CALLBACKS', sReuseModelCallbacks);
end


%%
function nUsage = i_getUsage(bIsTlModel)
nUsage = 2;
if (bIsTlModel)
    nUsage = 1;
end
end


%%
% * split multivalue at separator ';'
% * trim the resulting parts
% * remove all blanks (empty strings)
function sMultiValue = i_mergeToMultiValue(casValues)
if isempty(casValues)
    sMultiValue = '';
else
    sMultiValue = sprintf('%s;', casValues{:});
    sMultiValue(end) = []; % remove last ";"
end
end


%%
function i_connect_blocks(sExtractionModelName, stExtrResult, hSFunctionIn, hSFunctionOut, hDsmIn, hDsmOut)
stSutPortHandles = get(stExtrResult.hSubsystem, 'PortHandles');

% Connect input harness
if isempty(stExtrResult.hInnerHarnessLeft)
    iNumInports = length(stSutPortHandles.Inport);
    i_linkSubsystems(sExtractionModelName, hSFunctionIn, 0, stExtrResult.hSubsystem, 0, iNumInports);
else
    stHarnessLeftPortHandles = get(stExtrResult.hInnerHarnessLeft, 'PortHandles');
    iNumInports = length(stHarnessLeftPortHandles.Inport);
    i_linkSubsystems(sExtractionModelName, hSFunctionIn, 0, stExtrResult.hInnerHarnessLeft, 0, iNumInports);
end
if ~isempty(hDsmIn)
    stPortHandlesDsmIn = get(hDsmIn, 'PortHandles');
    i_linkSubsystems(sExtractionModelName, hSFunctionIn, iNumInports, hDsmIn, 0, length(stPortHandlesDsmIn.Inport));
end

% Connect output harness
if isempty(stExtrResult.hInnerHarnessRight)
    iNumOutports = length(stSutPortHandles.Outport);
    i_linkSubsystems(sExtractionModelName, stExtrResult.hSubsystem, 0, hSFunctionOut, 0, iNumOutports);
else
    stHarnessRightPortHandles = get(stExtrResult.hInnerHarnessRight, 'PortHandles');
    iNumOutports = length(stHarnessRightPortHandles.Outport);
    i_linkSubsystems(sExtractionModelName, stExtrResult.hInnerHarnessRight, 0, hSFunctionOut, 0, iNumOutports);
end
if ~isempty(hDsmOut)
    stPortHandlesDsmOut = get(hDsmOut, 'PortHandles');
    i_linkSubsystems(sExtractionModelName, hDsmOut,0, hSFunctionOut,iNumOutports, length(stPortHandlesDsmOut.Outport));
end
end

%%
function stOpt = i_get_extraction_options(stArgs)
stOpt = struct( ...
    'ExportPath', stArgs.ExportPath, ...
    'Name', stArgs.Name, ...
    'BreakLinks', stArgs.BreakLinks, ...
    'bCloseExtrModel', false, ...
    'bEnableTLHook', stArgs.TL_HOOK_MODE, ...
    'SutAsModelRef', stArgs.SutAsModelRef, ...
    'OriginalSimulationMode', stArgs.OriginalSimulationMode, ...
    'ModelRefMode', stArgs.ModelRefMode);
stOpt.PreserveLibLinks = stArgs.PreserveLibLinks;
end


%%
function stResult = i_get_result(stExtrResult)
stResult = struct( ...
    'ExtractionModel',   stExtrResult.ExtractionModel, ...
    'InitScript',        stExtrResult.InitScript, ...
    'TopLevelSubsystem', stExtrResult.TopLevelSubsystem, ...
    'ModuleName',        stExtrResult.ModuleName);
end


%%
function stArgs = i_parse_input_args(varargin)
casValidKeys = {'ModelFile', 'InitScriptFile', 'ExtractionModelFile', 'HarnessModelFileIn', 'HarnessModelFileOut','MessageFile',...
    'Name', 'Mode', 'EnableCalibration', 'EnableLogging', 'EnableSubsystemLogging', 'EnableDebugUseCase', ...
    'BreakLinks', 'PreserveLibLinks', 'ModelRefMode', 'UseFromWS', 'MIL_RND_METH', ...
    'OriginalSimulationMode', 'TL_HOOK_MODE', 'REUSE_MODEL_CALLBACKS','Progress', 'ExportPath', 'SutAsModelRef', ...
    'FuncExtractSUT', 'SetGlobalSettingsTL', 'AddTLMainDialog', 'EnableCalibrationFunc', 'EnableLoggingFunc', ...
    'TLAddCodeSettings', 'ResetGlobalSettingsTL', 'TLAdaptations', 'TLChecks', 'isToplevelProfile'};

stArgs = ep_core_transform_args(varargin, casValidKeys);

stArgs = i_get_defaults(stArgs);

ep_sim_argcheck('ModelFile', stArgs, 'obligatory', {'class', 'char'});
ep_sim_argcheck('ModelFile', stArgs, 'file');

ep_sim_argcheck('InitScriptFile', stArgs, 'obligatory', {'class', 'char'});

ep_sim_argcheck('ExtractionModelFile', stArgs, 'obligatory', {'class', 'char'});
ep_sim_argcheck('ExtractionModelFile', stArgs, 'file');
ep_sim_argcheck('ExtractionModelFile', stArgs, {'xsdvalid', 'ExtractionModel.xsd'});

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
ep_sim_argcheck('MessageFile', stArgs, {'class', 'char'});
ep_sim_argcheck('Name', stArgs, {'class', 'char'});
ep_sim_argcheck('Mode', stArgs, {'class', 'char'}, {'keyvalue_i', {'MIL', 'PIL', 'SIL'}});
ep_sim_argcheck('MIL_RND_METH', stArgs, {'class', 'char'}, ...
    {'keyvalue', {'Nearest', 'Zero', 'Round', 'Simplest', 'Convergent', 'Ceiling', 'Floor'}});
ep_sim_argcheck('TL_HOOK_MODE', stArgs, {'class', 'logical'});
ep_sim_argcheck('REUSE_MODEL_CALLBACKS', stArgs, {'class', 'cell'});
ep_core_check_args('REUSE_MODEL_CALLBACKS', stArgs, {'ismember',  { 'PreLoadFcn', 'PostLoadFcn', 'InitFcn', ...
    'StartFcn', 'PauseFcn', 'ContinueFcn', 'StopFcn', 'PreSaveFcn', 'PostSaveFcn', 'CloseFcn', 'none'}});
ep_sim_argcheck('Mode', stArgs, {'class', 'char'}, {'keyvalue_i', {'MIL', 'PIL', 'SIL'}});
ep_sim_argcheck('OriginalSimulationMode', stArgs, 'obligatory', {'class', 'char'}, {'keyvalue_i', i_getKnownSimModes()});
ep_sim_argcheck('EnableCalibration', stArgs, {'class', 'logical'});
ep_sim_argcheck('EnableLogging', stArgs, {'class', 'logical'});
ep_sim_argcheck('EnableSubsystemLogging', stArgs, {'class', 'logical'});
ep_sim_argcheck('BreakLinks', stArgs, {'class', 'logical'});
ep_sim_argcheck('PreserveLibLinks', stArgs, {'class', 'cell'});
ep_sim_argcheck('UseFromWS', stArgs, {'class', 'logical'});
ep_sim_argcheck('ModelRefMode', stArgs, {'class', 'double'});
ep_sim_argcheck('Progress', stArgs, {'class','ep.core.ipc.matlab.server.progress.Progress'});
ep_sim_argcheck('ExportPath', stArgs, {'class', 'char'});
ep_sim_argcheck('ExportPath', stArgs, 'dir');
ep_sim_argcheck('SutAsModelRef', stArgs, {'class', 'logical'});
ep_sim_argcheck('isToplevelProfile', stArgs, {'class', 'logical'});
end


%%
function casKnownSimModes = i_getKnownSimModes()
casKnownSimModes = { ...
    'TL MIL', ...
    'TL MIL NEW', ...
    'TL MIL (EV)', ...
    'SL MIL', ...
    'SL MIL (Toplevel)', ...
    'SL MIL SFunc', ...
    'PIL', ...
    'SIL', ...
    'TL SIL', ...
    'SL SIL', ...
    'TL ClosedLoop SIL', ...
    ''};
end


%% get defaults
function stArgs = i_get_defaults(stArgs)
%Load constants
Constants = ep_sl.Constants;


if ~isfield(stArgs, 'ModelFile')
    stArgs.ModelFile = '';
end

if ~isfield(stArgs, 'ExtractionModelFile')
    stArgs.ExtractionModelFile = '';
end

if ~isfield(stArgs, 'MessageFile')
    stArgs.MessageFile = '';
end

if ~isfield(stArgs, 'Name')
    stArgs.Name = [];
end

if ~isfield(stArgs, 'REUSE_MODEL_CALLBACKS')
    stArgs.REUSE_MODEL_CALLBACKS = {'none'};
end

if ~isfield(stArgs, 'MIL_RND_METH')
    stArgs.MIL_RND_METH = '';
end

if ~isfield(stArgs, 'TL_HOOK_MODE')
    stArgs.TL_HOOK_MODE = false;
end

if ~isfield(stArgs, 'MODE')
    stArgs.MIL = 'MIL';
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

if ~isfield(stArgs, 'BreakLinks')
    stArgs.BreakLinks = true;
end

if isfield(stArgs, 'PreserveLibLinks')
    % Slash is appened in order to ensure that only libs with an exact
    % match are considered.
    stArgs.PreserveLibLinks = cellfun(@(c)[c,'/'], stArgs.PreserveLibLinks, 'uni', false);
else
    stArgs.PreserveLibLinks = {};
end

if ~isfield(stArgs, 'ModelRefMode')
    stArgs.ModelRefMode = Constants.COPY_REFS;
end

if ~isfield(stArgs, 'UseFromWS')
    stArgs.UseFromWS = false;
end

if ~isfield(stArgs, 'ExportPath')
    stArgs.ExportPath = EPEnvironment.getTempDirectory();
end

if ~isfield(stArgs, 'SutAsModelRef')
    stArgs.SutAsModelRef = false;
end

if ~isfield(stArgs, 'isToplevelProfile')
    stArgs.isToplevelProfile = false;
end
end


%%
function stExtrModelInfo = i_createEmptyExtractionModel(sExtrModelName, sExportPath, sSampleTime)
if isempty(sExtrModelName)
    sExtrModelName = ['m', datestr(now, 'mmddHHMMSS')];
end
hExtrModel = ep_simenv_create_model(sExtrModelName);
stExtrModelInfo = struct(...
    'sPath',  sExportPath, ...
    'sName',  sExtrModelName, ...
    'hModel', hExtrModel);

% set FixedPointSolver and the needed SampleTime directly; otherwise setting into compiled mode later when
% adding harness S-Functions with the predefined SampleTime could throw exceptions (see EP-2939)
i_setFixedPointSolver(hExtrModel, sSampleTime);
end


%%
function i_setFixedPointSolver(xModel, sSampleTime)
oConfig = getActiveConfigSet(xModel);
oSolverConfig = oConfig.getComponent('Solver');

i_setProperty(oSolverConfig, 'Solver', 'FixedStepDiscrete');
stFixedStepProps = struct( ...
    'StartTime',            '0.0', ...
    'StopTime',             'inf', ...
    'FixedStep',            sSampleTime, ...
    'MaxStep',              'auto', ...
    'MinStep',              'auto', ...
    'SampleTimeConstraint', 'Unconstrained');
casProps = fieldnames(stFixedStepProps);
for i = 1:numel(casProps)
    sProp = casProps{i};
    xValue = stFixedStepProps.(sProp);

    i_setProperty(oSolverConfig, sProp, xValue);
end
end


%%
function oEx = i_setProperty(oConfig, sProperty, xNewValue)
oEx = [];

try
    bSettingAllowed = oConfig.getPropEnabled(sProperty);
catch oEx
    bSettingAllowed = false;
end
if ~bSettingAllowed
    return;
end

try
    xCurrentValue = oConfig.get(sProperty);
    if ~isequal(xNewValue, xCurrentValue)
        oConfig.set(sProperty, xNewValue);
    end
catch oEx
end
end


%%
function i_linkSubsystems(sExtractionModelName, hSubLeft, iOffsetLeft, hSubRight, iOffsetRight, iNumberOfConnections)
for i = 1:iNumberOfConnections
    add_line(sExtractionModelName, ...
        [get_param(hSubLeft, 'Name'),'/', num2str(i + iOffsetLeft)], ...
        [get_param(hSubRight, 'Name'),'/', num2str(i + iOffsetRight)]);
end
end


%%
function i_set_block_locations(hSFuncIn, hSFuncOut, stExtrResult, hDsmIn, hDsmOut, casSLFunctionPaths)
aSubPos = get_param(stExtrResult.hSubsystem, 'Position');
aSubWidth = aSubPos(3) - aSubPos(1);
iLowerBoundIn = aSubPos(4);
iLowerBoundOut = aSubPos(4);
if ~isempty(hDsmIn)
    anPosition = get_param(hDsmIn, 'Position');
    anPosition =  [aSubPos(1),  aSubPos(4)+50, aSubPos(1)+(anPosition(3)-anPosition(1)), aSubPos(4)+50+(anPosition(4) - anPosition(2))];
    set_param(hDsmIn, 'Position', anPosition);
    set_param(hDsmIn, 'BackgroundColor', 'Yellow');
    iLowerBoundIn = aSubPos(4)+50+(anPosition(4) - anPosition(2));
end

if ~isempty(hDsmOut)
    anPosition = get_param(hDsmOut, 'Position');
    anPosition =  [aSubPos(3)-(anPosition(3)-anPosition(1)),  aSubPos(4)+50, aSubPos(3), aSubPos(4)+50+(anPosition(4) - anPosition(2))];
    set_param(hDsmOut, 'Position', anPosition);
    set_param(hDsmOut, 'BackgroundColor', 'Yellow');
    iLowerBoundOut = aSubPos(4)+50+(anPosition(4) - anPosition(2));
end

if isempty(stExtrResult.hInnerHarnessRight)
    ahSfunctionInPos = [aSubPos(1)-100-aSubWidth aSubPos(2)-25 aSubPos(1)-100 iLowerBoundIn+25];
    ahSfunctionOutPos = [aSubPos(3)+100 aSubPos(2)-25 aSubPos(3)+100+aSubWidth iLowerBoundOut+25];
else
    ahSfunctionInPos = [aSubPos(1)-200-aSubWidth aSubPos(2)-25 aSubPos(1)-200 iLowerBoundIn+25];
    ahSfunctionOutPos = [aSubPos(3)+200 aSubPos(2)-25 aSubPos(3)+200+aSubWidth iLowerBoundOut+25];
end

set_param(hSFuncIn, 'Position', ahSfunctionInPos);
set_param(hSFuncOut, 'Position', ahSfunctionOutPos);

anWindowSize = [100 100 floor(ahSfunctionOutPos(3)-ahSfunctionInPos(1))+350 ahSfunctionOutPos(4)];

% arrange SLFunction-Blocks below the model
anSLFunctionStartPos = [ahSfunctionInPos(1) ahSfunctionInPos(4)+50 ahSfunctionInPos(1)+100 ahSfunctionInPos(4)+100];
iRows = 4;
iColumns = 6;
iMaxAmount = iRows * iColumns;
for i = 1:numel(casSLFunctionPaths)
    iActiveLayer = floor((i-1)/iMaxAmount);
    iLayeredIndex = mod(i-1, iMaxAmount);
    iActiveRow = floor(iLayeredIndex/iColumns);
    iActiveColumn = mod(iLayeredIndex, iColumns);
    iBlockStartSpacing = floor((ahSfunctionOutPos(3)-ahSfunctionInPos(1))/iColumns);

    iLeft = anSLFunctionStartPos(1)+iActiveColumn*iBlockStartSpacing+iActiveLayer*5;
    iTop = anSLFunctionStartPos(2)+iActiveRow*80+iActiveLayer*5;

    anSLFunctionPosition = [iLeft iTop iLeft+100 iTop+50] ;
    set_param(casSLFunctionPaths{i}, 'Position', anSLFunctionPosition);
    set_param(casSLFunctionPaths{i}, 'ZOrder', iActiveLayer);

    if anWindowSize(4) <  anSLFunctionPosition(4)
        anWindowSize(4) = anSLFunctionPosition(4);
    end
end
anWindowSize(4) = anWindowSize(4)+400;
set_param(stExtrResult.stExtrModelInfo.sName, 'location', anWindowSize);
end


%% controling Priority for the blocks is mandatory because of DSM usage
function i_set_block_priorities(hHarnessIn, hHarnessOut, hSut, hDsmIn, hDsmOut)
sHarnessInPrio  = '100';
sDsmInPrio      = '200';
sSutPrio        = '300';
sDsmOutPrio     = '400';
sHarnessOutPrio = '500';

set_param(hHarnessIn, 'Priority', sHarnessInPrio);
set_param(hDsmIn,     'Priority', sDsmInPrio);
set_param(hSut,       'Priority', sSutPrio);
set_param(hDsmOut,    'Priority', sDsmOutPrio);
set_param(hHarnessOut,'Priority', sHarnessOutPrio);

set_param(hHarnessIn, 'BackgroundColor', 'Yellow');
set_param(hHarnessOut, 'BackgroundColor', 'Yellow');
end


%%
function i_set_line_name(hModel, sSrcSub, hDstSub)
sElemNameMismatch = get_param(hModel, 'BusObjectLabelMismatch');
if strcmp(sElemNameMismatch, 'error') && ~strcmp(get_param(sSrcSub, 'Type'), 'block_diagram')
    ph_src = get_param(sSrcSub, 'PortHandles');
    ph_dst = get_param(hDstSub, 'PortHandles');

    aInports = ph_src.Inport;
    for i=1:numel(aInports)
        hSrcLine = get_param(aInports(i), 'Line');
        if hSrcLine > 0
            sName = get_param(hSrcLine, 'Name');
            if ~isempty(sName)
                hDstLine = get_param(ph_dst.Inport(i), 'Line');
                set_param(hDstLine, 'Name', sName);
            end
        end
    end

    aOutports = ph_src.Outport;
    for i=1:numel(aOutports)
        hSrcLine = get_param(aOutports(i), 'Line');
        if hSrcLine > 0
            sName = get_param(hSrcLine, 'Name');
            if ~isempty(sName)
                hDstLine = get_param(ph_dst.Outport(i), 'Line');
                set_param(hDstLine, 'Name', sName);
            end
        end
    end
end
end


%%
function i_saveAndCloseExtrMdl(sExtrModelName, bSutAsModelRef, iModelRefMode, sClearDDEnumInWSScript)
if bSutAsModelRef
    if verLessThan('matlab', '9.12')
        % workaround to avoid a pop-up window to refresh the model reference
        save_system(sExtrModelName, sExtrModelName, 'SaveDirtyReferencedModels', 'on');
        close_system([sExtrModelName, '_ref']);
    end
    atgcv_m13_save_model(sExtrModelName, true, true);
else
    bCloseModelRefs = iModelRefMode ~= 0;
    atgcv_m13_save_model(sExtrModelName, true, bCloseModelRefs);
end
if ~isempty(sClearDDEnumInWSScript)
    try
        warning('off', 'Simulink:DataType:DynamicEnum_NowNotOwnedByDictionary');
        warning('off', 'Simulink:DataType:DynamicEnum_CannotClearClass');
        run(sClearDDEnumInWSScript);
        warning('on', 'Simulink:DataType:DynamicEnum_NowNotOwnedByDictionary');
        warning('off', 'Simulink:DataType:DynamicEnum_CannotClearClass');
    catch
    end
end
end


%%
function [hSub, iSub2RefConversion, stSrcModelInfo] = i_convertSutToModelRef(xEnv, hSub, stSrcModelInfo, stExtrModelInfo, stArgs, sDefineDDEnumInWSScript)
stEnv = ep_core_legacy_env_get(xEnv, true);
iSub2RefConversion = 1;
sReferencedModelName   = strcat(stExtrModelInfo.sName, '_ref');
iNumberOfSubs = length(ep_find_system(hSub, 'BlockType', 'SubSystem')) - 1;

oOnCleanupRevertClosingModel = [];
if ~isempty(sDefineDDEnumInWSScript)
    oOnCleanupRevertClosingModel = ...
        ep_sim_harness_prepare_ws(stSrcModelInfo.sModelName, sDefineDDEnumInWSScript);
end
%convert subsystem to model reference
[bSuccess, hMdlRefBlk] = Simulink.SubSystem.convertToModelReference(...
    hSub, ...
    sReferencedModelName,...
    'UseConversionAdvisor',false,...
    'AutoFix',true,...
    'ReplaceSubsystem',true);

if ~isempty(oOnCleanupRevertClosingModel)
    clear('oOnCleanupRevertClosingModel');
    stSrcModelInfo.hModel = get_param(stSrcModelInfo.sModelName, 'Handle');
end
if bSuccess
    hSub = hMdlRefBlk;
    sModelRef=get_param(hSub, 'ModelName');
    stModelRefInfo.hModel = get_param(sModelRef, 'Handle');
    set_param(stModelRefInfo.hModel, 'PreLoadFcn', '');
    stModelRefInfo.sName = sModelRef;
    stModelRefInfo.sPath = stExtrModelInfo.sPath;
    iNumberOfSubsInRef = length(ep_find_system(stModelRefInfo.hModel, 'BlockType', 'SubSystem'));
    i_copy_model_settings(stEnv, stSrcModelInfo, stModelRefInfo, stArgs);
    atgcv_m13_save_model(sModelRef, false, false);
    % Due to a behavior change in ML2020a, it is possible that an indirection has been created
    % ML2020 release notes:
    % When you convert a subsystem to a referenced model, the conversion minimizes the number of Simulink.Bus
    % objects it creates for virtual bus inputs and outputs. In Bus Element and Out Bus Element blocks allow
    % virtual buses to cross the model boundary without Bus objects.
    % Values of iSub2RefConversion:
    % 0 = no model reference conversion
    % 1 = simple model reference conversion
    % 2 = model reference conversion with one indirection
    if (iNumberOfSubs ~= iNumberOfSubsInRef)
        iSub2RefConversion = 2;
    end
end
end


%%
function i_copy_model_settings(stEnv, stSrcModelInfo, stExtrModelInfo, stArgs)
atgcv_m13_mdlbase_copy(stSrcModelInfo.hModel, stExtrModelInfo.hModel);

sModelRefPath = atgcv_m13_modelref_get(stSrcModelInfo.xSubsys, stSrcModelInfo.bIsTlModel);
if isempty(sModelRefPath)
    ep_simenv_copy_model_settings(stEnv, bdroot(hSubBlock), stExtrModelInfo.hModel,  stSrcModelInfo.sSampleTime);
else
    hModelRef = get_param(sModelRefPath, 'Handle');
    ep_simenv_copy_model_settings(stEnv, bdroot(hModelRef), stExtrModelInfo.hModel,  stSrcModelInfo.sSampleTime);
end

if stArgs.BreakLinks
    atgcv_m13_sf_settings_copy(stEnv, stSrcModelInfo.sModelName, stExtrModelInfo.sName, ...
        stSrcModelInfo.sModelPath, stExtrModelInfo.sPath,  stSrcModelInfo.sSampleTime);
end

atgcv_m13_sfdebug_disable(stEnv, stExtrModelInfo.sName); %see BTS/21566
end


%%
function i_setOutputAsBusOnBusSelectors(hSFunctionOut)
casBusSelectors= ep_find_system([get_param(hSFunctionOut, 'Parent'), '/', get_param(hSFunctionOut, 'Name')], ...
    'FollowLinks', 'on', ...
    'SearchDepth', 1, ...
    'BlockType',   'BusSelector');
for b = 1:numel(casBusSelectors)
    hBusSelector = get_param(casBusSelectors{b}, 'Handle');
    casInputSignals = get_param(hBusSelector, 'InputSignals');
    sAllSelectedSignals = '';
    for i = 1:numel(casInputSignals)
        if iscell(casInputSignals{i})
            casInSig = casInputSignals{i};
            sAllSelectedSignals = strcat(sAllSelectedSignals, casInSig{1});

        else
            sAllSelectedSignals = strcat(sAllSelectedSignals, casInputSignals{i});
        end
        if i ~= numel(casInputSignals)
            sAllSelectedSignals = strcat(sAllSelectedSignals, ',');
        end
    end
    if ~isempty(sAllSelectedSignals)
        set_param(hBusSelector, 'OutputSignals', sAllSelectedSignals);
        set_param(hBusSelector, 'OutputAsBus', 1);
    end
end
end


%%
function i_formatSUTBlock(hHandle)
aiPosition = get_param(hHandle, 'Position');
iMinBlockHeight = 120;
iMinBlockWidth  = 300;
iHeight = aiPosition(4)-aiPosition(2);
iWidth  = aiPosition(3)-aiPosition(1);
if iWidth < iMinBlockWidth
    aiPosition(3) = aiPosition(3) + iMinBlockWidth - iWidth;
end
if iHeight < iMinBlockHeight
    aiPosition(4) = aiPosition(4) + iMinBlockHeight - iHeight;
end
set_param(hHandle, 'Position', aiPosition)
i_createBTCMask(hHandle);
end


%%
function i_createBTCMask(hBlock)
oMask = Simulink.Mask.create(hBlock);

%Spaces are needed for formatting! Do not remove!
oMask.Display = ['disp(''\color{gray}\it\fontsize{20}                          embedded\newline' ...
    '                          systems'', ''texmode'', ''on'');disp(''{{\color{gray}\bf\fontsize{50}' ...
    '\it   BTC}  \fontsize{80}|      \color{black}\fontsize{20}\newline }'', ''texmode'', ''on'');'];
end


%%
function i_prepend_callback(sModel, sCallbackName, sExpression)
if isempty(sExpression)
    return;
end
sCurrentContent = get_param(sModel, sCallbackName);
if isempty(sCurrentContent)
    sContent = sExpression;
else
    sContent = sprintf('%s;%s', sExpression, sCurrentContent);
end
set_param(sModel, sCallbackName, sContent);
end


%%
function i_addReplacedModelRefInfo(hScopeNode, sExtractedSutBlockPath)
mSubToRefModel = ep_sim_modelref_replacement('find', sExtractedSutBlockPath);
if mSubToRefModel.isempty()
    return;
end

hRootNode = mxx_xmltree('get_root', hScopeNode);
casSubBlocks = mSubToRefModel.keys;
for i = 1:numel(casSubBlocks)
    sSubBlock = casSubBlocks{i};
    sRefModel = mSubToRefModel(sSubBlock);

    hReplacedModelRefNode = mxx_xmltree('add_node', hRootNode, 'ReplacedModelRef');
    mxx_xmltree('set_attribute', hReplacedModelRefNode, 'replacementSub', sSubBlock);
    mxx_xmltree('set_attribute', hReplacedModelRefNode, 'refModel', sRefModel);
end
end

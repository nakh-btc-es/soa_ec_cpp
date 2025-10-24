function stExtractInfo = ep_sim_extract_sl_toplevel_model(varargin)
% This function extract from the provided Simulink model an extraction model. It is assumed that the model is already open.
%
% function stExtractInfo = ep_sim_extract_sl_toplevel_model(varargin)
%
%  INPUT              DESCRIPTION
%   - varargin           ([Key, Value]*)  Key-value pairs with the following
%                                       possibles values. Inputs marked with (*)
%                                       are mandatory.
%    Key(string):            Meaning of the Value:
%         ModelFile*              Path to the original TargetLink/Simulink
%                                 model file (.mdl|.slx). It is assmed that
%                                 the model file is already loaded.
%         ExtractionModelFile*    Path to the extraction model XML File(see
%                                 extraction_model.xsd)
%         InitScriptFile*         Path to the original init script file
%         Name                    Name of the extraction model
%     !!! Mode                    kind of model (SL MIL|SL SIL) !!!ALWAYS SL MIL!!!
%         ExportPath*   (String)  Path where the extraction model shall be created. 
%         EnableCalibration
%                      (boolean)  Calibration should be enabled (Default :
%                                 true)
%         EnableLogging(boolean)  Logging should be enabled (Default :
%                                  true)
%         EnableSubsystemLogging  (boolean)  Logging should be enabled
%                                 (Default : false)
%     !!! BreakLinks   (boolean)  Break Links to Libraries (Default :
%                                 true)
%     !!! PreserveLibLinks
%                    (cell-array) Defines a list of library names for which the links must not be broken.
%                                 For some libraries it is possible that a link break leads to an invalid
%                                 extraction model. E.g (SimScape). Hence no simulation is possible.
%                                 Only active if 'BreakLinks' is true. (Default : empty list)
%     !!! UseFromWS    (boolean)  When true, use inputs from WS block
%                                 instead from FromFile block
%         MIL_RND_METH  (string)  {'Nearest', 'Zero', 'Round', 'Simplest',
%                                 'Convergent', 'Ceiling', 'Floor'}
%                                 Default : ''
%     !!! TL_HOOK_MODE (boolean)  When true, internal TL hooks in the
%                                 extraction model will be generated.
%                                 Default : false
%     !!! REUSE_MODEL_CALLBACKS   {'PreLoadFcn', 'PostLoadFcn', 'InitFcn',
%                       (cell)     'StartFcn', 'PauseFcn', 'ContinueFcn',
%                                  'StopFcn', 'PreSaveFcn', 'PostSaveFcn',
%                                  'CloseFcn'}
%                                 Default : {}
%     !!! OriginalSimulationMode* Defines the original simulation mode
%                                 ('SL MIL' | SL SIL')
%         MessageFile             The absoulte path to the message file for
%                                 recording errors/warnings/info messages.
%
%     !!! SutAsModelRef           (boolean)    When true, the system under test will be a model reference
%
%         Progress     (object)   Progress object for progress information.
%
%  OUTPUT            DESCRIPTION
%  - stExtractInfo       (struct)  Information about the extraction model
%    .ExtractionModel    (string)  Full path to the extraction model file
%    .InitScript         (string)  Full path to the initialize script for
%                                  the extraction model.
%    .TopLevelSubsystem  (string)  Top level subsystem of the extraction
%                                  model file.
%    .ModuleName         (string)  TL Model, the module name of the
%                                  extraction model (for SL models is '')
%


%% init environment
stArgs = i_vararginToStruct(varargin);

caxArgs = [varargin, {'FuncExtractSUT', @ep_sim_extract_toplevel_model_sl}];
if (isfield(stArgs, 'EnableCalibration') && stArgs.EnableCalibration)
    caxArgs = [caxArgs, {'EnableCalibrationFunc', @ep_sl_top_enable_calibration}];
else
    caxArgs = [caxArgs, {'EnableCalibrationFunc', []}];
end

if (isfield(stArgs, 'EnableLogging') && stArgs.EnableLogging)
    % TODO: implement here toplevel solution!
    %caxArgs = [caxArgs, {'EnableLoggingFunc', @ep_sl_enable_logging}];
else
    caxArgs = [caxArgs, {'EnableLoggingFunc', []}];
end

caxArgs = [caxArgs, {'isToplevelProfile', true}];

stExtractInfo = ep_sim_harness_create(caxArgs{:});
end


%%
function stArgs = i_vararginToStruct(varargin)
stArgs = struct();
inputs = varargin{1};
nLen = numel(inputs);
for i = 1:2:nLen
    sKey   = inputs{i};
    xValue = inputs{i+1};
    try
        stArgs.(sKey) = xValue;
    catch
    end
end
end

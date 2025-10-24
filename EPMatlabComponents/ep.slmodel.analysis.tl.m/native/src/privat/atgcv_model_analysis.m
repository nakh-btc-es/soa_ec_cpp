function [stRes, stModel] = atgcv_model_analysis(stEnv, varargin)
% analysing TL(SL) model and corresponding C-code
%
% function stRes = atgcv_model_analysis(stEnv, stOpt)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)  environment structure
%     stOpt               (struct)  structure with options for model analysis
%       .sDdPath          (string)  full path to DataDictionary to be used for analysis
%       .sTlModel         (string)  name of TargetLink model to be used for analysis (assumed to be open)
%       .sSlModel         (string)  name of Simulink model corresponding to the TargetLink model (optional parameter)
%       .sTlSubsystem     (string)  name (without path) of TL toplevel Subsystem
%                                   (optional if there is just one Subsystem in the model; obligatory if there are many)
%       .bCalSupport        (bool)  TRUE if CalibrationSupport shall be activated, otherwise FALSE
%       .bDispSupport       (bool)  TRUE if DisplaySupport shall be activated, otherwise FALSE
%       .bParamSupport      (bool)  TRUE if ParameterSupport shall be activated, otherwise FALSE
%       .sDsmMode         (string)  DataStoreMode support
%                                   'all' | <'read'> | 'none'
%       .bExcludeTLSim      (bool)  TRUE if only the pure ProductionCode shall be considered
%                                   (i.e. all files from TLSim directory are excluded); default is FALSE
%       .bAddEnvironment    (bool)  consider also the Parent-Subsystem of the TL-TopLevel Subsystem; default is FALSE
%       .bIgnoreStaticCal   (bool)  if TRUE, ignore all STATIC_CAL Variables; default is FALSE
%       .bIgnoreBitfieldCal (bool)  if TRUE, ignore all CAL Variables with Type Bitfield; default is FALSE
%        ... TODO ...
%
%   OUTPUT              DESCRIPTION
%     stRes               (struct) result structure
%       .sModelAnalysis   (string) name of the generated XML file following
%                                  ModelAnalysis.dtd; placed into the result
%                                  dir: stEnv.sResultPath
%       .sAssumptions     (string) name of the generated XML file containing
%                                  the InterfaceAsssumptions derived from the
%                                  model
%       .sAddModelInfo    (string) Path to the XML file including
%                                  additional model information.
%
% **************** (deprecated: but still supported for UnitTests) *************
%
% function stRes = atgcv_model_analysis(stEnv, sDDPath, sSLModel, sTLModel, ...
%       sTLSubsystem, sCodeSymbols, sCCodePath, bCalSupport, bDispSupport)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)  Environment structure.
%     sDDPath             (string) full path to the TargetLink Data Dictionary (OSC.dd).
%     sSLModel            (string) optinal: Name of the current Simulink model, or empty string.
%     sTLModel            (string) Name of the current TargetLink model.
%     sTLSubsystem        (string) Name of the current TargetLink subsystem.
%     sCodeSymbols        (string) full path to the CodeSymbols XML file with renamed function and variable
%                                  names (CodeSymbols.dtd).
%     sCCodePath          (string) full path to the generated C Code. Information is necessary to analyse
%                                  CodeSymbols.dtd.
%     bCalSupport         (boolean) If set to 'on' calibration variables are regarded as additional inputs to
%                                   system and are included in stimuli/test vectors
%     bDispSupport        (boolean) If set to 'true' Display (DISP) variables
%                                   are regarded as additional outputs in the
%                                   interfaces of subsystems and are included in
%                                   stimuli/test vectors
%     bParamSupport       (boolean) If set to 'true' CAL variables
%                                   are regarded as additional inputs
%                                   of subsystems and are included in
%                                   stimuli/test vectors
%

%%
if (nargin < 1)
    stEnv = 0;
end
stOpt = atgcv_m01_options_get(varargin{:});


%% outputs
sFileName     = 'ModelAnalysis.xml';
sAssumpName   = 'InterfaceAssumption.xml';
stRes = struct( ...
    'sModelAnalysis', sFileName, ...
    'sAssumptions',   sAssumpName, ...
    'sAddModelInfo',  '');

if ~isstruct(stEnv) || ~isfield(stEnv, 'sResultPath')
    sResultPath = pwd();
else
    sResultPath = stEnv.sResultPath;
end
sOutputFile = fullfile(sResultPath, sFileName);
sAssumpFile = fullfile(sResultPath, sAssumpName);

try
    % analyse
    stModel = atgcv_m01_model_analyse(stEnv, stOpt);
        
    if (isfield(stOpt, 'bSkipExport') && stOpt.bSkipExport)
        return;
    end
    
    % write XML
    atgcv_m01_model_analysis_export(stEnv, stModel, sOutputFile);
    
    % add DisplayInfo
    atgcv_m01_display_info_add(sOutputFile, sOutputFile);
    
    % create Assumptions XML
    atgcv_m01_assumptions_create(stEnv, sOutputFile, sAssumpFile);
catch
    stErr = osc_lasterror();
    osc_throw(stErr);
end
end


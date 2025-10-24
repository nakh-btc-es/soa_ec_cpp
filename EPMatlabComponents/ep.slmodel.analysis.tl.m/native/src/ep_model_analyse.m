function stModel = ep_model_analyse(stOpt)
% Analyse a TL with an optional SL model or a pure SL model and export all architecture/constraint files.
%
% function ep_model_analyse(stOpt)
%
%   INPUT               DESCRIPTION
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

%% main
stModel = ep_model_info_get(stOpt);
stModel = ep_model_info_export(stOpt, stModel);
end



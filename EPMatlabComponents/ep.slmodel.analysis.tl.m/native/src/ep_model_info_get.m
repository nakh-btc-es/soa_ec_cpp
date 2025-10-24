function stModel = ep_model_info_get(stOpt)
% Analyse a TL with an optional SL model or a pure SL model and export all architecture/constraint files.
%
% function stModel = ep_model_info_get(stOpt)
%
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

%%
if isfield(stOpt, 'sModelMode') && ~strcmp(stOpt.sModelMode, 'TL')
    error('EP:INTERNAL_ASSERT:WRONG_USAGE', 'Obsolete usage: SL analysis not supported anymore by this function.');
end


%% main
% call legacy code
clear atgcv_cal_settings; % Need to be cleared, because the global preference handling has been changed.
i_set_global_settings_for_legacy_code(stOpt);
stSettings = atgcv_cal_settings;

stEnvLegacy = ep_core_legacy_env_get(stOpt.xEnv);
[stModelAna, stModel] = atgcv_model_analysis(stEnvLegacy, stOpt);
sModelAnalysis = fullfile(stEnvLegacy.sResultPath, stModelAna.sModelAnalysis);

% check for Simulink.Variant
i_check_variant_subsystems(stOpt.xEnv, stModel);

if isfield(stOpt, 'sEnvironmentFileList')
    stModel.sUserInitFunc = i_arch_add_user_init_fct_to_ma(sModelAnalysis, stOpt.sEnvironmentFileList);
else
    stModel.sUserInitFunc = '';
end

atgcv_m01_tlcheck(stEnvLegacy, sModelAnalysis);

if (isfield(stOpt, 'sSlModel') && ~isempty(stOpt.sSlModel))
    sModifiedMa = 'tmp_ma.xml';
    clear ep_sl_type_info_get;
    atgcv_m01_slcheck(stEnvLegacy, sModelAnalysis, sModifiedMa);
    stModel.astSlTypeInfos = ep_sl_type_info_get();
    EPEnvironment.moveFile(fullfile(stEnvLegacy.sResultPath, sModifiedMa), sModelAnalysis);
end

sAssumptions = fullfile(stEnvLegacy.sResultPath, stModelAna.sAssumptions);
if (isfield(stOpt, 'sAssumptions') && ~isempty(stOpt.sAssumptions))
    EPEnvironment.moveFile(sAssumptions, stOpt.sAssumptions);
end

if (isfield(stOpt, 'sModelAnalysis') && ~isempty(stOpt.sModelAnalysis))
    EPEnvironment.moveFile(sModelAnalysis, stOpt.sModelAnalysis);
end

% cleanup tempdirs of legacy component
EPEnvironment.deleteDirectory(stEnvLegacy.sOutputDirectory);
end


%%
function i_check_variant_subsystems(xEnv, stModel)
for i = 1:length(stModel.astSubsystems)
    if isfield(stModel.astSubsystems(i), 'sModelPathSl')
        sModelPath = stModel.astSubsystems(i).sModelPathSl;
    elseif isfield(stModel.astSubsystems(i), 'sModelPath')
        sModelPath = stModel.astSubsystems(i).sModelPath;
    end
    % check if parent subsystem is a variant subsystem if the current subsystem is the active one
    % (elsewise it would not be in the list)
    sParent = get_param(sModelPath, 'Parent');
    if (~isempty(sParent) ...
            && isfield(get_param(sParent, 'ObjectParameters'), 'Variant') ...
            && strcmp('on', get_param(sParent, 'Variant')) ...
            && i_has_active_variant_field(sParent))
        oModelContext = EPModelContext.get(sParent);
        
        sActiveVariant = i_get_active_variant(sParent);
            
        if isvarname(sActiveVariant)
            oActiveVariant = oModelContext.getVariable(sActiveVariant);
            if isa(oActiveVariant, 'Simulink.Variant')
                xEnv.addMessage('EP:EPSLIMP:VARIANT_SUBSYSTEM_IMPORTED', ...
                    'subsystem', sModelPath, 'condition', oActiveVariant.Condition);
            else
                xEnv.addMessage('EP:EPSLIMP:VARIANT_SUBSYSTEM_IMPORTED', ...
                    'subsystem', sModelPath, 'condition', sActiveVariant);
            end
        else
            xEnv.addMessage('EP:EPSLIMP:VARIANT_SUBSYSTEM_IMPORTED', ...
                'subsystem', sModelPath, 'condition', sActiveVariant);
        end
    end
end
end


%%
function sInitFunc = i_arch_add_user_init_fct_to_ma(sModelAnalysis, sUserFileList)
sInitFunc = '';
% Return, if no user defined file list is given.
if isempty(sUserFileList)
    return;
end

% if defined, load the user defined init function
hUserFileList = mxx_xmltree('load', sUserFileList);
ahInitFunc = mxx_xmltree('get_nodes', hUserFileList, '//cg:InitFunction');
if isempty(ahInitFunc)
    return;
end
sInitFunc = mxx_xmltree('get_attribute', ahInitFunc(1), 'name');

% change init function in ModelAnalysis
hMaDoc = mxx_xmltree('load', sModelAnalysis);
ahSubsys = mxx_xmltree('get_nodes', hMaDoc, '/ma:ModelAnalysis/ma:Subsystem');
for i = 1:length(ahSubsys)
    mxx_xmltree('set_attribute', ahSubsys(i), 'initFct', sInitFunc);
end

% clean up mxx_ xmltree handles
mxx_xmltree('save', hMaDoc, sModelAnalysis);
mxx_xmltree('clear', hMaDoc);
mxx_xmltree('clear', hUserFileList);
end


%%
function i_set_global_settings_for_legacy_code(stOpt)
stSettings = struct(...
    'ET_CAL_ignore_variable_classes', '', ...
    'ET_CAL_ignore_LUT_axis', false,...
    'ET_CAL_ignore_LUT_1D_values', false, ...
    'ET_CAL_ignore_LUT_2D_values', false, ...
    'ET_CAL_ignore_Interpolation_values', false, ...
    'ET_CAL_ignore_arrays', false, ...
    'accept_inport_type_inconsistent', false);


if isfield(stOpt, 'sIgnoreCalVariableClasses')
    stSettings.ET_CAL_ignore_variable_classes = stOpt.sIgnoreCalVariableClasses;
end

if isfield(stOpt, 'bIgnoreCalLutAxis')
    stSettings.ET_CAL_ignore_LUT_axis = stOpt.bIgnoreCalLutAxis;
end

if isfield(stOpt, 'bIgnoreCalLut1DValues')
    stSettings.ET_CAL_ignore_LUT_1D_values = stOpt.bIgnoreCalLut1DValues;
end

if isfield(stOpt, 'bIgnoreCalLut2DValues')
    stSettings.ET_CAL_ignore_LUT_2D_values = stOpt.bIgnoreCalLut2DValues;
end

if isfield(stOpt, 'bIgnoreCalInterpolationValues')
    stSettings.ET_CAL_ignore_Interpolation_values = stOpt.bIgnoreCalInterpolationValues;
end

if isfield(stOpt, 'bIgnoreCalArrays')
    stSettings.ET_CAL_ignore_arrays = stOpt.bIgnoreCalArrays;
end

if isfield(stOpt, 'bAcceptInportTypeInconsistent')
    stSettings.accept_inport_type_inconsistent = num2str(stOpt.bAcceptInportTypeInconsistent);
end
atgcv_global_property_set('SET_GLOBAL_STRUCT', stSettings);
end


%%
function bIsAvailable = i_has_active_variant_field(sParent)
if (ep_core_version_compare('ML9.6') >= 0)
    bIsAvailable = isfield(get_param(sParent, 'ObjectParameters'), 'CompiledActiveChoiceControl');
else
    bIsAvailable = isfield(get_param(sParent, 'ObjectParameters'), 'ActiveVariant');
end
end


%%
function sActiveVariant = i_get_active_variant(sParent)
if (ep_core_version_compare('ML9.6') >= 0)
    sActiveVariant = get_param(sParent, 'CompiledActiveChoiceControl');
else
    sActiveVariant = get_param(sParent, 'ActiveVariant');
end
end
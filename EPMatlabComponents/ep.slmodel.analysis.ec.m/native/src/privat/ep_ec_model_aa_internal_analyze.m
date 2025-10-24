function [bAnalysisSuccess, oEca] = ep_ec_model_aa_internal_analyze(oEca, stPreInfo)
% Doing a full analysis of the Adaptive AUTOSAR model.
%
% function [bAnalysisSuccess, oEca] = ep_ec_model_aa_internal_analyze(oEca)
%
%   INPUT                              DESCRIPTION
%    oEca                       (object)    EcaItf analysis object with some initial info about the model but without
%                                           any analysis information yet.
%    stPreInfo                  (struct)    info as returned by ep_ec_model_meta_info_get
%
%  OUTPUT                              DESCRIPTION
%    bAnalysisSuccess           (boolean)   Flag telling if analysis was successful
%    oEca                       (object)    EcaItf analysis object with full analysis info.
%


%%
oEca.bIsAdaptiveAutosar = true;
bAnalysisSuccess = true; %#ok

if (~ep_ec_aa_version_check())
    error('EP:EC:ANALYSIS_FAILED', ...
        'EP EmbeddedCoder analysis for Adaptive AUTOSAR models is not supported.');
end

if (nargin < 2)
    stPreInfo = [];
end
%
bAnalysisSuccess = i_checkMandatoryEvents(oEca);
if ~bAnalysisSuccess
    return;
end

% note: for the wrapper-mode we do not need to pre-analyze the model; we treat wrapper model as non-AUTOSAR
if ~oEca.isWrapperMode()
    stPreInfo = i_preAnalyzeForAutosar(oEca, stPreInfo);
    if ~stPreInfo.bIsValid
        for i = 1:numel(stPreInfo.casMessages)
            sMsg = stPreInfo.casMessages{i};
            oEca.addMessageEPEnv('EP:SLC:ERROR', 'msg', sMsg);
            oEca.consoleErrorPrint(sMsg);
        end
        bAnalysisSuccess = false;
        return;
    end
    if stPreInfo.bIsAutosarArchitecture
        oEca = i_extendWithAutosarInfo(oEca, stPreInfo);
    end
end

oEca.sStubCodeFolderPath = oEca.getActiveConfig().General.sStubCodeFolderPath;
oEca = oEca.generateCode();

% Note: AUTOSAR meta info gets updated during code generation --> evaluate it after generating the code
if oEca.bIsAutosarArchitecture
    oEca = i_extendWithAutosarMetaInfo(oEca);
end

oEca = oEca.analyzeMergedArchitectures();
if isempty(oEca.oRootScope)
    sMsg = '## Top level subsystem could not be retrieved! Check if the model complies with the analysis conditions.';
    oEca.addMessageEPEnv('EP:SLC:ERROR', 'msg', sMsg);
    oEca.consoleErrorPrint(sMsg);
    bAnalysisSuccess = false;
end
end


%%
function bAnalysisSuccess = i_checkMandatoryEvents(oEca)
bAnalysisSuccess = true;
if ~bdIsLoaded(oEca.sModelName)
    load_system(oEca.sModelName);
end
if i_isScheduleEditorNeeded(oEca.sModelFile)
    [~, bMissingEvents] = ep_ec_aa_wrapper_activate_event_scheduling(oEca.sModelName, false, oEca);
    if bMissingEvents
        bAnalysisSuccess = false;
    end
end
end


%%
function bRes = i_isScheduleEditorNeeded(sModelFile)
[~, sF, ~] = fileparts(sModelFile);
bRes = false;
if (strncmp(sF, 'Wrapper_', length('Wrapper_')))
    sOrigModelName = sF(length('Wrapper_')+1 : length(sF));
    casModels = ep_find_mdlrefs(sF);
    if any(strcmp(casModels, sOrigModelName))
        try
            sIntModelName = ['W_integ_', sOrigModelName];
            casEnhModel = ep_find_system([sF, '/', sIntModelName, '/', sIntModelName], 'BlockType','ModelReference');
            hEnhModel = get_param(casEnhModel{1}, 'Handle');
            if strcmp(get(hEnhModel, 'ScheduleRatesWith'), 'Schedule Editor')
                bRes = true;
            end
        catch
        end
    end
end
end


%%
function stPreInfo = i_preAnalyzeForAutosar(oEca, stPreInfo)
casValidAutosarVersions = oEca.stAutosarConfig.General.casAdaptiveAutosarVersions;
stPreInfo = i_performAdditionalChecksForValidity(stPreInfo, casValidAutosarVersions);
end


%%
function stInfo = i_performAdditionalChecksForValidity(stInfo, casValidAutosarVersions)
if (stInfo.bIsValid && stInfo.bIsAutosarArchitecture)
    if ~ismember(stInfo.sAutosarVersion, casValidAutosarVersions)
        stInfo.casMessages{end + 1} = ...
            sprintf('## The AUTOSAR version "%s" of the model is not supported.', stInfo.sAutosarVersion);
        stInfo.bIsValid = false;
    end
end
end


%%
function oEca = i_extendWithAutosarInfo(oEca, stModelInfo)
oEca.bIsAutosarArchitecture = true;
oEca.sAutosarArchitectureType = stModelInfo.sAutosarArchitectureType;

if stModelInfo.bIsWrapperContext
    oEca.sAutosarArchitectureType = 'SWC_WRAPPER';
    oEca.sAutosarModelName = stModelInfo.sAutosarModelName;
    oEca.hAutosarModel = get_param(stModelInfo.sAutosarModelName, 'handle');

    oEca.bIsWrapperComplete = stModelInfo.bIsWrapperComplete;
    oEca.sAutosarWrapperModelName = oEca.sModelName;
    oEca.sAutosarWrapperRootSubsystem = stModelInfo.sAutosarWrapperRootSubsystem;
    oEca.sAutosarWrapperRefSubsystem = stModelInfo.sAutosarWrapperRefSubsystem;
    oEca.sAutosarWrapperSchedSubsystem = stModelInfo.sAutosarWrapperSchedSubsystem;
    oEca.sAutosarWrapperVariantSubsystem = stModelInfo.sAutosarWrapperVariantSubsystem;
else
    oEca.sAutosarArchitectureType = 'SWC';
    oEca.sAutosarModelName = oEca.sModelName;
    oEca.hAutosarModel = oEca.hModel;
end
end


%%
function oEca = i_extendWithAutosarMetaInfo(oEca)
stAutosarInfo = ep_core_feval('ep_ec_autosar_meta_info_get', ...
    'Environment', oEca.EPEnv, ...
    'ModelName',   oEca.sAutosarModelName);

oEca.oAutosarProps     = stAutosarInfo.oAutosarProps;
oEca.oAutosarSLMapping = stAutosarInfo.oAutosarSLMapping;
oEca.mApp2Imp          = stAutosarInfo.mApp2Imp;
oEca.sArComponentPath  = stAutosarInfo.sArComponentPath;
oEca.sArComponentName  = stAutosarInfo.sArComponentName;
oEca.sAutosarVersion   = stAutosarInfo.sAutosarVersion;

oEca.oAutosarMetaProps = stAutosarInfo.stPorts;
oEca.aoRunnables       = stAutosarInfo.aoRunnables;
end

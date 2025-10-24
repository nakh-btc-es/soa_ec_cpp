function ep_sim_harness_sl_sil_prepare(sExtractionModelName, hSub, sOrigModelName, bEnableLogging)
% This function prepares the extraction model for the SL SIL
%
% ep_sim_harness_sl_sil_prepare(sExtractionModelName, hSub, sOrigModelName, bEnableLogging)
%
%  INPUT              DESCRIPTION
%   - sExtractionModelName    (string)  Name of the extraction model.
%   - hSub                    (handle)  Handle of the subsystem under test.
%   - sOrigModelName          (string)  Name of the original model.
%   - bEnableLogging          (boolean) True, logging has to be enabled.

sModelRefName = get_param(hSub, 'ModelName');
sLoggingOnOff = get_param(sExtractionModelName ,'SignalLogging');
sLoggingName = get_param(sExtractionModelName ,'SignalLoggingName');

%Transfer ConfigSet from original model to the extraction model
i_prepareExtractionModel(sOrigModelName, sExtractionModelName);
%Configure model block
if i_isAutosarStyle(hSub)
    i_configureModelBlk(hSub, true);
else
    i_configureModelBlk(hSub);
end

i_prepareExtractionModel(sOrigModelName, sModelRefName);
i_configureReferencedModel(sModelRefName);


%Deactivate User logging options tranfered from ConfigSet
i_cleanLoggingOptions(sExtractionModelName);
%For local signals
if bEnableLogging
    %prepare SIL logging options
    i_prepareSILlogging(sExtractionModelName);
    i_prepareSILlogging(sModelRefName);
    
    %restore Original ExtractionModel logging option
    set_param(sExtractionModelName ,'SignalLogging', sLoggingOnOff);
    set_param(sExtractionModelName,'SignalLoggingName', sLoggingName);
    set_param(sModelRefName ,'SignalLogging', sLoggingOnOff);
    set_param(sModelRefName,'SignalLoggingName', sLoggingName);
end
%Prevent code change with Rebuild option (Only if CodeInterface = Model Reference)
cfg = slsilcfg_analysis_btc();
if strcmp(cfg.General.ModelBlkCodeInterface, 'ReferencedModelCode') && cfg.General.ForceBuildReuseBtwExecution
    sStopFcnCallBackFile = [sExtractionModelName, '_closefcn.m'];
    fid = fopen(sStopFcnCallBackFile, 'w');
    fprintf(fid, 'if exist(fullfile(fileparts(get_param(bdroot, ''FileName'')),''vecs''), ''dir'') > 0\n'); %If simulation
    fprintf(fid, '  set_param(bdroot, ''UpdateModelReferenceTargets'', ''AssumeUpToDate'');\n'); %Never
    fprintf(fid, '  set_param(bdroot, ''CheckModelReferenceTargetMessage'', ''warning'');\n'); %Warning if change needed
    fprintf(fid, '  set_param(bdroot, ''UpdateModelReferenceTargets'', ''AssumeUpToDate'');\n');
    fprintf(fid, 'end\n');
    fclose(fid);
    set_param(sExtractionModelName, 'CloseFcn', [sExtractionModelName, '_closefcn;save_system(bdroot);']);
end
end


%%
function i_prepareExtractionModel(sOriginalModelName, sExtractionModelName)
%Sampletime of Extraction model
sOrigSampleTime = get_param(sExtractionModelName,'FixedStep');
% get ConfigSet of original model
oConfigObj = getActiveConfigSet(sOriginalModelName);
if isa(oConfigObj, 'Simulink.ConfigSetRef')
    oConfigObj = oConfigObj.getRefConfigSet;
end
oConfigObjCopy = oConfigObj.copy;
oConfigObjCopy.Name = 'CopiedAndAdaptedFromOriginalModel';
% set ConfigSet to extraction model
attachConfigSet(sExtractionModelName, oConfigObjCopy, true);
setActiveConfigSet(sExtractionModelName, oConfigObjCopy.Name);
% do not overwrite the extracted sample-time
set_param(sExtractionModelName,'FixedStep', sOrigSampleTime);
% Signal resolution parameter must be set to Explicit only (needed for Subsystem-To-ModelBlock conversion)
set_param(sExtractionModelName,'SignalResolutionControl', 'UseLocalSettings');
% activate build for model reference
set_param(sExtractionModelName, 'UpdateModelReferenceTargets', 'IfOutOfDateOrStructuralChange'); %If any change detected
% support long long
set_param(sExtractionModelName,'ProdLongLongMode','on');
end


%%
function i_cleanLoggingOptions(sExtractionModelName)
%Deactivate User Logging options tranfered from ConfigSet

% do not record signals in Simulink Data Inspector
set_param(sExtractionModelName,'InspectSignalLogs','off');
% do not enable live streaming in Simulink Data Inspector
set_param(sExtractionModelName,'VisualizeSimOutput','off');
% deactivate logging options
set_param(sExtractionModelName, 'SaveTime', 'off');
set_param(sExtractionModelName, 'SaveOutput', 'off');
set_param(sExtractionModelName, 'SaveState', 'off');
set_param(sExtractionModelName, 'SaveFinalState', 'off');
end


%%
function i_prepareSILlogging(sExtractionModelName)
% enable C-API Interface (Signal only)
set_param(sExtractionModelName,'RTWCAPISignals', 'on');
set_param(sExtractionModelName,'RTWCAPIParams', 'off');
set_param(sExtractionModelName,'RTWCAPIStates', 'off');
set_param(sExtractionModelName,'RTWCAPIRootIO', 'off');
% activate Floating point for C API logging
set_param(sExtractionModelName,'PurelyIntegerCode','off');
end


%%
function i_configureReferencedModel(sReferencedModelName)
% number of instances allowed to One
set_param(sReferencedModelName, 'ModelReferenceNumInstancesAllowed', 'Single');
% support long long
set_param(sReferencedModelName,'ProdLongLongMode','on');
% support portble word size
set_param(sReferencedModelName,'PortableWordSizes','on');
% verbose on
set_param(sReferencedModelName,'RTWVerbose','on');
end


%%
function i_configureModelBlk(hMdlRefBlk, bForceTopModeCode)

if nargin < 2
    bForceTopModeCode = false;
end
set(hMdlRefBlk,'SimulationMode','Software-in-the-loop (SIL)');
if bForceTopModeCode
    set(hMdlRefBlk,'CodeInterface', 'Top Model');
else
    cfg = slsilcfg_analysis_btc();
    if strcmpi(cfg.General.ModelBlkCodeInterface, 'ReferencedModelCode')
        set(hMdlRefBlk,'CodeInterface', 'Model Reference');
    else
        set(hMdlRefBlk,'CodeInterface', 'Top Model');
    end
end
end


%%
function [bFlag, hARModelRefs] = i_isAutosarStyle(sTopLevelSubsystem)
bFlag = false;
hARModelRefs = [];

[~,casModelBlks] = ep_find_mdlrefs(sTopLevelSubsystem);
casModelBlks = cellstr(casModelBlks);
for iBlk = 1:numel(casModelBlks)
    if strcmp(get_param(get_param(casModelBlks{iBlk},'ModelName'),'RTWSystemTargetFile'),'autosar.tlc')
        bFlag= true;
        hARModelRefs(end+1) = get_param(casModelBlks{iBlk},'handle');
    end
end
end
function [bAnalysisSuccess, oEca] = ep_ec_model_internal_analyze(oEca, stPreInfo)
% Doing a full analysis of the model.
%
% function [bAnalysisSuccess, oEca] = ep_ec_model_internal_analyze(oEca)
%
%   INPUT                              DESCRIPTION
%    oEca                       (object)    EcaItf analysis object with some initial info about the model but without
%                                           any analysis information yet.
%
%  OUTPUT                              DESCRIPTION
%    bAnalysisSuccess           (boolean)   Flag telling if analysis was successful
%    oEca                       (object)    EcaItf analysis object with full analysis info.
%


%%
bAnalysisSuccess = true;

if (nargin < 2)
    stPreInfo = [];
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
oEca = oEca.analyzeMergedArchitectures();
if isempty(oEca.oRootScope)
    sMsg = '## Top level subsystem could not be retrieved! Check if the model complies with the analysis conditions.';
    oEca.addMessageEPEnv('EP:SLC:ERROR', 'msg', sMsg);
    oEca.consoleErrorPrint(sMsg);
    bAnalysisSuccess = false;
else
    oEca = i_requiredStubCreate(oEca);
end
end


%%
function stPreInfo = i_preAnalyzeForAutosar(oEca, stPreInfo)
casValidAutosarVersions = oEca.stAutosarConfig.General.casAutosarVersions;
stPreInfo = i_performAdditionalChecksForValidity(stPreInfo, casValidAutosarVersions);
end


%%
function stInfo = i_performAdditionalChecksForValidity(stInfo, casValidAutosarVersions)
if (stInfo.bIsValid && stInfo.bIsAutosarArchitecture)
    if ~ismember(stInfo.sAutosarVersion, casValidAutosarVersions)
        stInfo.casMessages{end + 1} = '## The AUTOSAR version of the model is not supported.';
        stInfo.bIsValid = false;
    end
end
end


%%
function oEca = i_requiredStubCreate(oEca)
stIncludeFile = oEca.evalHook('ecahook_stub_include_files');

% RTE stubs for AUTOSAR
if oEca.bIsAutosarArchitecture
    if ~verLessThan('matlab','23.2')
        if ~any(strcmpi({oEca.oAutosarBuildInfo.Inc.Files.FileName}, 'rtwtypes.h'))...            
                && any(strcmpi({oEca.oAutosarBuildInfo.Inc.Files.FileName}, 'Platform_Types.h'))
            %create rtwtypes.h because it is needed by our stubs
            sHeaderPath = fullfile(oEca.sAutosarCodegenPath, 'rtwtypes.h');
            i_createRtwTypes(sHeaderPath);
            stIncludeFile.casFileNames = ['rtwtypes.h' stIncludeFile.casFileNames];
        else
            if any(strcmpi({oEca.oAutosarBuildInfo.Inc.Files.FileName}, 'rtwtypes.h'))
                stIncludeFile.casFileNames = ['rtwtypes.h' stIncludeFile.casFileNames];
            end
        end
    else
        stIncludeFile.casFileNames = ['rtwtypes.h' stIncludeFile.casFileNames];
    end
       
    oEca = oEca.createRteStub(stIncludeFile.casFileNames);
    if oEca.bIsAutosarMultiInstance
        oEca = oEca.createMultiInstanceAdapterLayer();
    end
else
    stIncludeFile.casFileNames = ['rtwtypes.h' stIncludeFile.casFileNames];
end

% stub missing interfaces variables definition
bCreateInterfaceStubs = oEca.stActiveConfig.General.AllowStubGeneration;
if bCreateInterfaceStubs
    oEca = oEca.createInterfacesStub(stIncludeFile.casFileNames);
end
end


%%
function oEca = i_extendWithAutosarInfo(oEca, stModelInfo)
oEca.bIsAutosarArchitecture = true;
oEca.sAutosarArchitectureType = stModelInfo.sAutosarArchitectureType;
oEca.bIsAutosarMultiInstance = stModelInfo.stAutosarStyle.bIsMultiInstance;

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

% ---- AUTOSAR meta info from the model ------
stAutosarInfo = ep_core_feval('ep_ec_autosar_meta_info_get', ...
    'Environment', oEca.EPEnv, ...
    'ModelName',   oEca.sAutosarModelName);

oEca.oAutosarProps = stAutosarInfo.oAutosarProps;
oEca.oAutosarSLMapping = stAutosarInfo.oAutosarSLMapping;
oEca.mApp2Imp = stAutosarInfo.mApp2Imp;
oEca.sArComponentPath = stAutosarInfo.sArComponentPath;
oEca.sArComponentName = stAutosarInfo.sArComponentName;
oEca.sAutosarVersion = stAutosarInfo.sAutosarVersion;

oEca.oAutosarMetaProps = stAutosarInfo.stPorts;
oEca.aoRunnables = stAutosarInfo.aoRunnables;
end

%%
function i_createRtwTypes(sHeaderPath)
fid = fopen(sHeaderPath,'w');
fprintf(fid ,'/*\n');
fprintf(fid ,'* File: rtwtypes.h\n');
fprintf(fid ,'*\n');
fprintf(fid ,'* This version of rtwtypes.h is generated for compatibility with custom\n');
fprintf(fid ,'* source code or static source files that are located under matlabroot.\n');
fprintf(fid ,'* Automatically generated code does not have to include this file.\n');
fprintf(fid ,'*/\n\n');
fprintf(fid ,'#ifndef RTWTYPES_H\n');
fprintf(fid ,'#define RTWTYPES_H\n\n');
fprintf(fid ,'#include "Platform_Types.h"\n\n');
fprintf(fid ,'typedef sint8 int8_T;\n');
fprintf(fid ,'typedef uint8 uint8_T;\n');
fprintf(fid ,'typedef sint16 int16_T;\n');
fprintf(fid ,'typedef uint16 uint16_T;\n');
fprintf(fid ,'typedef sint32 int32_T;\n');
fprintf(fid ,'typedef uint32 uint32_T;\n');
fprintf(fid ,'typedef sint64 int64_T;\n');
fprintf(fid ,'typedef uint64 uint64_T;\n');
fprintf(fid ,'typedef boolean boolean_T;\n');
fprintf(fid ,'typedef float64 real_T;\n');
fprintf(fid ,'typedef float64 real64_T;\n');
fprintf(fid ,'typedef float64 time_T;\n');
fprintf(fid ,'typedef float32 real32_T;\n');
fprintf(fid ,'typedef char char_T;\n');
fprintf(fid ,'typedef unsigned char uchar_T;\n');
fprintf(fid ,'typedef char byte_T;\n');
fprintf(fid ,'typedef sint32 int_T;\n');
fprintf(fid ,'typedef uint32 uint_T;\n');
fprintf(fid ,'typedef unsigned long ulong_T;\n\n');
fprintf(fid ,'#define MIN_int8_T ((sint8)(-128))\n');
fprintf(fid ,'#define MAX_int8_T ((sint8)(127))\n');
fprintf(fid ,'#define MAX_uint8_T ((uint8)(255U))\n');
fprintf(fid ,'#define MIN_int16_T ((sint16)(-32768))\n');
fprintf(fid ,'#define MAX_int16_T ((sint16)(32767))\n');
fprintf(fid ,'#define MAX_uint16_T ((uint16)(65535U))\n');
fprintf(fid ,'#define MIN_int32_T ((sint32)(-2147483647-1))\n');
fprintf(fid ,'#define MAX_int32_T ((sint32)(2147483647))\n');
fprintf(fid ,'#define MAX_uint32_T ((uint32)(0xFFFFFFFFU))\n');
fprintf(fid ,'#define MIN_int64_T ((sint64)(-9223372036854775807LL-1LL))\n');
fprintf(fid ,'#define MAX_int64_T ((sint64)(9223372036854775807LL))\n');
fprintf(fid ,'#define MAX_uint64_T ((uint64)(0xFFFFFFFFFFFFFFFFULL))\n\n');
fprintf(fid ,'#endif /* RTWTYPES_H */');
fclose(fid);
end
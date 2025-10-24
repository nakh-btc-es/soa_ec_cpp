classdef Utils
    methods (Static)
        function hModel = createModel(sModelName, sTag)
            i_saveAndCloseOpenModel(sModelName);
            hModel = i_createModel(sModelName);
            set_param(sModelName, 'Tag', sTag);
        end

        function oWrapperConfig = copyAndAdaptModelConfig(oOrigConfig, dSampleTime)
            oWrapperConfig = i_copyAndAdaptConfig(oOrigConfig, dSampleTime);
        end

        function saveModel(sModelName, sFile, varargin)
            i_avoidOverwrite(sFile);
            save_system(sModelName, sFile, varargin{:});
        end
    end    
end


%%
function hModel = i_createModel(sModelName)
hModel = new_system(sModelName);
Simulink.BlockDiagram.deleteContents(sModelName);
end


%%
function i_saveAndCloseOpenModel(sModelName)
bIsLoaded = ~isempty(find_system('SearchDepth', 0, 'Name', sModelName, 'Type', 'block_diagram'));
if bIsLoaded
    fprintf('\n[INFO] Saving and closing model "%s" in order to proceed".\n\n', sModelName);
    close_system(sModelName, 1);
end
end


%%
function i_avoidOverwrite(sFileToBeWritten)
if ~exist(sFileToBeWritten, 'file')
    return;
end

nTries = 0;
nMaxTries = 100;
sBakFileBase = [sFileToBeWritten, '.bak'];
sBakFile = sBakFileBase;
while exist(sBakFile, 'file')
    nTries = nTries + 1;
    if (nTries > nMaxTries)
        error('EP:WRAPPER_CREATE_FAILED', ...
            ['File "%s" cannot be created because it already exists. ', ...
            'Ranaming existing file failed because number of backup files exceeds maximum.'], ...
            sFileToBeWritten);
    end
    
    sBakFile = sprintf('%s_%.3d', sBakFileBase, nTries);
end
fprintf('\n[INFO] To avoid overwriting data, moving file "%s" to "%s".\n\n', sFileToBeWritten, sBakFile);
movefile(sFileToBeWritten, sBakFile, 'f');
end


%%
function oWrapperConfigSet = i_copyAndAdaptConfig(oOrigConfigSet, dCompiledStepSize)
oWrapperConfigSet = copy(oOrigConfigSet);

% Set FixedStep parameter to dCompiledStepSize  in case is set to auto
dSampleTime = str2double(get_param(oWrapperConfigSet, 'FixedStep'));
if (isempty(dSampleTime)  || isequal(dSampleTime, -1) || ~isfinite(dSampleTime))
    oWrapperConfigSet.set_param('FixedStep', dCompiledStepSize);
    casContentLines = { ...
        sprintf('\n[EP:WARNING]: Fundamental sample time of the original model was found to be set to ''auto''.'), ...
        sprintf('Setting it to the sample time computed in compiled mode ''CompiledSampletime'': %s.\n', num2str(dCompiledStepSize)), ...
        };
    sContent = strjoin(casContentLines, '\n');
    fprintf(sContent);
end

% rename the config set to wrapper-specific name
sWrapperConfigName = 'WrapperModelConfigSet';
set_param(oWrapperConfigSet, 'Name', sWrapperConfigName);

% target needs to be ERT instead of AUTOSAR
set_param(oWrapperConfigSet, 'SystemTargetFile', 'ert.tlc');
i_repairWrapperConfigAfterTargetSwitch(oWrapperConfigSet, oOrigConfigSet);

% checks for scheduling times would lead to wrong issues --> switch them off
set_param(oWrapperConfigSet, 'EnableRefExpFcnMdlSchedulingChecks' , 'off');

% global types/variables in orig model and wrapper can clash --> try to avoid this by sightly changing the macro
sGlobalTypeMacro = oWrapperConfigSet.getProp('CustomSymbolStrType');
oWrapperConfigSet.setProp('CustomSymbolStrType', ['w_', sGlobalTypeMacro]);
sGlobalVarMacro = oWrapperConfigSet.getProp('CustomSymbolStrGlobalVar');
oWrapperConfigSet.setProp('CustomSymbolStrGlobalVar', ['w_', sGlobalVarMacro]);
oWrapperConfigSet.setProp('CustomSymbolStrModelFcn', '$R$N');

% RTE names can be very long --> extend the max allowed length to max
oWrapperConfigSet.set_param('MaxIdLength', '256');

% TODO: not clear why this is needed?
oWrapperConfigSet.set_param('MultiTaskCondExecSysMsg',   'Error');
oWrapperConfigSet.set_param('UnderSpecifiedDataTypeMsg', 'off');
end


%%
% Restoring the replacement type settings, because they are set to default after the target switch
function i_repairWrapperConfigAfterTargetSwitch(oWrapperConfigSet, oOrigConfigSet)
casParameterSet = i_getParameterWhitelist();
for i = 1:numel(casParameterSet)
    % checking that the given parameter is available for both configs
    sParam = casParameterSet{i};
    try
        sWrapperVal = oWrapperConfigSet.getProp(sParam);
        sOrigVal = oOrigConfigSet.getProp(sParam);
    catch
        continue;
    end
    if ~isequal(sWrapperVal, sOrigVal)
        bSettingAllowed = oWrapperConfigSet.getPropEnabled(sParam);
        if(bSettingAllowed)
            oWrapperConfigSet.set_param(sParam, sOrigVal);
        end
    end
end
end


%%
function casParameterSet = i_getParameterWhitelist()
casParameterSet = { ...
    'EnableUserReplacementTypes', ...
    'ReplacementTypes', ...
    'BooleanTrueId', ...
    'BooleanFalseId', ...
    'MaxIdInt64', ...
    'MaxIdInt32', ...
    'MaxIdInt16', ...
    'MaxIdInt8', ...
    'MaxIdUint64', ...
    'MaxIdUint32', ...
    'MaxIdUint16', ...
    'MaxIdUint8', ...
    'MinIdInt64', ...
    'MinIdInt32', ...
    'MinIdInt16', ...
    'MinIdInt8'};
end

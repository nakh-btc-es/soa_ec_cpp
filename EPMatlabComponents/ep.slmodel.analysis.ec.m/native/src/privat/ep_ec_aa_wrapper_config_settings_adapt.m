function oWrapperConfigSet = ep_ec_aa_wrapper_config_settings_adapt(sWrapperModelName, sModelName, dCompiledStepSize)
oOrigConfigSet = getActiveConfigSet(sModelName);
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
oWrapperConfigSet.set_param('UnderSpecifiedDataTypeMsg', 'off');

% AA C++ code generation settings
set_param(oWrapperConfigSet, 'SimTargetLang', 'C++');
set_param(oWrapperConfigSet, 'CodeInterfacePackaging', 'Nonreusable function');
set_param(oWrapperConfigSet, 'CustomSourceCode', ['#include ' '"' sModelName '_adapter.h"']);
set_param(oWrapperConfigSet, 'CustomInitializer', 'sut_initialize();');
% set adapted config as active config of wrapper
attachConfigSet(sWrapperModelName, oWrapperConfigSet);
setActiveConfigSet(sWrapperModelName, sWrapperConfigName);
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

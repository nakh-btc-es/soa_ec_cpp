function aoParams = getModelWiseParameters(oEca, sKind, astParams, casParamBlackList)


% init arguments
aoParams = [];
if strcmp(sKind, 'PARAM')
    stDataObjCfg = oEca.stActiveConfig.ParameterDOCfg;
elseif strcmp(sKind, 'DEFINE')
    stDataObjCfg = oEca.stActiveConfig.DefineDOCfg;
else
    return;
end
stCodeFormat = oEca.stActiveCodeFormat;


% main algo:
% find and filter according to naming rule in the config analysis file
if ~isempty(stDataObjCfg.SearchGlobal.DataObjectName)
    casRegExps = unique(cellstr(stDataObjCfg.SearchGlobal.DataObjectName));
else
    casRegExps = {'.'}; %Any names
end
astParams = i_filterParametersByRegExp(astParams, casRegExps);
astParams = i_filterByBlacklist(astParams, casParamBlackList);

% filter with config analysis according to other filter parts
if oEca.bIsAutosarArchitecture
    oEca.mParamReceiverPortsToInterface = i_getParameterReceiverPortMapping(oEca.oAutosarProps, oEca.sArComponentPath);
    oEca.jDeclaredRteParams = ep_core_feval('ep_code_rte_params_get', oEca.getCodegenRteStubHeaderFiles());
end

aoParams = repmat(Eca.MetaInterface, 1, numel(astParams));
abDoSelect = false(size(aoParams));
for i = 1:numel(astParams)
    stParam = astParams(i);

    if (isempty(stParam.oObj) || ~i_isAcceptedParamClass(stParam.oObj))
        continue;
    end

    if oEca.isConfigAnalysisCompliant(stParam.oObj, stDataObjCfg)
        aoParams(i) = i_getParamItfObj(oEca, stParam, stParam.oObj, stCodeFormat, sKind);
        abDoSelect(i) = true;
    end
end
aoParams = aoParams(abDoSelect);
end


%%
function astParams = i_filterByBlacklist(astParams, casParamBlackList)
if isempty(casParamBlackList)
    return;
end

abSelect = true(size(astParams));
for i = 1:numel(astParams)
    for k = 1:numel(casParamBlackList)
        if ~isempty(regexp(astParams(i).sRawName, casParamBlackList{k}, 'match'))
            abSelect(i) = false;
            break;
        end
    end
end
astParams = astParams(abSelect);
end


%%
function bIsParamClass = i_isAcceptedParamClass(oObj)
bIsParamClass = false;

casAcceptedClasses = {'Simulink.Parameter', 'Simulink.LookupTable', 'Simulink.Breakpoint'};
for i = 1:numel(casAcceptedClasses)
    bIsParamClass = bIsParamClass || isa(oObj, casAcceptedClasses{i});
end
end


%%
function mParamReceiverPortsToInterface = i_getParameterReceiverPortMapping(arProps, sArComponentPath)
mParamReceiverPortsToInterface = containers.Map;

casParamPorts = arProps.find(sArComponentPath, 'ParameterReceiverPort', 'PathType', 'FullyQualified');
for i = 1:numel(casParamPorts)
    sParamPort = casParamPorts{i};
    mParamReceiverPortsToInterface(arProps.get(sParamPort, 'Name')) = ...
        arProps.get(sParamPort, 'Interface', 'PathType', 'FullyQualified');
end
end


%%
function oParam = i_getParamItfObj(oEca, stParam, oParamObj, stCodeFormat, sKind)
oParam = Eca.MetaInterface;
oParam.name = stParam.sRawName;
oParam.kind = sKind;
oParam.userBlocks = {stParam.astBlockInfo(:).sPath};
oParam.sParentModelName = oEca.sModelName;
oParam.stParam_ = stParam;

%Exclude parameters with Structure value (eg. defined with Bus type)
xValue = stParam.xValue;
[bIsValid, sNote] = i_checkParamValue(xValue);
if bIsValid
    if oEca.bMergedArch
        oParam = oParam.getSignalProperties(oParamObj);
        if oEca.bIsAutosarArchitecture
            oParam = oEca.analyzeAutosarCommunication(oParam, 'DATAOBJECT', oParamObj);
        end
        if oParam.bIsAutosarCom
            oParam = oParam.getCodeVariableAutosar(stCodeFormat, oParamObj);
            sParamRootVar = oParam.getCodeRootVarName();

            % Note: constant memory calibrations are not stubbed but are part of the production code
            %   --> skip them when checking for declared variables
            oComInfo = oParam.oAutosarComInfo;
            bIsConstMem = oComInfo.bIsInternalCalibrationCom && strcmp(oComInfo.sComType, 'ConstantMemory');
            if ~bIsConstMem
                if ~oEca.jDeclaredRteParams.contains(sParamRootVar)
                    oParam.bMappingValid = false;
                    oParam.casAnalysisNotes{end + 1} = ...
                        sprintf('Corresponding RTE stub variable "%s" was not found inside the code.', sParamRootVar);
                end
            end
        else
            oParam = oParam.getCodeVariable(stCodeFormat, oParamObj);
        end
    end
else
    oParam.casAnalysisNotes{end + 1} = sNote;
end
end


%%
function [bIsValid, sNote] = i_checkParamValue(xValue)
bIsValid = true;
sNote = '';

if isempty(xValue)
    bIsValid = false;
    sNote = 'Parameter value could not be evaluated correctly';
    return;
end

if isstruct(xValue)
    bIsValid = false;
    sNote = 'Parameter with structure value are not supported as test interfaces';
    return;
end

nDims = numel(size(xValue));
if (nDims > 2)
    bIsValid = false;
    sNote = sprintf('Parameter dimensions (%d-D) higher than 2D is not supported as test interfaces', nDims);
end
end


%%
function astParams = i_filterParametersByRegExp(astParams, casRegExps)
if isempty(astParams)
    return;
end

if any(strcmp(casRegExps, '.'))
    return;
end

abSelect = false(size(astParams));
for i = 1:numel(astParams)
    for k = 1:numel(casRegExps)
        sRegExp = casRegExps{k};
        abSelect(i) = abSelect(i) || ~isempty(regexp(astParams(i).sRawName, sRegExp, 'once'));
    end
end
astParams = astParams(abSelect);
end

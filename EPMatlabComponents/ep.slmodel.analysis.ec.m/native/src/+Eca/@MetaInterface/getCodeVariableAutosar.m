function oItf = getCodeVariableAutosar(oItf, stArComCfg, oDataObj)
% Adds code variable info to the provided interface object in context of AUTOSAR communication.
%


%%
% otional params
if (nargin < 3)
    oDataObj = [];
end

% try to find matching configuration --> returns oItf.bMappingValid = true if found
if ~isempty(oItf.sldatatype)
    oItf = i_findAutosarComMatchingConfig(oItf, stArComCfg);
else
    oItf.bMappingValid = false;
end

% if configuration available, use it to determine the name of the code variable
if oItf.bMappingValid
    oItf.isAccessedByFunction = true; % Rte functions
        
    [oItf.isCodeStructComponent, sStructUseCase] = i_isGeneratedAsStruct(oItf, oDataObj);
    if oItf.isCodeStructComponent
        if oItf.stArComCfg.Format.bToBeStubbed
            oItf.codeStructName = oItf.replaceMacrosAutosar(oItf.stArComCfg.Format.oStubInfo.sStubCustomVariableName);
        else
            oItf.codeStructName = oItf.replaceMacrosAutosar(oItf.stArComCfg.Format.sRteVariableName);
        end
        
        switch sStructUseCase
            case 'bus'
                oItf.codeStructComponentAccess = oItf.getMetaBus().codeVariableAccess;

            case 'lut'
                oItf.codeStructComponentAccess = ['.', oDataObj.Table.FieldName];
                
            otherwise
                error('INTERNAL:ERROR', 'Unknown struct use case: "%s".', sStructUseCase);
        end
        
    else
        if oItf.stArComCfg.Format.bToBeStubbed
            oItf.codeVariableName = oItf.replaceMacrosAutosar(oItf.stArComCfg.Format.oStubInfo.sStubCustomVariableName);
        else
            oItf.codeVariableName = oItf.replaceMacrosAutosar(oItf.stArComCfg.Format.sRteVariableName);
        end
    end
end
end


%%
function [bIsStruct, sStructUseCase] = i_isGeneratedAsStruct(oItf, oObj)
bIsStruct = i_isBusElement(oItf);
if bIsStruct
    sStructUseCase = 'bus';
    return;
end

bIsStruct = i_isNonRefLUT(oObj);
if bIsStruct
    sStructUseCase = 'lut';
    return;
end

bIsStruct = false;
sStructUseCase = '';
end


%%
function bIsBusElem = i_isBusElement(oItf)
bIsBusElem = oItf.isBusElement && oItf.getMetaBus().iBusObjElement;
end


%%
function bIsNonRefLUT = i_isNonRefLUT(oObj)
bIsNonRefLUT = false;

if (isempty(oObj) || ~isa(oObj, 'Simulink.LookupTable'))
    return;
end

bIsNonRefLUT = ~strcmp(oObj.BreakpointsSpecification, 'Reference');
end


%%
function oItf = i_findAutosarComMatchingConfig(oItf, cfgArCodeFormat)
if oItf.isBusElement && oItf.metaBus.bFirstElmtMappingValid
    %Bus element
    oItf.bMappingValid = true;
    oItf.stArComCfg = oItf.metaBus.stFirstElmtArComCfg;
    oItf.oAutosarComInfo.sRteApiName = oItf.stArComCfg.Format.sRteApiName;
    oItf.oAutosarComInfo.sRteApiReference = oItf.stArComCfg.Format.sRteApiReference;
else
    oArComInfo = oItf.oAutosarComInfo;
    bMappingValid = false;
    if (~isempty(oArComInfo))
        for iCfg = 1:numel(cfgArCodeFormat.ArCom)
            if (i_isMatchingAutosarVersionForModelAndConfig(oArComInfo.sAutosarVersion, ...
                    cfgArCodeFormat.ArCom(iCfg).Filter.RestrictedArVersion))
                if ~isempty(cfgArCodeFormat.ArCom(iCfg).Filter.bAdditionalCondEval)
                    bAdditionalCondition = eval(cfgArCodeFormat.ArCom(iCfg).Filter.bAdditionalCondEval);
                else
                    bAdditionalCondition = true;
                end
                if bAdditionalCondition
                    if (oArComInfo.bIsInterfaceCom == true)
                        %%Sender Receiver, Client Server, Mode Switch, CalPrm
                        if strcmpi(cfgArCodeFormat.ArCom(iCfg).Filter.sComType, 'Interface') && ...
                                ismember(oArComInfo.sInterfaceType, cellstr(cfgArCodeFormat.ArCom(iCfg).Filter.sInterfaceType)) &&...
                                ismember(oArComInfo.sPortType, cellstr(cfgArCodeFormat.ArCom(iCfg).Filter.sPortType)) &&...
                                strcmpi(cfgArCodeFormat.ArCom(iCfg).Filter.sAccessMode,oArComInfo.sAccessMode)
                            stRetainedFormatCfg = cfgArCodeFormat.ArCom(iCfg);
                            bMappingValid = true;
                            break;
                        end
                        %InterRunnableVariable, InternalCalibration, PerInstanceMemory
                    elseif ~strcmpi(cfgArCodeFormat.ArCom(iCfg).Filter.sComType, 'Interface') && ...
                            strcmpi(cfgArCodeFormat.ArCom(iCfg).Filter.sComType, oArComInfo.sComType)
                        
                        if strcmp(oArComInfo.sComType,'InterRunnableVariable')
                            %InterRunnableVariable
                            if strcmpi(cfgArCodeFormat.ArCom(iCfg).Filter.sAccessMode, oArComInfo.sAccessMode) && ...
                                    strcmpi(cfgArCodeFormat.ArCom(iCfg).Filter.sItfKind, oItf.kind)
                                stRetainedFormatCfg = cfgArCodeFormat.ArCom(iCfg);
                                bMappingValid = true;
                                break;
                            end
                        else
                            %InternalCalibration, PerInstanceMemory
                            stRetainedFormatCfg = cfgArCodeFormat.ArCom(iCfg);
                            bMappingValid = true;
                            break;
                        end
                    end
                end
            end
        end
    end
    if bMappingValid
        oItf.bMappingValid = bMappingValid;
        oItf.stArComCfg = stRetainedFormatCfg;
        oItf.oAutosarComInfo.sRteApiName = oItf.stArComCfg.Format.sRteApiName;
        oItf.oAutosarComInfo.sRteApiReference = oItf.stArComCfg.Format.sRteApiReference;
    else
        oItf.casAnalysisNotes{end+1} = ['Autosar communication interface ', oItf.name, ' is not supported.'];
    end
end
end


%%
function bMatch = i_isMatchingAutosarVersionForModelAndConfig(sModelArVersion, sCfgArVersion)
if isempty(sCfgArVersion)
    bMatch = true;
else
    bMatch = ismember(sModelArVersion, cellstr(sCfgArVersion));
end
end
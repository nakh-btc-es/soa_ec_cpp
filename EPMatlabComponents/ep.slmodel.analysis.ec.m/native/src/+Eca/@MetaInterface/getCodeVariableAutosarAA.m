function oItf = getCodeVariableAutosarAA(oItf)
% Adds code variable info to the provided interface object in context of AUTOSAR communication.
%


%%
if ~isempty(oItf.sldatatype)
    oItf.bMappingValid = true;
else
    oItf.bMappingValid = false;
end

% define here the name of the code variable to be created later by the AA stub code generator
if oItf.bMappingValid
    oItf.isAccessedByFunction = false; % AUTOSAR communication; however EC Analysis will not produce any stubs for that
        
    oItf.isCodeStructComponent = i_isGeneratedAsStruct(oItf);
    if oItf.isCodeStructComponent
        oItf.codeStructName = i_getStubVariableNameForInterface(oItf);
        oItf.codeStructComponentAccess = oItf.getMetaBus().codeVariableAccess;
        
    else
        oItf.codeVariableName = i_getStubVariableNameForInterface(oItf);
    end
end
end


%%
function bIsStruct = i_isGeneratedAsStruct(oItf)
bIsStruct = i_isBusElement(oItf);
end


%%
function bIsBusElem = i_isBusElement(oItf)
bIsBusElem = oItf.isBusElement && oItf.getMetaBus().iBusObjElement;
end


%%
function sStubVariableName = i_getStubVariableNameForInterface(oItf)
oCom = oItf.oAutosarComInfo;
sStubVariableName = Eca.aa.CodeSymbols.getEventVariable(oCom.sInterfaceName, oCom.sPortName, oCom.sMappedEventName);
end

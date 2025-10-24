classdef MetaAutosarCom
    properties
        sComponentName = '';
        sRunnableName = '';
        sRunnableSymbol = '';
        sAutosarVersion = '';
        sRteApiName = '';
        sRteApiReference = '';
        sImplDatatype = '';
        sComType = ''; %InterRunnableVariable, InternalCalibration, PerInstanceMemory
        
        bIsModeSwitchInterfaceCom = false;
        bIsInternalCalibrationCom = false;
        bIsClientServerInterfaceCom = false;
        bIsInterfaceCom = false;
        bIsSenderReceiverInterfaceCom = false;
        bIsCalPrmInterfaceCom = false;
        bIsNvDataInterfaceCom = false;
        bIsIRVCom = false;
        bIsPIMCom = false; %Per Instance memory
        
        sInterfaceType = ''; %Apply to: S-R, CalPrm, NvData, MS
        sPortType = '';      %Apply to: S-R, CalPrm, NvData, MS
        sAccessMode = ''; 	 %Apply to: S-R, IRV
        sPortName = '';      %Apply to: S-R, CalPrm, NvData
        sItfName = '';       %Apply to: S-R, CalPrm, NvData
        sDataElementName = '';  %Apply to: S-R, CalPrm, NvData
        sOpArgName = '';        %Apply to: C-S
        sDataName = '';         %Apply to: Internal Cal, IRV
        sPerInstanceParam = true; %Apply to: Internal Cal (false -> SharedParameter)
        bPimAccessNVRam = false;  %Apply to: PIM
        sPimIsComplexType = false;
        sModeGroup = ''; % Apply to: SwitchMode
        
        bValidCom = false;
    end
end
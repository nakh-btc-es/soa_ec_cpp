classdef MetaFunArg      
    properties
        sKind = ''; %'input', 'output' or 'return'
        sArgName = '';
        sDataType = ''; 
        bIsPointer = false;
        sQualiferScalar = '';
        sQualiferArray = '';
        bArrayPointerNotation = false;
        bUseArrayDataType = false;
        sPointerDimensions = '';
        bMapToStubVar = false; %Eca.MetaFunArg
    end
end
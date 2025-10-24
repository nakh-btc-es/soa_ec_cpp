classdef MetaStubIntefaceInfo
    
    properties
    
        sStubType = ''; % 'Variable', 'Define', 'Function', 'VarInit';
        sVariableDatatype = '';
        
        %% Variable stub info
        bIsStructComponent = false;
        sVariableStructName = ''; %applies if isStructComponent
        sVariableStructComponentName = '';%applies if isStructComponent
        sVariableName = '';
        
        %% Define stub info
        sDefineName = '';
        sDefineValue = '';

        %% VarInit info
        bIsExplicitLUT = false;
        stInitInfo = [];

        %% Function stub info
        sStubFuncType = ''; %'SimulinkGetSet' or 'Custom'
        
        %- SimulinkGetSet -
        %get access stub format
        sStubSLGetFunName = '';
        %set access stub format
        sStubSLSetFunName = '';
        sStubSLGetSetVariableName = '';
        
        %- Custom -
        bStubVariable = false;
        sStubCustomVariableName = '';
        %get access stub fomart
        sStubCustomGetFunName = '';
        sStubCustomSetFunName = '';
        %Function arguments
        aoStubCustomGetFunArgs = []; %Array of objects Eca.MetaFunArg
        aoStubCustomSetFunArgs = []; %Array of objects Eca.MetaFunArg
        
        nVarDimensions = [];
        b2DMatlabIs1DCode = false; %generated as Malab Column-Major format
        s2DMatlabIs1DCodeConv = '';
        s2DMatlabTo2DCodeConv = '';
        bIsScalar = true;
        nDimAsRowCol = [];
        bIsArray1D = false;
        bForceScalarVarAccessAsPointer = false;
    end
    
    methods
        %%
        function sDecl = getDeclaration(oObj)
            [sDef, bIsValid] = i_getDefinition(oObj);
            if bIsValid
                sDecl = sprintf('extern %s', sDef); % just prepend the "extern" key-word
            else
                sDecl = '';
            end
        end
        
        %%
        function sDef = getDefinition(oObj)
            sDef = i_getDefinition(oObj);
        end
        
        %%
        function sType = getDataType(oObj)
            sType = oObj.sVariableDatatype;
        end
        
        %%
        function casAssigns = getInitAssignments(oObj)
            casAssigns = i_getInitAssignments(oObj);
        end
    end    
end


%%
function casAssigns = i_getInitAssignments(oStubInfo)
casAssigns = {};

if isempty(oStubInfo.stInitInfo)
    return;
end
mValues = oStubInfo.stInitInfo.mValues;
if isempty(mValues)
    return;
end

casAccess = {};
casValues = {};

casFields = mValues.keys();
for i = 1:numel(casFields)
    stValInfo = mValues(casFields{i});
    
    [casSubAccess, casSubValues] = i_splitAndEvalValues(stValInfo, oStubInfo);
    casAccess = [casAccess, casSubAccess]; %#ok<AGROW>
    casValues = [casValues, casSubValues]; %#ok<AGROW>
end

nAssigns = numel(casAccess);
casAssigns = cell(1, nAssigns);
for i = 1:nAssigns
    casAssigns{i} = sprintf('%s%s = %s;', oStubInfo.sVariableName, casAccess{i}, casValues{i});
end
end


%%
function [casAccess, casValues] = i_splitAndEvalValues(stValInfo, oStubInfo)
nVals = numel(stValInfo.xValues);
casAccess = cell(1, nVals);
casValues = cell(1, nVals);

if ((nVals < 0) || isempty(stValInfo.stTypeInfo))
    return;
end

if (nVals < 2)
    casAccess{1} = i_getFieldAccess(stValInfo.sAccess);
    casValues{1} = i_getValueAsString(stValInfo.xValues(1), stValInfo.stTypeInfo);
else
    for i = 1:nVals
        casAccess{i} = i_getFieldAccess(stValInfo.sAccess, i);
        casValues{i} = i_getValueAsString(stValInfo.xValues(i), stValInfo.stTypeInfo);
    end
end
end


%%
function sFieldAccess = i_getFieldAccess(sAccess, iIndex)
if isempty(sAccess)
    sFieldAccess = '';
else
    sFieldAccess = ['.', sAccess];
end
if (nargin > 1)
    sFieldAccess = sprintf('%s[%d]', sFieldAccess, iIndex - 1);
end
end


%%
function sVal = i_getValueAsString(xVal, stTypeInfo)
if isfi(xVal)    
    xVal = int(xVal);
else
    xVal = round((xVal - stTypeInfo.dOffset)/stTypeInfo.dLsb);
end
sVal = sprintf('%g', xVal);
end


%%
function sVarName = i_getVariableName(oStubInfo)
if any(strcmp(oStubInfo.sStubType, {'variable', 'varinit'}))
    sVarName = oStubInfo.sVariableName;
else
    if strcmp(oStubInfo.sStubFuncType, 'SimulinkGetSet')
         sVarName = oStubInfo.sStubSLGetSetVariableName;
    else
         sVarName = oStubInfo.sStubCustomVariableName;
    end
end
end


%%
function sDimPostfix = i_getDimPostfix(oStubInfo)
if oStubInfo.bIsScalar
    sDimPostfix = '';

else
    aiDims = oStubInfo.nDimAsRowCol;
    if oStubInfo.bIsArray1D
        sDimPostfix = sprintf('[%d]', aiDims(2));
        
    else
        if oStubInfo.b2DMatlabIs1DCode
            sDimPostfix = sprintf('[%d]', prod(aiDims));
            
        else
            s2DMatlabTo2DCodeConv = oStubInfo.s2DMatlabTo2DCodeConv;
            if strcmpi(s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                sDimPostfix = sprintf('[%d][%d]', aiDims(1), aiDims(2));
                
            elseif strcmpi(s2DMatlabTo2DCodeConv, 'M_RowCol_C_ColRow')
                sDimPostfix = sprintf('[%d][%d]', aiDims(2), aiDims(1));
                
            else
                sDimPostfix = sprintf('[%d]', prod(aiDims));
            end
        end
    end
end
end


%%
function [sDefinition, bIsValid] = i_getDefinition(oStubInfo)
sDefinition = '';
bIsValid = false;

if ~oStubInfo.bIsStructComponent
    sVariableName = i_getVariableName(oStubInfo);
    if ~isempty(sVariableName)
        sPostfix = i_getDimPostfix(oStubInfo);
        sDefinition = sprintf('%s %s%s;', oStubInfo.getDataType(), sVariableName, sPostfix);
        bIsValid = true;
    end
else
    sVariableStructComponentName = oStubInfo.sVariableStructComponentName;
    sVariableStructName = oStubInfo.sVariableStructName;
    sDefinition = sprintf('//Stub of structure variables is not supported yet: %s.%s', ...
        sVariableStructName, sVariableStructComponentName);
end
end

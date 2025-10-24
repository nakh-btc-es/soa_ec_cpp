function stCodeInfo = getCodeInfoModelRef(oEca, oScope)

stCodeInfo = oEca.getCodeInfoDefault();
if ~isempty(oScope.astCodegenSourcesFiles)
    casSrcFiles = {oScope.astCodegenSourcesFiles(:).path};
else
    casSrcFiles = {};
end

% slprj/target/model
% slprj/target/model/referenced_model_includes

% get the name of the referenced model
if ~isempty(oScope.sSubSystemModelRef)
    sReferencedModelName = get_param(oScope.sSubSystemModelRef, 'ModelName');
else
    sReferencedModelName = get_param(oScope.sSubSystemFullName, 'ModelName');
end
sCFileName = [sReferencedModelName, '.c'];

for i = 1:numel(casSrcFiles)
    sFullFile = casSrcFiles{i};
    
    if contains(sFullFile, sCFileName)
        oAncestorScope = oScope.getAncestorWithCodeInfo();

        oFuncSpec = RTW.getFunctionSpecification(sReferencedModelName);
        if isa(oFuncSpec, 'RTW.ModelSpecificCPrototype')
            % model specified specific function prototype (including function arguments)
            stCodeInfo.sCFunctionName     = oFuncSpec.FunctionName;
            stCodeInfo.sInitCFunctionName = oFuncSpec.InitFunctionName;   
            stCodeInfo.bHasFuncArgs       = (oFuncSpec.getNumArgs() > 0);
        else
            stCodeInfo.sCFunctionName     = sReferencedModelName;
            if isempty(oAncestorScope)
                stCodeInfo.sInitCFunctionName = [sReferencedModelName, '_initialize'];
            else
                stCodeInfo.sInitCFunctionName = oAncestorScope.sInitCFunctionName;
            end
        end    
        stCodeInfo.sCFunctionUpdateName = i_getCFunctionUpdateName(oEca, oScope.nHandle, stCodeInfo.sCFunctionName);
        
        if ~isempty(oAncestorScope)
            stCodeInfo.sPreStepCFunctionName = oAncestorScope.sPreStepCFunctionName;
        end
        
        stCodeInfo.sCFunctionDefinitionFileName = sCFileName;
        stCodeInfo.sCFunctionDefinitionFile = sFullFile;
        
        stCodeInfo.sEPCFunctionPath = ...
            i_getStackPath(oAncestorScope, stCodeInfo.sCFunctionName, stCodeInfo.sCFunctionDefinitionFileName);
        break;
    end
end
end


%%
function sStackPath = i_getStackPath(oAncestorScope, sCFunctionName, sCFunctionDefinitionFileName)
if ~isempty(oAncestorScope)
    sStackPath = [oAncestorScope.sEPCFunctionPath, '/', [sCFunctionDefinitionFileName, ':1:', sCFunctionName]];
else
    sStackPath = [sCFunctionDefinitionFileName, ':1:', sCFunctionName];
end
end


%%
function sFuncName = i_getCFunctionUpdateName(oEca, hScope, sFuncPrefix)
hModel = bdroot(hScope);
mMap = oEca.mCombineOutputUpdate;
sSetting = mMap(hModel);
if strcmp(sSetting, 'off')
    sFuncName = [sFuncPrefix '_Update'];
else
    sFuncName = '';
end
end



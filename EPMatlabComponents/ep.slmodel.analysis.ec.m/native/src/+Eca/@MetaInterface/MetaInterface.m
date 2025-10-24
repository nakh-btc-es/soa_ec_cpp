classdef MetaInterface
    
    properties
        kind                        = ''; % PARAM, IN, OUT, LOCAL, DEFINE
        name                        = '';
        alias                       = '';
        min                         = [];
        max                         = [];
        dimension                   = [];
        
        resolution                  = [];
        offset                      = [];
        sldatatype                  = 'UNKNOWN';
        sldatatypesource            = '';
        codedatatype                = 'UNKNOWN';
        datatypeNamespace           = '';
        
        isFloatPoint                = false;
        isBoolean                   = false;
        isEnumeration               = false;
        isDsm                       = false;
        
        bIsScalar                   = false;
        bIsArray1D                  = false;
        bIsArray2D                  = false;
        nDimAsRowCol                = [];
        bMLArrayUseRowIndexOnly     = false;
        
        bIsActive                   = true; % active or part of inactive variant, commented out, etc.
        
        ioPortNumber                = []; % for Input or Output only
        
        handle                      = [];
        sourceBlockName             = '';
        sourceBlockFullName         = '';
        sourceBlockPortNumber       = ''; %For Local
        sUniqID                     = '';
        sourcePortName              = '';
        internalSourcePortHandle    = [];
        externalSourcePortHandle    = [];
        hRootIOSrcBlk               = [];
        hParentRunExtIOPort         = [];
        sourcePortHandle            = [];
        sInternLineName             = '';
        sExternLineName             = '';
        bIsRootIO                   = false;
        bParentScopeIsRunnable      = false;
        bParentScopeIsRunnableChild = false;
        bIsModelReference           = false;
        
        sVirtualPath                = '';
        
        userBlocks                  = {};
        stDsmInfo                   = [];
        
        isAccessedByVariable        = true;
        isAccessedByFunction        = false;
        isCodeStructComponent       = false;
        
        %Code representation
        codeStructName              = '';
        codeStructComponentAccess   = '';
        codeVariableName            = '';
        codeDefinitionFile          = '';
        codeHeaderFile              = '';
        
        %CodeFormat Cfg feedback
        sCodeVarCfgID               = '';
        codeFormatCfg               = [];
        %AutosarCodeFormat
        stArComCfg                  = [];
        
        oSigSL_                     = [];
        oMetaBusSig_                = []; % planned as replacement for attribute metaBusSignal   
        isBusElement                = false;
        isBusFirstElement           = false;
        metaBus                     = Eca.MetaBus;
        metaBusSignal               = [];
        
        bMappingValid               = false;
        bMappingCanceled            = false;
        bStubNeeded                 = false;
        bCFileMissing               = false;
        bHFileMissing               = false;
        
        dataClass                   = '';
        storageClass                = '';
        dataObjectSource            = ''; %Workspace or Model
        oDataObj_                   = [];

        stParam_                    = [];
        
        %For debugging
        casAnalysisNotes            = {};
        
        %Scope information
        sParentModelName            = '';
        sParentScopePath            = '';
        sParentScopeAccess          = '';
        sParentScopeModelRef        = '';
        sParentScopeDefFile         = '';
        sParentScopeFuncName        = '';
        sParentRunnableName         = '';
        sParentRunnablePath         = '';
        
        %Autosar
        bIsAutosarCom               = false;
        bIsAdaptiveAutosar          = false;
        oAutosarComInfo             = [];
    end

    methods (Static = true)
        function casCodeAttributeNames = getCodeAttributeNames()
            casCodeAttributeNames = { ...
                'alias', ...
                'codedatatype', ...
                'datatypeNamespace', ...
                'isAccessedByVariable', ...
                'isAccessedByFunction', ...
                'isCodeStructComponent', ...
                'codeStructName', ...
                'codeStructComponentAccess', ...
                'codeVariableName', ...
                'codeDefinitionFile', ...
                'codeHeaderFile', ...
                'sCodeVarCfgID', ...
                'codeFormatCfg', ...
                'stArComCfg', ...
                'bMappingValid', ...
                'bMappingCanceled', ...
                'bStubNeeded', ...
                'bCFileMissing', ...
                'bHFileMissing', ...
                'dataClass', ...
                'storageClass', ...
                'dataObjectSource', ...
                'oDataObj_', ...
                'casAnalysisNotes', ...
                'bIsAutosarCom', ...
                'bIsAdaptiveAutosar', ...
                'oAutosarComInfo'};

        end
    end
    
    methods
        %%
        function oIf = MetaInterface()
        end
        
        %%
        function bIsArrayOfBus = isArrayOfBus(oObj)
            bIsArrayOfBus = ~isempty(oObj.oMetaBusSig_) && oObj.oMetaBusSig_.isArrayOfBusSignal();
        end
        
        %%
        function bIsScalar = isScalar(oObj)
            bIsScalar = oObj.bIsScalar;
        end
        
        %%
        function aiWidth = getModelLeafWidth(oObj)
            if oObj.bIsScalar
                aiWidth = [];
            else
                aiWidth = oObj.nDimAsRowCol;
                if oObj.bMLArrayUseRowIndexOnly
                    aiWidth = prod(aiWidth);
                end
            end
        end
        
        %%
        function aiWidth = getCodeLeafWidth(oObj)
            if oObj.bIsScalar
                aiWidth = [];
            else
                aiWidth = oObj.nDimAsRowCol;
                if oObj.bIsArray1D
                    aiWidth = prod(aiWidth);
                end
            end
        end

        %%
        function sHandling = getHandling2D(oObj)
            sHandling = i_getHandling2D(oObj);
        end

        %%
        function sVarName = getCodeRootVarName(oObj)
            if oObj.isCodeStructComponent
                sVarName = oObj.codeStructName;
            else
                sVarName = oObj.codeVariableName;
            end
        end
        
        %%
        function sModelName = getBdroot(oItf)
            if oItf.isDsm
                sModelName = bdroot(oItf.stDsmInfo.sModelContext);
                
            elseif ~isempty(oItf.userBlocks)
                sModelName = bdroot(oItf.userBlocks{end});
                
            elseif ~isempty(oItf.sParentModelName)
                sModelName = oItf.sParentModelName;
                
            elseif ~isempty(oItf.sParentScopeAccess)
                sModelName = bdroot(oItf.sParentScopeAccess);
                
            else
                sModelName = bdroot();
            end
        end
        
        %%
        function xValue = evalinGlobal(oItf, sExpr)
            xValue = Simulink.data.evalinGlobal(oItf.getBdroot(), sExpr);
        end
        
        %%
        function xValue = evalinLocal(oItf, sExpr)
            oModelWorkspace = get_param(oItf.getBdroot(), 'modelworkspace');
            xValue = oModelWorkspace.evalin(sExpr);
        end
        
        %%
        function xValue = evalinGlobalLocal(oItf, sExpr)
            try
                xValue = oItf.evalinGlobal(sExpr);
            catch oEx %#ok<NASGU>
                xValue = oItf.evalinLocal(sExpr);
            end
        end
        
        %%
        function sPath = getVirtualPath(oItf)
            if isempty(oItf.sVirtualPath)
                sPath = i_replacePrefix(oItf.sourceBlockFullName, oItf.sParentScopeAccess, oItf.sParentScopePath);
            else
                sPath = oItf.sVirtualPath;
            end
        end
        
        %%
        function sAliasName = getAliasRootName(oItf)
            if ~isempty(oItf.alias)
                sAliasName = oItf.alias;
            else
                sAliasName = oItf.name;
            end
        end
        
        %%
        function sDispName = getDisplayName(oItf)
            if isempty(oItf.sourceBlockFullName)
                sDispName = oItf.name;
            else
                if ~isempty(oItf.oMetaBusSig_)
                    sDispName = [oItf.sourceBlockFullName, oItf.oMetaBusSig_.modelSignalPath];
                else
                    sDispName = [oItf.sourceBlockFullName, '.', oItf.name];
                end
            end
        end

        %%
        function sName = getName(oItf)
            if isempty(oItf.stParam_)
                sName = oItf.name;
            else
                % special handling for parameters
                sName = oItf.stParam_.sName;
            end
        end
        
        %%
        function oNewItf = replaceCodeProperties(oItf, oOtherItf)
            oNewItf = i_replaceCodeProperties(oItf, oOtherItf);
        end

        %%
        function oNextLeafItf = copyForNextBusLeafInterface(oItf)
            oNextLeafItf = Eca.MetaInterface;
            oNextLeafItf = i_transferCommonPropertiesToNextBusLeafInterface(oItf, oNextLeafItf);
        end

        %%
        function oItf = applyVariableFormat(oItf, stVarFormat, oDataObj)
            oItf = i_applyVariableFormat(oItf, stVarFormat, oDataObj);
        end
        
        %%
        function oMetaBus = getMetaBus(oItf)
            if isempty(oItf.metaBusSignal)
                oMetaBus = oItf.oMetaBusSig_;
            else
                oMetaBus = oItf.metaBusSignal; % NOTE: legacy access that should be removed
            end
        end
        
        %%
        function sDataType = getMetaBusDataType(oItf)
            if isempty(oItf.metaBusSignal)
                sDataType = oItf.oMetaBusSig_.getDataType();
            else
                sDataType = oItf.metaBusSignal.elementObject.DataType;  % NOTE: legacy access that should be removed
            end
        end
        
        %%
        function [sMin, sMax] = getMetaBusMinMax(oItf)
            if isempty(oItf.metaBusSignal)
                [sMin, sMax] = oItf.oMetaBusSig_.getMinMax();
            else
                sMin = oItf.metaBusSignal.elementObject.Min; % NOTE: legacy access that should be removed
                sMax = oItf.metaBusSignal.elementObject.Max; % NOTE: legacy access that should be removed
            end
        end
        
        %%
        function aiDim = getMetaBusDimensions(oItf)
            if isempty(oItf.metaBusSignal)
                aiDim = oItf.oMetaBusSig_.getDimension();
            else
                aiDim = oItf.metaBusSignal.elementObject.Dimensions;  % NOTE: legacy access that should be removed
            end
        end
        
    end
end


%%
function sString = i_replacePrefix(sString, sPrefix, sNewPrefix)
sString = regexprep(sString, ['^', regexptranslate('escape', sPrefix)], sNewPrefix);
end


%%
function oItf = i_applyVariableFormat(oItf, stVarFormat, oDataObj)
oItf.bMappingValid = true;

oItf.codeFormatCfg = stVarFormat;
oItf.sCodeVarCfgID = stVarFormat.cfgID;

oItf.isCodeStructComponent = stVarFormat.Format.isCodeStructComponent;
oItf.isAccessedByFunction  = stVarFormat.Format.isAccessedByFunction;
oItf.isAccessedByVariable  = not(oItf.isCodeStructComponent) && not(oItf.isAccessedByFunction);

stBusInfo = i_getBusInfo(oItf);
if stBusInfo.bTreatAsBus
    if oItf.isCodeStructComponent
        oItf.codeStructName = oItf.replaceAndEvaluateMacros(stVarFormat.Format.codeStructName, oDataObj);
        oItf.codeStructComponentAccess = ['.', stBusInfo.sCodeRootName, stBusInfo.sCodeVarAccess];
    else
        oItf.codeStructName = stBusInfo.sCodeRootName;
        oItf.codeStructComponentAccess = stBusInfo.sCodeVarAccess;
        oItf.isCodeStructComponent = true;
    end
else
    oItf.codeStructName = oItf.replaceAndEvaluateMacros(stVarFormat.Format.codeStructName, oDataObj);
    oItf.codeStructComponentAccess = strcat('.', ...
        oItf.replaceAndEvaluateMacros(stVarFormat.Format.codeStructComponentName, oDataObj));
    oItf.codeVariableName = oItf.replaceAndEvaluateMacros(stVarFormat.Format.codeVariableName, oDataObj);
    
end
oItf.sUniqID = [oItf.codeStructName, ':', oItf.codeStructComponentAccess, ':', oItf.codeVariableName];

oItf.codeDefinitionFile = oItf.replaceAndEvaluateMacros(stVarFormat.Format.codeDefinitionFile, oDataObj);
oItf.codeHeaderFile     = oItf.replaceAndEvaluateMacros(stVarFormat.Format.codeHeaderFile, oDataObj);
end


%%
function stBusInfo = i_getBusInfo(oItf)
stBusInfo = struct( ...
    'bTreatAsBus',    false, ...
    'sCodeRootName',  '', ...
    'sCodeVarAccess', '');
if ~oItf.isBusElement
    return;
end

oMetaBus = oItf.getMetaBus();
if ~oMetaBus.iBusObjElement
    return;
end

sCodeRootName = oItf.alias;
if isempty(sCodeRootName)
    sCodeRootName = oMetaBus.topBusSignalName;
end

stBusInfo.bTreatAsBus    = true;
stBusInfo.sCodeRootName  = sCodeRootName;
stBusInfo.sCodeVarAccess = oMetaBus.codeVariableAccess;
end


%%
function oItf = i_replaceCodeProperties(oItf, oOtherIf)
casCodeProps = { ...
    'isAccessedByVariable', ...
    'isAccessedByFunction', ...
    'isCodeStructComponent', ...
    'codeStructName', ...
    'codeStructComponentAccess', ...
    'codeVariableName', ...
    'codeDefinitionFile', ...
    'codeHeaderFile', ...
    'sCodeVarCfgID', ...
    'codeFormatCfg', ...
    'stArComCfg', ...
    'storageClass', ...
    'bIsAutosarCom', ...
    'oAutosarComInfo'};
for i = 1:numel(casCodeProps)
    sProp = casCodeProps{i};

    oItf.(sProp) = oOtherIf.(sProp);
end
end


%%
function oNextLeafItf = i_transferCommonPropertiesToNextBusLeafInterface(oFirstLeafItf, oNextLeafItf)
casBusCommonProps = { ...
    'kind', ...
    'handle', ...
    'sourceBlockName', ...
    'sourceBlockFullName', ...
    'sourceBlockPortNumber', ...
    'ioPortNumber', ...
    'sParentScopeDefFile', ...
    'sParentScopeFuncName', ...
    'internalSourcePortHandle', ...
    'externalSourcePortHandle', ...
    'sourcePortHandle', ...
    'sParentScopePath', ...
    'sParentScopeAccess', ...
    'metaBus', ...
    'isBusElement', ...
    'oSigSL_', ...
    'bIsAutosarCom', ...
    'bIsRootIO', ...
    'hRootIOSrcBlk', ...
    'oAutosarComInfo'};
for i = 1:numel(casBusCommonProps)
    sProp = casBusCommonProps{i};

    oNextLeafItf.(sProp) = oFirstLeafItf.(sProp);
end
end


%%
function sHandling = i_getHandling2D(oItf)
if oItf.bIsAutosarCom
    stCodeFormatCfg = oItf.stArComCfg;
else
    stCodeFormatCfg = oItf.codeFormatCfg;
end
if isempty(stCodeFormatCfg)
    sHandling = 'col-major';
else
    if stCodeFormatCfg.Format.b2DMatlabIs1DCode
        if strcmpi(stCodeFormatCfg.Format.s2DMatlabTo1DCodeConv, 'ColumnMajor')
            sHandling = 'col-major';
        else
            sHandling = 'row-major';
        end
    else
        if strcmpi(stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
            sHandling = 'keep';

        elseif strcmpi(stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv, 'M_RowCol_C_ColRow')
            sHandling = 'transpose';

        else
            sHandling = 'row-major'; % fallback mapping: RowMajor
        end
    end
end
end

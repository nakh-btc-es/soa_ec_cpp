function  [oDataObject, oItf] = findCorrespondingDataObject(oItf)
if ~isempty(oItf.oDataObj_)
    oDataObject = oItf.oDataObj_;
    return;
end

if ~oItf.isDsm
    %Ports signal object
    oDataObject = [];
    if any(strcmp(oItf.kind, {'IN', 'OUT'}))
        oDataObject = i_getSignalObjectFromPortBlock(oItf);
    end
    if isempty(oDataObject)
        oDataObject = i_findObjectInBaseWorkspaceOrSLDD(oItf); %Try to find in WS or SLDD
    end
    if isempty(oDataObject)
        oDataObject = i_findSigObjAsEmbdSigObj(oItf); %Try to find as Embedded Signal Object
    end
else
    bIsLocalDsm = ~isempty(oItf.stDsmInfo.sPath);
    if bIsLocalDsm
        if strcmp(get_param(oItf.stDsmInfo.sPath, 'StateMustResolveToSignalObject'), 'on')
            oDataObject = i_findObjectInBaseWorkspaceOrSLDD(oItf);
        else
            oDataObject = i_findSigObjAsEmbdSigObj(oItf);
        end
    else
        oDataObject = i_findObjectInBaseWorkspaceOrSLDD(oItf);
    end
end
oItf.oDataObj_ = oDataObject;
end


%%
function oDataObject = i_getSignalObjectFromPortBlock(oItf)
switch get(oItf.handle, 'BlockType')
    case 'Inport'
        hPort = oItf.sourcePortHandle;
        oDataObject = get_param(hPort, 'SignalObject');

    case 'Outport'
        hBlock = oItf.handle;
        oDataObject = get_param(hBlock, 'SignalObject');

    otherwise
        oDataObject = [];
end
end


%%
function oDataObject = i_findObjectInBaseWorkspaceOrSLDD(oItf)
oDataObject = [];

if (oItf.isBusElement && oItf.getMetaBus().iBusObjElement)
    sSignalName = oItf.getMetaBus().topBusSignalName;
    if strcmp(sSignalName, 'EMPTY')
        sSignalName = '';
    end
else
    sSignalName = oItf.name;
end

if ~isempty(sSignalName)
    try
        bIsParam = strcmp(oItf.kind, 'PARAM');
        if bIsParam
            oDataObject = oItf.evalinGlobalLocal(sSignalName);
        else
            oDataObject = oItf.evalinGlobal(sSignalName);
        end

        % accept Signal and Parameter objects and reject everything else
        if (isa(oDataObject, 'Simulink.Signal') || isa(oDataObject, 'Simulink.Parameter'))
            oItf.dataObjectSource = 'WorkspaceOrSLDD';
        else
            oDataObject = [];
            oItf.dataObjectSource = 'Unknown';
            oItf.casAnalysisNotes{end + 1} = ...
                'A workspace variable has the same name as the signal name but is not a Signal or Parameter Object.';
        end

    catch oEx
        oDataObject = [];
        oItf.dataObjectSource = 'Unknown';
        oItf.casAnalysisNotes{end + 1} = ...
            sprintf('Error when evaluating the Data object for the interface "%s": %s', oItf.name, oEx.message);
        return;
    end
else
    oItf.dataObjectSource = 'Unknown';
    oItf.casAnalysisNotes{end + 1} = sprintf('Missing a Data object for the interface "%s".', oItf.name);
end
end


%%
function oDataObject = i_findSigObjAsEmbdSigObj(oItf)
if ~oItf.isDsm
    oCache = Eca.EmbeddedSignalsCache.getInstance;
    oSigsInModel = oCache.getSignalsInModel(oItf.getBdroot());

    if (oItf.isBusElement && oItf.getMetaBus().iBusObjElement)
        [oDataObjectTmp, sSourceBlock] = oSigsInModel.getByName(oItf.getMetaBus().topBusSignalName);

    else
        [oDataObjectTmp, sSourceBlock] = oSigsInModel.getByRtwIdentifier(oItf.getAliasRootName());
        if isempty(oDataObjectTmp)
            [oDataObjectTmp, sSourceBlock] = oSigsInModel.getByName(oItf.name);
        end        
    end    
    if ~isempty(oDataObjectTmp)
        oItf.dataObjectSource = [sSourceBlock, '(Embedded Signal Object)'];
    end

else
    oDataObjectTmp = get_param(oItf.stDsmInfo.sPath, 'StateSignalObject');
    if ~isempty(oDataObjectTmp)
        oItf.dataObjectSource = [oItf.stDsmInfo.sPath, '(Embedded Signal Object)'];
    end
end
oDataObject = oDataObjectTmp;
end

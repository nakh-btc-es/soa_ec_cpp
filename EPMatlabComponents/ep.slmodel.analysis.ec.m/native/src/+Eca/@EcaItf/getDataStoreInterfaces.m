function aoItfs = getDataStoreInterfaces(oEca, oScope, sKind)
aoItfs = [];

astDsm = oEca.stDataStores;
sParentScopePath = oScope.sSubSystemFullName;
if isempty(astDsm)
    return;
end

hIsPathInScopeContextFunc = oScope.getContextMatcherForScope();
for i = 1:numel(astDsm)
    stDsm = astDsm(i);
    if ~stDsm.stSignalInfo.bIsSupported
        continue;
    end
    
    [hAcceptedAccessBlock, iIdxBlock] = i_findAcceptedAccessBlock( ...
        stDsm, hIsPathInScopeContextFunc, sKind, oEca.bDSReadWriteObservable);
    if ~isempty(hAcceptedAccessBlock)
        stUsingBlock = stDsm.astUsingBlocks(iIdxBlock);
        
        %Properties
        oItf = Eca.MetaInterface;
        oItf.name                     = stDsm.sName;
        oItf.kind                     = sKind;
        oItf.alias                    = i_getNameAlias(stDsm.oStateSig);
        oItf.handle                   = hAcceptedAccessBlock;
        oItf.sourceBlockName          = get_param(oItf.handle, 'Name');
        oItf.sourceBlockFullName      = getfullname(oItf.handle);
        oItf.sourceBlockPortNumber    = 1;
        oItf.sParentScopeDefFile      = oScope.sCFunctionDefinitionFileName;
        oItf.sParentScopeFuncName     = oScope.sCFunctionName;
        oItf.sParentScopePath         = sParentScopePath;
        oItf.sParentScopeAccess       = oScope.sSubSystemAccess;
        oItf.sParentScopeModelRef     = oScope.sSubSystemModelRef;
        oItf.sourcePortHandle         = i_getPortHdl(oItf.handle, sKind);
        oItf.isBusElement             = false;
        oItf.isDsm                    = true;
        oItf.stDsmInfo                = stDsm;
        oItf.sVirtualPath             = stUsingBlock.sVirtualPath;
        
        [oItf, aoBusSigs] = analyzeBusForDataStore(oItf);
                
        if oEca.bIsAutosarArchitecture
            oDataObject = stDsm.oStateSig;
            if ~isempty(oDataObject)
                oItf = oEca.analyzeAutosarCommunication(oItf, 'DATAOBJECT', oDataObject);
            end
        end
        
        stCodeFormat = [];
        if oEca.bMergedArch
            stCodeFormat = oEca.stActiveCodeFormat;
        end
        aoPartItfs = ep_core_feval('ep_ec_interface_create', oItf, aoBusSigs, stCodeFormat);
        
        aoItfs = [aoItfs, aoPartItfs];             %#ok<AGROW>
    end
end
end


%%
function sAlias = i_getNameAlias(oDataObject)
sAlias = '';
try %#ok<TRYNC>
    sAlias = oDataObject.CoderInfo.Alias;
end
end


%%
function [hAcceptedAccessBlock, iIdxBlock] = i_findAcceptedAccessBlock(stDsm, hIsPathInScopeContextFunc, sKind, bDSReadWriteObservable)
hAcceptedAccessBlock = [];
iIdxBlock = -1;

bMemBlkInsideScope = ~isempty(stDsm.sPath) && feval(hIsPathInScopeContextFunc, stDsm.sVirtualPath) ; %Is Local DS and is in SUT
if ~bMemBlkInsideScope
    [sReaderBlock, iIdxReader] = i_getAccessorBlkInsideScope(stDsm, hIsPathInScopeContextFunc, 'IN');
    [sWriterBlock, iIdxWriter] = i_getAccessorBlkInsideScope(stDsm, hIsPathInScopeContextFunc, 'OUT');
    
    switch sKind
        case 'IN'
            if (~isempty(sReaderBlock) && isempty(sWriterBlock))
                hAcceptedAccessBlock = get_param(sReaderBlock, 'handle');
                iIdxBlock = iIdxReader;
            end
            
        case 'OUT'
            bValid = ~isempty(sWriterBlock);
            if bValid
                % we have found a writer; now see if we also need to check for readers
                if ~bDSReadWriteObservable
                    % case Read-Write is not accepted:
                    % DS is only accepted as output if there are only writers but no readers
                    bValid = isempty(sReaderBlock);
                end
                if bValid
                    hAcceptedAccessBlock = get_param(sWriterBlock, 'handle');
                    iIdxBlock = iIdxWriter;
                end
            end
    end
end
end


%%
function [sBlkPath, k] = i_getAccessorBlkInsideScope(stDsm, hIsPathInScopeContextFunc, sKind)
switch sKind
    case 'IN'
        sBoolKindField = 'bIsReader';
        
    case 'OUT'
        sBoolKindField = 'bIsWriter';
        
    otherwise
        error('INTERNAL:ERROR', 'Usage error.');
end

sBlkPath = '';
for k = 1:numel(stDsm.astUsingBlocks)
    stBlock = stDsm.astUsingBlocks(k);
    if (stBlock.(sBoolKindField) && feval(hIsPathInScopeContextFunc, stBlock.sVirtualPath))
        sBlkPath = stBlock.sPath;
        return;
    end
end
k = -1;
end


%%
function hPort = i_getPortHdl(hBlock, sKind)
ph = get_param(hBlock, 'PortHandles');
switch sKind
    case 'IN'
        hPort = ph.Outport(1); %  read block --> outport
    case 'OUT'
        hPort = ph.Inport(1);  % write block --> inport
end
end

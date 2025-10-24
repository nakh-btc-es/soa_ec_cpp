function aoItfs = getSignalInterfaces(oEca, oScope, sKind, bForce)
aoItfs = [];

if (nargin < 4)
    bForce = false;
end

if ~bForce
    if ((oScope.bScopeIsModel || oScope.bScopeIsModelBlock) && oScope.isExportFuncModel())
        return;
    end
    if ~oScope.isActive()
        return;
    end
end

% in force-mode we have to filter out invalid ports; otherwise this will lead to exceptions
bFilterOutInvalidPorts = bForce;

bArgsInfoAvailable = oScope.hasArgsInfo();
if bArgsInfoAvailable
    stArgsInfo = oScope.getArgsInfo();
    stArgsInfo.bIsConsistent = true;
else
    stArgsInfo = [];
end

ahIOBlocks = [];
bIsInOutBlock = false;
if strcmpi(sKind, 'IN')
    bIsInOutBlock = true;
    ahIOBlocks = i_getPortBlocks(oScope.sSubSystemAccess, 'Inport', bFilterOutInvalidPorts);
    nPorts = numel(ahIOBlocks);
    nIOPortNums = ones(1, nPorts);
    stArgsInfo.bIsConsistent = bArgsInfoAvailable && (numel(stArgsInfo.castInArgs) == nPorts);

elseif strcmpi(sKind, 'OUT')
    bIsInOutBlock = true;
    ahIOBlocks = i_getPortBlocks(oScope.sSubSystemAccess, 'Outport', bFilterOutInvalidPorts);
    nPorts = numel(ahIOBlocks);
    nIOPortNums = ones(1, nPorts);
    stArgsInfo.bIsConsistent = bArgsInfoAvailable && (numel(stArgsInfo.castOutArgs) == nPorts);

elseif strcmpi(sKind, 'LOCAL')
    [ahIOBlocks, nIOPortNums] = oEca.getLocalSignalBlocks(oScope, oEca.stActiveConfig.LocalDOCfg);
end

%Loop over all Inport and Outport blocks
if ~isempty(ahIOBlocks)
    % IO to be analyzed as AUTOSAR comunication
    bAnalyzeIOasAutosarItf = bIsInOutBlock && (oScope.bIsAutosarRunnable || ...
        (oScope.bIsAutosarRunnableChild && oEca.stActiveConfig.General.bAnalyzeLowerScopeIOAsAutosarItf));
    bAnalyzeAsAdaptiveAutosarItf = oEca.bIsAdaptiveAutosar && bIsInOutBlock && oScope.bScopeIsModel;
    stEnvLegacy = ep_core_feval('ep_core_legacy_env_get', oEca.EPEnv, true);
    aoItfs = Eca.MetaInterface;
    iItf = 0;
    for iBlk = 1:numel(ahIOBlocks)
        iItf = iItf + 1;

        hBlock = ahIOBlocks(iBlk);
        aoItfs(iItf).kind = sKind;
        aoItfs(iItf).handle = hBlock;
        sBlockName = get_param(hBlock, 'Name');
        aoItfs(iItf).sourceBlockName = sBlockName;
        aoItfs(iItf).sourceBlockFullName = getfullname(hBlock);
        aoItfs(iItf).sourceBlockPortNumber = nIOPortNums(iBlk); % For Local signals blocks

        sPortVarName = '';
        if bIsInOutBlock
            aoItfs(iItf).ioPortNumber = str2double(get(hBlock, 'Port'));
            aoItfs(iItf).bIsActive = i_isActive(hBlock);
            if oScope.hasPort2VarMapping()
                sPortVarName = oScope.mapPort2Var(sBlockName);
            end
        end
        aoItfs(iItf).sParentScopeDefFile = oScope.sCFunctionDefinitionFileName;
        aoItfs(iItf).sParentScopeFuncName = oScope.sCFunctionName;
        aoItfs(iItf).sParentRunnableName = oScope.sRunnableName;
        aoItfs(iItf).sParentScopePath = oScope.sSubSystemFullName;
        aoItfs(iItf).sParentScopeAccess = oScope.sSubSystemAccess;
        aoItfs(iItf).sParentScopeModelRef = oScope.sSubSystemModelRef;
        aoItfs(iItf).bParentScopeIsRunnableChild = oScope.bIsAutosarRunnableChild;
        aoItfs(iItf).sParentRunnablePath = oScope.sParentRunnablePath;

        %Source port handle
        aoItfs(iItf).bIsModelReference = oScope.bScopeIsModelBlock;
        aoItfs(iItf).sParentScopeModelRef = oScope.sSubSystemModelRef;
        aoItfs(iItf) = aoItfs(iItf).getSourcePortHandle(oScope.bScopeIsModelBlock);

        %Analyse if interface is part of a Bus signal and extract all bus elements information
        [aoItfs(iItf), astBusSignals, sErrMsg] = aoItfs(iItf).analyzeBus(stEnvLegacy);
        if ~isempty(sErrMsg)
            oEca.addMessageEPEnv('EP:SLC:WARNING', 'msg', sErrMsg);
            oEca.consoleWarningPrint(sErrMsg);
        end

        %Analyze wether it's autosar communication
        if bAnalyzeIOasAutosarItf
            aoItfs(iItf) = oEca.analyzeAutosarCommunication(aoItfs(iItf), 'PORT', []);
        elseif bAnalyzeAsAdaptiveAutosarItf
            aoItfs(iItf) = oEca.analyzeAutosarCommunicationAA(aoItfs(iItf));
        end

        %For Bus Interfaces, expand Intefarces objects to all Bus elements signals
        if aoItfs(iItf).isBusElement
            iFirstBusElement = iItf;
            aoItfs(iItf).isBusFirstElement = true;
            for iBusElmt = 1:numel(astBusSignals)
                if iBusElmt > 1
                    iItf = iItf + 1;
                    aoItfs(iItf) = aoItfs(iItf-1).copyForNextBusLeafInterface(); % make a copy from the previous element

                    aoItfs(iItf).metaBus.bFirstElmtMappingValid = aoItfs(iFirstBusElement).bMappingValid;
                    aoItfs(iItf).metaBus.stFirstElmtArComCfg = aoItfs(iFirstBusElement).stArComCfg;
                end
                if oEca.bMergedArch % Merged architecture use case
                    aoItfs(iItf).metaBusSignal = astBusSignals(iBusElmt);
                    aoItfs(iItf).oMetaBusSig_ = astBusSignals(iBusElmt).oMetaBusSig;
                    %Retreive signal properties and code representation
                    if aoItfs(iItf).bIsAutosarCom
                        if bAnalyzeAsAdaptiveAutosarItf
                            aoItfs(iItf) = i_analyzePropsAndCodeRepAutosarAA(aoItfs(iItf));
                        else
                            aoItfs(iItf) = i_analyzePropsAndCodeRepAutosar(aoItfs(iItf), oEca.stActiveCodeFormat);
                        end
                    else
                        aoItfs(iItf) = i_getBusSignalName(aoItfs(iItf), astBusSignals(iBusElmt).signalName);
                        if isempty(sPortVarName)
                            if bArgsInfoAvailable
                                aoItfs(iItf) = i_addCodeVariableUsingCodeDescInfo(...
                                    aoItfs(iItf), stArgsInfo, sKind, oEca.stActiveCodeFormat);
                            else
                                aoItfs(iItf) = i_analyzePropsAndCodeRep(aoItfs(iItf), oEca.stActiveCodeFormat);
                            end
                        else
                            aoItfs(iItf) = ...
                                i_addCodeVariableUsingVarName(aoItfs(iItf), sPortVarName, oEca.stActiveCodeFormat);
                        end
                    end
                end
            end
        else
            if oEca.bMergedArch
                if aoItfs(iItf).bIsAutosarCom
                    if bAnalyzeAsAdaptiveAutosarItf
                        aoItfs(iItf) = i_analyzePropsAndCodeRepAutosarAA(aoItfs(iItf));
                    else
                        aoItfs(iItf) = i_analyzePropsAndCodeRepAutosar(aoItfs(iItf), oEca.stActiveCodeFormat);
                    end
                else
                    bIsModelInterface = oScope.bScopeIsModelBlock && (any(strcmp(sKind, {'IN', 'OUT'})));
                    if isempty(sPortVarName)
                        if bArgsInfoAvailable
                            bIssueWarning = false;
                            aoItfs(iItf) = i_getSignalName(aoItfs(iItf), bIsModelInterface, bIssueWarning);
                            aoItfs(iItf) = i_addCodeVariableUsingCodeDescInfo( ...
                                aoItfs(iItf), stArgsInfo, sKind, oEca.stActiveCodeFormat);
                        else
                            aoItfs(iItf) = i_getSignalName(aoItfs(iItf), bIsModelInterface);
                            aoItfs(iItf) = i_analyzePropsAndCodeRep(aoItfs(iItf), oEca.stActiveCodeFormat);
                        end
                    else
                        bIssueWarning = false;
                        aoItfs(iItf) = i_getSignalName(aoItfs(iItf), bIsModelInterface, bIssueWarning);
                        aoItfs(iItf) = ...
                            i_addCodeVariableUsingVarName(aoItfs(iItf), sPortVarName, oEca.stActiveCodeFormat);
                    end
                end
            end
        end
    end
end
end


%%
function oItf = i_addCodeVariableUsingCodeDescInfo(oItf, stArgsInfo, sKind, stActiveCodeFormat)
if ~stArgsInfo.bIsConsistent
    oItf.casAnalysisNotes{end + 1} = ...
        'Function argument information for this interface object is inconsistent and cannot be used.';
    return;
end

if strcmp(sKind, 'IN')
    iItf = oItf.ioPortNumber;
    oItf = i_addCodeVariableUsingVarName(oItf, stArgsInfo.castInArgs{iItf}.Name, stActiveCodeFormat);

elseif  strcmp(sKind, 'OUT')
    iItf = oItf.ioPortNumber;
    oItf = i_addCodeVariableUsingVarName(oItf, stArgsInfo.castOutArgs{iItf}.Name, stActiveCodeFormat);

else
    bIssueWarning = false;
    oItf = i_analyzePropsAndCodeRep(oItf, stActiveCodeFormat, bIssueWarning);
end
end


%%
function oItf = i_addCodeVariableUsingVarName(oItf, sVarName, stActiveCodeFormat)
bIssueWarning = false;
oItf = i_analyzePropsAndCodeRep(oItf, stActiveCodeFormat, bIssueWarning);
if oItf.isBusElement
    oItf.codeStructName = sVarName;
else
    oItf.codeVariableName = sVarName;
end
oItf.bMappingValid = true;
end


%%
% get code variable name for non-Bus interfaces
function oItf = i_getSignalName(oItf, bIsModelInterface, bIssueWarning)
if (nargin < 3)
    bIssueWarning = true;
end

%a. Get name from port name (if port resolves a Signal Object or a Signal Object is specified locally)
hPort = oItf.sourcePortHandle;
stPortProps = get(hPort);
if strcmp(stPortProps.MustResolveToSignalObject, 'on') || ~isempty(stPortProps.SignalObject)
    sName = stPortProps.Name;
    if isempty(sName)
        sName = get(hPort, 'CompiledRTWSignalIdentifier');
    end
    oItf.name = sName;
else
    %b. Get name from CompiledRTWIdentifier
    hPort = i_getPortHandleForSignalIdentifier(oItf, bIsModelInterface);
    sRTWSignalIdentifier = get(hPort, 'CompiledRTWSignalIdentifier');
    if isempty(sRTWSignalIdentifier)
        oItf.name = 'UNKNOWN-SIGNAL-NAME';
        if bIssueWarning
            oItf.casAnalysisNotes{end + 1} = ...
                'Signal name cannot be retrieved from compiled RTW Identifier because it is empty.';
        end
    else
        oItf.name = sRTWSignalIdentifier;
    end
end
end


%%
function hPort = i_getPortHandleForSignalIdentifier(oItf, bIsModelInterface)
if (strcmpi(oItf.kind, 'IN') && ~isempty(oItf.externalSourcePortHandle) && ~bIsModelInterface)
    hPort = oItf.externalSourcePortHandle;
else
    if ~isempty(oItf.internalSourcePortHandle)
        hPort = oItf.internalSourcePortHandle;
    else
        hPort = oItf.externalSourcePortHandle;
    end
end
end


%%
% get code variable for Bus element interface
function oItf = i_getBusSignalName(oItf, sSignalName)
if isempty(sSignalName)
    oItf.name = 'UNKNOWN-SIGNAL-NAME';
    oItf.casAnalysisNotes{end + 1} = 'Signal name cannot be retrieved from Bus hierarchy.';
else
    oItf.name = sSignalName;
end
end


%%
function oItf = i_analyzePropsAndCodeRepAutosar(oItf, cfgCodeFormatAutosar)
oItf = oItf.getSignalProperties([]);
oItf = oItf.getCodeVariableAutosar(cfgCodeFormatAutosar);
end


%%
function oItf = i_analyzePropsAndCodeRepAutosarAA(oItf)
oItf = oItf.getSignalProperties([]);
oItf = oItf.getCodeVariableAutosarAA();
end


%%
function oItf = i_analyzePropsAndCodeRep(oItf, cfgCodeFormat, bIssueWarning)
if (nargin < 3)
    bIssueWarning = true;
end

bSearchForSignalObject = not(isempty(oItf.name) || strcmp(oItf.name, 'UNKNOWN-SIGNAL-NAME'));
if bSearchForSignalObject
    [oDataObject, oItf] = oItf.findCorrespondingDataObject();
else
    oDataObject = [];
end

oItf = oItf.getSignalProperties(oDataObject);
if ~isempty(oDataObject)
    oItf = oItf.getCodeVariable(cfgCodeFormat, oDataObject, bIssueWarning);
else
    if bSearchForSignalObject && bIssueWarning
        oItf.casAnalysisNotes{end + 1} = ...
            'Code representation cannot be extracted because no corresponding signal object can be found.';
    end
end
end


%%
function h = i_getSimulinkBlockHandle(paths)
h = cell2mat(get_param(cellstr(paths), 'handle'));
end


%%
function ahBlocks = i_getPortBlocks(sSubsystemPath, sBlockType, bFilterOutInvalidPorts)
ahBlocks = i_getSimulinkBlockHandle(ep_core_feval('ep_find_system', sSubsystemPath, ...
    'SearchDepth',    1, ...
    'FollowLinks',    'on', ...
    'LookUnderMasks', 'all', ...
    'BlockType',      sBlockType));
if ~bFilterOutInvalidPorts
    return;
end

% filter out func-call Inports or client/server ports in AA
bIsInportType = strcmp(sBlockType, 'Inport');
abSelect = true(size(ahBlocks));
for i = 1:numel(ahBlocks)
    % use try-catch because applying get_param to client/server ports will result in an exception
    if strcmp(get_param(ahBlocks(i), 'IsBusElementPort'), 'on')
        % NOTE: currently no other way to identify a client/server port!
        abSelect(i) = false;
    else
        if bIsInportType
            abSelect(i) = ~strcmp(get_param(ahBlocks(i), 'OutputFunctionCall'), 'on');
        end
    end
end
ahBlocks = ahBlocks(abSelect);
end


%%
function bIsActive = i_isActive(hBlock)
bIsActive = true; % default == active
try %#ok<TRYNC>
    bIsActive = strcmp(get_param(hBlock, 'CompiledIsActive'), 'on');
end
end

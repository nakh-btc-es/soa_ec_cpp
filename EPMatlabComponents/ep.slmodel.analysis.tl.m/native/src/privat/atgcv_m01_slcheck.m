function atgcv_m01_slcheck(stEnv, sModelAna, sAdaptedModelAna)
% check and adapt info in ModelAnalysis.xml to SL model
%
%  atgcv_m01_slcheck(stEnv, sModelAna, sAdaptedModelAna)
%
%   INPUT              DESCRIPTION
%     stEnv              (struct)      environment structure
%     sModelAna          (string)      fullpath to ModelAnalysis.xml
%     sAdaptedModelAna   (string)      name of adapted ModelAnalysis.xml
%                                      (to be stored in stEnv.sResultPath)
%
%   OUTPUT             DESCRIPTION
%
%
%   REMARKS
%       Function throws exception if info in ModelAnalysis cannot be mapped 
%       to data in SL model.
%
%   <et_copyright>

%% internal
%
%   AUTHOR(S):
%     Alex Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 209477 $
%   Last modified: $Date: 2016-03-02 15:28:56 +0100 (Mi, 02 Mrz 2016) $
%   $Author: frederikb $
%


%% read data base
i_lastError([]); % init last error as empty

hDoc = mxx_xmltree('load', sModelAna);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

astModelRefMap = i_getModelRefMap(hDoc);

% checkSet means that the function does not only check but also modify the ModelAnalysis
i_checkSetExistence(stEnv, hDoc, astModelRefMap);

stLastErr = i_lastError();
if isempty(stLastErr)
    % if we are here, we can safely assume the existence of the SL-Objects and can now checkSet their types
    i_checkSetSignalTypes(stEnv, hDoc, astModelRefMap);
    stLastErr = i_lastError();
end

if isempty(stLastErr)
    sFullPath = fullfile(stEnv.sResultPath, sAdaptedModelAna);
    mxx_xmltree('save', hDoc, sFullPath);
else
    osc_throw(stLastErr);
end
end




%%
function stErrOut = i_lastError(stErrIn)
persistent stLastError;

if (nargout > 0)
    stErrOut = stLastError;
end
if (nargin > 0)
    stLastError = stErrIn;
end
end


%%
function [bIsValid, sBlockPath] = i_checkBlock(hBlock, sExpectedBlockType, astModelRefMap)
bIsValid = false;

sBlockPath = i_getBlockRealModelPath(hBlock, 'slPath', astModelRefMap);
try
    if isempty(get_param(sBlockPath, 'Parent'))
        sBlockType = 'SubSystem'; % root-level sub
    else
        sBlockType = get_param(sBlockPath, 'BlockType');
    end
    bIsValid = strcmpi(sBlockType, sExpectedBlockType);
catch
    % path does not exist
end
end


%%
function sRealPath = i_getBlockRealModelPath(hBlockNode, sPathAttrib, astModelRefMap)
sRealPath = mxx_xmltree('get_attribute', hBlockNode, sPathAttrib);
if isempty(astModelRefMap)
    return;
end

nPath = length(sRealPath);
for i = 1:length(astModelRefMap)
    nVirtPath = length(astModelRefMap(i).sVirtualPath);
    if ((nPath >= nVirtPath) && strncmp(sRealPath, astModelRefMap(i).sVirtualPath, nVirtPath))
        sRealPath = [astModelRefMap(i).sModelPath, sRealPath(nVirtPath+1:end)];
        break;
    end
end
end


%%
function astMap = i_getModelRefMap(hDoc)
ahSubs = mxx_xmltree('get_nodes', hDoc, '//ma:Subsystem[ma:ModelReference[@kind="SL"]]');
nSubs = length(ahSubs);
astMap = repmat(struct( ...
    'sModelPath',   '', ...
    'sVirtualPath', ''), 1, nSubs);

if (nSubs > 0)
    aiPathLength = zeros(1, nSubs);
    for i = 1:length(ahSubs)
        astMap(i).sVirtualPath = mxx_xmltree('get_attribute', ahSubs(i), 'slPath');
        aiPathLength(i) = length(astMap(i).sVirtualPath);

        hModelRef = mxx_xmltree('get_nodes', ahSubs(i), './ma:ModelReference[@kind="SL"]');
        astMap(i).sModelPath = mxx_xmltree('get_attribute', hModelRef, 'path');
    end
    
    % sort according in descending order of length of the virtual path
    if (nSubs > 1)
        [aDummy, aiSortIdx] = sort(aiPathLength); %#ok aDummy not needed
        astMap = astMap(aiSortIdx(end:-1:1));
    end
end
end


%%
function i_checkSetExistence(stEnv, hDoc, astModelRefMap)
try    
    ahSubsystem = mxx_xmltree('get_nodes', hDoc, '//ma:Subsystem');
    for i = 1:length(ahSubsystem)
        hSubsystem = ahSubsystem(i);

        if i_checkBlock(hSubsystem, 'SubSystem', astModelRefMap)            
            i_checkInports(stEnv, hSubsystem, astModelRefMap);
            i_checkOutports(stEnv, hSubsystem, astModelRefMap);
            i_checkDisp(stEnv, hSubsystem, astModelRefMap);            
            i_checkCal(stEnv, hSubsystem, astModelRefMap);    
        else
            sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
            sTlPath = mxx_xmltree('get_attribute', hSubsystem, 'tlPath');
            i_lastError(osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_SUBSYSTEM_NOT_FOUND', ...
                'sl_subsys',  sSubPath, ...
                'tl_subsys',  sTlPath));
        end
    end
catch
    i_lastError(osc_lasterror());
end
end


%%
function i_checkInports(stEnv, hSubsystem, astModelRefMap)
ahPorts = mxx_xmltree('get_nodes', hSubsystem, './ma:Interface/ma:Input/ma:Port[@slPath]');
for i = 1:length(ahPorts)
    hPort = ahPorts(i);
    stRes = mxx_xmltree('get_attributes', hPort, '.', 'portNumber', 'signal');
    if ~strcmpi(stRes.portNumber, '0')
        [bIsValid, sBlockPath] = i_checkBlock(hPort, 'Inport', astModelRefMap);
        sPortPath = mxx_xmltree('get_attribute', hPort, 'slPath');
        if bIsValid
            [bIsValid, sActualPortNumber] = i_checkPortNumber(sBlockPath, stRes.portNumber);
            if ~bIsValid
                sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
                i_lastError(osc_messenger_add(stEnv, ...
                    'ATGCV:MOD_ANA:SL_INPORT_UNEXPECTED_NUM', ...
                    'block',  sPortPath, ...
                    'subsys', sSubPath, ...
                    'expectedNum', stRes.portNumber, ...
                    'actualNum', sActualPortNumber));
            end
        else
            sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
            i_lastError(osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_INPORT_NOT_FOUND', ...
                'block',  sPortPath, ...
                'subsys', sSubPath));
        end
    else
        [bBlockCheckPassed, sBlockPath] = i_checkBlock(hPort, 'DataStoreRead', astModelRefMap);
        sPortPath = mxx_xmltree('get_attribute', hPort, 'slPath');
        if ~bBlockCheckPassed
            sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
            i_lastError(osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_DSR_NOT_FOUND', ...
                'block',  sPortPath, ...
                'subsys', sSubPath));
            continue;
        end
        sDataStoreSL = get_param(sBlockPath, 'DataStoreName');
        if ~strcmp(sDataStoreSL, stRes.signal)
            sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
            i_lastError(osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_INVALID_DATA_STORE_NAME', ...
                'block',  sPortPath, ...
                'subsys', sSubPath, ...
                'signal', stRes.signal, ...
                'dataStore', sDataStoreSL));
        end
    end
    if ~strcmp(sBlockPath, sPortPath)
        i_addModelReferenceNode([], hPort, sBlockPath)
    end
end
end


%%
function [bIsValid, sPortNumber] = i_checkPortNumber(sPortBlockPath, sExpectedPortNumber)
sPortNumber = '';
if isempty(sExpectedPortNumber)
    bIsValid = true;
else
    try
        sPortNumber = get_param(sPortBlockPath, 'Port');
    catch
    end
    bIsValid = strcmp(sPortNumber, sExpectedPortNumber);
end
end


%%
function i_checkOutports(stEnv, hSubsystem, astModelRefMap)
ahPorts = mxx_xmltree('get_nodes', hSubsystem, './ma:Interface/ma:Output/ma:Port[@slPath]');
for i = 1:length(ahPorts)
    hPort = ahPorts(i);
    stRes = mxx_xmltree('get_attributes', hPort, '.', 'portNumber', 'signal');
    if ~strcmpi(stRes.portNumber, '0')
        [bIsValid, sBlockPath] = i_checkBlock(hPort, 'Outport', astModelRefMap);
        sPortPath = mxx_xmltree('get_attribute', hPort, 'slPath');
        if bIsValid
            [bIsValid, sActualPortNumber] = i_checkPortNumber(sBlockPath, stRes.portNumber);
            if ~bIsValid
                sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
                i_lastError(osc_messenger_add(stEnv, ...
                    'ATGCV:MOD_ANA:SL_OUTPORT_UNEXPECTED_NUM', ...
                    'block',  sPortPath, ...
                    'subsys', sSubPath, ...
                    'expectedNum', stRes.portNumber, ...
                    'actualNum', sActualPortNumber));
            end
        else
            sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
            i_lastError(osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_OUTPORT_NOT_FOUND', ...
                'block',  sPortPath, ...
                'subsys', sSubPath));
        end
    else
        [bBlockCheckPassed, sBlockPath] = i_checkBlock(hPort, 'DataStoreWrite', astModelRefMap);
        sPortPath = mxx_xmltree('get_attribute', hPort, 'slPath');
        if ~bBlockCheckPassed
            sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
            i_lastError(osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_DSW_NOT_FOUND', ...
                'block',  sPortPath, ...
                'subsys', sSubPath));
            continue;
        end
        sDataStoreSL = get_param(sBlockPath, 'DataStoreName');
        if ~strcmp(sDataStoreSL, stRes.signal)
            sSubPath = mxx_xmltree('get_attribute', hSubsystem, 'slPath');
            i_lastError(osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_INVALID_DATA_STORE_NAME', ...
                'block',  sPortPath, ...
                'subsys', sSubPath, ...
                'signal', stRes.signal, ...
                'dataStore', sDataStoreSL));
        end
    end
    if ~strcmp(sBlockPath,sPortPath)
        i_addModelReferenceNode([],hPort,sBlockPath)
    end
end
end


%%
function i_checkDisp(stEnv, hSubsystem, astModelRefMap)
ahDisp = mxx_xmltree('get_nodes', hSubsystem, './ma:Interface/ma:Output/ma:Display[@slBlockPath]');
for j = 1:length(ahDisp)
    hDisp = ahDisp(j);
    
    sBlockPath = i_getBlockRealModelPath(hDisp, 'slBlockPath', astModelRefMap);
    sSlBlockPath = mxx_xmltree('get_attribute', hDisp, 'slBlockPath');
    if ~strcmp(sSlBlockPath, sBlockPath)
        i_addModelReferenceNode([], hDisp ,sBlockPath)
    end
    
    sSfVar     = mxx_xmltree('get_attribute', hDisp, 'sfVariable');
    bIsStateflow = ~isempty(sSfVar);
    if bIsStateflow
        hSfRoot = sfroot;
        xData = hSfRoot.find( ...
            '-isa', 'Stateflow.Data', ...
            'Path', sBlockPath, ...
            'Name', sSfVar);
        % sometimes problems with newline --> replace with blank
        if isempty(xData)
            sBlockPath = regexprep(sBlockPath, '\n', ' ');
            xData = hSfRoot.find( ...
                '-isa', 'Stateflow.Data', ...
                'Path',  sBlockPath, ...
                'Name',  sSfVar);
        end
        if isempty(xData)
            sTlPath = mxx_xmltree('get_attribute', hSubsystem, 'tlPath');
            osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_SFDISP_NOT_FOUND', ...
                'sf_chart',  sBlockPath, ...
                'sf_var',    sSfVar, ...
                'subsys',    sTlPath);
            mxx_xmltree('del_attribute', hDisp, 'slBlockPath');
        end
    else
        try
            ep_find_system(sBlockPath);
        catch
            sTlPath = mxx_xmltree('get_attribute', hSubsystem, 'tlPath');
            osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:SL_DISP_NOT_FOUND', ...
                'block',  sBlockPath, ...
                'subsys', sTlPath);
            mxx_xmltree('del_attribute', hDisp, 'slBlockPath');
        end
    end
end
end


%%
function i_checkCal(stEnv, hSubsystem, astModelRefMap)
ahCal = mxx_xmltree('get_nodes', hSubsystem, './ma:Interface/ma:Input/ma:Calibration[@slBlockPath]');
for j = 1:length(ahCal)
    hCal = ahCal(j);
    bCalValid = true;
    
    bIsExplicit = strcmpi(mxx_xmltree('get_attribute', hCal, 'usage'), 'explicit_param');

    % different strategies for StateflowCharts and ordinary Subsystems
    ahContext = mxx_xmltree('get_nodes', hCal, './ma:ModelContext');
    nContext  = length(ahContext);
    for k = 1:nContext
        hCtx = ahContext(k);  

        sBlockPath = i_getBlockRealModelPath(hCtx, 'slPath', astModelRefMap);
        sSlPath = mxx_xmltree('get_attribute', hCtx, 'slPath');
        if ~strcmp(sSlPath,sBlockPath)
            i_addModelReferenceNode([],hCtx,sBlockPath)
            if (k == 1)
                i_addModelReferenceNode([],hCal,sBlockPath)
            end
        end
        
        sSfVar = mxx_xmltree('get_attribute', hCal, 'sfVariable');
        bIsStateflow = ~isempty(sSfVar);
        if bIsStateflow
            hSfRoot = sfroot;
            xData = hSfRoot.find( ...
                '-isa', 'Stateflow.Data', ...
                'Path', sBlockPath, ...
                'Name', sSfVar);
            % sometimes problems with newline --> replace with blank
            if isempty(xData)
                sBlockPath = regexprep(sBlockPath, '\n', ' ');
                xData = hSfRoot.find( ...
                    '-isa', 'Stateflow.Data', ...
                    'Path',  sBlockPath, ...
                    'Name',  sSfVar);
            end
            if isempty(xData)
                bCalValid = false;
                sTlPath = mxx_xmltree('get_attribute', hSubsystem, 'tlPath');
                if bIsExplicit
                    osc_messenger_add(stEnv, ...
                        'ATGCV:MOD_ANA:SL_SFEXPAR_NOT_FOUND', ...
                        'sf_chart',  sBlockPath, ...
                        'sf_var',    sSfVar, ...
                        'subsys',    sTlPath);
                else
                    i_lastError(osc_messenger_add(stEnv, ...
                        'ATGCV:MOD_ANA:SL_SFCAL_NOT_FOUND', ...
                        'sf_chart',  sBlockPath, ...
                        'sf_var',    sSfVar, ...
                        'subsys',    sTlPath));
                end
            end
        else
            try
                ep_find_system(sBlockPath);
            catch
                bCalValid = false;
                sTlPath = mxx_xmltree('get_attribute', hSubsystem, 'tlPath');
                if bIsExplicit
                    sName = mxx_xmltree('get_attribute', hCal, 'name');
                    osc_messenger_add(stEnv, ...
                        'ATGCV:MOD_ANA:SL_EXPAR_NOT_FOUND', ...
                        'block',  sBlockPath, ...
                        'param',  sName, ...
                        'subsys', sTlPath);
                else
                    i_lastError(osc_messenger_add(stEnv, ...
                        'ATGCV:MOD_ANA:SL_CAL_NOT_FOUND', ...
                        'block',  sBlockPath, ...
                        'subsys', sTlPath));
                end
            end
        end
    end
    if bCalValid
        ahIfs = mxx_xmltree('get_nodes', hCal, './ma:Variable/ma:ifName[@min|@max]');
        for n = 1:length(ahIfs)
            hIf = ahIfs(n);
            sMin = mxx_xmltree('get_attribute', hIf, 'min');
            if ~isempty(sMin)
                mxx_xmltree('set_attribute', hIf, 'slMin', sMin);
            end
            sMax = mxx_xmltree('get_attribute', hIf, 'max');
            if ~isempty(sMax)
                mxx_xmltree('set_attribute', hIf, 'slMax', sMax);
            end
        end
    end
end
end


%%
function [sTlSignal, sSlSignal] = i_getSignalDisplayNames(hIf)
stSubInfo = mxx_xmltree('get_attributes', hIf, 'ancestor::ma:Subsystem', 'tlPath', 'slPath');

if isempty(stSubInfo.tlPath)
    stSubInfo.tlPath = '<unknown>';
end
if isempty(stSubInfo.slPath)
    stSubInfo.slPath = '<unknown>';
end

astModelInfo = mxx_xmltree('get_attributes', hIf, './/ma:ModelInfo', 'relPath', 'name', 'specifier');
if ~isempty(astModelInfo)
    sTlSignal = [stSubInfo.tlPath, '/', astModelInfo(1).relPath, astModelInfo(1).name, astModelInfo(1).specifier];
    sSlSignal = [stSubInfo.slPath, '/', astModelInfo(1).relPath, astModelInfo(1).name, astModelInfo(1).specifier];
else
    sTlSignal = [stSubInfo.tlPath, '/<unknown>'];
    sSlSignal = [stSubInfo.slPath, '/<unknown>'];
end
end


%%
function i_compareSignalTypes(stEnv, hIf)
sSlSigtype = mxx_xmltree('get_attribute', hIf, 'slSignalType');
if ~isempty(sSlSigtype)
    sTlSigtype = mxx_xmltree('get_attribute', hIf, 'signalType');
    if isempty(sTlSigtype)
        sTlSigtype = 'double';
    end
    
    if ~strcmpi(sSlSigtype, sTlSigtype)
        [sTlSignal, sSlSignal] = i_getSignalDisplayNames(hIf);
        osc_messenger_add(stEnv, ...
            'ATGCV:MOD_ANA:SL_TL_SIGNALTYPE_DIFF', ...
            'sl_sig',      sSlSignal, ...
            'sl_sigtype',  sSlSigtype, ...
            'tl_sig',      sTlSignal, ...
            'tl_sigtype',  sTlSigtype);
    end
end
end


%%
% The bus signals are considered and the corresponding slSignalType is added.
function i_considerBusSubsignalTypes(stEnv, hPort, astSignals, bDoCheck)
if (nargin < 4)
    bDoCheck = true;
end

casSignalNames = {astSignals(:).sName};

ahIf = mxx_xmltree('get_nodes', hPort, './ma:Variable/ma:ifName');
for i = 1:length(ahIf)
    hIf = ahIf(i);
    
    sSigName = mxx_xmltree('get_attribute', hIf, 'signalName');
    iFound = [];
    if ~isempty(sSigName)
        iFound = find(strcmp(sSigName, casSignalNames));
        if (length(iFound) > 1)
            iFound = iFound(1);
        end
    end
    if isempty(iFound)
        % dirty heuristics: if we failed to find signal by name, use current
        % index and hope for the best (better algo would need to take different 
        % signal widths into account)
        %iFound = min(i, length(astSignals)); 
        % Heuristic with signal width.
        temp = 0;
        for j = 1:length(astSignals)
            temp = temp + astSignals(j).iWidth;
            if(i <= temp)
                iFound = j;
                break;
            end
        end
    end
    
    stSignal = astSignals(iFound);
    [sMin, sMax] = i_getSignalMinMax(stSignal);
   
    if ~isempty(stSignal.sType)
        mxx_xmltree('set_attribute', hIf, 'slSignalType', stSignal.sType);
    end
    if ~isempty(sMin)
        mxx_xmltree('set_attribute', hIf, 'slMin', sMin);
    end
    if ~isempty(sMax)
        mxx_xmltree('set_attribute', hIf, 'slMax', sMax);
    end
    
    if bDoCheck
        i_compareSignalTypes(stEnv, hIf);
    end
end
end


%%
function [sMin, sMax] = i_getSignalMinMax(stSignal)
% use the highest possible min
sMin = i_getDesignMin(stSignal);
if (isfield(stSignal, 'sMin') && ~isempty(stSignal.sMin))
    if (isempty(sMin) || (str2double(stSignal.sMin) > str2double(sMin)))
        sMin = stSignal.sMin;
    end
end

% use the lowest possible max
sMax = i_getDesignMax(stSignal);
if (isfield(stSignal, 'sMax') && ~isempty(stSignal.sMax))
    if (isempty(sMax) || (str2double(stSignal.sMax) < str2double(sMax)))
        sMax = stSignal.sMax;
    end
end
end


%%
function sMin = i_getDesignMin(stSignal)
sMin = i_getDesignData(stSignal, 'xDesignMin');
end


%%
function sMax = i_getDesignMax(stSignal)
sMax = i_getDesignData(stSignal, 'xDesignMax');
end


%%
function sValue = i_getDesignData(stSignal, sDesignDataField)
sValue = '';
if ~isfield(stSignal, sDesignDataField)
    return;
end
try
    xDesignData = stSignal.(sDesignDataField);
    if iscell(xDesignData)
        abIsEmptyElem = cellfun('isempty', xDesignData);
        if all(abIsEmptyElem)
            xDesignData = [];
        else
            xDesignData = xDesignData(~abIsEmptyElem);
            xDesignData = xDesignData{1};
        end
    end    
    if isnumeric(xDesignData)
        sValue = sprintf('%.16e', xDesignData);
    else
        warning('EP:MODEL_ANALYSIS:INTERNAL', 'Unexpected kind of Design Data found.');
    end
catch oEx
    warning('EP:MODEL_ANALYSIS:INTERNAL', 'Retrieving Design Data failed.\n%s', oEx.message);
end
end


%%
function i_considerArraySubsignalTypes(stEnv, hPort, stSignal, bDoCheck)
if (nargin < 4)
    bDoCheck = true;
end

[sMin, sMax] = i_getSignalMinMax(stSignal);
sType = stSignal.sType;

if (~isempty(sType) || ~isempty(sMin) || ~isempty(sMax))
    ahIf = mxx_xmltree('get_nodes', hPort, './ma:Variable/ma:ifName');
    for i = 1:length(ahIf)
        hIf = ahIf(i);
        
        if ~isempty(sType)
            mxx_xmltree('set_attribute', hIf, 'slSignalType', sType);
        end
        if ~isempty(sMin)
            mxx_xmltree('set_attribute', hIf, 'slMin', sMin);
        end
        if ~isempty(sMax)
            mxx_xmltree('set_attribute', hIf, 'slMax', sMax);
        end
        
        if bDoCheck
            i_compareSignalTypes(stEnv, hIf);
        end
    end
end
end


%%
function i_considerSignalTypes(stEnv, hSubsystem, stSubInfo)
ahPorts = mxx_xmltree('get_nodes', hSubsystem, './ma:Interface/ma:Input/ma:Port[@slPath]');

for i = 1:length(ahPorts)
    hPort = ahPorts(i);
    stPortInfo = stSubInfo.astInports(i);
    
    if strcmpi(stPortInfo.sSigKind, 'bus')
        i_considerBusSubsignalTypes(stEnv, hPort, stPortInfo.astSignals, true)
    else
        i_considerArraySubsignalTypes(stEnv, hPort, stPortInfo.astSignals(1), true)
    end
    
end

ahPorts = mxx_xmltree('get_nodes', hSubsystem, './ma:Interface/ma:Output/ma:Port[@slPath]');
for i = 1:length(ahPorts)
    hPort = ahPorts(i);
    stPortInfo = stSubInfo.astOutports(i);
    
    if strcmpi(stPortInfo.sSigKind, 'bus')
        i_considerBusSubsignalTypes(stEnv, hPort, stPortInfo.astSignals, true)
    else
        i_considerArraySubsignalTypes(stEnv, hPort, stPortInfo.astSignals(1), true)
    end   
end

end


%%
function i_checkSetSignalTypes(stEnv, hDoc, astModelRefMap)
try
    % loop over subsystems
    ahSubsystems = mxx_xmltree('get_nodes', hDoc, '//ma:Subsystem');
    nSub = length(ahSubsystems);
    
    casSubPaths = cell(1, nSub);
    for i = 1:nSub
        casSubPaths{i} = mxx_xmltree('get_attribute', ahSubsystems(i), 'slPath');
        astRes = mxx_xmltree('get_attributes', ahSubsystems(i), './ma:ModelReference[@kind="SL"]', 'path');
        if ~isempty(astRes)
            casSubPaths{i} = astRes.path;
        end
    end
    astDisps = i_getDisplayBlocks(hDoc, astModelRefMap);
    if isempty(astDisps)
        casDispBlocks = {};
    else
        casDispBlocks = reshape(unique({astDisps(:).sBlockPath}), 1, []);
    end
    nUniqueDispBlocks = length(casDispBlocks);
        
    astInfo = atgcv_m01_compiled_info_get(stEnv, [casSubPaths, casDispBlocks]);
    astSubInfo = astInfo(1:nSub);
        
    for i = 1:nSub
        if astSubInfo(i).bIsInfoComplete
            i_considerSignalTypes(stEnv, ahSubsystems(i), astSubInfo(i));
        end
    end

    if (nUniqueDispBlocks < 1)
        return;
    end
    astDispInfo = astInfo(nSub+1:end);
    
    casAllBlocks = {astDisps(:).sBlockPath};
    
    for i = 1:nUniqueDispBlocks
        stDispInfo = astDispInfo(i);
        
        if stDispInfo.bIsInfoComplete
            sBlockPath = casDispBlocks{i};
            
            aiIdx = find(strcmp(sBlockPath, casAllBlocks));
            
            for k = 1:length(aiIdx)
                stDisp   = astDisps(aiIdx(k));
                iOutPort = str2double(stDisp.sPortNumber);
                
                stOutInfo = stDispInfo.astOutports(iOutPort);
                i_addSignalTypeDisp(stEnv, stDisp.hDisp, stOutInfo);
            end
        end
    end
    
catch
    % do nothing (yet)
end
end


%%
function i_addSignalTypeDisp(stEnv, hDisp, stDispInfo)
bDoCheck = false;
if strcmpi(stDispInfo.sSigKind, 'bus')
    i_considerBusSubsignalTypes(stEnv, hDisp, stDispInfo.astSignals, bDoCheck);
else
    i_considerArraySubsignalTypes(stEnv, hDisp, stDispInfo.astSignals(1), bDoCheck);
end
end


%%
function astDisps = i_getDisplayBlocks(hDoc, astModelRefMap)
stDisp = struct( ...
    'hDisp',       [], ...
    'sBlockPath',  '', ...
    'sPortNumber', '');

ahDisp = mxx_xmltree('get_nodes', hDoc, ...
    '/ma:ModelAnalysis/ma:Subsystem/ma:Interface/ma:Output/ma:Display[@slBlockPath and @portNumber]');
astDisps = repmat(stDisp, 1, length(ahDisp));
for j = 1:length(ahDisp)
    hDisp = ahDisp(j);
    sBlockPath = i_getBlockRealModelPath(hDisp, 'slBlockPath', astModelRefMap);    
    
    astDisps(j).hDisp       = hDisp; 
    astDisps(j).sBlockPath  = sBlockPath;
    astDisps(j).sPortNumber = mxx_xmltree('get_attribute', hDisp, 'portNumber');       
end
end


%%
function i_addModelReferenceNode(~, hParentNode, sModelPath)
% find separator / but ignore mutliple separators //
iFind = regexp(sModelPath, '[^/]/[^/]', 'once');
if isempty(iFind)
    sModelName = sModelPath;
else
    sModelName = sModelPath(1:iFind);
end
[~, ~, sExt] = fileparts(get_param(sModelName, 'FileName'));
sModelFile = [sModelName, sExt];
hModelRefNode = mxx_xmltree('add_node', hParentNode, 'ModelReference');
mxx_xmltree('set_attribute', hModelRefNode, 'path',  sModelPath);
mxx_xmltree('set_attribute', hModelRefNode, 'model', sModelFile);
mxx_xmltree('set_attribute', hModelRefNode, 'kind',  'SL');
end

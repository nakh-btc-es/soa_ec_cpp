function [astDispVars, abValid] = atgcv_m01_disp_vars_signal_info_add(stEnv, astDispVars, astBlockInterface, aiBlockDispMap, bReportInvalidDisps)


%% main
castBlockOutputs = i_getBlockOutputs(astBlockInterface);
caoLocalsMaps = i_getBlockLocals(astBlockInterface);

abValid = true(size(astDispVars));
for i = 1:length(astDispVars)
    astDispVars(i).sSigKind       = ''; % set default values
    astDispVars(i).sBusType       = ''; % set default values
    astDispVars(i).sBusObj        = ''; % set default values
    astDispVars(i).astSignals     = [];
    astDispVars(i).astSomeSubSigs = [];
    
    iBlockIdx = aiBlockDispMap(i);
    if (iBlockIdx < 1)
        continue;
    end
    
    if isempty(astDispVars(i).iPortNumber)
        oLocalsMap = caoLocalsMaps{iBlockIdx};
        if (oLocalsMap.size() < 1)
            continue;
        end
        stSfInfo = astDispVars(i).astBlockInfo(1).stSfInfo;
        sSfUniqueName = [stSfInfo.sSfRelPath, '/', stSfInfo.sSfName];
        stBlockOutput = oLocalsMap(sSfUniqueName);
    else
        astBlockOutputs = castBlockOutputs{iBlockIdx};
        if isempty(astBlockOutputs)
            continue;
        end
        stBlockOutput = astBlockOutputs(astDispVars(i).iPortNumber);
    end
    
    % MIL currently unable to log 3/4/...-dim Matrix-Signals --> filter them out
    if i_containsHighDimMatrixSignals(stBlockOutput)
        abValid(i) = false;
        if bReportInvalidDisps
            sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astDispVars(i).hVar, 'Name');
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_DISP_MATRIX', 'variable',  sVarName);
        end
        continue;
    end
    
    % MIL type (u)int64 is not supported
    if ~i_checkForSupportedTypes(stBlockOutput.astSignals)
        abValid(i) = false;
        if bReportInvalidDisps
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_SUPPORTED_LOCAL_DISPLAY', ...
                'path', astDispVars(i).astBlockInfo(1).sTlPath);
        end
        continue;
    end
    
    % store info about the whole Signal coming out of the corresponing outport of the block
    astDispVars(i).sSigKind   = stBlockOutput.sSigKind;
    astDispVars(i).sBusType   = stBlockOutput.sBusType;
    astDispVars(i).sBusObj    = stBlockOutput.sBusObj;
    astDispVars(i).astSignals = i_getBlockOutputSignals(stBlockOutput);
    
    % now try to get the specific subsignals that are really mapped to the corresponding C-Code DISP variable
    % (might be a subset of the whole signal --> potentially true for bus signals)
    if isempty(astDispVars(i).aiOutIdx)
        % Note: if there is no info about output indices, this means that *all* subsignal are mapped
        % --> use all available indices
        astDispVars(i).aiOutIdx = 1:length(stBlockOutput.aiIdxMap);
    end
    nSigs = length(astDispVars(i).aiOutIdx);
    for j = 1:nSigs
        iOutIdx = astDispVars(i).aiOutIdx(j);
        
        iSigIdx = stBlockOutput.aiIdxMap(iOutIdx);
        iSubSigIdx = stBlockOutput.aiSubSigIdx(iOutIdx);
        if isempty(astDispVars(i).astSomeSubSigs)
            astDispVars(i).astSomeSubSigs = astDispVars(i).astSignals(iSigIdx).astSubSigs(iSubSigIdx);
        else
            astDispVars(i).astSomeSubSigs(end + 1) = astDispVars(i).astSignals(iSigIdx).astSubSigs(iSubSigIdx);
        end
    end
end
end


%%
function bIsValid = i_checkForSupportedTypes(astSignals)
bIsValid = true;
for i=1:length(astSignals)
    if ~isempty(astSignals(i).sUserType)
        bIsValid = ~any(strcmp({astSignals(i).sUserType}, {'ufix64', 'sfix64', 'uint64', 'int64'}));
        if bIsValid
            bIsValid = isempty(strfind(astSignals(i).sUserType, 'fix128'));
        end
    end
    if ~bIsValid
        return
    end
end
end


%%
function astSignals = i_getBlockOutputSignals(stBlockOutput)
astSignals = stBlockOutput.astSignals;

iIdx = 0;
for iSigIdx = 1:length(stBlockOutput.astSignals)
    astSignals(iSigIdx).stVarInfo  = [];
    [astSignals(iSigIdx).astSubSigs, iIdx] = i_extendSubSignals(stBlockOutput.astSignals(iSigIdx), iSigIdx, iIdx);
end
end


%%
function [astSubSigs, iIdx] = i_extendSubSignals(stSignal, iSigIdx, iIdx)
astSubSigs = rmfield(stSignal, {'iWidth'});
astSubSigs.iIdx = [];
astSubSigs.iSigIdx = iSigIdx;
astSubSigs.iSubSigIdx = [];

if (~isfield(stSignal, 'iWidth') || isempty(stSignal.iWidth))
    iWidth = 1;
else
    iWidth = stSignal.iWidth;
end

if (iWidth > 1)
    astSubSigs = repmat(astSubSigs, 1, iWidth);
    for k = 1:iWidth
        iIdx = iIdx + 1;
        astSubSigs(k).iIdx = iIdx;
        
        % note: add subsig index only if we have a non-scalar signal (iWidth > 1)
        astSubSigs(k).iSubSigIdx = k;
    end
else
    iIdx = iIdx + 1;
    astSubSigs(1).iIdx = iIdx;
end
end


%%
function bContainsHighDimSig = i_containsHighDimMatrixSignals(stBlockOutput)
bContainsHighDimSig = false;
for i = 1:length(stBlockOutput.astSignals)
    bContainsHighDimSig = bContainsHighDimSig || i_isHighDimSignal(stBlockOutput.astSignals(i));
end
end


%%
function caoLocalsMaps = i_getBlockLocals(astBlockInterfaces)
nBlocks = numel(astBlockInterfaces);
caoLocalsMaps = cell(1, nBlocks);
for i = 1:nBlocks
    nLocals = length(astBlockInterfaces(i).astLocals);
    
    oLocalsMap = containers.Map;
    for k = 1:nLocals
        stLocal = astBlockInterfaces(i).astLocals(k);
        
        [aiIdxMap, aiSubSigIdx] = i_getIdxMapping(stLocal.astSignals);
        stInfo = struct( ...
            'astSignals',  stLocal.astSignals, ...
            'sSigKind',    stLocal.sSigKind, ...
            'sBusType',    stLocal.sBusType, ...
            'sBusObj',     stLocal.sBusObj, ...
            'aiIdxMap',    aiIdxMap, ...
            'aiSubSigIdx', aiSubSigIdx);
        
        sSfUniqueName = [stLocal.sSfRelPath, '/', stLocal.sSfName];
        oLocalsMap(sSfUniqueName) = stInfo;
    end
    
    caoLocalsMaps{i} = oLocalsMap;
end
end


%%
function castBlockOutputs = i_getBlockOutputs(astBlockInterface)
stBlockOutput =  struct( ...
    'astSignals',  [], ...
    'sSigKind',    '', ...
    'sBusType',    '', ...
    'sBusObj',     '', ...
    'aiIdxMap',    [], ...
    'aiSubSigIdx', []);

nBlocks = length(astBlockInterface);
castBlockOutputs = cell(1, nBlocks);
for i = 1:nBlocks
    nOut = length(astBlockInterface(i).astOutports);
    if (nOut > 0)
        castBlockOutputs{i} = repmat(stBlockOutput, 1, nOut);
        for j = 1:nOut
            stOutport = astBlockInterface(i).astOutports(j);
            [aiIdxMap, aiSubSigIdx] = i_getIdxMapping(stOutport.astSignals);
            castBlockOutputs{i}(j) = struct( ...
                'astSignals',  stOutport.astSignals, ...
                'sSigKind',    stOutport.sSigKind, ...
                'sBusType',    stOutport.sBusType, ...
                'sBusObj',     stOutport.sBusObj, ...
                'aiIdxMap',    aiIdxMap, ...
                'aiSubSigIdx', aiSubSigIdx);
        end
    else
        % Outports used as DISP (OutportBlock has no Outputs!)
        nIn = length(astBlockInterface(i).astInports);
        if (nIn == 1)
            castBlockOutputs{i} = stBlockOutput;
            
            stInport = astBlockInterface(i).astInports(1);
            [aiIdxMap, aiSubSigIdx] = i_getIdxMapping(stInport.astSignals);
            castBlockOutputs{i} = struct( ...
                'astSignals',  stInport.astSignals, ...
                'sSigKind',    stInport.sSigKind, ...
                'sBusType',    stInport.sBusType, ...
                'sBusObj',     stInport.sBusObj, ...
                'aiIdxMap',    aiIdxMap, ...
                'aiSubSigIdx', aiSubSigIdx);
        end
    end
end
end


%%
% returns two array with length equal to the number of  _all_ elements in the
% provided signals
% 1) SigIdx    --> index of the provided Signal
% 2) SubSigIdx --> index of each individual element inside each Signal
% Example: 
%     IN --> SigA[2] and SigB[3]
%    OUT <-- SigIdx=[1 1 2 2 2] SubSigIdx=[1 2 1 2 3]
function [aiSigIdx, aiSubSigIdx] = i_getIdxMapping(astSignals)
nSig  = length(astSignals);
aiNum = arrayfun(@i_getNumberOfElements, astSignals);
aiSigIdx    = i_arrayfun2(@(x, y) y*ones(1, x), aiNum, 1:nSig);
aiSubSigIdx = i_arrayfun2(@(x) 1:x, aiNum);
end


%%
% arrayfun2 is simply a combination of arrayfun() and cell2mat()
function axArrayOut = i_arrayfun2(hFuncHandle, axArrayIn, varargin)
axArrayOut = cell2mat( ...
    arrayfun(hFuncHandle, axArrayIn, varargin{:}, 'UniformOutput', false));
end


%%
% TODO? maybe use aiDim 
function iNum = i_getNumberOfElements(stSignalMIL)
if isempty(stSignalMIL.iWidth)
    iNum = 1;
else
    iNum = prod(stSignalMIL.iWidth);
end
end


%%
function [aiIdxMap, aiSubSigIdx] = i_getIdxMappingOld(astSignals)
nSigs = length(astSignals);
aiIdxMap    = [];
aiSubSigIdx = [];
for i = 1:nSigs
    iWidth = astSignals(i).iWidth;
    aiIdxMap = [aiIdxMap, repmat(i, 1, iWidth)]; %#ok<AGROW>
    if (iWidth > 1)
        aiSubSigIdx = [aiSubSigIdx, 1:iWidth]; %#ok<AGROW>
    else
        aiSubSigIdx = [aiSubSigIdx, 1]; %#ok<AGROW>
    end
end
end


%%
% Note: 
%  1) the Dim of array-valued signals has the format:
%     aiDim = [<widthDim1>]
%  2) the Dim of matrix-valued signals has the format:
%     aiDim = [<#numDim> <widthDim1> <widthDim2> <widthDim3> ...]
function bIsHighDim = i_isHighDimSignal(stSignal)
nDim = 1;
if (length(stSignal.aiDim) > 2)
    nDim = stSignal.aiDim(1);
end
bIsHighDim = (nDim > 2);
end

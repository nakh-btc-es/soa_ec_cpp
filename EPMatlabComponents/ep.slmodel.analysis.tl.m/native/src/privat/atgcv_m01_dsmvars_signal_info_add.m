function [astDsmVars, abValid] = atgcv_m01_dsmvars_signal_info_add(stEnv, astDsmVars)


%% main
abValid = true(size(astDsmVars));
for i = 1:length(astDsmVars)
    astDsmVars(i).sSigKind       = ''; % set default values
    astDsmVars(i).sBusType       = ''; % set default values
    astDsmVars(i).sBusObj        = ''; % set default values
    astDsmVars(i).astSignals     = [];
    astDsmVars(i).astSomeSubSigs = [];
    
    oWorkspaceSig = astDsmVars(i).stDsm.oWorkspaceSig;
    if isempty(oWorkspaceSig)
        abValid(i) = false;
        continue;
    end
        
    % MIL currently unable to log 3/4/...-dim Matrix-Signals --> filter them out
%     if i_containsHighDimMatrixSignals(stBlockOutput)
%         abValid(i) = false;
%         if bReportInvalidDisps
%             sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astDsmVars(i).hVar, 'Name');
%             osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_DISP_MATRIX', 'variable',  sVarName);
%         end
%         continue;
%     end
    
    % MIL type (u)int64 is not supported
%     if ~i_checkForSupportedTypes(stBlockOutput.astSignals)
%         abValid(i) = false;
%         if bReportInvalidDisps
%             osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_SUPPORTED_LOCAL_DISPLAY', ...
%                 'path', astDsmVars(i).astBlockInfo(1).sTlPath);
%         end
%         continue;
%     end
    
    % store info about the whole Signal coming out of the corresponing outport of the block
    stBlockOutput = i_getBlockOutput(oWorkspaceSig);
    
    astDsmVars(i).sSigKind   = stBlockOutput.sSigKind;
    astDsmVars(i).sBusType   = stBlockOutput.sBusType;
    astDsmVars(i).sBusObj    = stBlockOutput.sBusObj;
    astDsmVars(i).astSignals = i_extendAllSignalsWithSubSignals(stBlockOutput.astSignals);
    
    % now try to get the specific subsignals that are really mapped to the corresponding C-Code DISP variable
    % (might be a subset of the whole signal --> potentially true for bus signals)
    if isempty(astDsmVars(i).aiVarIdx)
        % Note: if there is no info about output indices, this means that *all* subsignal are mapped
        % --> use all available indices
        astDsmVars(i).aiVarIdx = 1:length(stBlockOutput.aiIdxMap);
    end
    
    % assume a 1:1 mapping between DSM (bus) signal in MIL and DSM (field) variable in SIL
    nSigs = length(astDsmVars(i).aiVarIdx);
    for j = 1:nSigs
        iVarIdx = astDsmVars(i).aiVarIdx(j);
        
        iSigIdx = stBlockOutput.aiIdxMap(iVarIdx);
        iSubSigIdx = stBlockOutput.aiSubSigIdx(iVarIdx);
        if isempty(astDsmVars(i).astSomeSubSigs)
            astDsmVars(i).astSomeSubSigs = astDsmVars(i).astSignals(iSigIdx).astSubSigs(iSubSigIdx);
        else
            astDsmVars(i).astSomeSubSigs(end + 1) = astDsmVars(i).astSignals(iSigIdx).astSubSigs(iSubSigIdx);
        end
    end   
end
end


%%
function stBlockOutput = i_getBlockOutput(oSig)
astSigs = oSig.getLegacySignalInfos;
astSigs = arrayfun(@(x) setfield(x, 'iSubSigIdx', []), astSigs);

[aiIdxMap, aiSubSigIdx] = i_getIdxMapping(astSigs);

stBlockOutput =  struct( ...
    'astSignals',  astSigs, ...
    'sSigKind',    i_getSigKind(oSig), ...
    'sBusType',    oSig.getBusType, ...
    'sBusObj',     oSig.getBusObjectName, ...
    'aiIdxMap',    aiIdxMap, ...
    'aiSubSigIdx', aiSubSigIdx);
end


%%
function sSigKind = i_getSigKind(oSig)
if oSig.isBus
    sSigKind = 'bus';
else
    sSigKind = 'simple';
end
end


%%
function astExtendedSignals = i_extendAllSignalsWithSubSignals(astSignals)
iIdx = 0;

% IMPORTANT: make a copy for the extended signals because the original signals will be the prototype for the sub-signals
astExtendedSignals = astSignals;

for iSigIdx = 1:length(astSignals)
    [astExtendedSignals(iSigIdx).astSubSigs, iIdx] = i_extendSubSignals(astSignals(iSigIdx), iSigIdx, iIdx);
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
function bContainsHighDimSig = i_containsHighDimMatrixSignals(stBlockOutput)
bContainsHighDimSig = false;
for i = 1:length(stBlockOutput.astSignals)
    bContainsHighDimSig = bContainsHighDimSig || i_isHighDimSignal(stBlockOutput.astSignals(i));
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

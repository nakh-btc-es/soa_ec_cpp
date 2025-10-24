function stInterface = atgcv_m01_if_from_comp_if_derive(stCompInterface, sRealRootPath, sVirtualRootPath)
stInterface = stCompInterface;

% inports
for i = 1:length(stCompInterface.astInports)
    stInterface.astInports(i).sSlPortPath = stCompInterface.astInports(i).sPath;
    stInterface.astInports(i).iPortNumber = stCompInterface.astInports(i).iNumber;
    
    stInterface.astInports(i).stCompInfo = struct( ...
        'sSigKind', stCompInterface.astInports(i).sSigKind, ...
        'sBusType', stCompInterface.astInports(i).sBusType, ...
        'sBusObj',  stCompInterface.astInports(i).sBusObj);
    
    % stVarInfo and SubSigs
    for j=1:length(stCompInterface.astInports(i).astSignals)
        stInterface.astInports(i).astSignals(j).stVarInfo = [];
        stInterface.astInports(i).astSignals(j).astSubSigs = ...
            i_extendSubSignals(stInterface.astInports(i).astSignals(j));
    end
end

% outports
for i = 1:length(stCompInterface.astOutports)
    stInterface.astOutports(i).sSlPortPath = stCompInterface.astOutports(i).sPath;
    stInterface.astOutports(i).iPortNumber = stCompInterface.astOutports(i).iNumber;
    
    stInterface.astOutports(i).stCompInfo = struct( ...
        'sSigKind', stCompInterface.astOutports(i).sSigKind, ...
        'sBusType', stCompInterface.astOutports(i).sBusType, ...
        'sBusObj',  stCompInterface.astOutports(i).sBusObj);
    
    % stVarInfo and SugSigs
    for j=1:length(stCompInterface.astOutports(i).astSignals)
        stInterface.astOutports(i).astSignals(j).stVarInfo = [];
        stInterface.astOutports(i).astSignals(j).astSubSigs = ...
            i_extendSubSignals(stInterface.astOutports(i).astSignals(j));
    end
end

if ((nargin > 2) && ~strcmp(sRealRootPath, sVirtualRootPath))
    sOrigPattern = ['^', regexptranslate('escape', sRealRootPath)];
    sReplacement = regexptranslate('escape', sVirtualRootPath);
    
    for i = 1:length(stInterface.astInports)
        sPortPath = stInterface.astInports(i).sSlPortPath;
        stInterface.astInports(i).sSlPortPath = ...
            regexprep(sPortPath, sOrigPattern, sReplacement);
        stInterface.astInports(i).sModelPortPath = sPortPath;
    end

    for i = 1:length(stInterface.astOutports)
        sPortPath = stInterface.astOutports(i).sSlPortPath;
        stInterface.astOutports(i).sSlPortPath = ...
            regexprep(sPortPath, sOrigPattern, sReplacement);
        stInterface.astOutports(i).sModelPortPath = sPortPath;
    end

end
end


%%
% Handle complex signals (e.g. arrays) and return the corresponding
% subsignals of the main signal.
function astSubSigs = i_extendSubSignals(stSignal)

% remove fields that are not part of SubSigs but are present in Sigs
stSubSig = rmfield(stSignal, 'iWidth');

% add fields that are part of SubSigs but missing in Sigs
stSubSig.iSubSigIdx = [];
stSubSig.iIdx = [];

if isfield(stSignal, 'iWidth')
    iWidth = stSignal.iWidth;
else
    iWidth = 1;
end
if (iWidth > 1)
    astSubSigs = repmat(stSubSig, 1, iWidth);
    for k = 1:iWidth
        astSubSigs(k).iIdx = k;
        astSubSigs(k).iSubSigIdx = k;
    end
else
    astSubSigs = stSubSig;
end
end

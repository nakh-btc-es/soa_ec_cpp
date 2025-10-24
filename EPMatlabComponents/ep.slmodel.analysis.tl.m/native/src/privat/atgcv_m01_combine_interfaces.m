function stInterface = atgcv_m01_combine_interfaces(stEnv, stFuncInterface, stSubInterface, stCompInterface, sSubRealPath, sSubVirtualPath)
% Combining the FuncInterface (DD), SubInterface (DD), and CompInterface (MDL).
%
%  TODO: description here
%


%%
if (nargin < 5)
    sSubRealPath = '';
    sSubVirtualPath = '';
end

%%
if ~atgcv_verLessThan('TL4.0')
    stSubInterface = i_handleInstanceSignals(stSubInterface, stFuncInterface);
end
stInterface = struct( ...
    'astInports',  i_remapPortsForModelRefs(stSubInterface.astInports,  sSubRealPath, sSubVirtualPath), ...
    'astOutports', i_remapPortsForModelRefs(stSubInterface.astOutports, sSubRealPath, sSubVirtualPath));

% create map between handles of BlockVar and handles of InterfaceVars
if ~isempty(stFuncInterface)
    stInterfaceBlockMap = i_getInterfaceBlockVarMap(stFuncInterface.astVars);
    
    stInterface.astInports = ...
        i_addMappingToPorts(stEnv, stInterface.astInports, stCompInterface.astInports, stInterfaceBlockMap);
    stInterface.astOutports = ...
        i_addMappingToPorts(stEnv, stInterface.astOutports, stCompInterface.astOutports, stInterfaceBlockMap);
end
end


%%
function astPorts = i_remapPortsForModelRefs(astPorts, sSourcePath, sTargetPath)
if ~strcmp(sSourcePath, sTargetPath)
    sOrigPattern = ['^', regexptranslate('escape', sSourcePath)];
    sReplacement = regexptranslate('escape', sTargetPath);
    
    for i = 1:length(astPorts)
        sPortPath = astPorts(i).sSlPortPath;
        astPorts(i).sSlPortPath = regexprep(sPortPath, sOrigPattern, sReplacement);
        astPorts(i).sModelPortPath = sPortPath;
    end
else
    for i = 1:length(astPorts)
        astPorts(i).sModelPortPath = astPorts(i).sSlPortPath;
    end
end
end


%%
function astPorts = i_addMappingToPorts(stEnv, astPorts, astCompInfo, stIfBlockMap)
nPorts = length(astPorts);
for i = 1:nPorts
    stCompInfo = astCompInfo(i);
    
    astPorts(i).stCompInfo = stCompInfo;
    astPorts(i).astSignals = i_addMappingToMIL(astPorts(i).astSignals, stCompInfo);
    
    astSignals = astPorts(i).astSignals;
    for j = 1:length(astSignals)
        stCheckSignal = astSignals(j);
        astPorts(i).astSignals(j).stVarInfo.bIsUsable = true; % default value for marker
        astPorts(i).astSignals(j).aiVarIdx = [];
        
        % Check if we can get the corresponding InterfaceVariable of the step function.
        [stIfVarInfo, aiVarIdx] = i_getCorrespondingInterfaceVariable(stCheckSignal, stIfBlockMap);
        bIfVarIsUniqueAndValid = ...
            ~isempty(stIfVarInfo) && (length(aiVarIdx) == 1) && i_isVariableValid(stEnv, stIfVarInfo);
        if bIfVarIsUniqueAndValid
            astPorts(i).astSignals(j).stVarInfo.stInterfaceVar = stIfVarInfo;            
        end
        
        % Note: Try a shortcut. Check if the Signal already has a useful Mapping to a C-Code Variable.
        %       For TL < TL4.0 this is already enough to quit the loop and continue with the next signal.
        %       For TL4.0 and higher we need extra checks because the info in DD is not always consistent.
        bHasUsefulMapping = i_signalHasUsefulMapping(stEnv, stCheckSignal);
        if atgcv_verLessThan('TL4.0')
            if bHasUsefulMapping
                % Mapping is useful and we do not need any more info.
                continue;
            end
        end
        
        % Note: For TL4.0 a useful mapping needs to be additionally validated by the following criterion:
        %       The mapping is not valid if the interface variable is overriding the signal variable.
        bDoPreferIfVar = ...
            bIfVarIsUniqueAndValid && i_isInterfaceVarOverridingSignalVar(stIfVarInfo, stCheckSignal);
        bHasUsefulMapping = bHasUsefulMapping && ~bDoPreferIfVar;
        if ~bHasUsefulMapping

            if bDoPreferIfVar
                astPorts(i).astSignals(j).stVarInfo = atgcv_m01_variable_info_get(stEnv, stIfVarInfo.hVar);
                astPorts(i).astSignals(j).stVarInfo.stInterfaceVar = stIfVarInfo;
                astPorts(i).astSignals(j).stVarInfo.bIsUsable = true;
                astPorts(i).astSignals(j).aiVarIdx = aiVarIdx;
                astPorts(i).astSignals(j).stVarInfo.stInterface = stIfVarInfo;
            else
                % Note: If we are here, there is no useful Mapping yet.
                %       Additional info needs to be gathered from the InterfaceVariable if there is any.
                astPorts(i).astSignals(j).stVarInfo.bIsUsable = false;
                if bIfVarIsUniqueAndValid
                    astPorts(i).astSignals(j).aiVarIdx = aiVarIdx;
                    astPorts(i).astSignals(j).stVarInfo.stInterface = stIfVarInfo;
                else
                    % Note: If we are here, there is no useful Mapping yet.
                    %       Assume that Info in DD is wrong and the Variable is not really used 
                    %      (see BTS/33965 and BTS/36011).
                    astPorts(i).astSignals(j).stVarInfo = [];
                    astPorts(i).astSignals(j).bIsDummyVar = true;
                end
            end
        end        
    end
end
end



%%
function bIsOverriding = i_isInterfaceVarOverridingSignalVar(stIfVarInfo, stSignal)
bIsOverriding = false;
if isempty(stIfVarInfo)
    return;
end

% 1) a RETURN value always overrides the signal variable
if ~bIsOverriding
    bIsOverriding = strcmpi(stIfVarInfo.sKind, 'RETURN_VALUE');
end

% 2) an interface variable always overrides a DUMMY signal variable
if ~bIsOverriding
    bIsOverriding = stSignal.bIsDummyVar;
end

% 3) a mismatch between the variable structures leads to an override
if ~bIsOverriding
    bIsOverriding = ~i_isInterfaceVarMatchingSignalVar(stIfVarInfo, stSignal);
end

% 4) a GLOBAL interface variable always overrides a local signal variable
if ~bIsOverriding
    % TODO: not clear if "struct_component" should also be counted as non-local
    bIsSigVarLocal = ~any(strcmpi(stSignal.stVarInfo.stRootClass.sScope, {'global', 'struct_component'}));
    bIsIfVarGlobal = ~isempty(regexpi(stIfVarInfo.sKind, 'GLOBAL'));
    bIsOverriding  = bIsSigVarLocal && bIsIfVarGlobal; 
end
end



%%
% Note: currently the only matching criterion is if both of the variables are components inside a struct or both are not
function bIsMatching = i_isInterfaceVarMatchingSignalVar(stIfVarInfo, stSignal)
bIsIfVarComponent = stIfVarInfo.hRootVar ~= stIfVarInfo.hVar;
bIsBlockVarComponent = stSignal.stVarInfo.hRootVar ~= stSignal.stVarInfo.hVar;
bIsMatching =  bIsIfVarComponent == bIsBlockVarComponent;
end


%%
function [stIfVar, aiVarIdx] = i_getCorrespondingInterfaceVariable(stSignal, stIfBlockMap)
stIfVar = [];
aiVarIdx = [];

% Assume that for Variables referencing Signal slices (<==> aiSigElements is _not_ empty), we have a real DummyVariable.
if isempty(stSignal.aiSigElements)
    [stIfVar, aiVarIdx] = i_getInterfaceVarInfoFromMap(stIfBlockMap, stSignal.hBlockVar);
end
end


%%
function [stIfVarInfo, aiVarIdx] = i_getInterfaceVarInfoFromMap(stIfBlockMap, hBlockVar)
stIfVarInfo = [];
aiVarIdx    = [];
if ~isempty(hBlockVar)
    % try to find mapping to interface indices
    abMatching = (hBlockVar == stIfBlockMap.ahBlockVars);
    aiVarIdx   = stIfBlockMap.aiIfVarIdx(abMatching);
    if ~isempty(aiVarIdx)
        stIfVarInfo = stIfBlockMap.astInterfaceVars(aiVarIdx(1));
    end
end
end


%%
function bHasUsefulMapping = i_signalHasUsefulMapping(stEnv, stSignal)
stVarInfo = stSignal.stVarInfo;
bHasUsefulMapping = ~isempty(stVarInfo) && i_isVarUsefulGlobal(stEnv, stVarInfo.hRootVar);
if bHasUsefulMapping
    iSilWidth = i_getNumElementsSIL(stSignal);
    % compare also the width of MIL and SIL objects
    iMilWidth = 1;
    if ~isempty(stSignal.iWidth)
        iMilWidth = prod(stSignal.iWidth);
    else
        if ~isempty(stSignal.astSubSigs)
            iMilWidth = length(stSignal.astSubSigs);
        end
    end
    bHasUsefulMapping = iSilWidth == iMilWidth;
end
end


%%
function stSubInterface = i_handleInstanceSignals(stSubInterface, stFuncInterface)
ahFuncVars = [];
if ~isempty(stFuncInterface.astVars)
    ahFuncVars = [stFuncInterface.astVars(:).hVarRef];
end
if isempty(ahFuncVars)
    return;
end
stSubInterface.astInports = i_handleInstanceSignalsPorts(stSubInterface.astInports, ahFuncVars);
stSubInterface.astOutports = i_handleInstanceSignalsPorts(stSubInterface.astOutports, ahFuncVars);
end


%%
function astPorts = i_handleInstanceSignalsPorts(astPorts, ahFuncVars)
for i = 1:length(astPorts)
    astPorts(i).astSignals = i_useInstanceSigs(astPorts(i).astSignals, ahFuncVars);
end
end


%%
function astSignalsOut = i_useInstanceSigs(astSignals, ahFuncVars)
astSignalsOut = [];
for i = 1:length(astSignals)
    astReplaceSigs = [];
    
    if ~isempty(astSignals(i).astInstanceSigs)
        astInstanceSigs = i_getSignalLeafInstances(astSignals(i));
        
        iOrigWidth = i_getSignalsTotalWidth(astSignals(i));
        
        % from the InstanceSigs just select the one which are either Dummy
        % or reference a Variable from the set of FunctionVariables
        abSelect = arrayfun(@(x) (x.bIsDummyVar || any(x.hVariableRef == ahFuncVars)), astInstanceSigs);
        astReplaceSigs = astInstanceSigs(abSelect);
        if (i_getSignalsTotalWidth(astReplaceSigs) ~= iOrigWidth)
            % The selection Algo yielded incorrect results. So try a
            % fallback: use _all_ Instance signals.
            % --> this is essentially the same approach that is used for
            %     TL-versions < TL4.0
            astReplaceSigs = astInstanceSigs;
            if (i_getSignalsTotalWidth(astReplaceSigs) ~= iOrigWidth)
                % if we are here, the fallback did also not work out
                % --> from now on we cannot hope to get any info from the DD
                astReplaceSigs = []; % essentially we give up here!!
            end
        end
    end
    
    % If we do not have any Signals to replace, use the original ones.
    if isempty(astReplaceSigs)
        astReplaceSigs = astSignals(i);
    end
    
    
    % extend output signals
    if isempty(astSignalsOut)
        astSignalsOut = astReplaceSigs;
    else
        astSignalsOut = [astSignalsOut, astReplaceSigs]; %#ok<AGROW>
    end
end
end


%%
% recursive function that returns all _leaf_ signal instances
function astSigs = i_getSignalLeafInstances(stSig)
if isempty(stSig.astInstanceSigs)
    astSigs = stSig;
else
    astSigs = i_arrayfun2(@i_getSignalLeafInstances, stSig.astInstanceSigs);
end
end


%%
function iWidth = i_getSignalsTotalWidth(astSigs)
if isempty(astSigs)
    iWidth = 0;
else
    iWidth = sum(arrayfun(@(x) (prod(x.iWidth)), astSigs));
end
end


%%
% map between provided Interface variables and the corresponding BlockVars
function stMap = i_getInterfaceBlockVarMap(astInterfaceVars)
aiIfVarIdx = [];
ahBlockVars = [];
nVars = length(astInterfaceVars);
for i = 1:nVars
    if ~isempty(astInterfaceVars(i).ahBlockVars)
        ahNewBlockVars = astInterfaceVars(i).ahBlockVars;
        aiIfVarIdx = [aiIfVarIdx, repmat(i, 1, length(ahNewBlockVars))]; %#ok<AGROW>
        ahBlockVars = [ahBlockVars, ahNewBlockVars]; %#ok<AGROW>
    end
end

stMap = struct( ...
    'astInterfaceVars', astInterfaceVars, ...
    'aiIfVarIdx',       aiIfVarIdx, ...
    'ahBlockVars',      ahBlockVars);
end


%%
function astVarSignals = i_addMappingToMIL(astVarSignals, stCompInfo)
stSubSig = struct( ...
    'sName',      '', ...
    'sUserType',  '', ...
    'sType',      '', ...
    'sMin',       '', ...
    'sMax',       '', ...
    'xDesignMin', [], ...
    'xDesignMax', [], ...
    'aiDim',      [], ...
    'iSubSigIdx', [], ...
    'iIdx',       []);

[aiIdxMap, aiSubSigIdx] = i_getIdxMapping(stCompInfo.astSignals);
nSubSigs = length(aiIdxMap);
nVarSigs = length(astVarSignals);

sErrMessage = '';

bIsTl = ds_isa(stCompInfo.sPath, 'tlblock');
hResolverFunc = atgcv_m01_generic_resolver_get(stCompInfo.sPath);

k = 0;
for i = 1:nVarSigs
    iWidth = i_getNumElementsSIL(astVarSignals(i));
    if isempty(astVarSignals(i).iWidth)
        astVarSignals(i).iWidth = iWidth;
    end
    [sVarSignalName, bVarSigValid] = i_getVarSignalName(astVarSignals(i));
    
    astVarSignals(i).astSubSigs = repmat(stSubSig, 1, iWidth);
    for j = 1:iWidth
        k = k + 1;
        try
            iModelSubSig = aiIdxMap(k);
        catch oEx
            rethrow(oEx);
        end
        iSubSigIdx = aiSubSigIdx(k);
        
        stSubSigInfo = stCompInfo.astSignals(iModelSubSig);
        astVarSignals(i).astSubSigs(j).sUserType  = stSubSigInfo.sUserType;
        astVarSignals(i).astSubSigs(j).sType      = stSubSigInfo.sType;
        astVarSignals(i).astSubSigs(j).sName      = stSubSigInfo.sName;
        astVarSignals(i).astSubSigs(j).sMin       = stSubSigInfo.sMin;
        astVarSignals(i).astSubSigs(j).sMax       = stSubSigInfo.sMax;
        astVarSignals(i).astSubSigs(j).xDesignMin = stSubSigInfo.xDesignMin;
        astVarSignals(i).astSubSigs(j).xDesignMax = stSubSigInfo.xDesignMax;
        astVarSignals(i).astSubSigs(j).aiDim      = stSubSigInfo.aiDim;
        if (iSubSigIdx > 0)
            astVarSignals(i).astSubSigs(j).iSubSigIdx = iSubSigIdx;
        end
        if (nSubSigs > 1)
            astVarSignals(i).astSubSigs(j).iIdx = k;
        end
        
        if (bIsTl && bVarSigValid)
            bIsEqual = i_compareVarAndModelSignal(sVarSignalName, stSubSigInfo.sName, hResolverFunc);
            if ~bIsEqual
                sErrMessage = sprintf( ...
                    'Variable SignalName "%s" differs from Model SignalName "%s".', ...
                    sVarSignalName, stSubSigInfo.sName);
                warning('ATGCV:DEBUG', '%s', sErrMessage);
            end
        end
    end
end
if i_isTestMode()
    if ~isempty(sErrMessage)
        error('ATGCV:DEBUG', 'Inconsistency between SignalNames.\n%s', sErrMessage);
    end
end
if ((length(aiIdxMap) ~= k) || (stCompInfo.iWidth ~= k))
    error('ATGCV:MOD_ANA:INTERNAL_ASSERT', 'Inconsistency between signal width (MIL) and variable width (SIL) of port.');
end
end


%%
function iNum = i_getNumElementsSIL(stVarSignal)
if ~isempty(stVarSignal.aiElements)
    if any(stVarSignal.aiElements < 0)
        iNum1 = stVarSignal.stVarInfo.aiWidth(1);
    else
        iNum1 = length(stVarSignal.aiElements);
    end
    
    iNum2 = 1;
    if ~isempty(stVarSignal.aiElements2)
        if any(stVarSignal.aiElements2 < 0)
            iNum2 = stVarSignal.stVarInfo.aiWidth(2);
        else
            iNum2 = length(stVarSignal.aiElements2);
        end
    end
    
    iNum = iNum1*iNum2;
else
    iWidth = stVarSignal.iWidth;
    if (isempty(iWidth) && ~isempty(stVarSignal.stVarInfo))
        iWidth = stVarSignal.stVarInfo.aiWidth;
    end
    if isempty(iWidth)
        iWidth = 1;
    end
    iNum = prod(iWidth);
end
end


%%
function bIsEqual = i_compareVarAndModelSignal(sVarSignal, sModelSignal, hResolverFunc)
bIsEqual = true;

if (~isempty(sModelSignal) && (sModelSignal(1) == '.'))
    sVarSignal = regexprep(sVarSignal, '^[^\.]+', '');
end
if ~strcmpi(sVarSignal, sModelSignal)
    if i_isBusType(sVarSignal, hResolverFunc)
        % TL sometimes uses the TL-Bus Type instead of the real SignalName
        % --> in this case just compare the remainder signal names
        sVarSignal = regexprep(sVarSignal, '[^.]+\.', '');
        sModelSignal = regexprep(sModelSignal, '[^.]+\.', '');
        bIsEqual = strcmp(sVarSignal, sModelSignal);
    else
        bIsEqual = false;
    end
end
end


%%
function bIsBusType = i_isBusType(sSignal, hResolverFunc)
bIsBusType = false;

sMainName = regexprep(sSignal, '\..*', '');
if ~isempty(sMainName)
    [xMaybeBusObj, nScope] = feval(hResolverFunc, sMainName);
    if (nScope > 0)
        bIsBusType = isa(xMaybeBusObj, 'Simulink.Bus');
    end
end
end


%%
function [sVarSignalName, bVarSigValid] = i_getVarSignalName(stVarSignal)
sVarSignalName = regexprep(stVarSignal.sSignalName, '[<>]', '');

bVarSigValid = ~isempty(sVarSignalName);
if bVarSigValid
    return;
end

% DummyVariables do not get SignalName info in DD (verified for TL3.2)
bVarSigValid = ~stVarSignal.bIsDummyVar;
if bVarSigValid
    if ~isempty(stVarSignal.stVarInfo)
        % RTE Variables do not get SignalName info in DD (verified for TL3.2)
        bVarSigValid = isempty(regexp(lower(stVarSignal.stVarInfo.sRootName), '^rte', 'once'));
    end
end

end


%%
function bIsTestMode = i_isTestMode()
persistent p_bIsTestMode;

p_bIsTestMode = []; % just for testing
if isempty(p_bIsTestMode)
    p_bIsTestMode = false;
    try
        astStack = dbstack();
        if ~isempty(astStack)
            p_bIsTestMode = any(strcmp('MUNITTEST', {astStack(:).name}));
        end
    catch  %#ok<CTCH>
    end
end

bIsTestMode = p_bIsTestMode;
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
aiSubSigIdx = i_arrayfun2(@i_createIdxArray, aiNum);
end


%%
% never create valid index for scalars --> zero is later a flag for other funcs
function aiIdx = i_createIdxArray(nLen)
if (nLen > 1)
    aiIdx = 1:nLen;
else
    aiIdx = 0;
end
end


%%
% arrayfun2 is simply a combination of arrayfun() and cell2mat()
function axArrayOut = i_arrayfun2(hFuncHandle, axArrayIn, varargin)
axArrayOut = cell2mat(arrayfun(hFuncHandle, axArrayIn, varargin{:}, 'UniformOutput', false));
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
function bIsUseful = i_isVarUsefulGlobal(stEnv, hVar)
bIsUseful = false;
if isempty(hVar)
    return;
end

% 1) var is only useful for us if we have a global var
sScope = i_getVarScope(stEnv, hVar);
if ~strcmpi(sScope, 'global')
    return;
end

% 2) var only useful if the module is valid/accessible
bIsUseful = i_checkModule(stEnv, hVar);
end


%%
function sScope = i_getVarScope(stEnv, hVar)
try
    stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
    sScope = stInfo.sScope;
    
catch %#ok<CTCH>
    sScope = '';
end
end


%%
function bIsModuleValid = i_checkModule(stEnv, hVar)
bIsModuleValid = false;

sPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
iFind = regexp(sPath, '/Variables/', 'once');
if isempty(iFind)
    % Variable handle is not inside a Module (maybe in Pool area of DD)
    return;
end

sModulePath = sPath(1:iFind-1);
bIsModuleValid = atgcv_m01_module_check(stEnv, sModulePath);
end


%%
% don't accept MACROs and local variables that cannot be reached through the function interface
function bIsValid = i_isVariableValid(stEnv, astVars)
if isempty(astVars)
    bIsValid = false;
    return;
end

for i = 1:length(astVars)
    bIsValid = true;
    
    if (astVars(i).iArgIdx < 0)
        bIsValid = false;
    else
        hInterfaceVar = astVars(i).hVar(i);
        if dsdd('Exist', hInterfaceVar, 'Property', 'Variable')
            hVar = dsdd('GetVariable', hInterfaceVar);
            if isempty(hVar)
                bIsValid = true;
            else
                stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
                bIsValid = ~stInfo.bIsMacro;
            end
        end
    end
    
    % all vars are invalid if just one of the them is invalid
    if ~bIsValid
        return;
    end
end
end




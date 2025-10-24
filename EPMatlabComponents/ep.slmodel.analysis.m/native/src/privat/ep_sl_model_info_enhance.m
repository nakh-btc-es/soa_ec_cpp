function stModel = ep_sl_model_info_enhance(xEnv, stModel, bDSReadWriteObservable)
% Enhances the model data with global information and evaluates connection between global elements and subsystems.
%
% function stModel = ep_sl_model_info_enhance(xEnv, stModel)
%
%   INPUT               DESCRIPTION
%        ... TODO ...
%

%%
stModel = i_addModelParameters(xEnv, stModel);
stModel.astLocals = i_enhanceLocalsWithStateflowInfo(stModel.astLocals);

% first assign the SL-Function usages, because they extend the context of a scope
% --> Example: if a DS is used in a SL-Function F that is called by subsystem X, this means that the DS is called inside
%              the context of subsystem X and needs to be assigned to X
%
astSlFuncUsages = ep_slfuncs_to_subs_assign(xEnv, stModel.astSubsystems, stModel.astSlFunctions);
for i = 1:numel(stModel.astSubsystems)
    stModel.astSubsystems(i).astSlFuncRefs = astSlFuncUsages(i).astUsageRefs;
end
aoScopeContexts = i_translateSubsystemsToScopeContexts(stModel.astSubsystems, stModel.astSlFunctions);


% ... now the other global elements: parameters, locals, DataStores
stModel.astParams = i_remapParamNames(stModel.astParams);
astParamUsages  = ep_params_to_subs_assign(xEnv, stModel.astSubsystems, stModel.astParams);
astLocalUsages  = ep_locals_to_subs_assign(xEnv, stModel.astSubsystems, stModel.astLocals);
astDsmUsages    = ep_datastores_to_subs_assign(xEnv, aoScopeContexts, stModel.astDsms, bDSReadWriteObservable);

for i = 1:numel(stModel.astSubsystems)
    stModel.astSubsystems(i).astParamRefs     = astParamUsages(i).astUsageRefs;
    stModel.astSubsystems(i).astLocalRefs     = astLocalUsages(i).astUsageRefs;
    stModel.astSubsystems(i).astDsmReaderRefs = astDsmUsages(i).astDsmReaderRefs;
    stModel.astSubsystems(i).astDsmWriterRefs = astDsmUsages(i).astDsmWriterRefs;
end
end

%%
function astParams = i_remapParamNames(astParams)
for i=1:length(astParams)
    if any(astParams(i).sName == ':')
        casNameTokens = strsplit(astParams(i).sName, ':');
        %select the part after the ':' character
        astParams(i).sName = char(casNameTokens{end});
    end
end
end

%%
function aoScopeContexts = i_translateSubsystemsToScopeContexts(astSubsystems, astSlFunctions)
aoExtendedScopes = i_arrayfun(@i_translateSlFuncToScopeContext, astSlFunctions);

aoScopeContexts = i_arrayfun(@(stSub) i_translateSubToScopeContext(stSub, aoExtendedScopes), astSubsystems);
end


%%
function oScopeContext = i_translateSlFuncToScopeContext(stSlFunc)
oScopeContext = ep_sl.ScopeContext(stSlFunc.sPath, stSlFunc.sVirtualPath);
end


%%
function oScopeContext = i_translateSubToScopeContext(stSub, aoAllExtendedScopes)
if (isempty(aoAllExtendedScopes) || isempty(stSub.astSlFuncRefs))
    aoRelevantScopes = [];
else
    aoRelevantScopes = aoAllExtendedScopes([stSub.astSlFuncRefs(:).iVarIdx]);
end
oScopeContext = ep_sl.ScopeContext(stSub.sPath, stSub.sVirtualPath, aoRelevantScopes);
end


%%
function astLocals = i_enhanceLocalsWithStateflowInfo(astLocals)
for i = 1:numel(astLocals)
    astLocals(i).stSfInfo = i_getSfInfo(astLocals(i));
end
end


%%
function stSfInfo = i_getSfInfo(stLocal)
stSfInfo = [];

if i_isSfChart(stLocal)
    if isempty(stLocal.aiPorts)
        sDataName  = stLocal.sName;
        sChartPath = stLocal.sPath;
        sRelPath   = stLocal.sSfRelPath;
    else
        iPort = stLocal.aiPorts(1);
        stPort = stLocal.stCompInfo.astOutports(iPort);

        sDataName  = get_param(stPort.sPath, 'Name');
        sChartPath = get_param(stPort.sPath, 'Parent');
        sRelPath   = '';
    end
    stSfInfo = ep_sf_data_info_get(sChartPath, sDataName, sRelPath);
end
end


%%
function bIsChart = i_isSfChart(stLocal)
bIsChart = strcmpi(stLocal.sClass, 'Stateflow.Chart');
if bIsChart
    return;
end
bIsChart = strcmpi(stLocal.sClass, 'Simulink.SubSystem') && atgcv_sl_block_isa(stLocal.sPath, 'Stateflow');
end


%%
function stModel = i_addModelParameters(xEnv, stModel)
stModel.astSubsystems = i_addChildHierarchy(xEnv, stModel.astSubsystems);
stModel.astSubsystems = i_addSampleTime(xEnv, stModel.astSubsystems, stModel.sName);

nSub = length(stModel.astSubsystems);
for i = 1:nSub
    stModel.astSubsystems(i).sId = sprintf('ss%i', i);
end
end


%% 
function astSubsystems = i_addChildHierarchy(~, astSubsystems)
abIsToplevel = arrayfun(@i_isToplevel, astSubsystems);
iTop = find(abIsToplevel);
if (length(iTop) ~= 1)
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Could not find unique toplevel subsystem.');
end
% tmp set parent index of top from [] to -1 (cannot be found in algo)
iOrig = astSubsystems(iTop).iParentIdx;
astSubsystems(iTop).iParentIdx = -1;
aiParents = [astSubsystems(:).iParentIdx];
astSubsystems(iTop).iParentIdx = iOrig;

nSub = length(astSubsystems);
for i = 1:nSub
    astSubsystems(i).aiChildIdx = find(i == aiParents);
end
end


%%
function bIsToplevel = i_isToplevel(stSub)
bIsToplevel = isempty(stSub.iParentID);
end


%%
function astSubsystems = i_addSampleTime(~, astSubsystems, sModelName)
if isempty(astSubsystems)
    return;
end

% global sample time to be used as fallback later
dGlobalSampleTime = -1; % dafault for "unknown"

nSub = length(astSubsystems);
adSubSampleTime = -ones(1, nSub); % default sample time for all subs: -1
for i = 1:nSub
    dSampleTime = -1;
    
    if (dSampleTime < 0)
        dSampleTime = i_getDiscreteFiniteCompiledSampleTime(astSubsystems(i).stCompInfo.cadSampleTime);
        if ((dSampleTime < 0) && i_isToplevel(astSubsystems(i)))
            dSampleTime = i_evalSampleTime(astSubsystems(i).stCompInfo.sStepSize);
        end
    end
    
    if (dSampleTime > 0)
        adSubSampleTime(i) = dSampleTime;
        
        % set the global SampleTime as SampleTime of TopLevel Sub if found
        if i_isToplevel(astSubsystems(i))
            dGlobalSampleTime = dSampleTime;
        end
    end
end

if any(adSubSampleTime < 0)
    % if any of the subsystem sample times is unknown we have to use the
    % some global sample time
    
    % 1) if the global SampleTime from TopLevel is "unknown", try the
    %    Model Sample Time
    if (dGlobalSampleTime < 0)
        dGlobalSampleTime = i_getModelSampleTime(sModelName);
    end    
    
    % 2) if still unknown, use the smallest of the valid subsystem sample times
    if ((dGlobalSampleTime < 0) && any(adSubSampleTime > 0))
        dGlobalSampleTime = min(adSubSampleTime(adSubSampleTime > 0.0));
    end
    
    % 3) if still unknown, use the default 1
    if (dGlobalSampleTime < 0)
        dGlobalSampleTime = 1.0; % use 1 as default sample time
    end
end

% now register the subsystem sample times
for i = 1:nSub
    dSampleTime = adSubSampleTime(i);
    
    % if sample time is inherited (-1), get the sample time
    % from (active!) configuration set
    if (dSampleTime == -1)
        dSampleTime = dGlobalSampleTime;
    end
    astSubsystems(i).dSampleTime = dSampleTime;
end
end


%%
function dSampleTime = i_evalSampleTime(sSampleTime)
dSampleTime = str2double(sSampleTime);
if (~isfinite(dSampleTime) || (dSampleTime <= 0))
    dSampleTime = -1;
end
end


%%
function dModelSampleTime = i_getModelSampleTime(sModelName)
dModelSampleTime = -1; % default value for "unknown"

% 0. try to use the explicit model sample time directly
hModel = get_param(sModelName, 'handle');
if (atgcv_version_p_compare('ML8.6') >= 0)
    sCompiledStepSize = get_param(hModel, 'CompiledStepSize');
    dModelSampleTime = i_evalSampleTime(sCompiledStepSize);
end
if (dModelSampleTime > 0)
    return;
end

sFixedStep = get_param(hModel, 'FixedStep');

% 1. try to convert directly (model sample time given as double value)
dFixedStep = str2double(sFixedStep);
if (isnumeric(dFixedStep) && isfinite(dFixedStep))
    dModelSampleTime = dFixedStep;
else
    % 2. try to evaluate in Workspace
    % (indirect conversion <-> sample time given as string)
    
    % if the sample time was specified as a variable,
    % evaluate the variable in the base workspace or
    % in a model workspace
    [val, bSuccess] = osc_mtl_evalinws(sFixedStep, sModelName);
    if bSuccess
        if ischar(val)
            val = str2double(val);  % sprintf('%g',val);
        end
        if (isnumeric(val) && ~isnan(val))
            dModelSampleTime = val;
        end
    end
end
end


%%
% * given CompiledSampleTimes, select the smallest, fininte, positive one 
% ( == Minimum Discrete SampleTime)
% * if none is found, return -1 indicating "unknown"
%
function dSampleTime = i_getDiscreteFiniteCompiledSampleTime(cadSampleTime)
dSampleTime = Inf;
for i = 1:length(cadSampleTime)
    adSampleTime = cadSampleTime{i};
    if isnumeric(adSampleTime)
        d = adSampleTime(1);
        if (isfinite(d) && (d > 0))
            dSampleTime = min(dSampleTime, d);
        end
    end

end
if ~isfinite(dSampleTime)
    dSampleTime = -1;  % default for "unknown"
end
end


%%
% this function is needed for lower ML versions (e.g. ML2015a)
% newer ML versions have a better "arrayfun" method that can directly produce arrays of any type
%
function axElemOut = i_arrayfun(hFunc, axElemIn)
axElemOut = i_cell2mat(arrayfun(hFunc, axElemIn, 'uni', false));
end


%%
% needed as a workaround helper for i_arrayfun
%
function axElem = i_cell2mat(caxElem)
caxElem(cellfun(@isempty, caxElem)) = []; % remove the empty elements from the cell array
if isempty(caxElem)
    axElem = [];
else
    nElem = numel(caxElem);
    axElem = reshape(caxElem{1}, 1, []);
    for i = 2:nElem
        axElem = [axElem, reshape(caxElem{i}, 1, [])]; %#ok<AGROW>
    end
end
end
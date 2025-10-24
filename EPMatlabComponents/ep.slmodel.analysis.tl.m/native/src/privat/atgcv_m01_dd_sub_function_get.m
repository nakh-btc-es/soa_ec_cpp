function stFunc = atgcv_m01_dd_sub_function_get(stEnv, hSub, sFuncKind)
% Find a certain kind of function that corresponds to the provided Subsystem.
%
% function stFunc = atgcv_m01_dd_sub_function_get(stEnv, hSub, sFuncKind)
%
%   INPUT           DESCRIPTION
%     stEnv            (struct)     error/result environment
%     hSub             (handle)     handle of subsystem
%     sFuncKind        (string)     optional: 'step' (== default) | 'proxy'
%
%   OUTPUT          DESCRIPTION
%     stFunc           (struct)   struct containing info with following data
%        .sName          (string)   name of the function (might be empty if not found)
%        .hFunc          (handle)   corresponding function handle
%        .hFuncInstance  (handle)   corresponding handle of function instance
%        .sModuleName    (string)   name of the containing C-file
%        .sStorage       (string)   storage class of the function:
%                                   'global' (== default) | 'static' | 'extern'
%        .bIsMapped      (boolean)  flag if the function instance has a 1:1 mapping to the model (inside ModelView area)
%


%%
if (nargin < 3)
    sFuncKind = 'step';
end

%%
if ischar(hSub)
    hSub = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hSub, 'hDDObject');
end

hFuncInstance = i_getFuncInstanceFromSub(stEnv, hSub);
switch lower(sFuncKind)
    case 'step'
        stFunc = i_getStepFunction(stEnv, hFuncInstance);
        
    case 'proxy'
        stFunc = i_getProxyFunction(stEnv, hFuncInstance);
        
    otherwise
        error('ATGCV:MOD_ANA:INTERNAL', 'unknown function kind "%s"', sFuncKind);
end
stFunc.bIsMapped = i_isFunctionInstanceMappedToModel(stEnv, hFuncInstance);
end


%%
function stFunc = i_getStepFunction(stEnv, hFuncInstance)
stFunc = i_getInfoFromFuncInstance(stEnv, hFuncInstance);
end


%%
function stInfo = i_getInfoFromFuncInstance(stEnv, hFuncInstance)
stInfo = struct( ...
    'sName',         '', ...
    'hFunc',          [], ...
    'hFuncInstance',  hFuncInstance, ...
    'sModuleName',    '', ...
    'sModuleType',    '', ...
    'sStorage',       '');
if ~isempty(hFuncInstance)
    stInfo.hFunc = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hFuncInstance, 'hDDParent');
    stInfo.sName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', stInfo.hFunc, 'name');
    [stInfo.sModuleName, stInfo.sModuleType] = ep_dd_function_module_get(stInfo.hFunc);
    stInfo.sStorage = i_getStorageType(stEnv, stInfo.hFunc);
end
end


%%
function stFunc = i_getProxyFunction(stEnv, hFuncInstance)
hProxyInstance = i_getProxyInstanceFromFuncInstance(stEnv, hFuncInstance);
if (~isempty(hProxyInstance) && (atgcv_version_p_compare('TL4.1') >= 0))
    % for TL4.1 we can have Wrapper Tasks which represent Proxies of Proxies
    hProxyWrapper = i_getProxyInstanceFromFuncInstance(stEnv, hProxyInstance);
    if ~isempty(hProxyWrapper)
        hProxyInstance = hProxyWrapper;
    end
end
stFunc = i_getInfoFromFuncInstance(stEnv, hProxyInstance);
end


%%
function hFuncInstance = i_getFuncInstanceFromSub(stEnv, hSub)
[bExist, hGroupInfo] = dsdd('Exist', 'GroupInfo', ...
    'Parent',   hSub, ...
    'Property', {'Name', 'FunctionInstanceRef'});
if bExist
    hFuncInstance = atgcv_mxx_dsdd(stEnv, 'Get', hGroupInfo, 'FunctionInstanceRef');
else
    hFuncInstance = i_getFuncInstanceByBlockRef(stEnv, hSub);
end
end


%%
function hFuncInstance = i_getFuncInstanceByBlockRef(stEnv, hSub)
hFuncInstance = [];

hRefTlSub = i_getReferencedTlSubsystem(hSub);
if ~isempty(hRefTlSub)
    sModelPathOfRefBlock = dsdd_get_block_path(hSub);
    hFuncInstance = i_getFuncInstanceFromSubsystemInfo(stEnv, hRefTlSub, sModelPathOfRefBlock);
    if isempty(hFuncInstance)
        hFuncInstance = i_getFuncInstanceFromModelView(stEnv, hRefTlSub);
    end
end
end


%%
function hFuncInstance = i_getFuncInstanceFromModelView(stEnv, hTlSubsystem)
hFuncInstance = [];

hModelView = atgcv_mxx_dsdd(stEnv, 'Find', hTlSubsystem, ...
    'name',       'ModelView', ...
    'objectKind', 'BlockGroup');
if ~isempty(hModelView)
    hFuncInstance = i_getFuncInstanceFromSub(stEnv, hModelView);
end
end


%%
function hFuncInstance = i_getFuncInstanceFromSubsystemInfo(stEnv, hTlSubsystem, sModelPathOfRefBlock)
hFuncInstance = [];

ahSubInfos = atgcv_mxx_dsdd(stEnv, 'GetSubsystemInfo', hTlSubsystem);
for i = 1:numel(ahSubInfos)
    hSubInfo = ahSubInfos(i);
    if strcmpi(i_getFullModelPathForReusable(stEnv, hSubInfo), sModelPathOfRefBlock)
        hFuncInstance = atgcv_mxx_dsdd(stEnv, 'GetInstanceDataRef', hSubInfo);
        return;
    end
end
end


%%
function sFullModelPath = i_getFullModelPathForReusable(stEnv, hSubInfo)
sFullModelPath = '';

bExist = dsdd('Exist', hSubInfo, 'property', {'Name', 'Reusable'});
if bExist
    sFullModelPath = atgcv_mxx_dsdd(stEnv, 'GetFullModelElementPath', hSubInfo);
end
end


%%
function hRefSub = i_getReferencedTlSubsystem(hSubBlock)
hRefSub = [];
try
    if strcmp(dsdd('GetAttribute', hSubBlock, 'objectKind'), 'Block')
        hRefSub = dsdd('GetSubsystemSubsystemRefTarget', hSubBlock);
    end
catch
    % nothing to do
end
end


%%
function hProxyInstance = i_getProxyInstanceFromFuncInstance(~, hFuncInstance)
hProxyInstance = [];

[bExist, hCallers] = dsdd('Exist', 'Callers', 'Parent', hFuncInstance);
if bExist
    stProp = dsdd('GetAll', hCallers);
    if isstruct(stProp)
        casFields = fieldnames(stProp);
        for i = 1:length(casFields)
            hProxyCandidate = stProp.(casFields{i});
            if i_isProxy(hProxyCandidate)
                hProxyInstance = hProxyCandidate;
                return;
            end
        end
    end
end
end


%%
function bIsProxy = i_isProxy(hFuncInstance)
bIsProxy = false;
if ~isempty(hFuncInstance)
    hFunc = dsdd('GetAttribute', hFuncInstance, 'hDDParent');
    bIsProxy = i_isRteSimFrameFunc(hFunc) && i_isStepFunc(hFunc);    
end
end


%%
function bIsRteSimFrameFunc = i_isRteSimFrameFunc(hFunc)
bIsRteSimFrameFunc = logical(dsdd('GetIsRteFrameFunction', hFunc));
end


%%
function bIsStepFunc = i_isStepFunc(hFunc)
bIsStepFunc = strcmpi(dsdd('GetFunctionKind', hFunc), 'StepFcn');
end


%%
function sStorage = i_getStorageType(stEnv, hFunc)
sStorage = 'global';

hFuncClass = atgcv_mxx_dsdd(stEnv, 'GetFunctionClass', hFunc);
if ~isempty(hFuncClass)
    sStorage = atgcv_mxx_dsdd(stEnv, 'GetStorage', hFuncClass);
end
if (isempty(sStorage) || strcmpi(sStorage, 'default'))
    sStorage = 'global';
end    
end


%%
% checks if the function instance has a 1:1 mapping to the model (some subsystem node inside the ModelView area)
% 1) go to model block M from function instance F
% 2) go from model block M to function instance F'
% 3) check if F and F' are the same
function bIsMapped = i_isFunctionInstanceMappedToModel(stEnv, hFuncInstance)
bIsMapped = false;
if dsdd('Exist', hFuncInstance, 'property', 'BlockGroupRef')
    hBlockGroup = atgcv_mxx_dsdd(stEnv, 'GetBlockGroupRefTarget', hFuncInstance, -1);
    if ~isempty(hBlockGroup)
        hFuncInstanceRef = atgcv_mxx_dsdd(stEnv, 'GetGroupInfoFunctionInstanceRefTarget', hBlockGroup);
        if ~isempty(hFuncInstanceRef)
            bIsMapped = (hFuncInstance == hFuncInstanceRef);
        end
    end
else
    % note: Stateflow charts have BlockRef instead of BlockGroupRef and we assume they are always mapped
    bIsMapped = true;
end
end


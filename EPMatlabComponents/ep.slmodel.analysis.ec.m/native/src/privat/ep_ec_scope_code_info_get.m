function stCodeInfo = ep_ec_scope_code_info_get(xScope)
% Return code mapping information for the provided scope (Note: currently restricted to model level).
%
%


%%
if (nargin < 1)
    xScope = bdroot();
end
sScope = getfullname(xScope);
if ~i_isModel(sScope)
    error('EP:INTERNAL:ERROR', 'Please provide a valid model as scope.');
end

% Get Code Descriptor information for ML2021a and higher; for lower ML versions go via RTW Information
if verLessThan('matlab', '9.10')
    stCodeInfo = i_getModelCodeInfoViaRTW(sScope);
else
    stCodeInfo = i_getModelCodeInfoViaCodeDescriptor(sScope);
end
end


%%
function stCodeInfo = i_getModelCodeInfoViaRTW(sModelName)
stCodeInfo = struct( ...
    'bIsValid',   false, ...
    'sStepFunc',  '', ...
    'sInitFunc',  '', ...
    'mPort2Var',  containers.Map);

oProto = RTW.getFunctionSpecification(sModelName);
if ~isempty(oProto)
    stCodeInfo.sStepFunc = oProto.getFunctionName();
    stCodeInfo.sInitFunc = oProto.getPropValue('InitFunctionName');
    
    aoArgs = oProto.ArgSpecData;
    for i = 1:numel(aoArgs)
        oArg = aoArgs(i);
        
        sObjectType = oArg.SLObjectType;
        if any(strcmp(sObjectType, {'Inport', 'Outport'}))
            sPortName = oArg.SLObjectName;
            sVarName = oArg.ArgName;
            stCodeInfo.mPort2Var(sPortName) = sVarName;
        end
    end
    if ~isempty(stCodeInfo.sStepFunc)
        stCodeInfo.bIsValid = true;
    end
end
end


%%
function stCodeInfo = i_getModelCodeInfoViaCodeDescriptor(sModelName)
stCodeInfo = struct( ...
    'bIsValid',   false, ...
    'sStepFunc',  '', ...
    'sInitFunc',  '', ...
    'mPort2Var',  containers.Map);

try
    oCD = Eca.cd.CodeDescriptor(sModelName);
    oModel = oCD.getRootModel();
    
    oInitFunc = i_getFirst(oModel.getInitializeFunctions());
    if ~isempty(oInitFunc)
        stCodeInfo.sInitFunc = oInitFunc.getName();
    end
    oStepFunc = i_getFirst(oModel.getOutputFunctions());
    if ~isempty(oStepFunc)
        stCodeInfo.sStepFunc = oStepFunc.getName();
        i_fillArgumentsMap(stCodeInfo.mPort2Var, oModel, oStepFunc);
        stCodeInfo.bIsValid = true;
    end
    
catch oEx
    % might be that code was not generated yet and CodeDescriptor is not available
    warning('EP:MODEL_CODE_INFO:CODE_DESC_FAILED', 'Information about model step function not available:\n%s', ...
        oEx.getReport('basic', 'hyperlinks', 'off'));
    stCodeInfo = i_getModelCodeInfoViaRTW(sModelName);
end
end


%%
function bIsModel = i_isModel(sScope)
bIsModel = strcmp(sScope, bdroot(sScope));
end


%%
function xElem = i_getFirst(caxElems)
if isempty(caxElems)
    xElem = [];
else
    xElem = caxElems{1};
end
end


%%
function i_fillArgumentsMap(mPort2Var, oModel, oStepFunc)
casArgNames = cellfun(@(o) o.getName(), oStepFunc.getArguments, 'UniformOutput', false);
if ~isempty(casArgNames)
    jKnownArgs = java.util.HashSet;
    for i = 1:numel(casArgNames)
        jKnownArgs.add(casArgNames{i});
    end

    i_fillArgumentsMapForPorts(mPort2Var, jKnownArgs, oModel.getInports());
    i_fillArgumentsMapForPorts(mPort2Var, jKnownArgs, oModel.getOutports());
end
end


%%
function i_fillArgumentsMapForPorts(mPort2Var, jKnownArgs, caoPorts)
for i = 1:numel(caoPorts)
    oPort = caoPorts{i};
    
    oImpl = oPort.getImplementation();
    stInfo = oImpl.getInfo();
    if jKnownArgs.contains(stInfo.Identifier)
        mPort2Var(oPort.getName()) = stInfo.Identifier;
    end
end
end


function stDebug = atgcv_m01_debug_interface_get(xInput)
% Debugging the interface analysis for Subsystems on Model and Code level.

%%
if (nargin < 1)
    xInput = gcb;
end
if ischar(xInput)
    xInput = i_getHandleFromDD(xInput);
end

%%
% shortcut for debugging just the combine part: input is the output of the previous debug run
if isstruct(xInput)
    stDebug = xInput;
    stDebug.stInterface = ...
        atgcv_m01_combine_interfaces(0, stDebug.stFuncIF, stDebug.stSubIF, stDebug.stCompIF);
    return;
end


%%
hSubOrFuncInstance = xInput;
sObjKind = dsdd('GetAttribute', hSubOrFuncInstance, 'objectKind');
bIsSF = false;
switch sObjKind
    case 'FunctionInstance'
        hFuncInstance = hSubOrFuncInstance;
        hSub = dsdd('GetBlockGroupRef', hFuncInstance, 0);
        
    case 'BlockGroup'
        hSub = hSubOrFuncInstance;
        [bExist, hGroupInfo] = dsdd('Exist', 'GroupInfo', ...
            'Parent',   hSub, ...
            'Property', {'Name', 'FunctionInstanceRef'});
        if ~bExist
            error('EP:DEV_DEBUG:ERROR', 'Provided DD subsystem has no reference to a step function.');
        end
        hFuncInstance = dsdd('Get', hGroupInfo, 'FunctionInstanceRef');

    case 'Block'
        % SF-Chart
        bIsSF = true;
        hFuncInstance = dsdd('GetStepFunctionInstanceRef', dsdd('GetStateflowNodes', xInput));
        hSub = xInput;
        
    otherwise
        error('EP:DEV_DEBUG:ERROR', 'DD Object kind "%s" is not supported.', sObjKind);
end

sSubPath = dsdd_get_block_path(hSub);
stFuncIF = atgcv_m01_function_interface_get(0, hFuncInstance);
if bIsSF
    stSubIF = atgcv_m01_chart_interface_get(0, hSub);
else
    stSubIF = atgcv_m01_subsystem_interface_get(0, hSub);
end
stCompIF = atgcv_m01_compiled_info_get(0, {sSubPath});

stInterface = atgcv_m01_combine_interfaces(0, stFuncIF, stSubIF, stCompIF);

stDebug = struct( ...
    'sSubPath', sSubPath, ...
    'stInterface', stInterface, ...
    'stFuncIF', stFuncIF, ...
    'stSubIF', stSubIF, ...
    'stCompIF', stCompIF);
end


%%
function hDD = i_getHandleFromDD(sSomePath)
[bExist, hDD] = dsdd('Exist', sSomePath);
if bExist
    return;
end
try
    sBlockType = get_param(sSomePath, 'BlockType');
catch oEx
    error('EP:DEV_DEBUG:ERROR', 'Invalid model path "%s". Cannot determine DD handle.', sSomePath);
end
if ~strcmp(sBlockType, 'SubSystem')
    error('EP:DEV_DEBUG:ERROR', 'Model block "%s" is not a subsystem. Cannot determine DD handle.', sSomePath);
end
sName = get_param(sSomePath, 'Name');

% try to find a Subsystem inside the DD with the same name
ahGroupDD = dsdd('Find', '/Subsystems', 'Name', 'GroupInfo', 'Property', {'Name', 'GroupName', 'Value', sName});
if (length(ahGroupDD) == 1)
    hDD = dsdd('GetAttribute', ahGroupDD(1), 'hDDParent');
end
if isempty(ahGroupDD)
    % try SF-Charts as alternative
    ahSfCharts = dsdd('Find', '/Subsystems', ...
        'objectKind', 'Block', ...
        'Name', sName, ...
        'Property', {'Name', 'BlockType', 'Value', 'Stateflow'});
    if (length(ahSfCharts) == 1)
        hDD = ahSfCharts(1);
    end
end
end


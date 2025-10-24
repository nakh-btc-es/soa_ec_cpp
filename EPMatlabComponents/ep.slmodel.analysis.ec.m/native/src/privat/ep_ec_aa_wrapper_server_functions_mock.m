function stMockModel = ep_ec_aa_wrapper_server_functions_mock(stArgs)
% Creates an export function model containing all server function mocks
%
%  function ep_ec_aa_wrapper_server_functions_mock(stModel, sToplevelName)
%
%  INPUT                        DESCRIPTION
%
%         stArgs
%             - sOrigModelName         The name of the original model
%             - sTagetPath             The location where the mock server model shall be placed
%             - aoRequiredMethods      The functions for which a mock must be created
%             - oWrapperConfig         The wrapper model configuration data object
%             - oWrapperData           The wrapper model data storage object
%
%  OUTPUT                       DESCRIPTION
%    - stMockModel
%         .hModel                (handle)  Handle of the created wrapper model (might be empty if not successful)
%         .sName                 (string)  Name of the created wrapper model
%         .sModelFile            (string)  Full path to the created wrapper model (might be empty if not successful)
%         .casServerMockNames    (cell)    Cell array containing the names of the server mocks
%         .ahServerMocks         (array)   Array containing the handles of the server mocks
%
%



%%
sServerMockModelName = ['W_server_mock_' stArgs.sOrigModelName];
stMockModel = struct( ...
    'hModel',              [], ...
    'sName',               sServerMockModelName, ...
    'sModelFile',          '', ...
    'casServerMockNames',  {{}}, ...
    'ahServerMocks',       []);

try
    stMockModel.hModel = i_createServerMockModel(sServerMockModelName, stArgs.oWrapperConfig, stArgs.oWrapperData);

    iReqMethAmount = numel(stArgs.aoRequiredMethods);
    stMockModel.casServerMockNames = cell(1, iReqMethAmount);
    ahServerMocks = zeros(1, iReqMethAmount);

    for i = 1:iReqMethAmount
        [stMockModel.casServerMockNames{i}, ahServerMocks(i)] = ...
            i_createMockServerFunctions(stMockModel.hModel, stArgs.aoRequiredMethods(i), stArgs.oWrapperData);
    end

    i_layoutServerMocks(ahServerMocks, sServerMockModelName);

    % Save model
    stMockModel.sModelFile = fullfile(stArgs.sTargetPath, [sServerMockModelName, '.slx']);
    Eca.aa.wrapper.Utils.saveModel(sServerMockModelName, stMockModel.sModelFile);

catch oEx
    i_cleanupAfterAbort(stMockModel.hModel);
    rethrow(oEx);
end
end


%%
function i_layoutServerMocks(ahServerMocks, sModelName)
aiIntegrationModelPosition = [500         100        1300         340];

% aiIntegrationModelPosition = get_param(hModelRefIntegrationModel, 'Position');
if numel(ahServerMocks) > 0
    ep_ec_ui_arrange_blocks([aiIntegrationModelPosition(1)-23, aiIntegrationModelPosition(4)+29], ahServerMocks, "top_down", [220 75], 46, [7, 3]);
    aiLastServerMockPosition = get_param(ahServerMocks(end), 'Position');
    aiBorders = [aiIntegrationModelPosition(1), aiIntegrationModelPosition(4)+25, aiIntegrationModelPosition(3), aiLastServerMockPosition(4)+25];
    iBorderWidth = 1;
    ep_ec_ui_create_bordered_area(aiBorders, [0.11 0.34 0.51], sModelName, iBorderWidth, '');
    ep_ec_ui_create_label(sModelName, [aiBorders(1)+iBorderWidth+3, aiBorders(2)+iBorderWidth+1, aiBorders(3)+iBorderWidth+1+133, aiBorders(4)+iBorderWidth+1+30], 'Server Function Mocks', '#1d5781');
end

for i = 1:numel(ahServerMocks)
    set_param(ahServerMocks(i), 'ShowName', 'off');
    set_param(ahServerMocks(i), 'ForegroundColor', '[0.11 0.34 0.51]');
end
end


%%
function [sFunName, hSlFunBlk] = i_createMockServerFunctions(hServerMockModel, oRequiredMethod, oWrapperData)
sPortName = oRequiredMethod.sArPortName;
jDataStoreHashSet = java.util.HashSet();

sOrigFuncName = oRequiredMethod.getMethodName();
sFunName = oRequiredMethod.getCodeGlobalFunction();
sSlFuncBlkName = ['Mock_' sFunName];

%Add Simulink Function block
hSlFunBlk = add_block('simulink/User-Defined Functions/Simulink Function', ...
    [getfullname(hServerMockModel) '/' sSlFuncBlkName]);
set(hSlFunBlk, 'ForegroundColor', 'Blue');

% Set Function name and visibility
hTriggerBlk = ep_find_system(hSlFunBlk, 'BlockType', 'TriggerPort', 'IsSimulinkFunction', 'on');
set_param(hTriggerBlk, 'FunctionName', sFunName);
set_param(hTriggerBlk, 'ScopeName', oRequiredMethod.sArPortName);
set_param(hTriggerBlk, 'FunctionVisibility', 'global');
set_param(hTriggerBlk, 'Name', sFunName);

% delete line in the added default block from the SL library
ahLines = ep_find_system(hSlFunBlk, 'FindAll', 'on', 'Type', 'Line');
for i = 1:numel(ahLines)
    delete_line(ahLines(i));
end

i_addFunctionArgsAndConnectDataStoreBlocks(hSlFunBlk, 'ArgIn', sOrigFuncName,  oRequiredMethod.aoFunctionInArgs, oWrapperData, jDataStoreHashSet, sPortName);
i_addFunctionArgsAndConnectDataStoreBlocks(hSlFunBlk, 'ArgOut', sOrigFuncName, oRequiredMethod.aoFunctionOutArgs, oWrapperData, jDataStoreHashSet, sPortName);
end


%%
function i_addFunctionArgsAndConnectDataStoreBlocks(hSlFunBlk, sArgType, sOrigFuncName,  aoFunctionArgs, oWrapperData, jDataStoreHashSet, sPortName )
hDummyArgLibBlk = i_getLibArgs(hSlFunBlk, sArgType);
aiPos = get_param(hDummyArgLibBlk, 'Position');
delete_block(hDummyArgLibBlk);

if ~isempty(aoFunctionArgs)
    iWidth = aiPos(3)-aiPos(1);
    iHeight = aiPos(4)-aiPos(2);
    if strcmp(sArgType, 'ArgOut')
        aiPos(1) = aiPos(1) + 100; %shift block further more on right side
        aiPos(3) = aiPos(3) + 100;
    end

    sSlFunPath = getfullname(hSlFunBlk);
    cntArg = 0;
    for iArg = 1:numel(aoFunctionArgs)
        oArg = aoFunctionArgs(iArg);

        cntArg = cntArg+1;
        sFuncArgName = oArg.sName;
        sArgPortName = [sArgType '_' sFuncArgName];
        aiPos = [aiPos(1) aiPos(2)+iHeight+(20)*iArg aiPos(1)+iWidth aiPos(2)+2*iHeight+(20)*iArg];
        sArgLibBlk = [sSlFunPath '/' sPortName];

        hArgBlk = add_block(['built-in/' sArgType], sArgLibBlk, 'ArgumentName', sFuncArgName, 'Name', sArgPortName);
        set(hArgBlk, 'Position', aiPos);
        sArgBlk = getfullname(hArgBlk);
        sArgsDT = oArg.sOutDataTypeStr;
        set_param(sArgBlk, 'OutDataTypeStr', sArgsDT);

        sDimForSetting = oArg.getDimForPortAttributeSetting;
        set_param(sArgBlk, 'PortDimensions', sDimForSetting);

        sDSBlockName = [sPortName '_' sOrigFuncName '_' sFuncArgName];

        if strcmp(sArgType, 'ArgOut')
            nDSPos = [aiPos(1)-(aiPos(3)-aiPos(1))-20 aiPos(2) aiPos(3)-(aiPos(3)-aiPos(1))-20 aiPos(4)];
            sDSBlockName = [sDSBlockName '_Out'];   %#ok<AGROW>
            sDSBlockType = 'Data Store Read';
        else
            nDSPos = [aiPos(1)+iWidth+20 aiPos(2) aiPos(3)+iWidth+20 aiPos(4)];
            sDSBlockName = [sDSBlockName '_In'];    %#ok<AGROW>
            sDSBlockType = 'Data Store Write';
        end

        hDSBlock = add_block(['simulink/Signal Routing/' sDSBlockType], [sSlFunPath '/' sDSBlockName]);
        set(hDSBlock, 'Position', nDSPos);

        [sDSName, bHashDuplication] = ep_ec_aa_wrapper_hash_create(sDSBlockName, jDataStoreHashSet);
        sDSName = ['s_' sDSName]; %#ok
        if bHashDuplication
            warning('EP:ECAA_WRAPPER:HASH_DUPLICATE', 'Detected duplicate hashing result from DataStore block name: %s', sDSBlockName);
        end

        set(hDSBlock, 'DataStoreName', sDSName);

        if strcmp(sArgType, 'ArgOut')
            add_line(sSlFunPath, [sDSBlockName '/1'], [sArgPortName '/1'], 'autorouting', 'on');
        else
            add_line(sSlFunPath, [sArgPortName '/1'], [sDSBlockName '/1'], 'autorouting', 'on');
        end

        sDSDataType = oArg.getDataTypeForDataStoreSignals;
        oWrapperData.createAndPersistDataStoreSignal(sDSName, sDSDataType, oArg.getVariableStyleDim, sDSBlockName);
    end
end
end


%%
function hArgLibBlk = i_getLibArgs(hFunCallerBlk, sType)
hArgLibBlk = ep_find_system(hFunCallerBlk, 'BlockType', sType);
end


%%
function hServerMockModel = i_createServerMockModel(sServerMockModelName, oWrapperConfig, oWrapperData)
hServerMockModel = Eca.aa.wrapper.Utils.createModel(sServerMockModelName, Eca.aa.wrapper.Tag.ServerFunctionsMock);

set_param(hServerMockModel, 'SetExecutionDomain', 'on');
set_param(hServerMockModel, 'ExecutionDomainType', 'ExportFunction');

i_setModelConfigAndDataDictionary(sServerMockModelName, oWrapperConfig, oWrapperData.sFileDD);
end


%%
function i_cleanupAfterAbort(hModel)
if ~isempty(hModel)
    try %#ok<TRYNC>
        close_system(hModel, 0);
    end
end
end


%%
function i_setModelConfigAndDataDictionary(sModelName, oWrapperConfigSet, sFileDD)
oOwnConfigSet = copy(oWrapperConfigSet);

% rename the config set to wrapper-specific name
sWrapperConfigName = 'WrapperServerMockModelConfigSet';
set_param(oOwnConfigSet, 'Name', sWrapperConfigName);

set_param(oOwnConfigSet, 'CustomSourceCode', '');
set_param(oOwnConfigSet, 'CustomInitializer', '');

set_param(oOwnConfigSet, 'ModelReferenceNumInstancesAllowed', 'Single');

attachConfigSet(sModelName, oOwnConfigSet);
setActiveConfigSet(sModelName, get_param(oOwnConfigSet, 'Name'));

if ~isempty(sFileDD)
    [~, f, e] = fileparts(sFileDD);
    set_param(sModelName, 'DataDictionary', [f, e]);
end
end


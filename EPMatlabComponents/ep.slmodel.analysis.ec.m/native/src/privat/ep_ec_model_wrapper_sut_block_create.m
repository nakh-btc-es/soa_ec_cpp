function stResult = ep_ec_model_wrapper_sut_block_create(varargin)
% Creates a wrapper model for AUTOSAR models that can be used as testing framework.
%
% function stResult = ep_ec_model_wrapper_create(varargin)
%
%  INPUT              DESCRIPTION
%    varargin           ([Key, Value]*)  Key-value pairs with the following possibles values
%
%    Allowed Keys:            Meaning of the Value:
%    - Model                    (handle/string)*  Name or handle to AUTOSAR model. Model is assumed to be open.
%    - WrapperName              (string)          Name of the wrapper to be created (default == "Wrapper_<model>")
%    - OpenWrapper              (boolean)         Shall model be open after creation?
%    - Overwrite                (boolean)         Shall existing files be overwritten during creation?
%    - Progress                 (object)          Object for tracking progress.
%
%  OUTPUT            DESCRIPTION
%    stResult                   (struct)          Return values ( ... to be defined)
%      .sWrapperModel           (string)            Full path to created wrapper model. (might be empty if not
%                                                   successful)
%      .sWrapperInitScript      (string)            Full path to created init script. (might be empty if not
%                                                   successful or if not created)
%      .sWrapperDD              (string)            Full path to created SL DD. (might be empty if not
%                                                   successful or if not created)
%      .bSuccess                (bool)              Was creation successful?
%      .casErrorMessages        (cell)              Cell containing warning/error messages.


%%
% evaluating and checking inputs
stArgs = i_evalArgs(varargin{:});
stResult = i_createVariantSubsystem(stArgs.hTargetModel, stArgs.hOrigModel);
end


%%
function [hVariantSub, hOrigModelRef, astInports, astOutports] = i_addVariantSub(hTargetModel, hOrigModel)
hOrigModelRef = i_createMainModelRefBlock(hTargetModel, hOrigModel);
if verLessThan('matlab', '23.2') %#ok<VERLESSMATLAB>
    hVariantSub = Simulink.VariantManager.convertToVariant(hOrigModelRef); %#ok<SVM2SUB>
else
    hVariantSub = Simulink.VariantUtils.convertToVariantSubsystem(hOrigModelRef);
end
i_formatSUTBlock(hVariantSub);
% note: variant conditions must be visible outside of the subsystem,
% otherwise the wrapper can't be validated
set_param(hVariantSub, 'PropagateVariantConditions', 'on');

[ahInports, ahOutports] = i_getPorts(hOrigModel);
astInports  = arrayfun(@i_getPortInfo, ahInports);
astOutports = arrayfun(@i_getPortInfo, ahOutports);

mInportNumToInfoIdx = containers.Map();
for i = 1:numel(ahInports)
    mInportNumToInfoIdx(get_param(ahInports(i), 'Port')) = i;
    stPortDim = get_param(ahInports(i), 'CompiledPortDimensions');
    astInports(i).nDim = i_getPortDim(stPortDim.Outport);
end

mOutportNumToInfoIdx = containers.Map();
for i = 1:numel(ahOutports)
    mOutportNumToInfoIdx(get_param(ahOutports(i), 'Port')) = i;
    stPortDim = get_param(ahOutports(i), 'CompiledPortDimensions');
    astOutports(i).nDim = i_getPortDim (stPortDim.Inport);
end

stPortHandles = get_param(hVariantSub, 'PortHandles');

[ahVarInports, ahVarOutports] = i_getPorts(hVariantSub);
for i = 1:numel(ahVarInports)
    hVarPortBlock = ahVarInports(i);
    
    sPort = get_param(hVarPortBlock, 'Port');
    iIdx = mInportNumToInfoIdx(sPort);
    if ~isempty(iIdx)
        % note: the SL command "Simulink.VariantManager.convertToVariant" is introducing artificial whitespaces in
        % port-names --> repair these names to get *exactly* the same name as the original one!
        set_param(hVarPortBlock, 'Name', astInports(iIdx).sName);
        
        nPort = sscanf(sPort, '%d');
        astInports(iIdx).hVariantPort = stPortHandles.Inport(nPort);
    else
        error('EP:UNEXPECTED:NOMATCH_PORT_NUM', ...
            'Variant Inport "%s" not found in original model.', get_param(hVarPortBlock, 'Name'));
    end
end
for i = 1:numel(ahVarOutports)
    hVarPortBlock = ahVarOutports(i);
    sPort = get_param(hVarPortBlock, 'Port');
    iIdx = mOutportNumToInfoIdx(sPort);
    if ~isempty(iIdx)
        % note: the SL command "Simulink.VariantManager.convertToVariant" is introducing artificial whitespaces in
        % port-names --> repair these names to get *exactly* the same name as the original one!
        set_param(hVarPortBlock, 'Name', astOutports(iIdx).sName);
        
        nPort = sscanf(sPort, '%d');
        astOutports(iIdx).hVariantPort = stPortHandles.Outport(nPort);
    else
        error('EP:UNEXPECTED:NOMATCH_PORT_NUM', ...
            'Variant Outport "%s" not found in original model.', get_param(hVarPortBlock, 'Name'));
    end
end
end


%%
function hMainModelRef = i_createMainModelRefBlock(hTopLevelModel, sMainModelName)
hMainModelRef = i_createModelRefBlock(hTopLevelModel, sMainModelName);
set(hMainModelRef, 'Tag', ep_ec_tag_get('AUTOSAR Main ModelRef'));
end


%%
function stResult = i_createVariantSubsystem(hTargetModel, hOrigModel)
[hVariantSub, hOrigModelRef, astInports, astOutports] = i_addVariantSub(hTargetModel, hOrigModel);

adModelRefPos = get_param(hOrigModelRef, 'Position');
dHeight = adModelRefPos(4) - adModelRefPos(2);
dDistance = 40 + dHeight;
adDummySubPos = adModelRefPos + [0, dDistance, 0, dDistance];

sDummyName = ['dummy_', get_param(hOrigModelRef, 'Name')];
hDummySub = i_dummySubsystemAdd(hVariantSub, sDummyName, adDummySubPos, hOrigModel);

i_setVariantConfigForVariantSubsystem(hVariantSub, hOrigModelRef, hDummySub);


mTriggRunnables = i_getRunnableTrigMap(get_param(hOrigModel, 'Name'));
mRunnableSymbols = i_getRunnableSymbols(get_param(hOrigModel, 'Name'));
stArgs = struct( ...
    'Scope',            hDummySub, ...
    'mTriggRunnables',  mTriggRunnables, ...
    'mRunnableSymbols', mRunnableSymbols, ...
    'astInports',       astInports, ...
    'astOutports',      astOutports);
[ahBlkBlackListRunnable, cahBlksBlackListInRunnable] = ep_ec_autosar_scope_reduce(stArgs);

casParamNames = i_getModelArguments(hOrigModelRef);
if ~isempty(casParamNames)
    i_copyModelParameterArguments(hTargetModel, hOrigModel, casParamNames);
    mParamToMaskParam = i_createMaskParams(hVariantSub, casParamNames, get_param(hOrigModel, 'Name'));
    i_setArgumentValues(hOrigModelRef, mParamToMaskParam);
end

stResult = struct( ...
    'hVariantSub',   hVariantSub, ...
    'hOrigModelRef', hOrigModelRef, ...
    'hDummySub',     hDummySub, ...
    'astInports',    astInports, ...
    'astOutports',   astOutports, ...
    'ahBlkBlackListRunnable', ahBlkBlackListRunnable, ...
    'cahBlksBlackListInRunnable', {cahBlksBlackListInRunnable});
end


%%
function i_formatSUTBlock(hHandle)
aiPosition = get_param(hHandle, 'Position');
iMinBlockHeight = 180;
iHeight = aiPosition(4)-aiPosition(2);
if iHeight < iMinBlockHeight
    aiPosition(4) = aiPosition(4) + iMinBlockHeight - iHeight;
end
set_param(hHandle, 'Position', aiPosition)
i_createBTCMask(hHandle);
end


%%
function i_createBTCMask(hBlock)

oMask = Simulink.Mask.create(hBlock);
oMask.addDialogControl( ...
    'Name',    'DescGroupVar', ...
    'Type',    'group', ...
    'Prompt',  'BTC Embedded Systems SUT block');
oMask.addDialogControl( ...
    'Name',    'DescTextVar', ...
    'Type',    'text', ...
    'Prompt',  'This is the BTC Embedded Systems SUT block, referencing the original AUTOSAR model.', ...
    'Container', 'DescGroupVar');
%Spaces are needed for formatting! Do not remove!
oMask.Display = ['disp(''\color{gray}\it\fontsize{20}                          embedded\newline' ...
    '                          systems'', ''texmode'', ''on'');disp(''{{\color{gray}\bf\fontsize{50}' ...
    '\it   BTC}  \fontsize{80}|      \color{black}\fontsize{20}\newline }'', ''texmode'',''on'');'];

end
%%
function casParamNames = i_getModelArguments(hOrigModelRef)
if verLessThan('Matlab', '9.6')
    stParamArgValues = get_param(hOrigModelRef, 'ParameterArgumentValues');
    casParamNames = fieldnames(stParamArgValues)';
else
    astInstanceParams = get_param(hOrigModelRef, 'InstanceParameters');
    casParamNames = {astInstanceParams.Name};
end
end


%%
function i_copyModelParameterArguments(hTargetModel, hOrigModel, casParamNames)
oOrigMWS = get_param(hOrigModel, 'ModelWorkspace');
oTargetMWS = get_param(hTargetModel, 'ModelWorkspace');
for i=1:numel(casParamNames)
    oParam = oOrigMWS.getVariable(casParamNames{i});
    if isa(oParam, 'AUTOSAR.Parameter') || ...
            isa(oParam, 'AUTOSAR4.Parameter')
        oParam = i_translateToSLParam(oParam);
    elseif isa(oParam, 'Simulink.LookupTable')
        if strcmp(oParam.BreakpointsSpecification, 'Reference')
            i_copyReferencedBreakpoints(oParam, oTargetMWS, oOrigMWS, hTargetModel);
        end
    end
    
    oTargetMWS.assignin(casParamNames{i}, oParam);
    set_param(hTargetModel, 'ParameterArgumentNames', '');
    oTargetMWS.getVariable(casParamNames{i}).CoderInfo.StorageClass = 'ExportedGlobal';
end
end


%%
function i_copyReferencedBreakpoints(oParam, oTargetMWS, oOrigMWS, hTargetModel)
for i = 1:numel(oParam.Breakpoints)
    oBPName = oParam.Breakpoints{i};
    oBreakpoints = oOrigMWS.getVariable(oBPName);
    oTargetMWS.assignin(oBPName, oBreakpoints);
    set_param(hTargetModel, 'ParameterArgumentNames', '');
    oTargetMWS.getVariable(oBPName).CoderInfo.StorageClass = 'ExportedGlobal';
end
end


%%
function oSlParam = i_translateToSLParam(oParam)

oSlParam = Simulink.Parameter;

oSlParam.Value = oParam.Value;
oSlParam.Description = oParam.Description;
oSlParam.DataType = oParam.DataType;
oSlParam.Min = oParam.Min;
oSlParam.Max = oParam.Max;
oSlParam.Unit = oParam.Unit;
oSlParam.Dimensions = oParam.Dimensions;
end


%%
function mParamToMaskParam = i_createMaskParams(hVariantSub, casParamNames, sModelName)

oMask = Simulink.Mask.get(hVariantSub);
iParamAmount = numel(casParamNames);
mParamToMaskParam = containers.Map;

if iParamAmount > 0
    oDescText = oMask.getDialogControl('DescTextVar');
    oDescText.Prompt = [oDescText.Prompt ' Model Parameter Arguments are listed below.'];
    oMask.addDialogControl( ...
        'Name', 'ParameterGroupVar', ...
        'Prompt', 'Model Parameter Arguments', ...
        'Type', 'group');
end

for i = 1:iParamAmount
    sParamName = casParamNames{i};

    % Note: For the mask parameters use the corresponding parameter name and prepend 'm_' as a prefix. However,
    % since the length of the variable name must not exceed 63, use an alternative pattern for long parameter names.
    if (numel(sParamName) < 62)
        sMaskParamName = ['m_' sParamName];   
    else
        sMaskParamName = ['m_' sParamName(3:end)];   
    end

    mParamToMaskParam(sParamName) = sMaskParamName;          
    oMask.addParameter( ...
        'Name',      mParamToMaskParam(sParamName), ...
        'Value',     sParamName, ...
        'Prompt',    [sModelName ':' sParamName], ...
        'Enabled',   'off', ...
        'Container', 'ParameterGroupVar');
    oMask.getParameter(mParamToMaskParam(casParamNames{i})).DialogControl.PromptLocation = 'left';
end

end


%%
function i_setArgumentValues(hOrigModelRef, mParamToMaskParam)

if verLessThan('Matlab', '9.6')
    stValues = get_param(hOrigModelRef, 'ParameterArgumentValues');
    casArgs = fieldnames(stValues);
    for i = 1:numel(casArgs)
        stValues.(casArgs{i}) = mParamToMaskParam(casArgs{i});
    end
    set_param(hOrigModelRef, 'ParameterArgumentValues', stValues);
else
    astValues = get_param(hOrigModelRef, 'InstanceParameters');
    for i = 1:numel(astValues)
        astValues(i).Value = mParamToMaskParam(astValues(i).Name);
    end
    set_param(hOrigModelRef, 'InstanceParameters', astValues);
end

end

%%
function mRunnableSymbols = i_getRunnableSymbols(sModelName)
mRunnableSymbols = containers.Map();
oArProps = autosar.api.getAUTOSARProperties(sModelName);
sArCmpPath = oArProps.get('XmlOptions','ComponentQualifiedName');
casRunArPaths = find(oArProps, sArCmpPath, 'Runnable', 'PathType', 'FullyQualified');
for k = 1:numel(casRunArPaths)
    sName = get(oArProps, casRunArPaths{k}, 'Name');
    sSymbol = get(oArProps, casRunArPaths{k}, 'symbol');
    mRunnableSymbols(sName) = sSymbol;
end
end

%%
function mRunnable = i_getRunnableTrigMap(sModelName)
oArSLMap = autosar.api.getSimulinkMapping(sModelName);

casRootFunCallTrig = ep_find_system(sModelName, ...
    'SearchDepth',        1, ...
    'BlockType',          'Inport', ...
    'OutputFunctionCall', 'on');
casRootFunCallTrigNames = get_param(casRootFunCallTrig, 'Name');

mRunnable = containers.Map();

for i = 1:numel(casRootFunCallTrigNames)
    try %#ok<TRYNC>
        if verLessThan('matlab' , '9.9') %#ok<VERLESSMATLAB>
            sExpFct = casRootFunCallTrigNames{i};
        else
            sExpFct = strcat('ExportedFunction:', casRootFunCallTrigNames{i});
        end
        sExportRunnableName = getFunction(oArSLMap, sExpFct);
        mRunnable(casRootFunCallTrigNames{i}) = sExportRunnableName;
    end
end
end


%%
function hDummySub = i_dummySubsystemAdd(hVariantSub, sDummyName, adPosition, hOrigModel)
hDummySub = add_block('built-in/SubSystem', [getfullname(hVariantSub), '/', sDummyName], 'Position', adPosition);
Simulink.BlockDiagram.copyContentsToSubsystem(get_param(hOrigModel, 'Name'), hDummySub);
end


%%
function i_setVariantConfigForVariantSubsystem(hVariantSub, hOrigModelRef, hDummySub)
sLabelOrig  = 'orig';
sLabelDummy = 'dummy';

set_param(hOrigModelRef, 'VariantControl', sLabelOrig);
set_param(hDummySub, 'VariantControl', sLabelDummy);

set_param(hVariantSub, 'OverrideUsingVariant', sLabelOrig);
set_param(hVariantSub, 'VariantControl', '');
end


%%
function hModelRef = i_createModelRefBlock(hTargetSub, hOrigModel)
sModelName = get_param(hOrigModel, 'Name');

%Add TopLevel SUT subsytems
hModelRef = add_block('built-in/ModelReference', [getfullname(hTargetSub), '/', sModelName]);
set(hModelRef, 'ModelName', sModelName);
set(hModelRef, 'SimulationMode', 'Normal');

%Adapt positions
P1_MDLREFBLK = 500; P2_MDLREFBLK = 100; MDLREFBLK_WIDTH = 1000;

anPortNumbers = get(hModelRef, 'Ports');
nMaxIOPorts = max(1, max(anPortNumbers(1), anPortNumbers(2)));
set(hModelRef, 'Position', [P1_MDLREFBLK, P2_MDLREFBLK, P1_MDLREFBLK + MDLREFBLK_WIDTH, P2_MDLREFBLK + 40*nMaxIOPorts]);
end


%%
function stPort = i_getPortInfo(hPortBlock)
stPort = struct( ...
    'sName',               get_param(hPortBlock, 'Name'), ...
    'bIsFunctionCall',     i_isFunctionCall(hPortBlock), ...
    'sOutDataTypeStr',     get_param(hPortBlock, 'OutDataTypeStr'), ...
    'hVariantPort',        [], ...
    'nPortNum',            sscanf(get_param(hPortBlock, 'Port'), '%d'), ...
    'sOutputAsVirtualBus', get_param(hPortBlock, 'BusOutputAsStruct'), ...
    'sSigName',            '', ...
    'nDim',                0);

% for Outport blocks we also need to store the signal name
if strcmp('Outport', get_param(hPortBlock, 'BlockType'))
    stPorts = get_param(hPortBlock, 'PortHandles');
    stPort.sSigName = ep_sl_signal_name_from_port_get(stPorts.Inport);
end
end


%%
function bIsFunctionCall = i_isFunctionCall(hPort)
bIsFunctionCall = false;

sBlockType = get_param(hPort, 'BlockType');
if strcmpi(sBlockType, 'Inport')
    bIsFunctionCall = strcmpi(get_param(hPort, 'OutputFunctionCall'), 'on');
end
end


%%
function [ahInports, ahOutports] = i_getPorts(hModelOrSub)
ahInports = ep_find_system(hModelOrSub, ...
    'SearchDepth',     1,...
    'LookUnderMasks',  'all',...
    'FollowLinks',     'on',...
    'BlockType',       'Inport');

ahOutports = ep_find_system(hModelOrSub, ...
    'SearchDepth',     1,...
    'LookUnderMasks',  'all',...
    'FollowLinks',     'on',...
    'BlockType',       'Outport');
end


%%
function stInternalArgs = i_evalArgs(varargin)
% default values
stArgs = struct ( ...
    'OrigModel',   '', ...
    'TargetModel', '');

stUserArgs = ep_core_transform_args(varargin, fieldnames(stArgs));
casUserArgs = fieldnames(stUserArgs);
for i = 1:numel(casUserArgs)
    sArgName = casUserArgs{i};
    stArgs.(sArgName) = stUserArgs.(sArgName);
end

stInternalArgs = struct();
if i_hasNonemptyValue(stArgs, 'OrigModel')
    stInternalArgs.hOrigModel = get_param(stArgs.OrigModel, 'handle');
else
    error('EP:ERROR:WRONG_USAGE', 'Original model name needs to be provided.');
end
if i_hasNonemptyValue(stArgs, 'TargetModel')
    stInternalArgs.hTargetModel = get_param(stArgs.TargetModel, 'handle');
else
    error('EP:ERROR:WRONG_USAGE', 'Target model name needs to be provided.');
end
end


%%
function bHasValue = i_hasNonemptyValue(stKeyValues, sKey)
bHasValue = isfield(stKeyValues, sKey) && ~isempty(stKeyValues.(sKey));
end


%%
function sDimToSet = i_getPortDim(aiPortDim)
if aiPortDim(1) == 1
    sDimToSet = sprintf('%d', aiPortDim(2));
elseif aiPortDim(1) == 2  %Matrix
    sDimToSet = sprintf('[%d %d]', aiPortDim(2), aiPortDim(3));
else
   error('EP:ERROR:DIMENSIONS_NOT_SUPPORTED', ...
       'Given Matrix dimension = %d! Matrix dimensions above 2 are not supported.', aiPortDim(1));
end
end

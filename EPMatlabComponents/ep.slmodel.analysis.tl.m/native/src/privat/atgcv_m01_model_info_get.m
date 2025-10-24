function stModel = atgcv_m01_model_info_get(stEnv, hSubsys, stOpt)
% Get all possible info from model and corresponding DataDictionary.
%
% function stModel = atgcv_m01_model_info_get(stEnv, hSubsys, stOpt)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)   error messenger environment
%     hSubsys             (handle)   DD handle of TL subsystem
%     stOpt               (struct)   options
%       .sCalMode         (string)   CalibrationMode
%                                    <'explicit'> | 'limited' | 'none'
%       .bDispMode        (string)   DispMode
%                                    <'all'> | 'none'
%       .sDsmMode         (string)   DataStoreMode
%                                    'all' | <'read'> | 'none'
%       .sDdPath          (string)   full path to DataDictionary
%       .bAddEnvironment    (bool)   consider also the Parent-Subsystem of the
%                                    TL-TopLevel Subsystem
%                                    default is FALSE
%       .bIgnoreStaticCal   (bool)   if TRUE, ignore all STATIC_CAL Variables
%                                    default is FALSE
%       .bIgnoreBitfieldCal (bool)   if TRUE, ignore all CAL Variables with Type
%                                    Bitfield; default is FALSE
%
%   OUTPUT              DESCRIPTION
%     stModel             (struct)   model info data
%       .sName            (string)   name of the model
%       ....
%


%% defaults for optional inputs
if (nargin < 3)
    stOpt = struct();
end
stOpt = i_checkSetDefaultOpt(stOpt);


%% main
% get hierarchy
stModel = struct();
stModel.sModelMode = 'TL';
stModel.sName = atgcv_mxx_dsdd(stEnv, 'GetSubsystemInfoModel', hSubsys);
try
    stModel.sModelFile = get_param(stModel.sName, 'FileName');
    stModel.sModelPath = fileparts(stModel.sModelFile);
catch %#ok<CTCH>
    stModel.sModelFile = '';
    stModel.sModelPath = '';
end
stModel.sDdPath = stOpt.sDdPath;
[astSubsystems, stModel.hInitFunc] = atgcv_m01_model_hierarchy_get(stEnv, hSubsys, stOpt.bAddEnvironment);

% check and reject special case early: no subsystems found
if isempty(astSubsystems)
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:TOPLEVEL_INVALID_NOT_RECOVERED', 'subsystem', '<unknown>');
    osc_throw(stErr);
end
% check and reject special case early: only one TopLevel selected that is a DummySub
if ((length(astSubsystems) == 1) && astSubsystems(1).bIsDummy)
    stErr = osc_messenger_add(stEnv, ...
        'ATGCV:MOD_ANA:TOPLEVEL_INVALID_NOT_RECOVERED', 'subsystem', astSubsystems(1).sTlPath);
    osc_throw(stErr);
end

% get compiled info for signals of subsystems and display variables
% - combine this with DISP vars if needed
casSubNames = {astSubsystems(:).sModelPath};
if strcmpi(stOpt.sDispMode, 'all')
    astDispVars = atgcv_m01_dispvars_get(stEnv, hSubsys);
    [astCompInterface, stModel.astDispVars] = i_getCompiledInfo(stEnv, casSubNames, stModel, astDispVars);
else
    astCompInterface = i_getCompiledInfo(stEnv, casSubNames, stModel);
    stModel.astDispVars = [];
end
stModel.astSubsystems = i_addInterface(stEnv, astSubsystems, astCompInterface, stOpt.bAdaptiveAutosar);

% extracting the interface could have produced invalid Subsystems: so again
% check and reject special cases:
% 1) no Subsystem is valid
% OR
% 2) only one TopLevel selected but that is either a DummySub or does not have MIL capability
astSubsystems = stModel.astSubsystems;
if isempty(astSubsystems)
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:TOPLEVEL_INVALID_NOT_RECOVERED', 'subsystem', '<unknown>');
    osc_throw(stErr);
end
if ((length(astSubsystems) == 1) && (astSubsystems(1).bIsDummy || ~astSubsystems(1).bHasMilSupport))
    stErr = osc_messenger_add(stEnv, ...
        'ATGCV:MOD_ANA:TOPLEVEL_INVALID_NOT_RECOVERED', 'subsystem', astSubsystems(1).sTlPath);
    osc_throw(stErr);
end

%check for constants/macros in data dictionary and get result as array of struct
stModel.astConstants = ep_tldd_constants_get(stEnv);

% add variable info for CAL vars and corresponding info
if any(strcmpi(stOpt.sCalMode, {'limited', 'explicit'}))
    stModel.astCalVars = atgcv_m01_calvars_get(stEnv, hSubsys, stOpt.sCalMode);
    if stOpt.bIgnoreStaticCal
        stModel.astCalVars = i_filterOutStaticCals(stEnv, stModel.astCalVars);
    end
    if stOpt.bIgnoreBitfieldCal
        stModel.astCalVars = i_filterOutBitfieldCals(stEnv, stModel.astCalVars);
    end

    stModel.astCalVars = i_filterOutHighDimCals(stEnv, stModel.astCalVars);
    stModel.astCalVars = i_filterOutCalsWithUnsupportedType(stEnv, stModel.astCalVars);
else
    stModel.astCalVars = [];
end

% add variable info for DSM vars and corresponding info
if any(strcmpi(stOpt.sDsmMode, {'read', 'all'}))
    stModel.astDsmVars = atgcv_m01_dsmvars_get(stEnv, hSubsys, 'read');
    if strcmpi(stOpt.sDsmMode, 'all')
        stModel.astDsmVars = [stModel.astDsmVars, atgcv_m01_dsmvars_get(stEnv, hSubsys, 'write')];
    end
    % now combine with MIL info
    [astVars, abIsValid] = atgcv_m01_dsmvars_signal_info_add(stEnv, stModel.astDsmVars);
    stModel.astDsmVars = astVars(abIsValid);
else
    stModel.astDsmVars = [];
end

% add links between subsystems and variables
stModel = atgcv_m01_local_ifs_to_subs_assign(stModel);

% add info about the SystemTime variable if there is any
stSystemTimeVar = i_getSystemTimeVar(stEnv, hSubsys);
if ~isempty(stSystemTimeVar)
    stModel.stSystemTimeVar = stSystemTimeVar;
end

% add env blocks from environment
if stOpt.bAddEnvironment
    astTopBlocks = atgcv_m01_subsystem_contained_blocks_get(stEnv, stModel.astSubsystems(1).sModelPath);
    casKnownChildren = i_getChildNames(stModel.astSubsystems, 1);
    stModel.astSubsystems(1).astBlocks = i_filterOutBlocks(astTopBlocks, casKnownChildren);
end
end


%%
function stSystemTimeVar = i_getSystemTimeVar(stEnv, hSubsys)
stSystemTimeVar = [];
ahSubs = atgcv_m01_involved_subsystems_get(stEnv, hSubsys);
for i = 1:length(ahSubs)
    hSub = ahSubs(i);

    hSystemTimeVar = i_findSystemTimeVar(stEnv, hSub);
    if ~isempty(hSystemTimeVar)
        stSystemTimeVar = atgcv_m01_variable_info_get(stEnv, hSystemTimeVar);
        return;
    end
end
end


%%
function hSystemTimeVar = i_findSystemTimeVar(stEnv, hSubsys)
ahFound = atgcv_mxx_dsdd(stEnv, ...
    'Find',       hSubsys, ...
    'ObjectKind', 'Variable', ...
    'Name',       'SystemTime');
if ~isempty(ahFound)
    hSystemTimeVar = ahFound(1);
else
    hSystemTimeVar = [];
end
end


%%
function astCalVars = i_filterOutStaticCals(stEnv, astCalVars)
astCalVars = i_filterOutVars(stEnv, astCalVars, @i_isCalVariableStatic, 'ATGCV:MOD_ANA:IGNORE_STATIC_CAL');
end


%%
function bIsStatic = i_isCalVariableStatic(stCalVar)
try
    bIsStatic = strcmpi(stCalVar.stInfo.stRootClass.sStorage, 'static');
catch oEx
    warning('ATGCV:MOD_ANA:INTERNAL', 'Storage property not properly read.\n%s', oEx.message);
    bIsStatic = false;
end
end


%%
function astCalVars = i_filterOutBitfieldCals(stEnv, astCalVars)
astCalVars = i_filterOutVars(stEnv, astCalVars, @i_hasCalVariableTypeBitfield, 'ATGCV:MOD_ANA:IGNORE_BITFIELD_CAL');
end


%%
function bHasTypeBitfield = i_hasCalVariableTypeBitfield(stCalVar)
try
    bHasTypeBitfield = strcmpi(stCalVar.stInfo.stVarType.sBase, 'Bitfield');
catch oEx
    warning('ATGCV:MOD_ANA:INTERNAL', 'Type check "Bitfield" failed.\n%s', oEx.message);
    bHasTypeBitfield = false;
end
end


%%
function astCalVars = i_filterOutCalsWithUnsupportedType(stEnv, astCalVars)
abIsSupportedType = arrayfun(@i_isSupportedType, astCalVars);
astInvalid = astCalVars(~abIsSupportedType);
for i = 1:length(astInvalid)
    stInvalid = astInvalid(i);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:NOT_SUPPORTED_SIMULINK_PARAMETER', 'parameter', stInvalid.stCal.sUniqueName);
end
astCalVars = astCalVars(abIsSupportedType);
end


%%
function bIsSupported = i_isSupportedType(stCalVar)
stTypeInfo = ep_sl_type_info_get(stCalVar.stCal.sType);
bIsSupported = ~any(strcmp(stTypeInfo.sBaseType, {'int64', 'uint64'}));
end


%%
function astCalVars = i_filterOutHighDimCals(stEnv, astCalVars)
% TODO put a real Messenger ID here as last arg!!!
astCalVars = i_filterOutVars(stEnv, astCalVars, @i_isHighDimVar, '');
end


%%
function bIsHighDim = i_isHighDimVar(stVar)
bIsHighDim = length(stVar.stInfo.aiWidth) > 2;
end


%%
function astVars = i_filterOutVars(stEnv, astVars, hIsInvalidFunc, sMsgID)
if isempty(astVars)
    return;
end
abIsInvalid = arrayfun(hIsInvalidFunc, astVars);
if ~isempty(sMsgID)
    i_enterFilterMessages(stEnv, astVars(abIsInvalid), sMsgID);
end
astVars = astVars(~abIsInvalid);
end


%%
function i_enterFilterMessages(stEnv, astFilteredVars, sMsgID)
for i = 1:length(astFilteredVars)
    stVar = astFilteredVars(i);

    sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', stVar.hVar, 'Name');
    sBlockPath = stVar.astBlockInfo(1).sTlPath;
    osc_messenger_add(stEnv, sMsgID, 'variable', sVarName, 'block', sBlockPath);
end
end


%%
function casChildNames = i_getChildNames(astSubsystems, iParentIdx)
casChildNames = {};
for i = 1:length(astSubsystems)
    if (astSubsystems(i).iParentIdx == iParentIdx)
        try
            casChildNames{end + 1} = get_param(astSubsystems(i).sModelPath, 'Name'); %#ok<AGROW>
        catch %#ok<CTCH>
        end
    end
end
end


%%
function astBlocks = i_filterOutBlocks(astBlocks, casFilterNames)
if isempty(astBlocks)
    return;
end
abIsValid = true(size(astBlocks));
for i = 1:length(astBlocks)
    if any(strcmpi(astBlocks(i).sName, casFilterNames))
        abIsValid(i) = false;
    end
end
astBlocks = astBlocks(abIsValid);
end


%%
function stOpt = i_checkSetDefaultOpt(stOpt)
if ~isfield(stOpt, 'sCalMode')
    stOpt.sCalMode = 'explicit';
end
if ~isfield(stOpt, 'sDispMode')
    stOpt.sDispMode = 'all';
end
if ~isfield(stOpt, 'sDsmMode')
    stOpt.sDsmMode = 'read';
end
if ~isfield(stOpt, 'sDdPath')
    stOpt.sDdPath = '';
end
if ~isfield(stOpt, 'bAddEnvironment')
    stOpt.bAddEnvironment = false;
end
if ~isfield(stOpt, 'bIgnoreStaticCal')
    stOpt.bIgnoreStaticCal = false;
end
if ~isfield(stOpt, 'bIgnoreBitfieldCal')
    stOpt.bIgnoreBitfieldCal = false;
end
if ~isfield(stOpt, 'bAdaptiveAutosar')
    stOpt.bAdaptiveAutosar = false;
end
end


%%
function sCurrDd = i_getCurrentDD()
sCurrDd = dsdd('GetDDAttribute', 0, 'fileName');
if strcmpi(sCurrDd, 'untitled.dd')
    sCurrDd = '';
end
end


%%
function [astCompInterface, astDispVars] = i_getCompiledInfo(stEnv, casSubNames, stModel, astDispVars)
sBeforeDD = i_getCurrentDD();

sModelRootPath = '';
if ~isempty(stModel.sModelFile)
    sModelRootPath = fileparts(stModel.sModelFile);
end
if (nargin < 4)
    astCompInterface = atgcv_m01_compiled_info_get(stEnv, casSubNames, sModelRootPath);

    % (re)open provided DD
    % important to reopen the provided DD because the compile-process could open an internal DD
    if ~isempty(stModel.sDdPath)
        sAfterDD = i_getCurrentDD();
        if ~strcmpi(sBeforeDD, sAfterDD)
            i_openProvidedDd(stEnv, stModel.sDdPath, stModel.sModelPath);
        end
    end

else
    [casDispBlocks, aiBlockDispMap] = i_getDispBlockMapping(astDispVars);

    astBlockInterface = atgcv_m01_compiled_info_get(stEnv, [casSubNames, casDispBlocks], sModelRootPath);
    astCompInterface  = astBlockInterface(1:length(casSubNames));
    astBlockInterface = astBlockInterface(length(casSubNames) + 1:end);

    % (re)open provided DD
    % important to reopen the provided DD because the compile-process could open an internal DD
    if ~isempty(stModel.sDdPath)
        sAfterDD = i_getCurrentDD();
        if ~strcmpi(sBeforeDD, sAfterDD)
            i_openProvidedDd(stEnv, stModel.sDdPath, stModel.sModelPath);
        end
    end

    % remove all Disp variables that are referencing a block for which there is no complete interface info
    abIsReferencedInfoComplete = true(size(astDispVars));
    for i = 1:length(astBlockInterface)
        if ~astBlockInterface(i).bIsInfoComplete
            abIsReferencedInfoComplete(aiBlockDispMap == i) = false;
        end
    end
    if any(~abIsReferencedInfoComplete)
        % TODO: messenger entry for each removed Disp
        astDispVars    = astDispVars(abIsReferencedInfoComplete);
        aiBlockDispMap = aiBlockDispMap(abIsReferencedInfoComplete);
    end

    [astDispVars, abValid] = atgcv_m01_disp_vars_signal_info_add(stEnv, astDispVars, astBlockInterface, aiBlockDispMap, true);
    astDispVars = astDispVars(abValid);
end
end


%%
function [casDispBlocks, aiBlockDispMap] = i_getDispBlockMapping(astDispVars)
nDisp = length(astDispVars);
aiBlockDispMap = zeros(1, nDisp);
casDispBlocks = {};
for i = 1:nDisp
    sKind = astDispVars(i).astBlockInfo(1).sBlockKind;
    if isempty(astDispVars(i).iPortNumber) && ~strcmpi(sKind, 'Stateflow')
        % looking only at ouputs of blocks here
        continue;
    end

    sBlockPath = astDispVars(i).astBlockInfo(1).sTlPath;
    iBlockIdx = find(strcmp(sBlockPath, casDispBlocks));
    if isempty(iBlockIdx)
        casDispBlocks{end + 1} = sBlockPath; %#ok<AGROW>
        iBlockIdx = length(casDispBlocks);
    end
    aiBlockDispMap(i) = iBlockIdx;
end
end


%%
function bIsEqual = i_isEqualInterfaces(stFuncIf1, stFuncIf2)
% for now check that both are not empty and have the same number of formal arguments
bIsEqual = ~isempty(stFuncIf1) && ~isempty(stFuncIf2);
if bIsEqual
    nArgs1 = length(stFuncIf1.astFormalArgs);
    nArgs2 = length(stFuncIf2.astFormalArgs);
    bIsEqual = (nArgs1 == nArgs2);
end
end


%%
function astSubsystems = i_addInterface(stEnv, astSubsystems, astCompInterface, bIsInt64Supported)
iTop = find([astSubsystems(:).bIsToplevel]);
if (length(iTop) ~= 1)
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Could not find a unique toplevel sub.');
end

nSub = length(astSubsystems);
abIsValid = true(1, nSub);
for i = 1:nSub
    stSubsystem = astSubsystems(i);

    stFuncInterface  = [];
    stSubInterface   = [];
    stInterface      = [];
    try
        % Check MIL Suppport for all Subsystems
        stCompInterface = astCompInterface(i);

        [astSubsystems(i).bHasMilSupport, bIsValid] = i_checkCompInterface(stEnv, stCompInterface, stSubsystem.sTlPath, bIsInt64Supported);
        if ~astSubsystems(i).bHasMilSupport
            % TODO: for ClosedLoop we need to issue a proper error here!
            if stSubsystem.bIsEnv
                error('ATGCV:MOD_ANA:WARNING', ...
                    'ClosedLoop cannot be established. Frame Subsystem is not supported for MIL Simulation.');
            end
        else
            if (~stSubsystem.bIsEnv && stSubsystem.bIsDummy)
                % a Subsystem that is not a closed-loop frame and is a DUMMY subsystem cannot support MIL
                astSubsystems(i).bHasMilSupport = false;
            end
        end

        % Note: SIL and Mapping between SIL and MIL check only for Subsystems
        % with both infos: DD-Function and DD-Subsystem
        bHasCodeInterface = ~isempty(stSubsystem.hFuncInstance) && ~isempty(stSubsystem.hSub);

        % Check SIL Support (only relevant if MIL and B2B is supported)
        if (bIsValid && bHasCodeInterface)
            [stFuncInterface, bIsValid] = i_getFuncInterface(stEnv, stSubsystem);
            if (isempty(stFuncInterface) || ~bIsValid)
                bHasCodeInterface = false;
            end
        end

        % check B2B Support (only relevant if MIL and SIL are supported)
        if (bIsValid && bHasCodeInterface)
            try
                if strcmpi(stSubsystem.sKind, 'stateflow')
                    stSubInterface = atgcv_m01_chart_interface_get(stEnv, stSubsystem.hSub);
                    if i_hasDummyInports(stSubInterface)
                        bIsValid = false;
                        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_CHART_DUMMY_INPORTS', ...
                            'sf_chart', stSubsystem.sTlPath);
                    end
                else
                    stSubInterface = atgcv_m01_subsystem_interface_get(stEnv, stSubsystem.hSub);
                end
            catch
                stErr = osc_lasterror();
                sText = sprintf('Reading out the interface of Subsystem "%s" in DD was not successful.\n%s', ...
                    stSubsystem.sTlPath, stErr.message);
                osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:INTERNAL_ERROR', 'script', 'model_info', 'text', sText);
                bIsValid = false;
            end
        end

        if bIsValid
            if bHasCodeInterface
                % If there is a CodeInterface, try to combine MIL and SIL.
                % Note_1: bIsValid can change its value here!
                bIsValid = i_checkInterfaceInconsistencies(stEnv, stSubsystem, stFuncInterface, stCompInterface);
                if bIsValid
                    sSubRealPath = astSubsystems(i).sModelPath;
                    sSubVirtualPath = astSubsystems(i).sTlPath;
                    stInterface = atgcv_m01_combine_interfaces(stEnv, ...
                        stFuncInterface, stSubInterface, stCompInterface, sSubRealPath, sSubVirtualPath);

                    % Combining the interfaces could produce new DummyVariables
                    % that have been hidden before --> For Stateflow-Charts this
                    % would mean that we need to recheck the validity again.
                    if strcmpi(stSubsystem.sKind, 'stateflow')
                        if i_hasDummyInports(stInterface)
                            bIsValid = false;
                            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_CHART_DUMMY_INPORTS', ...
                                'sf_chart', stSubsystem.sTlPath);
                        end
                    end

                    bIsValid = bIsValid && i_isInterfaceValid(stEnv, stInterface, stSubsystem.sTlPath);
                end
            else
                % if there is no CodeInterface, just use MIL-view with "fake" SIL
                if ~isempty(stCompInterface)
                    stInterface = atgcv_m01_if_from_comp_if_derive(stCompInterface);
                end
            end
        end


        % Note_2: ask again for bIsValid (see Note_1)
        if bIsValid
            astSubsystems(i).stInterface     = stInterface;
            astSubsystems(i).stFuncInterface = stFuncInterface;
            astSubsystems(i).stSubInterface  = stSubInterface;
            astSubsystems(i).stCompInterface = stCompInterface;
        else
            abIsValid(i) = false;
        end

    catch %#ok<CTCH>
        stErr = osc_lasterror();

        if i_isTestMode()
            warning('ATGCV:DEBUG', 'For debugging always throwing an exception!');
            osc_throw(stErr);
        end

        try
            % remove the HTML-stuff that Matlab adds to messages
            stErr.message = regexprep(stErr.message, '.*</a>\)\s', '');
        catch %#ok<CTCH>
        end
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', stErr.message);
        if (i == iTop)
            stErr = osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:LIMITATION_TOPLEVEL_INTERFACE_INCOMPLETE', ...
                'subsystem',  stSubsystem.sTlPath);
            osc_throw(stErr);
        else
            if strcmpi(stErr.identifier, 'ATGCV:MOD_ANA:UNSPEC_PORT')
                osc_messenger_add(stEnv, ...
                    'ATGCV:MOD_ANA:LIMITATION_UNSPECIFIED_PORTS', ...
                    'subsystem',  stSubsystem.sTlPath);
            else
                osc_messenger_add(stEnv, ...
                    'ATGCV:MOD_ANA:LIMITATION_INTERFACE_INCOMPLETE', ...
                    'subsystem',  stSubsystem.sTlPath);
            end
            abIsValid(i) = false;
        end
    end
end

% remove invalid subsystems from hierarchy
if abIsValid(iTop)
    astSubsystems = atgcv_m01_hierarchy_reduce(astSubsystems, abIsValid);
else
    stErr = osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:TOPLEVEL_INVALID_NOT_RECOVERED', ...
        'subsystem', astSubsystems(iTop).sTlPath);
    osc_throw(stErr);
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
function [bIsSupported, bIsValid] = i_checkCompInterface(stEnv, stCompInterface, sSubPath, bIsInt64Supported)
[stCheckInputs, stCheckOutputs] = atgcv_m01_compiled_interface_check(stCompInterface);
[bAreInputsSupported, bAreInputsValid] = i_arePortsSupported(stCheckInputs, false);
[bAreOutputsSupported, bAreOutputsValid] = i_arePortsSupported(stCheckOutputs, bIsInt64Supported);
bIsSupported = bAreInputsSupported && bAreOutputsSupported;
bIsValid = bAreInputsValid && bAreOutputsValid;

if bIsSupported
    return;
end

if ~isempty(stCheckInputs.astInvalidPorts) || ~isempty(stCheckInputs.astUnsupportedPorts) ...
        || ~isempty(stCheckOutputs.astInvalidPorts) || ~isempty(stCheckOutputs.astUnsupportedPorts)
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_UNSUPPORTED_TYPE_INTERFACE', 'subsystem', sSubPath);
end
if ~isempty(stCheckInputs.astHighDimPorts) || ~isempty(stCheckOutputs.astHighDimPorts)
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_MATRIX_SIGNAL', 'subsystem', sSubPath);
end
end


%%
function [bIsSupported, bIsValid] = i_arePortsSupported(stCheck, bIsInt64Supported)
if bIsInt64Supported
    bIsSupported = ...
        isempty(stCheck.astInvalidPorts) && ...
        isempty(stCheck.astHighDimPorts);
    bIsValid = isempty(stCheck.astHighDimPorts);
else
    bIsSupported = ...
        isempty(stCheck.astInvalidPorts) && ...
        isempty(stCheck.astUnsupportedPorts) && ...
        isempty(stCheck.astHighDimPorts);
    bIsValid = isempty(stCheck.astHighDimPorts) && isempty(stCheck.astUnsupportedPorts);
end
end

%%
function bIsValid = i_checkInterfaceInconsistencies(stEnv, stSubsystem, stFuncInterface, stCompInterface)
bIsValid = true;

if ~isempty(stFuncInterface)
    if ~isempty(stFuncInterface.casInconsistencies)
        nMsg = length(stFuncInterface.casInconsistencies);
        for j = 1:nMsg
            osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', stFuncInterface.casInconsistencies{j});
        end
        if stSubsystem.bIsToplevel
            stErr = osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:LIMITATION_TOPLEVEL_INTERFACE_INCOMPLETE', 'subsystem', stSubsystem.sTlPath);
            osc_throw(stErr);
        else
            osc_messenger_add(stEnv, ...
                'ATGCV:MOD_ANA:LIMITATION_INTERFACE_INCOMPLETE', 'subsystem',  stSubsystem.sTlPath);
            bIsValid = false;
        end
    end
end
if ~stCompInterface.bIsInfoComplete
    % AH TODO: replace with messenger entry
    warning('ATGCV:MOD_ANA:INTERNAL_WARNING', 'Compiled info incomplete.');
    bIsValid = false;
end
end


%%
function i_openProvidedDd(~, sDdFile, sModelPath)
sPwd = pwd();
bIsLoaded = false;

% close current DD to avoid interferences
atgcv_dd_close('Save', false);

% 1) try to load user DD from model path
if ~isempty(sModelPath)
    try
        cd(sModelPath);
        atgcv_dd_open('File', sDdFile);
        bIsLoaded = true;
    catch %#ok<CTCH>
        % could not fully restore user DD
    end
    cd(sPwd);
end

% 2) try to load user DD from DD path
if ~bIsLoaded
    sDdPath = fileparts(sDdFile);
    if ~isempty(sDdPath)
        try
            cd(sDdPath)
            atgcv_dd_open('File', sDdFile);
        catch %#ok<CTCH>
            %  could not fully restore user DD
        end
        cd(sPwd);
    else
        atgcv_dd_open('File', sDdFile);
    end
end
end


%%
function bHasDummyInports = i_hasDummyInports(stSubInterface)
bHasDummyInports = false;
for i = 1:length(stSubInterface.astInports)
    stInport = stSubInterface.astInports(i);
    for j = 1:length(stInport.astSignals)
        bHasDummyInports = stInport.astSignals(j).bIsDummyVar;
        if bHasDummyInports
            return;
        end
    end
end
end


%%
function [stFuncInterface, bIsValid] = i_getFuncInterface(stEnv, stSubsystem)
bIsValid = true;

stFuncInterface = atgcv_m01_function_interface_get(stEnv, stSubsystem.hFuncInstance);
if isempty(stFuncInterface)
    if ~stSubsystem.bIsDummy
        % Note: Missing SIL supported is not accepted for non-dummy Subs.
        bIsValid = false;

        sMsg = sprintf('Failed reading out the interface of step function "%s" for subsystem "%s".', ...
            stSubsystem.sStepFunc, stSubsystem.sTlPath);
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sMsg);
    end
    return;
end

% if we have a ProxyFunc check Assumption that the arguments are the same as for the StepFunc
if ~isempty(stSubsystem.stProxyFunc)
    hProxyInstance = stSubsystem.stProxyFunc.hFuncInstance;

    if ~isempty(hProxyInstance)
        stProxyInterface = atgcv_m01_function_interface_get(stEnv, hProxyInstance);
        if ~i_isEqualInterfaces(stFuncInterface, stProxyInterface)
            bIsValid = false;

            sMsg = sprintf(['Currently not supported: Step function "%s" ', ...
                'for subsystem "%s" has a different signature from the Proxy function.'], ...
                stSubsystem.sStepFunc, stSubsystem.sTlPath);
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sMsg);
        end
    end
end
end


%%
function bIsValid = i_isInterfaceValid(stEnv, stInterface, sSubsysPath)
bIsValid = ...
    ~i_hasDependentInputs(stEnv, stInterface, sSubsysPath) ...
    && i_isInterfaceConsistent(stEnv, stInterface, sSubsysPath) ...
    && i_isInterfaceSupported(stEnv, stInterface, sSubsysPath);
end


%%
function bHasDependentInputs = i_hasDependentInputs(stEnv, stInterface, sSubsysPath)
bHasDependentInputs = false;

xVarRegistry = containers.Map('KeyType', 'double', 'ValueType', 'any');
for i = 1:length(stInterface.astInports)
    stPort = stInterface.astInports(i);

    for j = 1:length(stPort.astSignals)
        stSignal = stPort.astSignals(j);
        if (stSignal.bIsDummyVar || isempty(stSignal.stVarInfo))
            continue;
        end

        dVarKey = stSignal.stVarInfo.hVar;
        if isempty(dVarKey)
            continue;
        end

        if xVarRegistry.isKey(dVarKey)
            xVarRegistry(dVarKey) = [xVarRegistry(dVarKey), stSignal];
        else
            xVarRegistry(dVarKey) = stSignal;
        end
    end
end

ahVars = xVarRegistry.keys();
for i = 1:length(ahVars)
    astSigs = xVarRegistry(ahVars{i});
    if ~i_areSignalsUnique(astSigs)
        bHasDependentInputs = true;

        i_issueMultivarInputsLimitation(stEnv, astSigs, sSubsysPath);
    end
end

if bHasDependentInputs
    if i_userAcceptsDependency()
        bHasDependentInputs = false;
    else
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_DEPENDENT_CODE_INPUTS', 'subsystem', sSubsysPath);
    end
end
end


%%
% TODO: remove the entering of message as side-effect and make function purely functional
function bIsConsistent = i_isInterfaceConsistent(stEnv, stInterface, sSubsysPath)
bIsConsistent = true;

for i = 1:length(stInterface.astInports)
    bIsPortConsistent = i_isPortConsistent(stEnv, stInterface.astInports(i));
    bIsConsistent = bIsConsistent && bIsPortConsistent;
end
for i = 1:length(stInterface.astOutports)
    bIsPortConsistent = i_isPortConsistent(stEnv, stInterface.astOutports(i));
    bIsConsistent = bIsConsistent && bIsPortConsistent;
end

if ~bIsConsistent
    sMsg = sprintf('DD info about the interfaces of subsystem "%s" is inconsistent.', sSubsysPath);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sMsg);
end
end


%%
% TODO: remove the entering of message as side-effect and make function purely functional
function bIsSupported = i_isInterfaceSupported(stEnv, stInterface, sSubsysPath)
bIsSupported = true;

for i = 1:length(stInterface.astInports)
    bIsPortSupported = i_isPortSupported(stEnv, stInterface.astInports(i));
    bIsSupported = bIsSupported && bIsPortSupported;
end
for i = 1:length(stInterface.astOutports)
    bIsPortSupported = i_isPortSupported(stEnv, stInterface.astOutports(i));
    bIsSupported = bIsSupported && bIsPortSupported;
end

if ~bIsSupported
    sMsg = sprintf('Subsystem "%s" contains unsupported ports.', sSubsysPath);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sMsg);
end
end


%%
% TODO: remove the entering of message as side-effect and make function purely functional
function bIsConsistent = i_isPortConsistent(stEnv, stPort)
bIsConsistent = isempty(stPort.astSignals) || all(arrayfun(@i_isSignalConsistent, stPort.astSignals));

if ~bIsConsistent
    sMsg = sprintf('DD info about port "%s" is inconsistent.', stPort.sModelPortPath);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sMsg);
end
end


%%
function bIsSupported = i_isPortSupported(stEnv, stPort)
bIsSupported = true;

bContainsAoB = i_containsArrayOfBusSignals(stPort);
if bContainsAoB
    bIsSupported = false;
    sMsg = sprintf('Port "%s" is not supported because it contains Array-of-Struct references.', stPort.sModelPortPath);
    osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', 'msg', sMsg);
end
end


%%
function bContainsAoB = i_containsArrayOfBusSignals(stPort)
bContainsAoB = false;

if verLessThan('tl', '5.2')
    % AoB signals are only supported for TL5.2 and higher --> just return here for lower versions
    return;
end

if ~any(strcmp(stPort.sBlockType, {'TL_BusInport', 'TL_BusOutport'}))
    % AoB signals can only be part of TL BusPorts --> just return for all other ports
    return;
end

ahRootVars = i_getRootVars(stPort);
if (numel(ahRootVars) == 1)
    hRootVar = ahRootVars(1);
    bContainsAoB = i_containsArrayOfStructs(hRootVar);
end
end


%%
function bContainsAoS = i_containsArrayOfStructs(hVar)
bContainsAoS = false;
if i_isStructVar(hVar)
    bContainsAoS = i_isArray(hVar);
    if bContainsAoS
        return;
    end

    ahSubVars = dsdd('Find', hVar, 'objectKind', 'Variable');
    for i = 1:numel(ahSubVars)
        hSubVar = ahSubVars(i);
        bContainsAoS = bContainsAoS || (i_isStructVar(hSubVar) && i_isArray(hSubVar));
    end
end
end


%%
function bIsStructVar = i_isStructVar(hVar)
bIsStructVar = dsdd('Exist', 'Components', 'Parent', hVar);
end


%%
function ahRootVars = i_getRootVars(stPort)
ahRootVars = [];
for i = 1:numel(stPort.astSignals)
    stVarInfo = stPort.astSignals(i).stVarInfo;
    if ~isempty(stVarInfo)
        ahRootVars(end + 1) = stVarInfo.hRootVar; %#ok<AGROW>
    end
end
ahRootVars = unique(ahRootVars);
end


%%
function bHasChildren = i_isArray(hBlockVar)
aiWidth = dsdd('GetWidth', hBlockVar);
bHasChildren = ~isempty(aiWidth) && (prod(aiWidth) > 1);
end


%%
% a signal is _not_ consistent if there is a corresponding C-Variable and ...
% 1) (aiElements is set) AND (aiWidth is not set)
% 2) (aiElements2 is set) AND (length of aiWidth is smaller one)
function bIsConsistent = i_isSignalConsistent(stSignal)
if stSignal.bIsDummyVar
    bIsConsistent = true;
    return;
end

bIsConsistent = i_isDimensionInfoConsistent(stSignal) && ~i_isElementAccessFunc(stSignal.stVarInfo);
end


%%
function bIsConsistent = i_isDimensionInfoConsistent(stSignal)
if ~isempty(stSignal.aiElements2)
    bIsConsistent = (length(stSignal.stVarInfo.aiWidth) > 1);

elseif ~isempty(stSignal.aiElements)
    bIsConsistent = ~isempty(stSignal.stVarInfo.aiWidth);

else
    bIsConsistent = true;
end
end


%%
function bIsElementAccessFunc = i_isElementAccessFunc(stVarInfo)
bIsElementAccessFunc = false;

stAccess = stVarInfo.stRootClass.stAccess;
if isempty(stAccess)
    return;
end
bIsElementAccessFunc = stAccess.bIsElementAccessFunc;
end


%%
function bIsAccepted = i_userAcceptsDependency()
bIsAccepted = false;
try
    [sAccept, bExists] = ep_ma_internal_property('get', 'accept_dependent_code_inputs', 'no');
    if bExists
        bIsAccepted = any(strcmpi(sAccept, {'on', 'yes', '1', 'true'}));
    end
catch
end
end


%%
function i_issueMultivarInputsLimitation(stEnv, astSigs, sSubsysPath)
stVar = astSigs(1).stVarInfo;
sVariableName = [stVar.sRootName, stVar.sAccessPath];

try
    casBlocks = unique(arrayfun(@(x) dsdd_get_block_path(x.hBlockVar), astSigs, 'UniformOutput', false));
catch
    casBlocks = {};
end

if isempty(casBlocks)
    sBlockList = '<blocks could not be determined>';
else
    sBlockList = sprintf('%s; ', casBlocks{:});
    sBlockList(end-1:end) = [];
end

osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:DEPENDENT_CODE_INPUTS', ...
    'variable',  sVariableName, ...
    'blocks',    sBlockList, ...
    'subsystem', sSubsysPath);
end


%%
function bAreUnique = i_areSignalsUnique(astSignals)
bAreUnique = true;
if (length(astSignals) < 2)
    aiElem1 = astSignals(1).aiElements;
    aiElem2 = astSignals(1).aiElements2;
    bIsElem1Unique = isempty(aiElem1) || (length(aiElem1) == length(unique(aiElem1)));
    bIsElem2Unique = isempty(aiElem2) || (length(aiElem2) == length(unique(aiElem2)));
    bAreUnique = bIsElem1Unique && bIsElem2Unique;
    return;
end

xElemRegistry = containers.Map();
for i = 1:length(astSignals)
    stSignal = astSignals(i);

    aiWidth = stSignal.stVarInfo.aiWidth;
    if (~isempty(aiWidth) && prod(aiWidth) > 1)
        aiElem1 = stSignal.aiElements;
        if isempty(aiElem1)
            aiElem1 = 0:aiWidth(1)-1;
        end
        if (length(aiWidth) > 1)
            aiElem2 = stSignal.aiElements2;
            if isempty(aiElem2)
                aiElem2 = 0:aiWidth(2)-1;
            end
            casElemKeys = cell(length(aiElem1), length(aiElem2));
            for n1 = 1:length(aiElem1)
                for n2 = 1:length(aiElem2)
                    casElemKeys{n1, n2} = sprintf('%d[%d][%d]', stSignal.stVarInfo.hVar, aiElem1(n1), aiElem2(n2));
                end
            end
            casElemKeys = reshape(casElemKeys, 1, []);
        else
            casElemKeys = cell(1, length(aiElem1));
            for n1 = 1:length(aiElem1)
                casElemKeys{n1} = sprintf('%d[%d]', stSignal.stVarInfo.hVar, aiElem1(n1));
            end
        end
    else
        casElemKeys = {sprintf('%d', stSignal.stVarInfo.hVar)};
    end

    for j = 1:length(casElemKeys)
        sKey = casElemKeys{j};

        if xElemRegistry.isKey(sKey)
            bAreUnique = false;
            return;
        else
            xElemRegistry(sKey) = 1;
        end
    end
end
end



classdef ModelInfo
    properties (Access = private)
        bIsValidWrapper = false;
    end
    properties
        bIsValid = true;
        bIsAutosarArchitecture = false;
        stAutosarStyle = [];
        bIsWrapperContext = false;
        bIsWrapperComplete = false;
        sAutosarVersion = '';
        sAutosarArchitectureType = '';
        sAutosarModelName = '';
        sAutosarWrapperModelName = '';
        sAutosarWrapperRefSubsystem = '';
        sAutosarWrapperSchedSubsystem = '';
        sAutosarWrapperVariantSubsystem = '';
        sAutosarWrapperRootSubsystem = '';
        casMessages = {};
    end

    methods (Static = true)
        function oObj = get(sModelName)
            oObj = Eca.ModelInfo();

            oObj.sAutosarVersion = ep_core_feval('ep_ec_model_autosar_version_get', sModelName);
            if ~isempty(oObj.sAutosarVersion)
                oObj.bIsAutosarArchitecture = true;
                oObj.sAutosarModelName = sModelName;
            else
                oObj = i_analyzeAutosarWrapperStructure(sModelName, oObj);
                if oObj.bIsValidWrapper
                    oObj.bIsAutosarArchitecture = true;
                    oObj.bIsWrapperContext = true;
                    oObj.sAutosarWrapperModelName = sModelName;
                end
            end
            if oObj.bIsAutosarArchitecture
                [oObj.stAutosarStyle, casMessages] = i_getAndValidateAutosarStyle(oObj.sAutosarModelName);
                oObj.casMessages = [oObj.casMessages, casMessages];
            end
            oObj.bIsValid = isempty(oObj.casMessages);
        end
    end

    methods
        %TODO: Add getters and setters
    end
end


%%
function [stInfo, casMessages] = i_getAndValidateAutosarStyle(sModelName)
casMessages = {};
stInfo = ep_core_feval('ep_ec_autosar_short_info_get', sModelName);

% Constraint 1: Rate-based AUTOSAR models must have a single runnable; otherwise they are not supported by EP
bIsRateBasedClassicAutosar = strcmp(stInfo.sStyle, 'rate-based') && ~stInfo.bIsAdaptiveAutosar;
if (bIsRateBasedClassicAutosar && (numel(stInfo.casRunnables) ~= 1))
    casMessages{end + 1} = sprintf( ...
        'Model "%s" is a rate-based AUTOSAR model with more than one runnable. Such models are currently not supported.', ...
        sModelName);
end
end


%%
function oObj = i_analyzeAutosarWrapperStructure(sModelName, oObj)

% find the "Wrapper" subsystem (or model)
[casRootSys, sWrapperTag] = i_findWrapperRoot(sModelName);
if isempty(casRootSys)
    return;
end
if (numel(casRootSys) > 1)
    oObj.casMessages{end + 1} = sprintf( ...
        '## Too many subsystems configured with the Wrapper Tag "%s" have been found in the model. Only one is allowed.', ...
        sWrapperTag);
    return;
end
oObj.sAutosarWrapperRootSubsystem = char(casRootSys);
oObj.bIsWrapperComplete = i_isWrapperComplete(oObj.sAutosarWrapperRootSubsystem);

% find the 'Scheduler' subsystem if there is any
casSchedSys = ep_core_feval('ep_find_system', oObj.sAutosarWrapperRootSubsystem, ...
    'SearchDepth', 1, ...
    'BlockType',   'SubSystem', ...
    'Name',        'Scheduler');
if ~isempty(casSchedSys)
    if (numel(casSchedSys) > 1)
        oObj.casMessages{end + 1} = sprintf(...
            ['## An AUTOSAR wrapper architecture type is being analyzed ', ...
            'but too many subsystems named "Scheduler" have been found in the subsystem "%s". ', ...
            'Only one expected'], oObj.sAutosarWrapperRootSubsystem);
        return;
    end
    oObj.sAutosarWrapperSchedSubsystem = char(casSchedSys);
end

% find model reference block referencing the AUTOSAR model
if oObj.bIsWrapperComplete
    iSearchDepth = 3;
else
    iSearchDepth = 1;
end
[sModelRefBlock, sErrMessage] = i_findAutosarModelReferenceBlockInContext(oObj.sAutosarWrapperRootSubsystem, iSearchDepth);
if isempty(sModelRefBlock)
    oObj.casMessages{end + 1} = sErrMessage;
    return;
end

oObj.sAutosarWrapperRefSubsystem = sModelRefBlock;

sParentBlock = get_param(oObj.sAutosarWrapperRefSubsystem, 'Parent');
if i_isVariantSubsystem(sParentBlock)
    [bIsValid, sError] = i_isValidVariantSubsystem(sParentBlock);
    if ~bIsValid
        oObj.casMessages{end + 1} = ...
            sprintf('## AUTOSAR Wrapper model "%s" is invalid: "%s".', sModelName, sError);
        return;
    end
    oObj.sAutosarWrapperVariantSubsystem = sParentBlock;
end

% additional check to for parent of parent (additional subsystem in EC AA Wrapper)
if isempty(oObj.sAutosarWrapperVariantSubsystem)
    sTmpBlock = get_param(sParentBlock, 'Parent');
    if i_isVariantSubsystem(sTmpBlock)
        [bIsValid, sError] = i_isValidVariantSubsystem(sTmpBlock);
        if ~bIsValid
            oObj.casMessages{end + 1} = ...
                sprintf('## AUTOSAR Wrapper model "%s" is invalid: "%s".', sModelName, sError);
            return;
        end
        sParentBlock = sTmpBlock;
        oObj.sAutosarWrapperVariantSubsystem = sParentBlock;
    end
end


% check if referenced model is even an AUTOSAR model
oObj.sAutosarModelName = i_findAutosarModel(oObj.sAutosarWrapperRefSubsystem);
if ~isempty(oObj.sAutosarModelName)
    oObj.sAutosarVersion = ep_core_feval('ep_ec_model_autosar_version_get', oObj.sAutosarModelName);
else
    oObj.casMessages{end + 1} = sprintf(...
        '## An AUTOSAR wrapper model is being analyzed but the referenced model "%s" is not an AUTOSAR model.', ...
        get_param(oObj.sAutosarWrapperRefSubsystem, 'ModelName'));
    return;
end

if ~strcmp(get_param(oObj.sAutosarWrapperRefSubsystem, 'SimulationMode'), 'Normal')
    oObj.casMessages{end + 1} = sprintf(...
        '## The referenced model block "%s" is expected to be configured with Simulation Mode = "Normal".', ...
        oObj.sAutosarWrapperRefSubsystem);
    return;
end

oObj.bIsValidWrapper = true;
end


%%
function [casWrapperRoots, sFoundTag] = i_findWrapperRoot(sModelName)
casWrapperRoots = {};
sFoundTag = '';

sCurrentTag = get_param(sModelName, 'Tag');

casKnownWrapperTags = ep_core_feval('ep_ec_tag_get', 'All Wrappers');
for i = 1:numel(casKnownWrapperTags)
    sTag = casKnownWrapperTags{i};
    
    if strcmp(sCurrentTag, sTag)
        casWrapperRoots = {sModelName};
        sFoundTag = sTag;
        break;
    end
    
    casSubs = i_findDirectChildSubsystemsWithTag(sModelName, sTag);
    if ~isempty(casSubs)
        casWrapperRoots = casSubs;
        sFoundTag = sTag;
        break;
    end
end
end


%%
function bIsWrapperComplete = i_isWrapperComplete(sWrapperContext)
casCompleteWrapperTags = { ...
    ep_core_feval('ep_ec_tag_get', 'AUTOSAR Wrapper Model Complete'), ...
    ep_core_feval('ep_ec_tag_get', 'Adaptive AUTOSAR Wrapper Model')};
bIsWrapperComplete = any(strcmp(get_param(sWrapperContext, 'Tag'), casCompleteWrapperTags));
end


%%
function [sModelRefBlock, sErrMessage] = i_findAutosarModelReferenceBlockInContext(sContext, iSearchDepth)
sModelRefBlock = '';
sErrMessage    = '';

casModelRefBlocks = ep_core_feval('ep_find_system', sContext, ...
    'SearchDepth',      iSearchDepth, ...
    'FollowLinks',      'on',...
    'LookUnderMasks',   'all', ...
    'IncludeCommented', 'off',...
    'BlockType',        'ModelReference');
if isempty(casModelRefBlocks)
    sErrMessage = sprintf(...
        ['## An AUTOSAR wrapper model is being analyzed ', ...
        'but no ModelBlock referencing an AUTOSAR model has been found in "%s".'], ...
        sContext);
else
    sMainModelTag = ep_core_feval('ep_ec_tag_get', 'AUTOSAR Main ModelRef');
    if (numel(casModelRefBlocks) > 1)

        for i = 1:numel(casModelRefBlocks)
            sModelBlock = casModelRefBlocks{i};

            sModelRefBlockTag = get_param(sModelBlock, 'Tag');
            if strcmp(sModelRefBlockTag, sMainModelTag)
                sModelRefBlock = char(sModelBlock);
                break;
            end
        end
    else
        sModelRefBlock = char(casModelRefBlocks);
    end

    if isempty(sModelRefBlock)
        sErrMessage = sprintf(...
            ['## An AUTOSAR wrapper model is being analyzed ', ...
            'but no ModelBlock with Tag "%s" has been found in "%s".'], ...
            sMainModelTag, sContext);
    end
end
end


%%
% Criteria for valid wrapper variant subsystem for EP
% 1) contains variant 'orig'
% 2) contains variant 'dummy'
% 3) active variant == 'orig'
function [bIsValid, sError] = i_isValidVariantSubsystem(xVariantSub)
bIsValid = false;
sError = '';

if ~i_containsVariant(xVariantSub, 'orig')
    sError = sprintf('Variant subsystem "%s" does not contain expected variant "orig".', getfullname(xVariantSub));
    return;
end
if ~i_containsVariant(xVariantSub, 'dummy')
    sError = sprintf('Variant subsystem "%s" does not contain expected variant "dummy".', getfullname(xVariantSub));
    return;
end
if ~strcmp("orig", get_param(xVariantSub, 'ActiveVariant'))
    sError = sprintf('Active variant of variant subsystem "%s" is not "orig" as expected.', getfullname(xVariantSub));
    return;
end

bIsValid = true;
end


%%
function sAutosarModel = i_findAutosarModel(sModelRefBlock, bContinueLookingDeeper)
sAutosarModel = '';

if (nargin < 2)
    % if the referenced model is not an AUTOSAR model itself, we try look one level deeper in the reference hierarchy
    % --> relevant for Adaptive AUTOSAR Wrapper
    bContinueLookingDeeper = true;
end

sReferencedModel = get_param(sModelRefBlock, 'ModelName');

oKind = Eca.ModelKind.get(sReferencedModel);
if oKind.isAUTOSAR()
    sAutosarModel = sReferencedModel;

else
    if bContinueLookingDeeper
        iSearchDepth = 1;
        sNewModelRefBlock = i_findAutosarModelReferenceBlockInContext(sReferencedModel, iSearchDepth);
    
        bContinueLookingDeeper = false;
        sAutosarModel = i_findAutosarModel(sNewModelRefBlock, bContinueLookingDeeper);
    end
end
end


%%
function bContainsVariant = i_containsVariant(xVariantSub, sVariantControl)
if verLessThan('matlab', '9.13')
    bContainsVariant = ~isempty(find_system(xVariantSub, ...
        'SearchDepth',    1, ...
        'LookUnderMasks', 'all', ...
        'Variants',       'AllVariants', ...
        'VariantControl', sVariantControl));
else
    bContainsVariant = ~isempty(find_system(xVariantSub, ...
        'SearchDepth',    1, ...
        'LookUnderMasks', 'all', ...
        'MatchFilter',    @Simulink.match.allVariants, ...
        'VariantControl', sVariantControl));
end
end


%%
function casSubs = i_findDirectChildSubsystemsWithTag(sModelContext, sTag)
casSubs = ep_core_feval('ep_find_system', sModelContext, ...
    'SearchDepth', 1, ...
    'BlockType',   'SubSystem', ...
    'Tag',         sTag);
end


%%
function bIsVariantSub = i_isVariantSubsystem(xBlock)
bIsVariantSub = strcmpi(get_param(xBlock, 'Type'), 'block') && strcmpi(get_param(xBlock, 'Variant'), 'on');
end


function [bLookInside, bIgnoreEntity] = atgcv_m01_subsys_filter(hEntity, bConsiderAtomicUnit)
% This function is the callback function for the hierarchical reader. The
% function determines which subsystems are visible in the SL-Only feature.
%
% function  [bLookInside, bIgnoreEntity] = atgcv_m01_subsys_filter(hEntity)
% Callback of ep_simulink_hierarchy_reader.
%   INPUT               DESCRIPTION
%      hEntity              Entity which has to be evaluated.
%      bConsiderAtomicUnit  If true, only subsystems are considered where the property "TreatAsAtomicUnit" 
%                           is on. Otherwise, all subsystems are considered.
%
%   OUTPUT              DESCRIPTION
%     bLookInside         If true, consider the subsystems of the given
%                         entity
%     bIgnoreEntity       If true, ignore the given entity.
%
%   REMARKS
%


%%
% default ouput for invalid input
bLookInside   = false;
bIgnoreEntity = true;
if nargin < 2
    bConsiderAtomicUnit = false;
end
try
    try
        [~,~,sF] = fileparts(get(hEntity, 'ModelFile'));
        if strcmp(sF,'.slxp') || strcmp(sF, '.mdlp')
            return;
        end
    catch
    end
    
    % ignore empty or invalid model handles
    if (isempty(hEntity) || ~ishandle(hEntity))
        warning('ATGCV:MOD_ANA:WRONG_CALLBACK_CALL', 'Provided entity is not a valid handle!');
        return;
    end
    
    % Diagrams are the only entities without MaskType
    % --> handle them early, before asking for MaskType
    if i_isDiagram(hEntity)
        bLookInside   = true;
        bIgnoreEntity = false;
        return;
    end
    
    % Filter out deactivated variants our commented (out/through) subsystems
    if ~i_canBeFound(hEntity)
        bLookInside   = false;
        bIgnoreEntity = true;
        return;
    end
    
    % Check for Stateflow as a special case
    bIsStateflow = atgcv_sl_block_isa(hEntity, 'stateflow');
    if bIsStateflow
        if i_isChart(hEntity)
            bLookInside   = false;
            if bConsiderAtomicUnit && ~i_isAtomicUnit(hEntity)
                bIgnoreEntity = true;
            else
                bIgnoreEntity = false;
            end
        else
            % maybe a Truth table or some such
            bLookInside   = false;
            bIgnoreEntity = true;
        end
        return;
    end
    
    % Filter variation point
    if isfield(get_param(hEntity, 'objectParameters'), 'Variant')
        if strcmp('on', get_param(hEntity, 'Variant'))
            bLookInside   = true;
            oEntity = get_param(hEntity, 'Object');
            bIgnoreEntity = ~isa(oEntity, 'Simulink.ModelReference'); % note: do *not* ignore model references
            return;
        end
    end
        
    % TODO: think about storing black list as persistent data in function
    % BlackList == all known MaskTypes of Subsystems that shall be ignored
    casBlackList =  { ...
        'Dummy_Function', ...
        'Dummy_Inport', ...
        'TL_MainDialog', ...
        'Dummy_Outport', ...
        'CMBlock', ...
        'EmbeddedTester'};
    
    % MaskType is the key property that can be used for further filtering
    sMaskType = get_param(hEntity, 'MaskType');
    if any(strcmpi(sMaskType, casBlackList))
        bLookInside   = false;
        bIgnoreEntity = true;
        
    else
        % Additional Check:
        % Ignore all Subsystems with MaskType starting with "TL_".
        % Only exception: Frame-Subsystems of main TL-Subsystem
        %                 TL_SimFrame, TL_Enable
        %
        if ~isempty(regexpi(sMaskType, '^TL_.+', 'once'))
            if any(strcmpi(sMaskType, {'TL_SimFrame', 'TL_Enable'}))
                bLookInside   = true;
                bIgnoreEntity = false;
            else
                bLookInside   = false;
                bIgnoreEntity = true;
            end
        else
            % ignore a predefined Simulink block
            if i_isPredefinedSimulinkBlock(hEntity)
                bLookInside   = false;
                bIgnoreEntity = true;
            elseif bConsiderAtomicUnit && ~i_isAtomicUnit(hEntity)
                bLookInside   = true;
                bIgnoreEntity = true;                    
            else
                bLookInside   = true;
                bIgnoreEntity = false;
            end
        end
    end
catch oEx
    % nothing special but at least a warning
    warning('ATGCV:MOD_ANA:INTERNAL', 'SL-FILTER CALLBACK failed:\n%s: %s', oEx.identifier, oEx.message);
end
end


%%
function bCanBeFound = i_canBeFound(hEntity)
if atgcv_verLessThan('ML8.0')
    casAddProps = {};
else
    casAddProps = {'IncludeCommented', 'off'};
end
if atgcv_verLessThan('ML9.10')
    caxVariantFilter = {'Variants', 'ActiveVariants'};
else
    % new Variant filter for ML2021a and higher
    caxVariantFilter = {'MatchFilter', @Simulink.match.activeVariants};
end

% check for deactivated variants our-commented (out/through) subsystems
hParent = get_param(hEntity, 'Parent');
if isempty(hParent)
    bCanBeFound = true;
else
    ahFoundObjects = find_system(hParent, ...
        'SearchDepth',       1, ...
        'FollowLinks',       'on', ...
        'LookUnderMasks',    'all', ...
        caxVariantFilter{:}, ...
        casAddProps{:},      ...
        'Name',             get_param(hEntity, 'Name'));
    bCanBeFound = ~isempty(ahFoundObjects);
end
end


%%
function bIsPredefSL = i_isPredefinedSimulinkBlock(hBlock)
bIsPredefSL = false;
try %#ok<TRYNC>
    if strcmpi(get_param(hBlock, 'Mask'), 'on')
        sRefBlock = get_param(hBlock, 'ReferenceBlock');
        if (~isempty(sRefBlock) && strncmpi(sRefBlock, 'simulink', 8))
            bIsPredefSL = true;
        end
    end
end
end


%%
function bIsDiagram = i_isDiagram(hModelHandle)
bIsDiagram = strcmp(get_param(hModelHandle, 'Type'), 'block_diagram');
end


%%
function bIsChart = i_isChart(hModelHandle)
bIsChart = false;
try %#ok<TRYNC>
    sPath = getfullname(hModelHandle);
    oSfBlock = atgcv_m01_sf_block_object_get(sPath);
    bIsChart = ~isempty(oSfBlock) && isa(oSfBlock, 'Stateflow.Chart');
end
end


%%
function bIsAtomicUnit = i_isAtomicUnit(hBlock)
bIsAtomicUnit = false;
try %#ok<TRYNC>
    bIsModelRef = strcmp(get(hBlock, 'BlockType'), 'ModelReference');
    if (bIsModelRef)
        bIsAtomicUnit = true;
        return;
    end
    bIsTLTopLevel = strcmp(get_param(hBlock, 'Tag'), 'MIL Subsystem');
    sParam = get_param(hBlock, 'TreatAsAtomicUnit');
    bTreatAsAtomicIsOn = ~isempty(sParam) && strcmpi(sParam, 'on');
    
    bIsAtomicUnit = bTreatAsAtomicIsOn || bIsTLTopLevel || bIsModelRef;
end
end
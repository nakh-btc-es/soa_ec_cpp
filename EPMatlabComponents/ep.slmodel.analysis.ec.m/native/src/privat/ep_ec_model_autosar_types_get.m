function astTypes = ep_ec_model_autosar_types_get(varargin)
% Retrieves infos about AUTOSAR types in model.
%
% function astTypes = ep_ec_model_autosar_types_get(varargin)
%
%  INPUT              DESCRIPTION
%    varargin           ([Key, Value]*)  Key-value pairs with the following possibles values
%
%    Allowed Keys:            Meaning of the Value:
%    - ModelName                (string)*         Name of the model.
%    - Model2CodeTranslator     (obj)*            Instance of Eca.Model2CodeType that references the provided model.
%
%  OUTPUT            DESCRIPTION
%    astTypes           (struct)        Array of structured info with following fields
%      .sKind               (string)    kind of type: 'simple' | 'bus' | 'enum'
%      .sModelType          (string)    type as visible in the model
%      .sImpType            (string)    the base implementation type in code
%      .bIsEffectiveAppType (string)    flag if the the model type is really representing an AUTOSAR Application type
%                                       (note: if false, the model type is effectively the Implementation type)
%      .sEffectiveImplType  (string)    the effective implementation type (note: can be different from the base
%                                       implementation type for 'simple' and 'enum' types)
%      .astFields           (struct)    additional info array for busses/structs containing type info of the fields
%         .sName               (string)    the name of the struct field
%         .stType              (struct)    type info following the main return structure
%

%%
stArgs = i_evalArgs(varargin{:});

[casTypes, casBusTypes, casEnums] = i_findAllTypes(stArgs.ModelName);
if (isempty(casTypes) && isempty(casBusTypes) && isempty(casEnums))
    astTypes = [];
else
    astTypes = i_createTypeInfos(stArgs.Model2CodeTranslator, casTypes, casBusTypes, casEnums);
end
end


%%
function [casTypes, casBusTypes, casEnums] = i_findAllTypes(sModelName)
casTypes = {};
casBusTypes = {};
casEnums = {};

stWarningStatusNow = warning('off');
oOnCleanupRestoreWarningState = onCleanup(@() warning(stWarningStatusNow));

astVars = Simulink.findVars(sModelName, 'IncludeEnumTypes', 'on', 'SearchMethod', 'cached');
for i = 1:numel(astVars)
    sVarName = astVars(i).Name;
        
    try
        bIsParamOrSig = ep_core_evalin_global(sModelName, ...
            sprintf('isa(%s, ''Simulink.Parameter'') || isa(%s, ''Simulink.Signal'')', sVarName, sVarName));
        if bIsParamOrSig
            continue;
        end
        
        bIsAlias = ep_core_evalin_global(sModelName, sprintf('isa(%s, ''Simulink.AliasType'')', sVarName));
        if bIsAlias
            casTypes{end + 1} = sVarName; %#ok<AGROW>
            continue;
        end
        
        bIsNumType = ep_core_evalin_global(sModelName, sprintf('isa(%s, ''Simulink.NumericType'')', sVarName));
        if bIsNumType
            casTypes{end + 1} = sVarName; %#ok<AGROW>
            continue;
        end

        bIsBus = ep_core_evalin_global(sModelName, sprintf('isa(%s, ''Simulink.Bus'')', sVarName));
        if bIsBus
            casBusTypes{end + 1} = sVarName; %#ok<AGROW>
            continue;
        end

    catch
        if i_isEnum(sVarName)
            casEnums{end + 1} = sVarName; %#ok<AGROW>
        end
    end
end

% Add dynamic Enumerated Data Type classes (see EP-2217) not defined in DD.
astIntEnum = Simulink.findIntEnumType();
if ~isempty(astIntEnum)
    for i = 1:numel(astIntEnum)
        casEnums{end + 1} = astIntEnum(i).Name; %#ok<AGROW>
    end
end

casEnums = unique(casEnums); %rm duplicates
end


%%
function bIsEnum = i_isEnum(sName)
try
    bIsEnum = ~isempty(enumeration(sName));
catch
    bIsEnum = false;
end
end


%%
function astTypes = i_createTypeInfos(oModel2CodeTranslator, casTypes, casBusTypes, casEnums)
astSimpleTypes = i_getModelCodeTypeInfos(casTypes, 'simple', oModel2CodeTranslator);
astBusTypes    = i_getModelCodeTypeInfos(casBusTypes, 'bus', oModel2CodeTranslator);
astEnumTypes   = i_getModelCodeTypeInfos(casEnums, 'enum', oModel2CodeTranslator);

astTypes = horzcat( ...
    reshape(astSimpleTypes, 1, []), ...
    reshape(astBusTypes, 1, []), ...
    reshape(astEnumTypes, 1, []));
end


%%
function astTypes = i_getModelCodeTypeInfos(casModelTypes, sKind, oModel2CodeTranslator)
astTypes = cellfun(@(s) i_getModelCodeTypeInfo(s, sKind, oModel2CodeTranslator), casModelTypes);
end


%%
function stType = i_getModelCodeTypeInfo(sModelType, sKind, oModel2CodeTranslator)
[sImpType, bIsRteType] = oModel2CodeTranslator.translateToImplementationType(sModelType);
stType = struct( ...
    'sKind',               sKind, ...
    'sModelType',          sModelType, ...
    'sImpCodeType',        sImpType, ...
    'sBaseCodeType',       '', ...
    'bIsRteType',          bIsRteType, ...
    'astFields',           []);
if strcmp(sKind, 'bus')
    hResolverFunc = atgcv_m01_generic_resolver_get(oModel2CodeTranslator.getModel());
    oSig = ep_sl_signal_from_bus_object_get(sModelType, hResolverFunc);
    stType.astFields = arrayfun(@(o) i_getFieldInfoForSignal(o, oModel2CodeTranslator), oSig.getSubSignals());
else
    % for non-bus model types we can hope to get the code base type
    stType.sBaseCodeType = oModel2CodeTranslator.translateToBaseType(sModelType);
end
end


%%
function stField = i_getFieldInfoForSignal(oSig, oModel2CodeTranslator)
if oSig.isBus()
    sKind = 'bus';
elseif oSig.stTypeInfo_.bIsEnum
    sKind = 'enum';
else
    sKind = 'simple';
end
stType = i_getModelCodeTypeInfos({oSig.stTypeInfo_.sType}, sKind, oModel2CodeTranslator);
stField = struct( ...
    'sName',  oSig.getName(), ...
    'stType', stType);
end


%%
function stArgs = i_evalArgs(varargin)
stArgs = struct( ...
    'ModelName',            '', ...
    'Model2CodeTranslator', []);

casValidKeys = fieldnames(stArgs);
stUserArgs = ep_core_transform_args(varargin, casValidKeys);

casFoundKeys = fieldnames(stUserArgs);
for i = 1:numel(casFoundKeys)
    sKey = casFoundKeys{i};
    stArgs.(sKey) = stUserArgs.(sKey);
end

bConsistencyEnsured = false;
if isempty(stArgs.ModelName)
    if ~isempty(stArgs.Model2CodeTranslator)
        stArgs.ModelName = stArgs.Model2CodeTranslator.getModel();
        bConsistencyEnsured = true;
    else
        stArgs.ModelName = bdroot;
    end
    if isempty(stArgs.ModelName)
        error('EP:USAGE_ERROR', 'Accessible model could not be found. Cannot retrieve types.');
    end
end
if isempty(stArgs.Model2CodeTranslator)
    stArgs.Model2CodeTranslator = Eca.Model2CodeType(stArgs.ModelName, true);
    bConsistencyEnsured = true;
end

if ~bConsistencyEnsured
    if ~strcmp(stArgs.Model2CodeTranslator.getModel(), stArgs.ModelName)
        error('EP:USAGE_ERROR', 'Mismatch found: Model (%s) -- Model2CodeTranslator (%s).', ...
            stArgs.Model2CodeTranslator.getModel(), stArgs.ModelName);
    end
end
end

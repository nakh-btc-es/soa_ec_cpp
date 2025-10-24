function sContent = ep_ec_autosar_extended_rte_types_create(varargin)
% Replaces the original "Rte_Type.h" created by the EC code generator with an extended version that is complete for all types.
%
% function ep_ec_autosar_extended_rte_types_create(varargin)
%
%  INPUT              DESCRIPTION
%    varargin           ([Key, Value]*)  Key-value pairs with the following possibles values
%
%    Allowed Keys:            Meaning of the Value:
%    - ModelName                (string)     Name of the open(!) model. (default == bdroot)
%
%  OUTPUT            DESCRIPTION
%    --
%

%%
sContent = '';
stArgs = i_evalArgs(varargin{:});

sRteTypeFile = i_findRteTypeFile(stArgs.ModelName);
if isempty(sRteTypeFile)
    warning('EP:RTE_TYPE_NOT_FOUND', 'Header file Rte_Type.h for model "%s" not found.', stArgs.ModelName);
    return;
end

if ~i_isRteTypeFileExtended(sRteTypeFile)
    sContent = i_createExendedContentRteFile(stArgs.ModelName, sRteTypeFile);
    if (nargout < 1)
        i_replaceRteFile(sContent, sRteTypeFile);
    else
        warning('EP:DEBUG', ...
            'Debug mode: Returning content of extension as string instead of replacing the "Rte_Type.h".');
    end
end
end


%%
function sContent = i_createExendedContentRteFile(sModelName, sRteTypeFile)
casDefinedTypes = ep_code_file_typedefs_get(sRteTypeFile);

[casTypedefLines, casEnumTypedefLines, casEnumDefines] = i_getTypedefAndDefineLines(sModelName, casDefinedTypes);
sContent = i_createHeaderContent(casTypedefLines, casEnumTypedefLines, casEnumDefines);
end


%%
function sContent = i_createHeaderContent(casTypedefLines, casEnumTypedefLines, casEnumDefines)
sOrigTypeHeader = i_getOrigHeaderNewName();
if verLessThan('matlab', '23.2') %#ok<VERLESSMATLAB>
    casIncludeHeaders = {sprintf('#include "%s"', sOrigTypeHeader)};
else
    % for ML2023b the base types are taken from the platform types and need to be made known by the included rtwtypes.h
    casIncludeHeaders = {sprintf('#include "%s"', sOrigTypeHeader), '#include "rtwtypes.h"'};
end

sHeaderGuard = 'BTC_EP_EXTENSION_RTE_TYPE_H';
casLines = { ...
    casIncludeHeaders{:}, ...
    '', ...
    sprintf('#ifndef %s', sHeaderGuard), ...
    sprintf('#define %s', sHeaderGuard), ...
    '', ...
    '/* Enum types */', ...
    casEnumTypedefLines{:}, ...
    '', ...
    casEnumDefines{:}, ...
    '', ...
    '/* Alias/Numeric types */', ...
    casTypedefLines{:}, ...
    '', ...
    sprintf('#endif /* %s */', sHeaderGuard)}; %#ok<CCAT> 

sContent = strjoin(casLines, '\n');
end


%%
function bIsExended = i_isRteTypeFileExtended(sRteTypeFile)
bIsExended = false;
try %#ok<TRYNC>
    sContent = fileread(sRteTypeFile);

    % if the original header was replaced there should be an include for original header with its new name
    sBtcReplacementPattern = regexptranslate('escape', sprintf('#include "%s"', i_getOrigHeaderNewName()));
    bIsExended = ~isempty(regexp(sContent, sBtcReplacementPattern, 'once'));
end
end


%%
function sOrigHeader = i_getOrigHeaderNewName()
sOrigHeader = 'EC_Rte_Type.h';
end


%%
function i_replaceRteFile(sContent, sRteTypeFile)
sPath = fileparts(sRteTypeFile);
sNewLocation = fullfile(sPath, i_getOrigHeaderNewName());
movefile(sRteTypeFile, sNewLocation);
i_writeContent(sContent, sRteTypeFile);
end


%%
function i_writeContent(sContent, sHeaderFile)
if ~isempty(sContent)
    hFid = fopen(sHeaderFile, 'w');
    fprintf(hFid, '%s', sContent);
    fclose(hFid);
end
end


%%
function [casTypedefLines, casEnumTypedefLines, casEnumDefines] = i_getTypedefAndDefineLines(sModelName, casDefinedTypes)
% already defined types that we can skip
jDefinedTypes = i_createSet(casDefinedTypes);

% all types that we need to consider
astAllTypes = ep_ec_model_autosar_types_get('ModelName', sModelName);
if ~isempty(astAllTypes)
    astAllTypes = astAllTypes([astAllTypes(:).bIsRteType]);
end

if ~isempty(astAllTypes)
    % Note: the order of the typedefs: "Enum, Simple, Bus" is extremly important for the recursive algo when later
    % handling busses (struct types)!

    % Enum types
    astEnumTypes = astAllTypes(strcmp({astAllTypes(:).sKind}, 'enum'));
    [casEnumTypedefLines, casEnumDefines] = i_getEnumTypedefs(astEnumTypes, sModelName, jDefinedTypes);
    
    % Simple alias types
    astSimpleTypes = astAllTypes(strcmp({astAllTypes(:).sKind}, 'simple'));
    casTypedefLines = i_getSimpleTypedefs(astSimpleTypes, jDefinedTypes);
    
    % Struct types
    astBusTypes = astAllTypes(strcmp({astAllTypes(:).sKind}, 'bus'));
    casBusTypedefLines = i_getBusTypedefs(astBusTypes, sModelName, jDefinedTypes);
    
    casTypedefLines = [casTypedefLines, casBusTypedefLines];

else
    casTypedefLines = {};
    casEnumTypedefLines = {};
    casEnumDefines = {};
end
end


%%
function [casEnumTypedefLines, casEnumDefines] = i_getEnumTypedefs(astEnumTypes, sModelName, jDefinedTypes)
casEnumTypedefLines = {};
casEnumDefines = {};

for i = 1:numel(astEnumTypes)
    stType = astEnumTypes(i);
    bTypeWasAdded = false;

    if ~stType.bIsRteType
        continue;
    end

    sImpType = stType.sImpCodeType;
    if (~jDefinedTypes.contains(sImpType) && ~isempty(stType.sBaseCodeType))
        casEnumTypedefLines{end + 1} = sprintf('typedef %s %s;', stType.sBaseCodeType, sImpType); %#ok<AGROW>
        jDefinedTypes.add(sImpType);
        bTypeWasAdded = true;

        casEnumDefines = [casEnumDefines, i_getEnumDefines(sModelName, stType)]; %#ok<AGROW>
    end

    sAppType = stType.sModelType;
    if (~jDefinedTypes.contains(sAppType) && jDefinedTypes.contains(sImpType))
        casEnumTypedefLines{end + 1} = sprintf('typedef %s %s;', sImpType, sAppType); %#ok<AGROW>
        jDefinedTypes.add(sAppType);
        bTypeWasAdded = true;
    end

    if bTypeWasAdded % add an empty line as separator between types for easier readability
        casEnumTypedefLines{end + 1} = ''; %#ok<AGROW>
    end
end
end


%%
function casSimpleTypedefLines = i_getSimpleTypedefs(astSimpleTypes, jDefinedTypes)
casSimpleTypedefLines = {};

for i = 1:numel(astSimpleTypes)
    stType = astSimpleTypes(i);
    bTypeWasAdded = false;

    if ~stType.bIsRteType
        continue;
    end

    sImpType = stType.sImpCodeType;
    if (~jDefinedTypes.contains(sImpType) && ~isempty(stType.sBaseCodeType))
        casSimpleTypedefLines{end + 1} = sprintf('typedef %s %s;', stType.sBaseCodeType, sImpType); %#ok<AGROW>
        jDefinedTypes.add(sImpType);
        bTypeWasAdded = true;
    end

    sAppType = stType.sModelType;
    if (~jDefinedTypes.contains(sAppType) && jDefinedTypes.contains(sImpType))
        casSimpleTypedefLines{end + 1} = sprintf('typedef %s %s;', sImpType, sAppType); %#ok<AGROW>
        jDefinedTypes.add(sAppType);
        bTypeWasAdded = true;
    end

    if bTypeWasAdded % add an empty line as separator between types for easier readability
        casSimpleTypedefLines{end + 1} = ''; %#ok<AGROW>
    end
end
end


%%
function casBusTypedefLines = i_getBusTypedefs(astBusTypes, sModel, jDefinedTypes)
casBusTypedefLines = {};

for i = 1:numel(astBusTypes)
    stType = astBusTypes(i);
    bTypeWasAdded = false;

    if ~stType.bIsRteType
        continue;
    end

    sImpType = stType.sImpCodeType;
    if ~jDefinedTypes.contains(sImpType)
        casBusTypedefLines = [casBusTypedefLines, i_getStructTypedefForBus(stType, sModel, jDefinedTypes)]; %#ok<AGROW>
        jDefinedTypes.add(sImpType);
        bTypeWasAdded = true;
    end

    sAppType = stType.sModelType;
    if (~jDefinedTypes.contains(sAppType) && jDefinedTypes.contains(sImpType))
        casBusTypedefLines{end + 1} = sprintf('typedef %s %s;', sImpType, sAppType); %#ok<AGROW>
        jDefinedTypes.add(sAppType);
        bTypeWasAdded = true;
    end

    if bTypeWasAdded % add an empty line as separator between types for easier readability
        casBusTypedefLines{end + 1} = ''; %#ok<AGROW>
    end
end
end


%%
function casStructTypedef = i_getStructTypedefForBus(stBusType, sModel, jDefinedTypes)
casStructTypedef = {};

% Note: The types of the fields have to be known before using them here! Since we have already handled the Enum types
%       and the Simple alias types before on a global level, we just need to take care of the nested bus types here.
astFields = stBusType.astFields;
for i = 1:numel(astFields)
    stField = astFields(i);
    if strcmp(stField.stType.sKind, 'bus')
        casStructTypedef = [casStructTypedef, i_getBusTypedefs(stField.stType.sKind, sModel, jDefinedTypes)]; %#ok<AGROW>
    end
end

% after making sure the field types were all defined, we can define now the main struct type
sImpType = stBusType.sImpCodeType;

casStructTypedef{end + 1} = 'typedef struct {';
for i = 1:numel(astFields)
    sFieldName = astFields(i).sName;
    sFieldType = astFields(i).stType.sImpCodeType;
    casStructTypedef{end + 1} = sprintf('  %s %s;', sFieldType, sFieldName); %#ok<AGROW>
end
casStructTypedef{end + 1} = sprintf('} %s;', sImpType);
jDefinedTypes.add(sImpType);
end


%%
function jSet = i_createSet(casStrings)
jSet = java.util.HashSet;
for i = 1:numel(casStrings)
    jSet.add(casStrings{i});
end
end


%%
% EP-3333: Enum values are sometimes not defined in the codebase of the original AUTOSAR model. However, for the wrapper
%          and the stub code we potentially need the first (default) enum value to be present in order to initialize 
%          inports/outports/parameters.
%          Currently, the behavior of the codegenerator suggests that such initializations are only done for enum types
%          with a default value that is non-zero.
%          --> Even though the enum value define might already be available, we create a definition here just to make
%              sure that the wrapper and stub code is compilable.
function casDefineLines = i_getEnumDefines(~, stType)
casDefineLines = {};
stDefaultEnumElem = i_getDefaultEnumElement(stType.sModelType);
if ~isempty(stDefaultEnumElem.sName)
    if (stDefaultEnumElem.iValue ~= 0)
        casDefineLines = { ...
            sprintf('#ifndef %s', stDefaultEnumElem.sName), ...
            sprintf('#define %s (%d)', stDefaultEnumElem.sName, stDefaultEnumElem.iValue), ...
            '#endif', ...
            ''};
    end
end
end


%%
function stDefaultEnumElem = i_getDefaultEnumElement(sModelType)
stDefaultEnumElem = struct( ...
    'sName', '', ...
    'iValue', []);
try
    aoEnumVals = enumeration(sModelType);
catch
    return;
end

if ~isempty(aoEnumVals)
    try
        oDefaultEnum = aoEnumVals(1).getDefaultValue();
    catch
        oDefaultEnum = aoEnumVals(1); % no default value defined --> in this case the first element is the default
    end
    try
        bWithClassName = oDefaultEnum.addClassNameToEnumNames();
    catch
        bWithClassName = false;
    end
    if bWithClassName
        stDefaultEnumElem.sName = sprintf('%s_%s', class(oDefaultEnum), char(oDefaultEnum));
    else
        stDefaultEnumElem.sName = char(oDefaultEnum);
    end
    stDefaultEnumElem.iValue = oDefaultEnum.int64;
end
end


%%
function sRteTypeFile = i_findRteTypeFile(sModel)
sRteTypeFile = '';

sBuildDir = RTW.getBuildDir(sModel).BuildDirectory;
if exist(sBuildDir, 'dir')
    sStubDir = fullfile(sBuildDir, 'stub');

    if exist(sStubDir, 'dir')
        sRteTypeCandidate = fullfile(sStubDir, 'Rte_Type.h');

        if exist(sRteTypeCandidate, 'file')
            sRteTypeFile = sRteTypeCandidate;
        end
    end
end
end


%%
function stArgs = i_evalArgs(varargin)
stArgs = struct( ...
    'ModelName',  '');

casValidKeys = fieldnames(stArgs);
stUserArgs = ep_core_transform_args(varargin, casValidKeys);

casFoundKeys = fieldnames(stUserArgs);
for i = 1:numel(casFoundKeys)
    sKey = casFoundKeys{i};
    stArgs.(sKey) = stUserArgs.(sKey);
end

if isempty(stArgs.ModelName)
    stArgs.ModelName = bdroot;
end
end

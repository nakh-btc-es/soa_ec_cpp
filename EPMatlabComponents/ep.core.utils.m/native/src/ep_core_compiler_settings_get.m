function ep_core_compiler_settings_get(varargin)
% Evaluates the compiler settings of the active mex compiler
%
% stMEXCompilerSettings = ep_core_compiler_settings_get(varargin)
%
%   INPUT
%    - varargin           ([Key, Value]*)        Key-value pairs with the following
%                                                possibles values. Inputs marked with (*)
%                                                are mandatory.
%
%       Key(string):                             Meaning of the Value:
%           XMLOutputFile               (String)*           Absolute path for the compiler settings export.
%                                                           If not set, no xml export is triggered.
%   OUTPUT
%       - stMEXCompilerSettings         (struct)            Settings of the MEX compiler and linker
%                                                           Null, if no supported compiler setting can be
%                                                           found.
%           .stCompiler                 (struct)            Settings of the MEX compiler
%           .sName                      (string)            Name of the compiler
%           .sAdditionalInfo            (string)            Additional information about the compiler
%           .sExecutable                (string)            Name of the compiler executable
%           .sLocation                  (string)            Location to the compiler executable
%           .sBitWidth                  (string)            Bit width of the compiler (32 Bit or 64 Bit)
%           .casCompilerFlags           (cell array)        List of default compiler flags
%           .hDefaultDefines            (HashMap)           Map of default compiler defines
%                                                           (The key describes the compiler define itself. The map value,
%                                                           the value of the compiler define.)
%           .hOutputObjectFileOption    (HashMap            Object output file option
%                                                           (The key describes the option itself. The value if a space
%                                                           after the option is required for the compiler call.)
%           .hObjectGenerationOption    (HashMap)           Object generation option
%                                                           (The key describes the option itself. The value if a space
%                                                           after the option is required for the compiler call.)
%           .casDefaultIncludePaths     (cell array)        List of default include paths
%           .hIncludeFolderOption       (HashMap)           Include folder option
%                                                           (The key describes the option itself. The value if a space
%                                                           after the option is required for the compiler call.)
%           .hMacroDefineOption         (HashMap)           Macro define option
%                                                           (The key describes the option itself. The value if a space
%                                                           after the option is required for the compiler call.)
%           .hEnvironmentVariables      (HashMap)           Map of environment variables
%                                                           (The key describes the variable itself. The map value,
%                                                           the value of the variable.)
%           .castRegistrySettings       (cell array)        Registry entries
%         .stLibTool                    (struct)            Setting of the Lib Tool
%           .sExecutable                (string)            Name of the Lib Tool executable
%           .sLocation                  (string)            Location of the Lib Tool executable
%           .hOutputFileOption          (HashMap)           Output file option for Lib Tool
%                                                           (The key describes the option itself. The value if a space
%                                                           after the option is required for the Lib Tool call.)
%         .stLinker                     (struct)            Setting of the MEX linker
%           .sExecutable                (string)            Name of the linker executable
%           .sLocation                  (string)            Location of the linker executable
%           .hDllOptionForLinker        (HashMap)           Dll option for linker
%                                                           (The key describes the option itself. The value if a space
%                                                           after the option is required for the linker call.)
%           .casLinkerFlags             (string)            List of default linker flags
%           .hOutputFileOption          (HashMap)           Output file option for linker
%                                                           (The key describes the option itself. The value if a space
%                                                           after the option is required for the linker call.)
%
% $$$COPYRIGHT$$$-2014


%%
persistent p_xSettingsMapC;
persistent p_xSettingsMapCpp;
persistent p_xSettingsMapC99;
if isempty(p_xSettingsMapC)
    p_xSettingsMapC = containers.Map;
    mlock;
end
if isempty(p_xSettingsMapCpp)
    p_xSettingsMapCpp = containers.Map;
    mlock;
end
if isempty(p_xSettingsMapC99)
    p_xSettingsMapC99 = containers.Map;
    mlock;
end

if i_doUnlock(varargin{:})
    munlock;
    return;
end

%%
try
    % Parser input parameters
    stArgs = i_parseInputArguments(varargin{:});
    
    % Get the information from 'mex.getCompilerConfigurations()'
    stMEXConfigC = i_getCompilerConfigurations('C');
    [stMEXCompilerSettingsC, p_xSettingsMapC] = i_getCompilerSettings(stMEXConfigC, p_xSettingsMapC);
    stMEXCompilerSettingsC = i_appendCompileModeToHashMapFields(stMEXCompilerSettingsC, 'C90');
    stMEXCompilerSettings = i_mergeCompilerSettings(stMEXCompilerSettingsC, stMEXCompilerSettingsC, 'C90');
    
    stMEXConfigC99 = i_getC99Config(stMEXConfigC);
    if ~isempty(stMEXConfigC99)
        [stMEXCompilerSettingsC99, p_xSettingsMapC99] = i_getCompilerSettings(stMEXConfigC99, p_xSettingsMapC99);
        stMEXCompilerSettingsC99 = i_appendCompileModeToHashMapFields(stMEXCompilerSettingsC99, 'C99');
        stMEXCompilerSettings = i_mergeCompilerSettings(stMEXCompilerSettings, stMEXCompilerSettingsC99, 'C99');
    end
    
    stMEXConfigCpp = i_getCompilerConfigurations('C++');
    if ~i_areCompilersEqual(stMEXConfigCpp, stMEXConfigC)
        stMEXConfigCpp = i_findCppMexCompiler(stMEXConfigC);
        if ~isempty(stMEXConfigCpp)
            warning('EP:STD:MEX_NOT_EQUAL', ['The mex compiler ''', stMEXConfigCpp.Name, ''' will be ', ...
                'used for C++ Code compilation in EP.']);
        end
    end
    if ~isempty(stMEXConfigCpp)
        [stMEXCompilerSettingsCpp, p_xSettingsMapCpp] = i_getCompilerSettings(stMEXConfigCpp, p_xSettingsMapCpp);
        stMEXCompilerSettingsCpp = i_appendCompileModeToHashMapFields(stMEXCompilerSettingsCpp, 'CPP');
        stMEXCompilerSettings = i_mergeCompilerSettings(stMEXCompilerSettings, stMEXCompilerSettingsCpp, 'CPP');
    end
    
    stMEXCompilerSettings = i_reduceMEXCompilerSettings(stMEXCompilerSettings);
    i_generateOutputFile(stMEXCompilerSettings, stArgs.sXmlOutputFile);
    
catch oEx
    % TODO: Introduce a message which can be handled by the message service.
    warning('EP:STD:MEXOPTS_READ_FAILED', 'Failed evaluating the mex compiler settings.');
    rethrow(oEx);
end
end


%%
function bDoUnlock = i_doUnlock(varargin)
bDoUnlock = (nargin == 1) && strcmp('unlock', varargin{1});
end


%%
function stMexConfig = i_getCompilerConfigurations(sLanguage)
oMexConfig = mex.getCompilerConfigurations(sLanguage, 'Selected');
if isempty(oMexConfig)
    error('EP:STD:NO_COMPILER_SELECTED', ...
        'Currently no mex compiler is selected for "%s" in Matlab. Cannot continue until a valid compiler has been set.', ...
        sLanguage);
end

% converting object with properties to a struct in order to being able
% to add additional fields.
stMexConfig = i_toStruct(oMexConfig);
stMexConfig.bUseC99 = false;
end


%%
function stMexConfig = i_getC99Config(stMexConfigIn)
stMexConfig = stMexConfigIn;
stMexConfig.bUseC99 = true;
end


%%
function [stMEXCompilerSettings, p_xSettingsMap] = i_getCompilerSettings(stMEXConfig, p_xSettingsMap)
% Check if the compiler used by the mex interface is supported
sCompilerName = i_supportedCompiler(stMEXConfig);
if p_xSettingsMap.isKey(sCompilerName)
    stMEXCompilerSettings = p_xSettingsMap(sCompilerName);
else
    if ~isempty(regexpi(sCompilerName, 'MSVC', 'ONCE')) || ~isempty(regexpi(sCompilerName, 'MSSDK', 'ONCE'))
        stMEXCompilerSettings = ep_core_compiler_msvc_get(stMEXConfig, sCompilerName);
    elseif ~isempty(regexpi(sCompilerName, 'MINGW', 'ONCE'))
        stMEXCompilerSettings = ep_core_compiler_mingw_get(stMEXConfig, sCompilerName);
    elseif ~isempty(regexpi(sCompilerName, 'g(cc|\+\+)', 'ONCE'))
        stMEXCompilerSettings = ep_core_compiler_gcc_get(stMEXConfig, sCompilerName);
    else
        % TODO: Introduce a message which can be handled by the message service.
        warning('EP:STD:MEX_NOT_SUPPORTED', ['The mex compiler ''', stMEXConfig.Name, ''' is not supported.']);
        throw(MException('EP:STD:MEX_NOT_SUPPORTED', 'The mex compiler ''%s'' is not supported.', stMEXConfig.Name));
    end
    p_xSettingsMap(sCompilerName) = stMEXCompilerSettings;
end
end


%%
function stMergedCompilerSettings = i_mergeCompilerSettings(stCompilerSettingsBasis, stCompilerSettingsAdd, Suffix)
stMergedCompilerSettings = struct(...
    'stCompiler', i_mergeStruct(stCompilerSettingsBasis.stCompiler, stCompilerSettingsAdd.stCompiler, Suffix), ...
    'stLibTool', i_mergeStruct(stCompilerSettingsBasis.stLibTool, stCompilerSettingsAdd.stLibTool, Suffix), ...
    'stLinker', i_mergeStruct(stCompilerSettingsBasis.stLinker, stCompilerSettingsAdd.stLinker, Suffix));
end


%%
function stMEXCompilerSettings = i_appendCompileModeToHashMapFields(stMEXCompilerSettings, sCompileMode)
sField = 'hDefaultDefines';
stMEXCompilerSettings.stCompiler.([sField, sCompileMode]) = stMEXCompilerSettings.stCompiler.(sField);
stMEXCompilerSettings.stCompiler.(sField) = [];
end


%%
function stMerged = i_mergeStruct(stBasis, stAdd, sSuffix)
casFieldNames = fieldnames(stBasis);
sFilteredField = 'hDefaultDefines';
abFilter = contains(casFieldNames, sFilteredField);
casFields = casFieldNames(~abFilter);
casFilteredFields = casFieldNames(abFilter);

for i=1:numel(casFields)
    sFieldName = casFields{i};
    stMerged.(sFieldName) = stBasis.(sFieldName);
    if i_needExtraField(stBasis, stAdd, sFieldName)
        stMerged.([sFieldName, sSuffix]) = stAdd.(sFieldName);
    end
end

for i = 1:numel(casFilteredFields)
    sFieldName = casFilteredFields{i};
    if strcmp(sFieldName, sFilteredField)
        stMerged.(sFilteredField) = stBasis.(sFilteredField);
        stMerged.([sFieldName, sSuffix]) = stAdd.([sFieldName, sSuffix]);
    else
        stMerged.(sFieldName) = stBasis.(sFieldName);
    end
end
end


%%
function bNeedExtraField = i_needExtraField(stBasis, stAdd, sFieldName)
if isa(stBasis.(sFieldName), 'java.util.HashMap')
    bNeedExtraField = false;
    jKeyList = stBasis.(sFieldName).keySet.toArray;
    jKeyListAdd = stAdd.(sFieldName).keySet.toArray;
    if length(jKeyList) ~= length(jKeyListAdd)
        bNeedExtraField = true;
        return;
    end
    for i=1:length(jKeyList)
        sKey = jKeyList(i);
        sKeyAdd = jKeyListAdd(i);
        sValue = stBasis.(sFieldName).get(sKey);
        sValueAdd = stAdd.(sFieldName).get(sKeyAdd);
        if ~strcmp(sKey, sKeyAdd) || ~(strcmp(sValue, sValueAdd) || (isempty(sValue) && isempty(sValueAdd)))
            bNeedExtraField = true;
            return;
        end
    end
else
    if ~isfield(stAdd, sFieldName)
        bNeedExtraField = false;
    else
        bNeedExtraField = ~isequal(stBasis.(sFieldName), stAdd.(sFieldName)) && ~strcmp(sFieldName, 'sName');
    end
end
end


%%
function stMEXCompilerSettings = i_reduceMEXCompilerSettings(stMEXCompilerSettings)
sField = 'hDefaultDefines';
casCompileModes = {'C90' 'C99' 'CPP'};
casFields = strcat(sField, casCompileModes);

caoHashMaps = repmat({{}}, 1, numel(casFields));
for i = 1:numel(casFields)
    if isfield(stMEXCompilerSettings.stCompiler, casFields{i})
        caoHashMaps{i} = stMEXCompilerSettings.stCompiler.(casFields{i});
    end
end
if ~cellfun(@isempty, caoHashMaps)
    if caoHashMaps{1}.equals(caoHashMaps{2}) && caoHashMaps{1}.equals(caoHashMaps{3})
        stMEXCompilerSettings.stCompiler.(sField) = caoHashMaps{1};
        for i = 1:numel(casFields)
            stMEXCompilerSettings.stCompiler.(casFields{i}) = [];
        end
    else
        stMEXCompilerSettings.stCompiler.(sField) = [];
    end
end
end


%%
function i_generateOutputFile(stMexConfig, sOutputFile)
try
    hRootNode = mxx_xmltree('create', 'EpexCompilerSetup');
    
    % Set Compiler
    stCompiler = stMexConfig.stCompiler;
    hCompilerNode = mxx_xmltree('add_node', hRootNode, 'compiler');
    
    mxx_xmltree('set_attribute', hCompilerNode, 'name', stCompiler.sName);
    
    i_setAttribute(hCompilerNode, 'additionalInfo', stCompiler, 'sAdditionalInfo');
    i_setAttribute(hCompilerNode, 'executable', stCompiler, 'sExecutable');
    i_setAttribute(hCompilerNode, 'location', stCompiler, 'sLocation');
    i_setAttribute(hCompilerNode, 'bitWidth', stCompiler, 'sBitWidth');
    
    i_addHashMapAsSimpleNodeForCAndCpp(hCompilerNode, 'outputObjectFileOption', stCompiler, 'hOutputObjectFileOption');
    
    i_addHashMapAsSimpleNodeForCAndCpp(hCompilerNode, 'objectGenerationOption', stCompiler, 'hObjectGenerationOption');
    
    i_addCasAsNodeWithChildrenForCandCpp(hCompilerNode, 'defaultIncludePaths', stCompiler, 'casDefaultIncludePaths');
    
    i_addCasAsNodeWithChildrenForCandCpp(hCompilerNode, 'defaultCompilerFlags', stCompiler, 'casCompilerFlags');
    
    i_addHashMapAsNoteWithChildrenForCandCpp(hCompilerNode, 'defaultDefines', stCompiler, 'hDefaultDefines');
    
    i_addHashMapAsSimpleNodeForCAndCpp(hCompilerNode, 'includeFolderOption', stCompiler, 'hIncludeFolderOption');
    
    i_addHashMapAsSimpleNodeForCAndCpp(hCompilerNode, 'macroDefineOption', stCompiler, 'hMacroDefineOption');
    
    i_addHashMapAsNoteWithChildrenForCandCpp(hCompilerNode, 'environmentVariables', stCompiler, 'hEnvironmentVariables');
    
    if (~isempty(stCompiler.castRegistrySettings))
        % Note: currently not necessary
    end
    
    % Set Lib Tool information
    stLibTool = stMexConfig.stLibTool;
    hLibToolNode = mxx_xmltree('add_node', hRootNode, 'libtool');
    i_setAttribute(hLibToolNode, 'executable', stLibTool, 'sExecutable');
    i_setAttribute(hLibToolNode, 'location', stLibTool, 'sLocation');
    
    i_addHashMapAsSimpleNodeForCAndCpp(hLibToolNode, 'outputFileOption', stLibTool, 'hOutputFileOption');
    
    
    % Set Linker information
    stLinker = stMexConfig.stLinker;
    hLinkerNode = mxx_xmltree('add_node', hRootNode, 'linker');
    i_setAttribute(hLinkerNode, 'executable', stLinker, 'sExecutable');
    i_setAttribute(hLinkerNode, 'location', stLinker, 'sLocation');
    
    i_addCasAsNodeWithChildrenForCandCpp(hLinkerNode, 'defaultLinkerFlags', stLinker, 'casLinkerFlags');
    
    i_addHashMapAsSimpleNodeForCAndCpp(hLinkerNode, 'dllOption', stLinker, 'hDllOptionForLinker');
    
    i_addHashMapAsSimpleNodeForCAndCpp(hLinkerNode, 'outputFileOption', stLinker, 'hOutputFileOption');
    
    i_addCasAsNodeWithChildrenForCandCpp(hLinkerNode, 'additionalSourceFiles', stLinker, 'casAdditionalSourceFiles');
    
    mxx_xmltree('save', hRootNode, sOutputFile);
    mxx_xmltree('clear', hRootNode);
catch exception % #ok
    if ~isempty(hRootNode)
        mxx_xmltree('clear', hRootNode);
    end
    rethrow(exception);
end
end


%%
function i_setAttribute(hNode, sAttibuteName, stStructure, sFieldName)
mxx_xmltree('set_attribute', hNode, sAttibuteName, stStructure.(sFieldName));
if isfield(stStructure, [sFieldName, 'CPP'])
    mxx_xmltree('set_attribute', hNode, [sAttibuteName ,'CPP'], stStructure.([sFieldName, 'CPP']));
end
end


%%
function i_addHashMapAsSimpleNodeForCAndCpp(hRoot, sNodeName, stStructure, sFieldName)
if ~isempty(stStructure.(sFieldName))
    i_addHashMapAsSimpleNode(hRoot, sNodeName, stStructure.(sFieldName));
    if isfield(stStructure, [sFieldName, 'CPP'])
        i_addHashMapAsSimpleNode(hRoot, [sNodeName ,'CPP'], stStructure.([sFieldName, 'CPP']));
    end
end
end


%%
function i_addHashMapAsSimpleNode(hRoot, sNodeName, hHashMap)
hNode = mxx_xmltree('add_node', hRoot, sNodeName);
hKeyList = hHashMap.keySet.toArray;
for i=1:length(hKeyList)
    mxx_xmltree('set_attribute', hNode, 'option', hKeyList(i));
    mxx_xmltree('set_attribute', hNode, 'spaceKeyValue', hHashMap.get(hKeyList(i)));
end
if isempty(hKeyList)
    mxx_xmltree('delete_node', hNode);
end
end


%%
function i_addHashMapAsNoteWithChildrenForCandCpp(hRoot, sNodeName, stStructure, sFieldName)
i_addHasHMapNotesIfPresent(hRoot, sNodeName, stStructure, sFieldName, '');
i_addHasHMapNotesIfPresent(hRoot, sNodeName, stStructure, sFieldName, 'C90');
i_addHasHMapNotesIfPresent(hRoot, sNodeName, stStructure, sFieldName, 'C99');
i_addHasHMapNotesIfPresent(hRoot, sNodeName, stStructure, sFieldName, 'CPP');
end


%%
function i_addHasHMapNotesIfPresent(hRoot, sNodeName, stStructure, sFieldName, sSuffix)
if isfield(stStructure, [sFieldName, sSuffix]) && ~isempty(stStructure.([sFieldName, sSuffix]))
    i_addHashMapAsNoteWithChildren(hRoot, [sNodeName ,sSuffix], stStructure.([sFieldName, sSuffix]));
end
end


%%
function i_addHashMapAsNoteWithChildren(hRoot, sNodeName, hHashMap)
hNode = mxx_xmltree('add_node', hRoot, sNodeName);
hKeyList = hHashMap.keySet.toArray;
for i=1:length(hKeyList)
    hPair = mxx_xmltree('add_node', hNode, 'pair');
    mxx_xmltree('set_attribute', hPair, 'key', hKeyList(i));
    sValue = char(hHashMap.get(hKeyList(i)));
    if isempty(sValue)
        mxx_xmltree('set_attribute', hPair, 'value', '');
    else
        mxx_xmltree('set_attribute', hPair, 'value', sValue);
    end
end
if isempty(hKeyList)
    mxx_xmltree('delete_node', hNode);
end
end


%%
function i_addCasAsNodeWithChildrenForCandCpp(hRoot, sNodeName, stStructure, sFieldName)
if ~isempty(stStructure.(sFieldName))
    i_addCasAsNodeWithChildren(hRoot, sNodeName, stStructure.(sFieldName));
    if isfield(stStructure, [sFieldName, 'C99'])
        i_addCasAsNodeWithChildren(hRoot, [sNodeName ,'C99'], stStructure.([sFieldName, 'C99']));
    end
    if isfield(stStructure, [sFieldName, 'CPP'])
        i_addCasAsNodeWithChildren(hRoot, [sNodeName ,'CPP'], stStructure.([sFieldName, 'CPP']));
    end
end
end


%%
function i_addCasAsNodeWithChildren(hRoot, sNodeName, casValues)
hNode = mxx_xmltree('add_node', hRoot, sNodeName);
for i=1:length(casValues)
    hItem = mxx_xmltree('add_node', hNode, 'item');
    mxx_xmltree('set_attribute', hItem, 'value', casValues{i});
end
end


%%
function stArgs = i_parseInputArguments(varargin)
% Definition of the return value (stArgs) with default values.
stArgs = struct('sXmlOutputFile', fullfile(pwd, 'my_mex_compiler.xml'));

% Parse inputs from main function
casValidKeys = {'XMLOutputFile'};
stArgsTmp = ep_core_transform_args(varargin, casValidKeys);

% mainly a re-mapping to new fields
stKeyMap = struct('XMLOutputFile', 'sXmlOutputFile');

casKnownKeys = fieldnames(stKeyMap);
for i = 1:length(casKnownKeys)
    sKey = casKnownKeys{i};
    if isfield(stArgsTmp, sKey)
        stArgs.(stKeyMap.(sKey)) = stArgsTmp.(sKey);
    end
end
end


%%
function sCompilerSupported = i_supportedCompiler(stMEXConfig)
casSupportedCompilers = { ...
    'MSVC70', ...
    'MSVC71', ...
    'MSVC80', ...
    'MSVC80FREE', ...
    'MSVC90', ...
    'MSVC90FREE', ...
    'MSVC100', ...
    'MSVC100FREE', ...
    'MSVC110', ...
    'MSVC120', ...
    'MSVC140', ...
    'MSVC150', ...
    'MSVC160', ...
    'MSVC170', ...
    'MSSDK71', ...
    'MINGW64', ...
    'gcc', ...
    'MSVCPP90', ...
    'MSVCPP90FREE', ...
    'MSVCPP100', ...
    'MSVCPP100FREE', ...
    'MSVCPP120', ...
    'MSVCPP140', ...
    'MSVCPP150', ...
    'MSVCPP150', ...
    'MSVCPP160', ...
    'MSVCPP170', ...
    'MSSDK71CPP', ...
    'mingw64-g++', ...
    'g++'};

if any(strcmpi(fieldnames(stMEXConfig), 'ShortName'))
    sCompiler = stMEXConfig.ShortName;
else
    sBatFile = fullfile(prefdir, 'mexopts.bat');
    if exist(sBatFile, 'file')
        sCompiler = i_read_compiler_from_bat_file(sBatFile);
    else
        sCompiler = ''; % not yet set by User
    end
end
if any(strcmpi(sCompiler, casSupportedCompilers))
    sCompilerSupported = sCompiler;
else
    sCompilerSupported = '';
end
end


%%
% Try to find the C++ compiler equivalent for a given C-Compiler.
function bCompilersEqual = i_areCompilersEqual(stMEXConfigCpp, stMEXConfigC)
if isempty(stMEXConfigCpp) || isempty(stMEXConfigCpp.Name)
    warning('EP:STD:MEX_NOT_EQUAL', 'The C++ mex compiler is not defined.');
    bCompilersEqual = false;
else
    oLocationC = java.io.File(stMEXConfigC.Location);
    oLocationCpp = java.io.File(stMEXConfigCpp.Location);
    bCompilersEqual = oLocationCpp.equals(oLocationC) || ...
        (oLocationC.getName().equalsIgnoreCase('gcc') && oLocationCpp.getName().equalsIgnoreCase('g++'));
    if ~bCompilersEqual
        warning('EP:STD:MEX_NOT_EQUAL', ['The mex compiler ''', stMEXConfigC.Name, ''' for C Code ' ...
            'and the mex Compiler ''', stMEXConfigCpp.Name, ''' for C++ Code are not the same.']);
    end
end
end


%%
% Try to find the C++ compiler equivalent for a given C-Compiler.
function stMEXConfigCpp = i_findCppMexCompiler(stMEXConfigC)
astMEXConfigCpp = mex.getCompilerConfigurations('C++', 'Installed');
if isempty(astMEXConfigCpp)
    stMEXConfigCpp = [];
else
    % it is possible to have two similar entries for the same compiler, allways use the first one: Bug EP-3202
    stMEXConfigCpp = astMEXConfigCpp(strcmpi({astMEXConfigCpp.Location}, stMEXConfigC.Location));
    if (length(stMEXConfigCpp) > 1)
        stMEXConfigCpp = stMEXConfigCpp(1);
    end
end
end


%%
% Try to parse the ShortName of the current Compiler from the mexopts.bat.
function sCompiler = i_read_compiler_from_bat_file(sBatFile)
% open MEX options bat file and read second line
fid = fopen(sBatFile,'rt');
fgetl(fid);
sLine = fgetl(fid);
fclose(fid);

casFound = regexp(sLine, '([\w\d]+)OPTS\.BAT', 'once', 'tokens');
if ~isempty(casFound)
    sCompiler = casFound{1};
else
    sCompiler = '';
end
end


%%
function stVar = i_toStruct(oObj)
casProps = properties(oObj);
stVar = struct;
for i=1:length(casProps)
    sPropName = casProps{i};
    xVal = oObj.(sPropName);
    stVar = setfield(stVar, sPropName, xVal); %#ok
end
end

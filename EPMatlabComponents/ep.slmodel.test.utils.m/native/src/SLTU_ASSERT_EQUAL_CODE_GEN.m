function SLTU_ASSERT_EQUAL_CODE_GEN(sExpectedCodegenFile, sTestCodegenFile)
% Asserts that the Codegen XML file is equal to the expected XML file.
%


%%
if SLTU_update_testdata_mode()
    MU_MESSAGE('Updating expectation values in CodeModel XML. No equality checking performed!');
    sltu_copyfile(sTestCodegenFile, sExpectedCodegenFile);
    return;
end


%%
% Note: currently just a trivial compare that all functions are mentioned
% TODO: --> extend functionality (preferably on Java level)
[hExpRoot,  oOnCleanupCloseExpDoc]  = i_openXml(sExpectedCodegenFile); %#ok<ASGLU> onCleanup object
[hTestRoot, oOnCleanupCloseTestDoc] = i_openXml(sTestCodegenFile);     %#ok<ASGLU> onCleanup object

SLTU_COMPARE_FILES(hExpRoot, hTestRoot);
SLTU_COMPARE_DEFINES(hExpRoot, hTestRoot);
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end


%%
function SLTU_COMPARE_FILES(hExpRoot, hTestRoot)
sltu_compare_generic(hExpRoot, hTestRoot, @i_getFiles, @(m1, m2) sltu_compare_maps_generic(m1, m2, 'file'));
end


%%
function SLTU_COMPARE_DEFINES(hExpRoot, hTestRoot)
sltu_compare_generic(hExpRoot, hTestRoot, @i_getDefines, @sltu_compare_defines);
end


%%
function sltu_compare_defines(oExpectedDefineMap, oTestDefineMap)
% ------------------
% compiler defines that are env-specific and should not be checked directly for equality
casDefineBlacklist = { ...
    '__LCC__', ...
    '__GCC__', ...
    '__MSC__'
    };
oExpectedDefineMap.remove(intersect(oExpectedDefineMap.keys, casDefineBlacklist));

casFoundCompilerDefines = intersect(oTestDefineMap.keys, casDefineBlacklist);
oTestDefineMap.remove(casFoundCompilerDefines);
SLTU_ASSERT_FALSE(isempty(casFoundCompilerDefines), 'Expected compiler define was not found.');

% ------------------
% special defines, depending on versions
sTlVerMacro = 'BTC_EP_TL_VERSION';
oExpectedDefineMap(sTlVerMacro) = i_getExpectedTlVerDefine(sTlVerMacro); % replace with current TL-version

% only for TL >= TL5.0
sSilMacro = '__SIL__';
if oExpectedDefineMap.isKey(sSilMacro)
    oExpectedDefineMap.remove(sSilMacro);
end
if ~verLessThan('tl', '5.0')
    SLTU_ASSERT_TRUE(oTestDefineMap.isKey(sSilMacro), 'Expecting define "__SIL__" for TL versions equal-higer TL5.0.');
    oTestDefineMap.remove(sSilMacro);
end

% ------------
% rest can be checked via generic maps compre
sltu_compare_maps_generic(oExpectedDefineMap, oTestDefineMap, 'file');
end


%%
function stExpDef = i_getExpectedTlVerDefine(sMacroName)
stVer = ver('tl');
sValue = regexprep(stVer.Version, '(\.|p.*)', '');

stExpDef = struct( ...
    'name',  sMacroName, ...
    'value', sValue);
end


%%
function oDefinesMap = i_getDefines(hRoot)
oDefinesMap = containers.Map;
astDefines = i_readAllDefines(hRoot);
for i = 1:numel(astDefines)
    oDefinesMap(astDefines(i).name) = astDefines(i);
end
end


%%
function astDefs = i_readAllDefines(hRoot)
ahDefs = mxx_xmltree('get_nodes', hRoot, '/cg:CodeGeneration/cg:Defines/cg:Define');
astDefs = arrayfun(@(hFunc) i_readDefine(hFunc), ahDefs);
end


%%
function stFunc = i_readDefine(hDefine)
stFunc = mxx_xmltree('get_attributes', hDefine, '.', ...
    'name', ...
    'value');
end


%%
function oFileMap = i_getFiles(hRoot)
oFileMap = containers.Map;
astFiles = i_readAllFiles(hRoot);
for i = 1:numel(astFiles)
    oFileMap(astFiles(i).name) = astFiles(i);
end
end


%%
function astFiles = i_readAllFiles(hRoot)
ahFiles = mxx_xmltree('get_nodes', hRoot, '/cg:CodeGeneration/cg:FileList/cg:File');
astFiles = arrayfun(@(hFile) i_readFile(hFile), ahFiles);
end


%%
function stFile = i_readFile(hFile)
stFile = mxx_xmltree('get_attributes', hFile, '.', ...
    'name', ...
    'kind', ...
    'translation_unit');
end


%%
function sltu_compare_generic(hExpRoot, hTestRoot, hGetMapFunc, hCompareMapsFunc)
oExpMap  = feval(hGetMapFunc, hExpRoot);
oFoundMap = feval(hGetMapFunc, hTestRoot);

feval(hCompareMapsFunc, oExpMap, oFoundMap);
end


%%
function sltu_compare_maps_generic(oExpMap, oFoundMap, sObjKind)
casExpected = oExpMap.keys;
for i = 1:numel(casExpected)
    sExpected = casExpected{i};
    
    if oFoundMap.isKey(sExpected)
        stExp = oExpMap(sExpected);
        stFound = oFoundMap(sExpected);
        
        bIsEqual = isequal(stExp, stFound);
        SLTU_ASSERT_TRUE(bIsEqual, 'Found unexpected properties in %s "%s".', sObjKind, sExpected);
    else
        SLTU_FAIL('Expected %s "%s" not found.', sObjKind, sExpected);
    end
end

casFound = oFoundMap.keys;
casUnexpected = setdiff(casFound, casExpected);
for i = 1:numel(casUnexpected)
    SLTU_FAIL('Found unexpected %s "%s".', sObjKind, casUnexpected{i});
end
end

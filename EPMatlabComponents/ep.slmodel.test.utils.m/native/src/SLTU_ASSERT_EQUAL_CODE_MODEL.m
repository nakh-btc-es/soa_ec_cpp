function SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, sTestCodeModelFile, bIncludeLibraryFiles)
% Asserts that the CodeModel XML file is equal to the expected XML file.
%

%%
if (nargin < 3)
    bIncludeLibraryFiles = false;
end


if ~exist(sExpectedCodeModelFile, 'file')
    if SLTU_update_testdata_mode()
        MU_MESSAGE('Creating expected version of the CodeModel XML. No equality checks performed!');
        sltu_copyfile(sTestCodeModelFile, sExpectedCodeModelFile);
    else
        SLTU_FAIL('No expected values found. Cannot perform any checking.');
    end
else
    % Note: currently just a trivial compare that all functions are mentioned
    % TODO: --> extend functionality (preferably on Java level)
    [hExpRoot,  oOnCleanupCloseExpDoc]  = i_openXml(sExpectedCodeModelFile); %#ok<ASGLU> onCleanup object
    [hTestRoot, oOnCleanupCloseTestDoc] = i_openXml(sTestCodeModelFile);     %#ok<ASGLU> onCleanup object
    
    casFileDiffs = SLTU_COMPARE_FILES(hExpRoot, hTestRoot, bIncludeLibraryFiles);
    casFuncDiffs = SLTU_COMPARE_FUNCTIONS(hExpRoot, hTestRoot);
    casAllDiffs = horzcat(reshape(casFileDiffs, 1, []), reshape(casFuncDiffs, 1, []));
    
    bDiffsFound = ~isempty(casAllDiffs);
    if bDiffsFound
        if SLTU_update_testdata_mode()
            MU_MESSAGE('Updating expected values in the CodeModel XML. No equality checks performed!');
            sltu_copyfile(sTestCodeModelFile, sExpectedCodeModelFile);
        else
            for i = 1:numel(casAllDiffs)
                SLTU_FAIL('%s', casAllDiffs{i});
            end
        end
    else
        MU_PASS();
    end
end
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end


%%
function casDiffs = SLTU_COMPARE_FILES(hExpRoot, hTestRoot, bIncludeLibraryFiles)
if bIncludeLibraryFiles
    mExpMap   = i_getFiles(hExpRoot);
    mFoundMap = i_getFiles(hTestRoot);
else
    mExpMap   = i_getNonLibraryFiles(hExpRoot);
    mFoundMap = i_getNonLibraryFiles(hTestRoot);
end
casDiffs = sltu_compare_generic(mExpMap, mFoundMap, 'file');
end


%%
function casDiffs = SLTU_COMPARE_FUNCTIONS(hExpRoot, hTestRoot)
mExpMap   = i_getFunctions(hExpRoot);
mFoundMap = i_getFunctions(hTestRoot);

casDiffs = sltu_compare_generic(mExpMap, mFoundMap, 'function');
end


%%
function oFuncMap = i_getFunctions(hRoot)
oFuncMap = containers.Map;
astFuncs = i_readAllFunctions(hRoot);
for i = 1:numel(astFuncs)
    oFuncMap(astFuncs(i).name) = astFuncs(i);
end
end


%%
function astFuncs = i_readAllFunctions(hRoot)
ahFuncs = mxx_xmltree('get_nodes', hRoot, '/CodeModel/Functions/Function');
astFuncs = arrayfun(@(h) i_readFunction(h), ahFuncs);
end


%%
function stFunc = i_readFunction(hFunc)
stFunc = mxx_xmltree('get_attributes', hFunc, '.', ...
    'name', ...
    'initFunc', ...
    'preStepFunc', ...
    'postStepFunc');
stFunc.Interface = i_readInterface(hFunc);
end


%%
function astInterfaceObj = i_readInterface(hFunc)
astInterfaceObj = mxx_xmltree('get_attributes', hFunc, './Interface/InterfaceObj', ...
    'cal', ...
    'var', ...
    'initVal');
end


%%
function oFileMap = i_getFiles(hRoot, hFilter)
if (nargin < 2)
    hFilter = [];
end

oFileMap = containers.Map;
astFiles = i_readAllFiles(hRoot);
for i = 1:numel(astFiles)
    stFile = astFiles(i);
    
    bAcceptFile = isempty(hFilter) || feval(hFilter, stFile);
    if bAcceptFile
        oFileMap(stFile.name) = stFile;
    end
end
end


%%
function bIsNonLibFile = i_isNonLibraryFile(stFile)
bIsNonLibFile = ~strcmp(stFile.kind, 'library');
end


%%
function oFileMap = i_getNonLibraryFiles(hRoot)
oFileMap = i_getFiles(hRoot, @i_isNonLibraryFile);
end


%%
function astFiles = i_readAllFiles(hRoot)
ahFiles = mxx_xmltree('get_nodes', hRoot, '/CodeModel/Files/File');
astFiles = arrayfun(@(hFile) i_readFile(hFile), ahFiles);
end


%%
function stFile = i_readFile(hFile)
stFile = mxx_xmltree('get_attributes', hFile, '.', ...
    'name', ...
    'kind', ...
    'annotate');
end


%%
function casDiffs = sltu_compare_generic(mExpMap, mFoundMap, sObjKind)
casDiffs = {};

casExpected = mExpMap.keys;
for i = 1:numel(casExpected)
    sExpected = casExpected{i};
    
    if mFoundMap.isKey(sExpected)
        stExp = mExpMap(sExpected);
        stFound = mFoundMap(sExpected);
        
        bIsEqual = isequal(stExp, stFound);
        if ~bIsEqual
            casDiffs{end + 1} = sprintf('Found unexpected properties in %s "%s".', sObjKind, sExpected); %#ok<AGROW>
        end
    else
        casDiffs{end + 1} = sprintf('Expected %s "%s" not found.', sObjKind, sExpected); %#ok<AGROW>
    end
end

casFound = mFoundMap.keys;
casUnexpected = setdiff(casFound, casExpected);
for i = 1:numel(casUnexpected)
    casDiffs{end + 1} = sprintf('Found unexpected %s "%s".', sObjKind, casUnexpected{i}); %#ok<AGROW>
end
end

function ut_ep_epdev_40759
% Check fix for Bug EP_638
%
%  REMARKS
%       Bug: Mapping contains wrong pointer references "->" for the interface variables of the C-scope.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_epdev_40759');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'NestedSharedFunction');

sTlModel     = 'shared_nested';
sTlModelFile = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile      = fullfile(sTestRoot, [sTlModel, '.dd']);


%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);
xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
try
    i_checkMapping(stOpt.sMappingResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx));
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_checkMapping(sMappingResultFile)
if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));


sScopePath = 'top_A/Subsystem/top_A/sub_B/sub_multi_gain1/sub_C';
casExpectedInOutMappings = { ...
    'Input:In1 <--> SgainID1_In1', ...
    'Output:Out1 <--> SgainID1_Out1->'};
i_assertExpectedMappings(hDoc, sScopePath, casExpectedInOutMappings);
end


%%
function i_assertExpectedMappings(hDoc, sScopePath, casExpectedInOutMappings)
oFoundInOutMappingsMap = i_getAllInOutMappingsForScope(hDoc, sScopePath);
for i = 1:length(casExpectedInOutMappings)
    sExpMapping = casExpectedInOutMappings{i};
    
    if oFoundInOutMappingsMap.isKey(sExpMapping)        
        oFoundInOutMappingsMap.remove(sExpMapping);
    else
        MU_FAIL(sprintf('%s: Expected mapping "%s" was not found.', sScopePath, sExpMapping));
    end
end
casUnexpected = oFoundInOutMappingsMap.keys;
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('%s: Found unexpected mapping "%s".', sScopePath, casUnexpected{i}));
end
end


%%
function oFoundInOut = i_getAllInOutMappingsForScope(hDoc, sScopePath)
oFoundInOut = containers.Map;

sXPath = sprintf( ...
    ['/Mappings/ArchitectureMapping/ScopeMapping[Path[@path="%s"]]/', ...
    'InterfaceObjectMapping[@kind="Input" or @kind="Output"]'], sScopePath);
ahIfMaps = mxx_xmltree('get_nodes', hDoc, sXPath);
for i = 1:length(ahIfMaps)
    hIfMap = ahIfMaps(i);
    
    sKind = mxx_xmltree('get_attribute', hIfMap, 'kind');
    casMilPaths = i_getFullInterfaceObjPaths(hIfMap, 'id0');
    casSilPaths = i_getFullInterfaceObjPaths(hIfMap, 'id1');

    for k = 1:length(casMilPaths)
        sKey = [sKind, ':', casMilPaths{k}, ' <--> ', casSilPaths{k}];
        oFoundInOut(sKey) = true;
    end
end
end


%%
function casFullPaths = i_getFullInterfaceObjPaths(hIfMap, sID)
stRoot = mxx_xmltree('get_attributes', hIfMap, sprintf('./Path[@refId="%s"]', sID), 'path');
astLeafs = mxx_xmltree('get_attributes', hIfMap, sprintf('./SignalMapping/Path[@refId="%s"]', sID), 'path');

if isempty(astLeafs)
    casFullPaths = {stRoot.path};
else
    casFullPaths = arrayfun(@(stLeaf) [stRoot.path, stLeaf.path], astLeafs, 'UniformOutput', false);
end
end


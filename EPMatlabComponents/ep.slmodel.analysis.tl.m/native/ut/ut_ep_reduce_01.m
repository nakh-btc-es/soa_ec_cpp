function ut_ep_reduce_01
% Check model reduce functionality (PROM-13672 and similar).
%
%

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'reduce_01');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'HierarchyWithCal');

sTlModel      = 'hierarchy_sut';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

sAddModelInfoEmpty      = fullfile(sTestRoot, 'AddModelInfo_00_empty.xml');
sAddModelInfoBlacklist0 = fullfile(sTestRoot, 'AddModelInfo_00_as_blacklist.xml');
sAddModelInfo1          = fullfile(sTestRoot, 'AddModelInfo_01.xml');
sAddModelInfoBlacklist1 = fullfile(sTestRoot, 'AddModelInfo_01_as_blacklist.xml');
sAddModelInfo2          = fullfile(sTestRoot, 'AddModelInfo_02.xml');
sAddModelInfoBlacklist2 = fullfile(sTestRoot, 'AddModelInfo_02_as_blacklist.xml');
sAddModelInfoBlacklist3 = fullfile(sTestRoot, 'AddModelInfo_03_as_blacklist.xml');


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));

stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'xEnv',          xEnv);
stOpt = ut_prepare_options(stOpt, sResultDir);


%% execute test and check
sContext = 'NO reduce';

stExp = struct( ...
    'casScopes', {{'top_A', 'sub_B1', 'sub_B2', 'sub_B3', 'sub_C1', 'sub_C2', 'sub_C3'}}, ...
    'casStacks', ...
    {{'top_A', ...
    'top_A|sub_B1', 'top_A|sub_B2', 'top_A|sub_B3', ...
    'top_A|sub_B1|sub_C1', 'top_A|sub_B2|sub_C2', 'top_A|sub_B3|sub_C3'}}, ...
    'casParams', {{'cal_A', 'cal_B1', 'cal_B2', 'cal_B3', 'cal_C1', 'cal_C2', 'cal_C3'}});

ut_ep_model_analyse(stOpt);
try 
    i_checkReduce(sContext, stOpt, stExp);
catch oEx
    MU_FAIL(i_printException(sContext, oEx)); 
end

% --- still no reduce but via empty list ----------
sContext = [sContext, ' (empty list)'];

stOpt.sAddModelInfo = sAddModelInfoEmpty;
ut_ep_model_analyse(stOpt);
try 
    i_checkReduce(sContext, stOpt, stExp);
catch oEx
    MU_FAIL(i_printException(sContext, oEx)); 
end

% --- still no reduce but via blacklist ----------
sContext = [sContext, ' (blacklist)'];

stOpt.sAddModelInfo = sAddModelInfoBlacklist0;
ut_ep_model_analyse(stOpt);
try 
    i_checkReduce(sContext, stOpt, stExp);
catch oEx
    MU_FAIL(i_printException(sContext, oEx)); 
end


%% execute test and check
sContext = 'SOME reduce';

stExp = struct( ...
    'casScopes', {{'top_A', 'sub_B1', 'sub_C3'}}, ...
    'casStacks', {{'top_A', 'top_A|sub_B1', 'top_A|sub_C3'}}, ...
    'casParams', {{'cal_A', 'cal_B3', 'cal_C1'}});

stOpt.sAddModelInfo = sAddModelInfo1;
ut_ep_model_analyse(stOpt);
try 
    i_checkReduce(sContext, stOpt, stExp);
catch oEx
    MU_FAIL(i_printException(sContext, oEx)); 
end

% --- via blacklist ----------
sContext = [sContext, ' (blacklist)'];

stOpt.sAddModelInfo = sAddModelInfoBlacklist1;
ut_ep_model_analyse(stOpt);
try 
    i_checkReduce(sContext, stOpt, stExp);
catch oEx
    MU_FAIL(i_printException(sContext, oEx)); 
end


%% execute test and check
sContext = 'MOST reduce';

stOpt.sAddModelInfo = sAddModelInfo2;
ut_ep_model_analyse(stOpt);

stExp = struct( ...
    'casScopes', {{'top_A'}}, ...
    'casStacks', {{'top_A'}}, ...
    'casParams', {{}});
try 
    i_checkReduce(sContext, stOpt, stExp);
catch oEx
    MU_FAIL(i_printException(sContext, oEx)); 
end

% --- via blacklist ----------
sContext = [sContext, ' (blacklist)'];

stOpt.sAddModelInfo = sAddModelInfoBlacklist2;
ut_ep_model_analyse(stOpt);
try 
    i_checkReduce(sContext, stOpt, stExp);
catch oEx
    MU_FAIL(i_printException(sContext, oEx)); 
end

% --- via blacklist and obsolete model name ----------
sContext = [sContext, ' (blacklist)'];

stOpt.sAddModelInfo = sAddModelInfoBlacklist3;
ut_ep_model_analyse(stOpt);
try 
    i_checkReduce(sContext, stOpt, stExp);
catch oEx
    MU_FAIL(i_printException(sContext, oEx)); 
end

end

%%
function i_checkReduce(sContext, stOpt, stExp)
stFound = i_getScopesAndParamsAndStacksFromMapping(stOpt.sMappingResultFile);
i_compareExpectedAndFound([sContext, ' --> Mapping'], stExp, stFound);

% following formats have no info about Stacks --> remove the expected values
stExp = rmfield(stExp, 'casStacks');
stFound = i_getScopesAndParamsFromCodeModel(stOpt.sCResultFile);
i_compareExpectedAndFound([sContext, ' --> CodeModel'], stExp, stFound);

stFound = i_getScopesAndParamsFromTlArch(stOpt.sTlResultFile);
i_compareExpectedAndFound([sContext, ' --> TL Arch'], stExp, stFound);
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_compareExpectedAndFound(sContext, stExp, stFound)
if isfield(stExp, 'casScopes')
    i_assertSetsEqual([sContext, ' --> Scopes'], stExp.casScopes, stFound.casScopes);
end
if isfield(stExp, 'casStacks')
    i_assertSetsEqual([sContext, ' --> Stacks'], stExp.casStacks, stFound.casStacks);
end
if isfield(stExp, 'casParams')
    i_assertSetsEqual([sContext, ' --> Params'], stExp.casParams, stFound.casParams);
end
end


%%
function i_assertSetsEqual(sContext, casExpected, casFound)
casMissing = setdiff(casExpected, casFound);
casUnexpected = setdiff(casFound, casExpected);
for i = 1:length(casMissing)
    MU_FAIL(sprintf('%s:\nExpected object "%s" not found.', sContext, casMissing{i}));
end
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('%s:\nUnexpected object "%s" found.', sContext, casUnexpected{i}));
end
end


%% TL Arch
function stFound = i_getScopesAndParamsFromTlArch(sTlResultFile)
stFound = struct( ...
    'casScopes', {{}}, ...
    'casParams', {{}});
if ~exist(sTlResultFile, 'file')
    MU_FAIL('TL Arch XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sTlResultFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hDoc));

astRes = mxx_xmltree('get_attributes', hDoc, '/tl:TargetLinkArchitecture/model/subsystem', 'name');
if ~isempty(astRes)
    stFound.casScopes = {astRes(:).name};
end

stRoot = mxx_xmltree('get_attributes', hDoc, ...
    '/tl:TargetLinkArchitecture/model/rootSystem', 'refSubsysID');
astRes = mxx_xmltree('get_attributes', hDoc, sprintf( ...
    '/tl:TargetLinkArchitecture/model/subsystem[@subsysID="%s"]/calibration', stRoot.refSubsysID), 'name');
if ~isempty(astRes)
    stFound.casParams = {astRes(:).name};
end
end


%% CodeModel
function stFound = i_getScopesAndParamsFromCodeModel(sCodeModel)
stFound = struct( ...
    'casScopes', {{}}, ...
    'casParams', {{}});
if ~exist(sCodeModel, 'file')
    MU_FAIL('CodeModel XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sCodeModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

astRes = mxx_xmltree('get_attributes', hDoc, '/CodeModel/Functions/Function', 'name');
if ~isempty(astRes)
    stFound.casScopes = {astRes(:).name};
    for i = 1:length(stFound.casScopes)
        sSubName = i_getScopeNameFromFuncName(stFound.casScopes{i});
        stFound.casScopes{i} = sSubName;
    end
end

astRes = mxx_xmltree('get_attributes', hDoc, ...
    '/CodeModel/Functions/Function/Interface/InterfaceObj[@kind="cal"]', 'var');
if ~isempty(astRes)
    stFound.casParams = unique({astRes(:).var});
end
end


%%
function sScopeName = i_getScopeNameFromFuncName(sFuncName)
sScopeName = regexprep(sFuncName, '^Sa\d+_', '');
end


%% Mapping
function stFound = i_getScopesAndParamsAndStacksFromMapping(sMappingResultFile)
stFound = struct( ...
    'casScopes', {{}}, ...
    'casStacks', {{}}, ...
    'casParams', {{}});
if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

astRes = mxx_xmltree('get_attributes', hDoc, ...
    '/Mappings/ArchitectureMapping/ScopeMapping/Path[@refId="id0"]', 'path');
if ~isempty(astRes)
    stFound.casScopes = cellfun(@i_getNameFromPath, {astRes(:).path}, 'UniformOutput', false);
end
astRes = mxx_xmltree('get_attributes', hDoc, ...
    '/Mappings/ArchitectureMapping/ScopeMapping/Path[@refId="id1"]', 'path');
if ~isempty(astRes)
    stFound.casStacks = cellfun(@i_getStackFromPath, {astRes(:).path}, 'UniformOutput', false);
end
astRes = mxx_xmltree('get_attributes', hDoc, ...
    '/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Parameter"]/Path[@refId="id0"]', 'path');
if ~isempty(astRes)
    stFound.casParams = unique(cellfun(@i_getNameFromPath, {astRes(:).path}, 'UniformOutput', false));
end
end


%%
% Note: Assumption --> no escaped path separators ("//") in path (otherwise the algo is wrong!)
function sName = i_getNameFromPath(sPath)
sName = regexprep(sPath, '.*/', '');
end


%%
% Note: Assumption --> no escaped path separators ("//") in path (otherwise the algo is wrong!)
function sStack = i_getStackFromPath(sPath)
casParts = textscan(sPath, '%s', 'delimiter', '/');
casParts = casParts{1};
casParts = cellfun(@i_getScopeNameFromStackPart, casParts, 'UniformOutput', false);
sStack = sprintf('%s|', casParts{:});
sStack(end) = [];
end


%%
% stackPart  --> Module.c:1:Sa3_subB2
% scopeName  --> sub_B2
function sScope = i_getScopeNameFromStackPart(sStackPart)
sScope = i_getScopeNameFromFuncName(regexprep(sStackPart, '.*:', ''));
end

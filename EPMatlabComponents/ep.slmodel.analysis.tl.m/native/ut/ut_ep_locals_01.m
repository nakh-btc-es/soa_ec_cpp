function ut_ep_locals_01
% Check handling of multiple Locals in same block.
%
%  REMARKS
%       UT is related to PROM-12989.
%

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'locals_01');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'disp_model');

sTlModel      = 'disp_model1';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sTlInitScript = fullfile(sTestRoot, 'init_model.m');
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));

%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);

ut_ep_model_analyse(stOpt);


%% check test results
try 
    i_check_mapping(stOpt.sMappingResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%% Mapping
function i_check_mapping(sMappingResultFile)
if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

nExp = 9;
ahScopeMappings = mxx_xmltree('get_nodes', hDoc, '/Mappings/ArchitectureMapping/ScopeMapping');
MU_ASSERT_TRUE(length(ahScopeMappings) == nExp, ...
    sprintf('Expecting %d Scope mappings instead of %d.', nExp, length(ahScopeMappings)));
for i = 1:length(ahScopeMappings)
    i_assert_local_path_unique(ahScopeMappings(i));
end
end


%%
function i_assert_local_path_unique(hScopeMapping)
% Locals that are not in SF-Charts should end with the port number of the corresponding block as index
sExpectedPattern = '.*\(\d+\)$';

oLocalsMap = containers.Map;
astRes = ...
    mxx_xmltree('get_attributes', hScopeMapping, './InterfaceObjectMapping[@kind="Local"]/Path[@refId="id0"]', 'path');
MU_ASSERT_TRUE(~isempty(astRes), 'Unexpected: Found a Scope without Locals.');
for i = 1:length(astRes)
    sLocal = astRes(i).path;
    if oLocalsMap.isKey(sLocal)
        MU_FAIL(sprintf('Found Local "%s" multiple times in the Interface mapping of the same Scope.', sLocal));
    else
        oLocalsMap(sLocal) = true;
    end
    
    % !implicit knowledge: all Locals in SF charts have the string "chart" inside their path
    if isempty(strfind(sLocal, 'chart'))
        MU_ASSERT_FALSE(isempty(regexp(sLocal, sExpectedPattern, 'once')), ...
            sprintf('Local "%s" does not match the expected RegExp Pattern "%s".', sLocal, sExpectedPattern)); 
    else
        MU_ASSERT_TRUE(isempty(regexp(sLocal, sExpectedPattern, 'once')), ...
            sprintf('Local "%s" in SF-Chart does wrongly have Block Pattern "%s".', sLocal, sExpectedPattern)); 
    end
end
end

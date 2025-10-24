function ut_ep_signals_06
% Check handling of scalar signals represented by one-element C-arrays.
%
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'signals_06');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'one_elem_arrays');

sTlModel      = 'one_elem_array';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

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
ut_ep_model_analyse(stOpt);

try 
    casExpectedCodePaths = { ...
        'in[0]', ...
        'out[0]', ...
        'a[0]', ...
        'b[0]', ...
        'in2', ...
        'out2', ...
        'a2', ...
        'b2'};
    
    casFoundCodePaths = i_readOutCodePaths(stOpt.sMappingResultFile);
    
    casMissing = setdiff(casExpectedCodePaths, casFoundCodePaths);
    casUnexpected = setdiff(casFoundCodePaths, casExpectedCodePaths);
    for k = 1:length(casMissing)
        MU_FAIL(sprintf('Expected code path "%s" not found.', casMissing{k}));
    end
    for k = 1:length(casUnexpected)
        MU_FAIL(sprintf('Unexpected code path "%s" found.', casUnexpected{k}));
    end
    
catch oEx
    MU_FAIL(i_printException('Check limitation', oEx)); 
end
end



%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function casCodePaths = i_readOutCodePaths(sMappingResultFile)
if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

ahInterfaceMap = mxx_xmltree('get_nodes', hDoc, ...
    '/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping');
casCodePaths = arrayfun(@i_getFullCodePath, ahInterfaceMap, 'UniformOutput', false);
end


%%
function sCodePath = i_getFullCodePath(hInterfaceMap)
stRoot = mxx_xmltree('get_attributes', hInterfaceMap, './Path[@refId="id1"]', 'path');
stAccess = mxx_xmltree('get_attributes', hInterfaceMap, './SignalMapping/Path[@refId="id1"]', 'path');

if isempty(stAccess)
    sCodePath = stRoot.path;
else
    sCodePath = [stRoot.path, stAccess.path];
end
end

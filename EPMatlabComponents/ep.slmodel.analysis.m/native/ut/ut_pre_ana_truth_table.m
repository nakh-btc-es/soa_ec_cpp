function ut_pre_ana_truth_table
% Check pre-analysis workflow.
%

%% prepare test
sModelKey  = 'simple_truth';
sSuiteName = 'UT_SL';

sltu_cleanup();
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, ~, stTestData] = sltu_prepare_ats_env(sModelKey, sSuiteName, sTestRoot);

sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% test
%
% Model: simple_truth
%   top_A  --> Subsystem     --> lookInside=true,  ignore=false
%   A      --> SF-Chart      --> lookInside=false, ignore=false
%   B      --> SF-TruthTable --> lookInside=false, ignore=false
%
astExpected = struct( ...
    'sModelPath',    {'simple_truth/top_A', 'simple_truth/top_A/A', 'simple_truth/top_A/B'}, ...
    'bLookInside',   {true, false, false}, ...
    'bIgnoreEntity', {false, false, true});

for i = 1:length(astExpected)
    stExp = astExpected(i);
    
    try
        hEntity = get_param(stExp.sModelPath, 'handle');        
    catch oEx
        MU_FAIL(sprintf('Could not obtain handle for model path "%s".\n%s', stExp.sModelPath, oEx.message));
        continue;
    end
    
    [bLookInside, bIgnoreEntity] = atgcv_m01_subsys_filter(hEntity);
    
    MU_ASSERT_TRUE(bLookInside == stExp.bLookInside, ...
        sprintf('Filter-output "Look-inside" should be "%d" instead of "%d" for "%s".', ...
        stExp.bLookInside, bLookInside, stExp.sModelPath));
    
    MU_ASSERT_TRUE(bIgnoreEntity == stExp.bIgnoreEntity, ...
        sprintf('Filter-output "Ignore" should be "%d" instead of "%d" for "%s".', ...
        stExp.bIgnoreEntity, bIgnoreEntity, stExp.sModelPath));
end
end






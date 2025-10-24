function ut_ep_ep_1602
% Check fix for Bug EP-1602.
%
%  REMARKS
%       Bug: RESTART function is missing for a model with a DUMMY toplevel subsystem and in a  closed-loop scenario.
%

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_1602');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'ep_1602');

sTlModel     = 'ep_1602';
sTlModelFile = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile      = fullfile(sTestRoot, [sTlModel, '.dd']);


%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);
xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
% note: use "Closed-Loop" setting --> bAddEnvironment == true
stOpt = struct( ...
    'sDdPath',         sDdFile, ...
    'sTlModel',        sTlModel, ...
    'bAddEnvironment', true, ...
    'xEnv',            xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
oInitFuncsExpected = containers.Map;
oInitFuncsExpected('Sa2_sub_B') = 'RESTART_Sa1_top_A';
oInitFuncsExpected('Sa3_sub_C') = 'RESTART_Sa1_top_A';

oInitFuncsFound = i_getInitFunctions(stOpt.sCResultFile);

casExp = oInitFuncsExpected.keys;
casFound = oInitFuncsFound.keys;
casMissing = setdiff(casExp, casFound);
for k = 1:length(casMissing)
    MU_FAIL(sprintf('Expected function "%s" not found.', casMissing{k}));
end

for i = 1:numel(casFound)
    sFunc = casFound{i};
    
    if oInitFuncsExpected.isKey(sFunc)
        sRestartExp = oInitFuncsExpected(sFunc);
        sRestartFound = oInitFuncsFound(sFunc);
        
        MU_ASSERT_TRUE(strcmp(sRestartExp, sRestartFound), sprintf( ...
            'For step-function "%s" expected the RESTART function "%s" instead of "%s".', ...
            sFunc, sRestartExp, sRestartFound));
    else
         MU_FAIL(sprintf('Unexpected function "%s" found.', sFunc));
    end
end
end


%%
function oInitFunctions = i_getInitFunctions(sCResultFile)
oInitFunctions = containers.Map;

hDoc = mxx_xmltree('load', sCResultFile);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

astRes = mxx_xmltree('get_attributes', hDoc, '/CodeModel/Functions/Function', 'name', 'initFunc');
for i = 1:numel(astRes)
    oInitFunctions(astRes(i).name) = astRes(i).initFunc;
end
end


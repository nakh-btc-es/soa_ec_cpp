function ut_ep_matrix_support_21
% Test fix for PROM-15298
%


%% check pre-req
if ep_core_version_compare('TL4.0') < 0
    MU_MESSAGE('TargetLink Matrix Support since TL4.0. Test omitted.');
    return;
end

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_matrix_support_21');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'matrix_sig_models', 'matrix_sig21', 'tl40');

sTlModel      = 'matrix_model_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.slx']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

%% open model
xOnCleanupCloseModels = ut_open_model(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% test
i_check_code_result_file(stOpt.sCResultFile);
i_check_mapping_result_file(stOpt.sMappingResultFile);
end


%%
function i_check_code_result_file(sCodeModel)

hCodeRoot = mxx_xmltree('load', sCodeModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hCodeRoot));

casExpectedInputs = { ...
    'top_A/Sa1_In1', ...
    'Sa2_sub_B1/Sa1_In1', ...
    'Sa3_sub_B2/Sa1_In1', ...
    'Sa4_sub_B3/Sa1_In1[0][0]', ...
    'Sa4_sub_B3/Sa1_In1[1][0]', ...
    'Sa4_sub_B3/Sa1_In1[2][0]', ...
    'Sa5_sub_B4/Sa1_In1[1][0]', ...
    'Sa5_sub_B4/Sa1_In1[1][1]', ...
    'Sa6_sub_B5/Sa1_In1[0][0]', ...
    'Sa6_sub_B5/Sa1_In1[1][0]', ...
    'Sa6_sub_B5/Sa1_In1[2][0]', ...
    'Sa6_sub_B5/Sa1_In1[0][1]', ...
    'Sa6_sub_B5/Sa1_In1[1][1]', ...
    'Sa6_sub_B5/Sa1_In1[2][1]', ...
    'Sa7_sub_B6/Sa1_In1[2][1]', ...
    'Sa7_sub_B6/Sa1_In1[0][1]'};

casFoundInputs = i_readOutInputs(hCodeRoot);

casMissing = setdiff(casExpectedInputs, casFoundInputs);
casUnexpected = setdiff(casFoundInputs, casExpectedInputs);
for k = 1:length(casMissing)
    MU_FAIL(sprintf('Expected input "%s" not found.', casMissing{k}));
end
for k = 1:length(casUnexpected)
    MU_FAIL(sprintf('Unexpected input "%s" found.', casUnexpected{k}));
end
end


%%
function casInputs = i_readOutInputs(hCodeModel)
ahFunctions = mxx_xmltree('get_nodes', hCodeModel, '/CodeModel/Functions/Function');
ccasInputs = arrayfun(@i_readOutFunctionInputs, ahFunctions, 'UniformOutput', false);
casInputs = [ccasInputs{:}];
end


%%
function casInputs = i_readOutFunctionInputs(hFunc)
sFuncName = mxx_xmltree('get_attribute', hFunc, 'name');
astIns = mxx_xmltree('get_attributes', hFunc, './Interface/InterfaceObj[@kind="in"]', 'var', 'access');

casInputs = reshape( ...
    arrayfun(@(stIn) [sFuncName, '/', stIn.var, stIn.access], astIns, 'UniformOutput', false), 1, []);
end


%%
function i_check_mapping_result_file(sMappingFile)
hMapRoot = mxx_xmltree('load', sMappingFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hMapRoot));

MU_MESSAGE('TODO: Check here the mapping for the Permute block!');
end


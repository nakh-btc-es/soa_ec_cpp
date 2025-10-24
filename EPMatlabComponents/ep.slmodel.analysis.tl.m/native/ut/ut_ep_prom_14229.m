function ut_ep_prom_14229
% Check fix for Bug PROM-14229.
%
%  REMARKS
%       Bug: Handling of element-wise array inputs is handled wrongly in CodeModel.xml.
%

%%
if (atgcv_version_p_compare('TL5.1p3') >= 0 && verLessThan('tl', '5.2'))
    MU_MESSAGE('TEST SKIPPED: Code generation for the test model is broken for TL5.1p3. Model cannot be upgraded.');
    return;
end



%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'prom_14229');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'prom_14229');

sTlModel      = 'prom_13496';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);

ut_ep_model_analyse(stOpt);


%% check test results
try 
    i_check_code_model(stOpt.sCResultFile);
catch oEx
    MU_FAIL(i_printException('C-Code', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%% CodeModel
function i_check_code_model(sCodeModel)
if ~exist(sCodeModel, 'file')
    MU_FAIL('CodeModel XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sCodeModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

% expected interface
xExpIf = containers.Map();
xExpIf('goodSub1') = {'in:Sa1_e.Sa1_a', 'in:Sa1_in1[0]', 'out:Sa10_LogOp'};
xExpIf('goodSub2') = {'in:Sa1_in1[0]', 'in:Sa1_in1[1]', 'out:Sa11_LogOp'};
xExpIf('goodSub3') = {'in:Sa1_e.Sa1_a', 'in:Sa1_e.Sa1_b', 'out:Sa12_LogOp'};
xExpIf('goodSub4') = {'in:Sa1_e.Sa1_c', 'in:Sa1_e.Sa1_b', 'out:Sa13_LogOp'};
xExpIf('goodSub5') = {'in:Sa1_e.Sa1_c[0]', 'in:Sa1_in1[0]', 'out:Sa14_LogOp'};

casSubs = xExpIf.keys();
for i = 1:length(casSubs)
    sSub = casSubs{i};
    
    sXPath = sprintf('/CodeModel/Functions/Function[contains(@name, "%s")]', sSub);
    hFunc = mxx_xmltree('get_nodes', hDoc, sXPath);
    if ~isempty(hFunc)
        casFound = i_readInterface(hFunc);
        casExpected = xExpIf(sSub);
        
        casMissing = setdiff(casExpected, casFound);
        casUnexpected = setdiff(casFound, casExpected);
        for k = 1:length(casMissing)
            MU_FAIL(sprintf('Expected interface "%s" not found for subsystem "%s".', casMissing{k}, sSub));
        end
        for k = 1:length(casUnexpected)
            MU_FAIL(sprintf('Unexpected interface "%s" found for subsystem "%s".', casUnexpected{k}, sSub));
        end
    else
        MU_FAIL(sprintf('Function for subsystem "%s" not found.', sSub));
    end
end
end


%%
function casInterfaces = i_readInterface(hFunc)
astIfs = mxx_xmltree('get_attributes', hFunc, './Interface/InterfaceObj', 'kind', 'var', 'access', 'alias');
casInterfaces = cell(1, length(astIfs));
for i = 1:length(astIfs)
    stIf = astIfs(i);
    
    if isempty(stIf.alias)
        casInterfaces{i} = [stIf.kind, ':', stIf.var, stIf.access];
    else
        casInterfaces{i} = [stIf.kind, ':', stIf.var, stIf.access, '|', stIf.alias];
    end
end
end

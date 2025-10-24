function ut_ep_prom_13652
% Check fix for Bug PROM-13652.
%
%  REMARKS
%       Bug: Min/Max values are not transferred correctly into the CodeModel for Bool types.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'prom_13361');
if verLessThan('tl', '5.2')
    sDataDir = fullfile(ut_local_testdata_dir_get(), 'prom_13652');
else
    sDataDir = fullfile(ut_local_testdata_dir_get(), 'prom_13652_tl52');
end

sTlModel      = 'prom_13652';
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

casExpectedVars = { ...
    'A_in', ...
    'D_in', ...
    'A_out', ...
    'D_out', ...
    'A_local', ...
    'D_local', ...
    'A_cal', ...
    'B_cal', ...
    'C_cal', ...
    'D_cal', ...
    'E_cal'};

% 1) check that we have exactly the variables we are expecting
astRes = mxx_xmltree('get_attributes', hDoc, ...
    '/CodeModel/Functions/Function/Interface/InterfaceObj', 'var', 'min', 'max');
casFoundVars = {astRes(:).var};

casMissing = setdiff(casExpectedVars, casFoundVars);
casUnexpected = setdiff(casFoundVars, casExpectedVars);
for i = 1:length(casMissing)
    MU_FAIL(sprintf('Expected var "%s" not found among the interface objects.', casMissing{i}));
end
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('Unexpected var "%s" found among the interface objects.', casUnexpected{i}));
end


% 2) check that the Min/Max values are exactly as expected
for i = 1:length(astRes)
    stRes = astRes(i);
    
    if ~isempty(stRes.min)
        MU_ASSERT_TRUE(i_equalsStringDouble(stRes.min, 0.0), ...
            sprintf('Variable "%s" shall have Min value 0 instead of "%s".', stRes.var, stRes.min));
    else
        MU_FAIL(sprintf('Min value for Variable "%s" is missing but shall be 0.', stRes.var));
    end
    if ~isempty(stRes.max)
        MU_ASSERT_TRUE(i_equalsStringDouble(stRes.max, 1.0), ...
            sprintf('Variable "%s" shall have Max value 1 instead of "%s".', stRes.var, stRes.max));
    else
        MU_FAIL(sprintf('Max value for Variable "%s" is missing but shall be 1.', stRes.var));
    end
end
end


%%
function bEquals = i_equalsStringDouble(sStringValue, dDoubleValue)
if isempty(sStringValue)
    bEquals = false;
else
    bEquals = isequal(str2double(sStringValue), dDoubleValue); % compare on numerical side
end
end

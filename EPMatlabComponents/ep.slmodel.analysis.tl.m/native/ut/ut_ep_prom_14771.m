function ut_ep_prom_14771
% Check fix for Bug PROM-14771.
%
%  REMARKS
%       Bug: Arrays with only one element are used as if they are scalars (without an access path).
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'prom_14771');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'cal_restrictions');

sTlModel      = 'cal_restrictions';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% check test results
try 
    i_check_code_constraints(stOpt.sCArchConstrFile);
catch oEx
    MU_FAIL(i_printException('C-Code', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%% C-Code Constraints
function i_check_code_constraints(sCodeConstraints)
if ~exist(sCodeConstraints, 'file')
    MU_FAIL('C-Code constraint XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sCodeConstraints);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

MU_ASSERT_FALSE(isempty(mxx_xmltree('get_nodes', hDoc, ...
    '//signalSignal[@relation="leq" and @signal1="f1[0]" and @signal2="g1[0]"]')), ...
    'The Signal-Signal relation "f1[0] <= g1[0]" is missing');

ahNodes = mxx_xmltree('get_nodes', hDoc, ['//signalValue[@relation="leq" and @signal="f1[0]" and @value="',i_double_str_2_str('0.0'),'"]']);
MU_ASSERT_FALSE(isempty(ahNodes), 'The Signal-Value relation "f1[0] <= 0.0" is missing');

ahNodes = mxx_xmltree('get_nodes', hDoc, ['//signalValue[@relation="geq" and @signal="g1[0]" and @value="',i_double_str_2_str('0.0'),'"]']);
MU_ASSERT_FALSE(isempty(ahNodes), 'The Signal-Value relation "g1[0] >= 0.0" is missing');

ahNodes = mxx_xmltree('get_nodes', hDoc, ['//signalValue[@relation="leq" and @signal="a1[0]" and @value="',i_double_str_2_str('0.0'),'"]']);
MU_ASSERT_FALSE(isempty(ahNodes), 'The Signal-Value relation "a1[0] <= 0.0" is missing');

ahNodes = mxx_xmltree('get_nodes', hDoc, ['//signalValue[@relation="geq" and @signal="e1[0]" and @value="',i_double_str_2_str('0.0'),'"]']);
MU_ASSERT_FALSE(isempty(ahNodes), 'The Signal-Value relation "e1[0] >= 0.0" is missing');
end

%%
function sVal = i_double_str_2_str(sValue)
sVal = eval(['sprintf(''%.16e'', ',sValue, ')']);
end

function ut_ep_code_02
% Check handling of Macros in context Replaceable Data Items.
%
%  REMARKS
%       UT is related to PROM-14402.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%%
if (atgcv_version_p_compare('TL3.4') < 0)
    MU_MESSAGE('Test SKIPPED. Testdata is using RDIs and thus is only suited for TL3.4 and higher!');
    return;
end

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'code_02');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'tl34_rdi_mod');

sTlModel      = 'ReplaceableDataItems';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);
sTlInitScript = fullfile(sTestRoot, 'start.m');

%% setup env for test
try
    [xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);
    
catch oEx
    MU_FAIL_FATAL(sprintf('Model could not be copied:\n%s\n\nCurrent path: "%s" (length=%d)\n', ...
        oEx.message, pwd, length(pwd)));
end

try
    xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);
    
catch oEx
    MU_FAIL_FATAL(sprintf('Model could not be prepared:\n%s\n\nCurrent path: "%s" (length=%d)\n', ...
        oEx.message, pwd, length(pwd)));
end


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

% check that for all variables ending with ...rdi the attribute "replaceable" is set to "yes"
astRes = mxx_xmltree('get_attributes', hDoc, '/CodeModel/Functions/Function/Interface/InterfaceObj', ...
    'var', 'replaceable');
 
nCountRDIs = 0;
for i = 1:length(astRes)
    sName = astRes(i).var;
    bIsReplaceable = ~isempty(astRes(i).replaceable) && strcmp(astRes(i).replaceable, 'yes');
    
    if i_endsWith(sName, '_rdi')
        nCountRDIs = nCountRDIs + 1;
        MU_ASSERT_TRUE(bIsReplaceable, sprintf('Variable "%s" shall be marked as replaceable.', sName));
    else
        MU_ASSERT_FALSE(bIsReplaceable, sprintf('Variable "%s" shall _not_ be marked as replaceable.', sName));
    end
end
MU_ASSERT_TRUE((nCountRDIs > 0) && (length(astRes) > nCountRDIs), ...
    'Testresults are inconclusive. No representable subset of RDIs found.');
end


%%
function bSuccess = i_endsWith(sString, sPostfix)
% note: if sPostfix is using special chars it needs to be escaped before used in regexp
bSuccess = ...
    ~isempty(sString) ...
    && (isempty(sPostfix) || ~isempty(regexp(sString, [sPostfix, '$'], 'once')));
end

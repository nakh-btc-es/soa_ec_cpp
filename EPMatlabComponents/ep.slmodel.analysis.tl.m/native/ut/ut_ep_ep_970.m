function ut_ep_ep_970
% Check fix for Bug EP-970.
%
%  REMARKS
%       Bug: Naming of CAL-DD-Variables does not display the C-Code naming but the DD identifiers which are non-unique.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_970');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'ep_970');

sTlModel     = 'ep_970';
sTlModelFile = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile      = fullfile(sTestRoot, [sTlModel, '.dd']);


%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);
xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
try
    ut_check_generic_consistency('Mapping', stOpt.sMappingResultFile, 'TlArch', stOpt.sTlResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx));
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


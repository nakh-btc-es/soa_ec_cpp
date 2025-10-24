function ut_mt02_ep_1415
%
% EP-1415: Code generation for models with DDIncludeFile objects that have no DDPath is not successful
%


%%
MU_MESSAGE('TEST SKIPPED. The DD Upgrade mechanism is broken and currently leads to blocking upgrade dialogs. TODO: Fix me!');
return;


%%
if verLessThan('TL', '3.5')
    MU_MESSAGE('TEST SKIPPED: Testdata only suitable for version TL3.5 and higher.');
    return;
end


%%
sltu_cleanup;


%%
sPwd     = pwd;
sTestRootDir = fullfile(sPwd, ['tmp', mfilename()]);
sOrigDataDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tst', 'testdata', 'dd_with_includes');

sDdMainDD = 'main.dd';
sDdFile = fullfile(sTestRootDir, sDdMainDD);


[xOnCleanupDoCleanup, xEnv] = sltu_prepare_local_env(sOrigDataDir, sTestRootDir); %#ok<ASGLU> onCleanup object


%%
dsdd('Open', 'File', sDdFile, 'Upgrade', 'on');
onCleanupClearAll = onCleanup(@sltu_cleanup);

%%
ep_adapt_current_dd(xEnv);
ahVars = dsdd('Find', '/Pool/Variables', 'objectKind', 'Variable');
MU_ASSERT_TRUE(numel(ahVars) == 8, 'Adaption of DD was not correct.');
end



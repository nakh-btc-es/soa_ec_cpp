function MU_pre_hook
% Define suites and tests for unit testing.
%
% function MU_pre_hook
%

%% 
sTmpDir = sltu_tmp_env;

%%
% DO NOT ADD suites here directly; instead extend the sub-pre-hooks called from here!

MU_pre_hook_no_tl(sTmpDir);
if i_isTlAvailable()
    MU_pre_hook_required_tl(sTmpDir);
else
    i_MU_pre_hook_dummy_tl(sTmpDir);
end
end


%%
function i_MU_pre_hook_dummy_tl(sTmpDir)
hSuite = MU_add_suite('TL DUMMY', [], [], sTmpDir);
MU_add_test(hSuite, 'Skipped', @i_issueSkippingMessage);
end


%%
function i_issueSkippingMessage()
MU_MESSAGE('TL is not installed. Intentionally skipping all tests that depend on TargetLink features.');
end


%%
function bIsAvailable = i_isTlAvailable()
bIsAvailable = true;
if exist('dsdd', 'file') == 0
    bIsAvailable = false;
end
end

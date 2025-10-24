function MU_pre_hook
% Define suites and tests for unit testing.
%
% function MU_pre_hook
%

%% 

%%
% DO NOT ADD suites here directly; instead extend the sub-pre-hooks called from here!

MU_pre_hook_no_tl();
if i_tl_available()
    MU_pre_hook_required_tl();
else
    i_MU_pre_hook_dummy_tl();
end
end


%%
function i_MU_pre_hook_dummy_tl
hSuite = MU_add_suite('TL DUMMY', [], [], '');
MU_add_test(hSuite, 'Skipped', @i_issueSkippingMessage);
end


%%
function i_issueSkippingMessage()
MU_MESSAGE('TL is not installed. Intentionally skipping all tests that depend on TargetLink features.');
end

%%
function bIsAvailable = i_tl_available()
bIsAvailable = true;
if exist('dsdd', 'file') == 0
    bIsAvailable = false;
end
end

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

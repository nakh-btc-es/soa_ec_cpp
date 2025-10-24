function ut_ep_simenv_clear_base()
% Check clean up method.
% EP-720 "Workspace variables which name start from "i_" are deleted during MIL"
%

%% prepare test
ep_tu_cleanup();
sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_simenv_clear_base');
try
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    
    ep_tu_mkdir(sTestRoot);
    cd(sTestRoot);
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception during test env setup: "%s".', exception.message));
end
%% Test
evalin('base', 'i_a = 1;');
evalin('base', 'o_a = 1;');
evalin('base', 'i_if_a = 1;');
evalin('base', 'o_if_a = 1;');
ep_simenv_clear_base();
stWhos = evalin('base', 'whos');
bIa = false;
bOa = false;
for i=1:length(stWhos)
    stVar = stWhos(i);
    if strncmp(stVar.name, 'i_if_', 5)
        MU_FAIL('Variable with prefix "i_if_" not cleaned');
    end
    if strncmp(stVar.name, 'i_a', 3)
        bIa = true;
    end
    if strncmp(stVar.name, 'o_a', 3)
        bOa = true;
    end
end
MU_ASSERT_TRUE(bIa && bOa, 'EP-720 still present');
%% clean up test dir
try
    cd(sPwd);
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    evalin('base', 'sltu_clear_all;');
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception during test env clean up: "%s".', exception.message));
end
end
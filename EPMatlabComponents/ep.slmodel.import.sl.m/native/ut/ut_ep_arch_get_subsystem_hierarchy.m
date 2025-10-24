function ut_ep_arch_get_subsystem_hierarchy
% Tests the ep_arch_get_sl_subsystem_hierarchy method
%


%% clean up first
ep_tu_cleanup();

%% predefined values
sPwd      = pwd;
sTestRoot = fullfile(sPwd, 'tmp_ep_arch_get_subsystem_hierarchy');

%% setup env for test
try
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    ep_tu_mkdir(sTestRoot);
    cd(sTestRoot);
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception during test env setup: "%s".', exception.message));
end


%% test if the delegation works
try
    % Create model
    ep_new_model_create('SYS', 'model');
    add_block('built-in/SubSystem', 'SYS/controller');
    add_block('built-in/SubSystem', 'SYS/controller/controller2');
   
    % call sut
    xEnv = EPEnvironment;
    stResult = ep_arch_get_sl_subsystem_hierarchy(xEnv, 'SYS');
    
    % ceck
    MU_ASSERT_EQUAL(stResult.caSubsystems{1}.sPath, 'SYS/controller', 'Top level subsystem wrong.');
    MU_ASSERT_EQUAL(length(stResult.caSubsystems), 1, 'Wrong length of top level subsystems');
    MU_ASSERT_EQUAL(stResult.caSubsystems{1}.caSubsystems{1}.sPath, 'SYS/controller/controller2', 'Subsystem wrong');
    MU_ASSERT_TRUE(~isfield(stResult.caSubsystems{1}.caSubsystems{1}, 'caSubsystem'), 'Unexpected subsystem hierarchy');
    
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception during test execution: "%s".', exception.message));
end

%% clean
try
    if ~isempty(xEnv)
        xEnv.clear();
    end
    cd(sPwd);
    ep_tu_cleanup();
    if exist(sTestRoot, 'file')
        ep_tu_rmdir(sTestRoot);
    end
catch exception
    cd(sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception during clean: "%s".', exception.message));
end
end

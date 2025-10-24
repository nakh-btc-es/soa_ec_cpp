function ut_ep_arch_get_sl_parameters
% Tests the ep_arch_get_sl_parameters method
%

%% clean up first
ep_tu_cleanup();

%% predefined values
sPwd      = pwd;
sTestRoot = fullfile(sPwd, 'tmp_ep_arch_get_sl_parameters');

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
    evalin('base', 'clear');
    
    xEnv = EPEnvironment();
    evalin('base', 'v1 = uint8([0 0 0; 0 0 0; 0 0 0]);');
    evalin('base', 'v2 = uint16([0 0 0]);');
    evalin('base', 'v3 = double(6.5);');
    evalin('base', 'v4 = Simulink.Parameter;');
    
    stResult = ep_arch_get_sl_parameters(xEnv);
    
    MU_ASSERT_TRUE(length(stResult.casName) == 4, 'Wrong number of parameters found.');
    
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casName,'v1'),1)), 'v1 not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casName,'v2'),1)), 'v2 not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casName,'v3'),1)), 'v3 not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casName,'v4'),1)), 'v4 not found');
    
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casClass,'Simple (1x1)'),1)), 'Simple (1x1) not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casClass,'Matrix (3x3)'),1)), 'Matrix (3x3) not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casClass,'Array (1x3)'),1)), 'Array (1x3) not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casClass,'Simulink.Parameter'),1)), 'Simulink.Parameter not found');
    
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casType,'uint8'),1)), 'uint8 not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casType,'uint16'),1)), 'uint16 not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casType,'double'),1)), 'double not found');
    MU_ASSERT_TRUE(~isempty(find(ismember(stResult.casType,'auto'),1)), 'auto not found');
    
    evalin('base', 'clear');
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
    if ( exist(sTestRoot, 'file') )
        ep_tu_rmdir(sTestRoot);
    end
catch exception
    cd(sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception during clean: "%s".', exception.message));
end
end

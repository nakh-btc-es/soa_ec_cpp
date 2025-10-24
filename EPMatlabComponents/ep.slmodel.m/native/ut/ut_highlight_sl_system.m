function ut_highlight_sl_system()
% Tests if the 'ep_core_highlight_sl_system' works
%


%%
if (isunix && ~usejava('desktop'))
    % slprofile_hilite_system in ep_core_highlight_sl_system does not work correct under linux in nodisplay mode.
    % However, highlighting is not a relevant feature under linux. Therefore, the test is skipped.
    MU_MESSAGE('TEST SKIPPED: Highlighting does not work in the nodisplay mode in Linux.');
    return;
end


%% prepare
% clean up first
ep_tu_cleanup();

% predefined values
sPwd = pwd;
sTestRoot = fullfile(sPwd, 'ut_highlight_sl_system_check');

% setup env for test
try
    if exist(sTestRoot, 'dir')
        rmdir(sTestRoot, 's');
    end
    mkdir(sTestRoot);
    
    cd(sTestRoot);
    oOnCleanupReturnToPwd = onCleanup(@() cd(sPwd));
    
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception during test env setup: "%s".', exception.message));
end


%% test
try 
    bdclose all;
    
    % create model
    sOtherSystem = 'SYS/mySubsystem';
    sSystemToBeHilited = 'SYS/mySubsystem/mySubsystem2';
    
    new_system('SYS', 'Model');
    add_block('built-in/Subsystem', sOtherSystem);
    add_block('built-in/Subsystem', sSystemToBeHilited);
    save_system('SYS');
    
    sFileName = 'SYS.slx';
    
    bdclose all;
    
    MU_ASSERT_EQUAL(-1, gcbh);

    ep_core_highlight_sl_system('ModelFile', fullfile(sTestRoot, sFileName), 'BlockPath', sSystemToBeHilited);
    
    MU_ASSERT_EQUAL(sSystemToBeHilited, gcb, 'Wrong subsystem highlighted.');
    
    bdclose all;
    
catch exception
    % clean up
    bdclose all;
    MU_FAIL(exception.message);
end
end
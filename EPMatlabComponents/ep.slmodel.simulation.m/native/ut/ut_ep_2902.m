function ut_ep_2902()
% Tests the ep_sim_harness_create method

if verLessThan('matlab', '9.7')
    MU_MESSAGE('TEST SKIPPED: subsystem reference is only available since ML2019b.');
    return;
end
if isunix && ~usejava('desktop')
    % close_system should close the referenced subsystems, but in the nodisplay mode it is not the case.
    % Mathworks confirms it as a bug.
    MU_MESSAGE('TEST SKIPPED: MATLAB BUG: close_system did not close referenced subsystems in the nodisplay mode');
    return
end
sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('EP_2902', 'UT_MIL_SL', 'EP_2902');

sOrgSimMode = 'SL MIL';

%% Test
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);


%% Test
% Open the original model and the referenced subsystem
% Modify the original model in such way that the referenced subsystem is modified and gets locked
% Checks if an error is thrown and the simulation is rejected
i_modifyReferencedSub(stTestData);

try
    [~, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
    xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));
catch oEx  
    SLTU_ASSERT_TRUE(isequal(oEx.identifier, 'EP:SIM:DIRTY_MODEL'), ...
        sprintf('Expected: "%s", but found: "%s" !', 'EP:SIM:DIRTY_MODEL', oEx.identifier));
end
end


%% Opens and modifies the main model
function i_modifyReferencedSub(stTestData)
open_system(stTestData.sModelFile);
open_system(strcat(fullfile(stTestData.sTestRootModel, 'gainSub.slx')));

casAllSubsystem = find_system('RefSubsystem', 'FollowLinks', 'on',...
    'LookUnderMasks', 'all','LookUnderReadProtectedSubsystems','on', 'BlockType','SubSystem');
hSubRef = get_param(casAllSubsystem{1}, 'Handle');
hGainRefSub = find_system(hSubRef, 'FollowLinks', 'on',...
    'LookUnderMasks', 'all','LookUnderReadProtectedSubsystems','on', 'BlockType','Gain');
pos = get_param(hGainRefSub, 'Position');
pos(1) = pos(1)+22;
set_param(hGainRefSub, 'Position', pos);
end
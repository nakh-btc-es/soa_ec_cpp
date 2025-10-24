function ut_model_solver_set()
% Tests if the 'ep_core_model_solver_set' method
% sets the correct porperties.
%
%  function ut_model_solver_set()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

try 
    % create model
    newSystem = new_system('SYS', 'Model');
    cfgSys = getActiveConfigSet(newSystem);
    solverSys = cfgSys.getComponent('Solver');
    
    % Set values which will be adjusted.
    solverSys.FixedStep = '0';
    solverSys.SolverType = 'Variable-Step';
    solverSys.Solver = 'ode45';
    solverSys.SampleTimeConstraint = 'Specified';
    solverSys.SolverMode = 'auto';
    solverSys.StartTime = '1';
    solverSys.StopTime = '1';
    solverSys.AutoInsertRateTranBlk = 'on';
    solverSys.PositivePriorityOrder = 'on';
    
    % sut
    ep_core_model_solver_set('SYS', '100');
    cfgSys = getActiveConfigSet(newSystem);
    solverSys = cfgSys.getComponent('Solver');
    
    % Check adjustments
    MU_ASSERT_EQUAL(solverSys.FixedStep, '100', 'FixedStep has not been set.');
    MU_ASSERT_EQUAL(solverSys.SolverType,'Fixed-step', 'SolverType has not been set.');
    MU_ASSERT_EQUAL(solverSys.Solver,'FixedStepDiscrete', 'Solver has not been set.');
    MU_ASSERT_EQUAL(solverSys.SampleTimeConstraint,'Unconstrained', 'SampleTimeConstraint  has not been set.');
    MU_ASSERT_EQUAL(solverSys.SolverMode,'SingleTasking', 'SolverMode has not been set.');
    MU_ASSERT_EQUAL(solverSys.StartTime,'0.0', 'StartTime has not been set.');
    MU_ASSERT_EQUAL(solverSys.stopTime,'inf', 'stopTime has not been set.');
    MU_ASSERT_EQUAL(solverSys.AutoInsertRateTranBlk,'off', 'AutoInsertRateTranBlk has not been set.');
    MU_ASSERT_EQUAL(solverSys.PositivePriorityOrder,'off', 'PositivePriorityOrder has not been set.');
    
     % with no sample time    
    solverSys.FixedStep = 'auto';
    ep_core_model_solver_set('SYS');
    MU_ASSERT_EQUAL(solverSys.FixedStep, 'auto', 'FixedStep has been set.');
    
    % clean up
    bdclose all;
    clear('newSystem');
catch exception
    % clean up
    bdclose all;
    clear('newSystem');
    MU_FAIL(exception.message);
end
end
%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
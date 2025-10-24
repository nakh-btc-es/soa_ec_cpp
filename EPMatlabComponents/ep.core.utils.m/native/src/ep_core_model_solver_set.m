function ep_core_model_solver_set(sModel, sSampleTime)
% Sets the solver type of the model to 'fixed-step' with given sample time.
%
% function ep_core_utils_model_solver_set(sModel, sSampleTime)
%
%   PARAMETER(S)        DESCRIPTION
%   - sModel                (String) The model which gets as new solver type 'fixed-step'.
%   - sSampleTime           (String) The new sample time for the model. Is optional.
%
%   OUTPUT
%
%   REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

if( nargin < 2 )
	sSampleTime = [];
end

sSolverType = get_param(sModel, 'SolverType');
if strcmpi(sSolverType, 'fixed-step')
    return;
end

hModel = get_param(sModel, 'Handle');
cfg = getActiveConfigSet(hModel);

solver = cfg.getComponent('Solver');
solver.SolverType           = 'Fixed-step';
solver.Solver               = 'FixedStepDiscrete';
solver.SampleTimeConstraint = 'Unconstrained';
solver.SolverMode           = 'SingleTasking';

if( ~isempty( sSampleTime ) )
	solver.FixedStep = sSampleTime;
end

solver.StartTime = '0.0';
solver.stopTime  = 'inf';

% default settings
solver.AutoInsertRateTranBlk = 'off';
solver.PositivePriorityOrder = 'off';
end

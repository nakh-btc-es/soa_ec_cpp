function MU_pre_hook
% Define suites and tests for unit testing.
%
% function MU_PRE_HOOK
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Thabo.Krick@btc-es.de
% $$$COPYRIGHT$$$

%  add suites and tests

%******************************************************************************
%% add suites 
hSuite  = MU_add_suite('BASIC', 0, 0, [cd, '\tmpdir']);

%MU_add_test(hSuite, 'MT_DUMMY.001', @ut_mt_dummy_001);


%******************************************************************************

return;
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

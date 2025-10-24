function ut_mt01_counter
% raising coverage of atgcv_m01_counter
%
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Alexander.Hornstein@osc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 42718 $ 
%   Last modified: $Date: 2008-09-11 09:25:55 +0200 (Do, 11 Sep 2008) $ 
%   $Author: ahornste $


%% clear persistent memory of counter
clear atgcv_m01_counter;

%% counter1
atgcv_m01_counter('add', 'a');

n = atgcv_m01_counter('get', 'a');
MU_ASSERT_TRUE(n==1, 'Default start value of counter should be one.');
n = atgcv_m01_counter('get', 'a');
MU_ASSERT_TRUE(n==2, 'Next value should be two.');

%% counter2 with explicit init value
atgcv_m01_counter('add', 'b', -10);

n = atgcv_m01_counter('get', 'a');
MU_ASSERT_TRUE(n==3, ...
    'Adding another counter has influenced value of first counter.');

atgcv_m01_counter('get', 'b');
atgcv_m01_counter('get', 'b');
n = atgcv_m01_counter('get', 'b');
MU_ASSERT_TRUE(n==-8, 'Expected value -8 for second counter.');

atgcv_m01_counter('set', 'b', 1);
n = atgcv_m01_counter('get', 'b');
MU_ASSERT_TRUE(n==1, 'Expected value 1 after explcitly setting it.');
n = atgcv_m01_counter('get', 'b');
MU_ASSERT_TRUE(n==2, 'After setting value. Next value should be two.');

n = atgcv_m01_counter('get', 'a');
MU_ASSERT_TRUE(n==4, ...
    'Operating on another counter has influenced value of first counter.');

%% error with usage
% unknown command
try
    atgcv_m01_counter('unknown_cmd_wtf', 'bla');
    MU_FAIL('Missing expected exception for unknown command.');
catch
    stErr = lasterror();
    MU_PASS(['Expected exception: ', stErr.message]);
end

% register the same counter twice
try
    atgcv_m01_counter('add', 'a');
    MU_FAIL('Missing expected exception for registering counter twice.');
catch
    stErr = lasterror();
    MU_PASS(['Expected exception: ', stErr.message]);
end

clear atgcv_m01_counter;

%% end
return;



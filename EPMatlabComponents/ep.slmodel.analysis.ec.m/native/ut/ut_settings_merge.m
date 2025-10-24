function ut_settings_merge
% Testing the hook/configuration functionality on low level.
%


%% prepare test
sltu_cleanup();

xEnv = EPEnvironment();
oOnCleanunClearEnv = onCleanup(@() xEnv.clear());


%% good case
stIn = struct( ...
    'a', 7, ...
    'b', 'xxx', ...
    'c', true);
stNew = struct( ...
    'b', 'yyy');
stExpected = struct( ...
    'a', 7, ...
    'b', 'yyy', ...
    'c', true);
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% unknown setting
stIn = struct( ...
    'a', 7);
stNew = struct( ...
    'b', 8);
stExpected = struct( ...
    'a', 7);
bWarningExpected = true;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% wrong type
stIn = struct( ...
    'a', 7);
stNew = struct( ...
    'a', '8');
stExpected = struct( ...
    'a', 7);
bWarningExpected = true;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% cell can override cell
stIn = struct( ...
    'a', {{'some string'}});
stNew = struct( ...
    'a', {{'some new string'}});
stExpected = struct( ...
    'a', {{'some new string'}});
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% empty cell cannot be overridden by non-cell
stIn = struct( ...
    'a', {{}});
stNew = struct( ...
    'a', 77);
stExpected = struct( ...
    'a', {{}});
bWarningExpected = true;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% empty char cannot be overridden by non-char
stIn = struct( ...
    'a', '');
stNew = struct( ...
    'a', 77);
stExpected = struct( ...
    'a', '');
bWarningExpected = true;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% cell with one elem can override char
stIn = struct( ...
    'a', 'some string');
stNew = struct( ...
    'a', {{'some new string'}});
stExpected = struct( ...
    'a', 'some new string');
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% cell with multiple elems cannot override char
stIn = struct( ...
    'a', 'some string');
stNew = struct( ...
    'a', {{'some new string', 'another string'}});
stExpected = struct( ...
    'a', 'some string');
bWarningExpected = true;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% cell with no elems can override char
stIn = struct( ...
    'a', 'some string');
stNew = struct( ...
    'a', {{}});
stExpected = struct( ...
    'a', '');
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% char can override cell
stIn = struct( ...
    'a', {{'some string', 'some other string'}});
stNew = struct( ...
    'a', 'some new string');
stExpected = struct( ...
    'a', {{'some new string'}});
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% empty array can override cell
stIn = struct( ...
    'a', {{'some string', 'some other string'}});
stNew = struct( ...
    'a', []);
stExpected = struct( ...
    'a', {{}});
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% everything can override empty array
stIn = struct( ...
    'a', [], ...
    'b', []);
stNew = struct( ...
    'a', 7, ...
    'b', 'xxx');
stExpected = struct( ...
    'a', 7, ...
    'b', 'xxx');
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% any struct can override struct
stNested = struct( ...
    'x', [1 2 3], ...
    'y', 'test');
stIn = struct( ...
    'a', 7, ...
    'b', stNested);
stNew = struct( ...
    'b', struct('x', [4 5]));
stExpected = stIn;
stExpected.b = stNew.b;
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% nested settings
stNested = struct( ...
    'x', [1 2 3], ...
    'y', 'test');
stIn = struct( ...
    'a', 7, ...
    'b', stNested);
stNew = struct( ...
    'b', struct('x', [4 5]));
stExpected = stIn;
stExpected.b.x = stNew.b.x;
bWarningExpected = false;
casKnownNestedSettings = {'b'};
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected, casKnownNestedSettings);


%% nested settings overriden wrongly by new values
stNested = struct( ...
    'x', [1 2 3], ...
    'y', 'test');
stIn = struct( ...
    'a', 7, ...
    'b', stNested);
stNew = struct( ...
    'b', 'yyy');
stExpected = stIn;
bWarningExpected = true;
casKnownNestedSettings = {'b'};
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected, casKnownNestedSettings);


%% nothing to merge
stIn = struct( ...
    'a', 7, ...
    'b', 'xxx', ...
    'c', true);
stNew = struct();
stExpected = stIn;
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);


%% nothing to be merged to
stIn = struct();
stNew = struct();
stExpected = stIn;
bWarningExpected = false;
sltu_assert_correct_merge(xEnv, stIn, stNew, stExpected, bWarningExpected);
end




%%
function sltu_assert_correct_merge(xEnv, stIn, stNew, stExpectedOut, bWarningsExpected, casKnownIntermSettings)
if (nargin < 5)
    bWarningsExpected = false;
end
if (nargin < 6)
    casKnownIntermSettings = {};
end

xEnv.clearMessages();
stOut = ep_ec_settings_merge(xEnv, stIn, stNew, casKnownIntermSettings);

SLTU_ASSERT_TRUE(isequal(stOut, stExpectedOut), 'Unexpected merge.');
sltu_assert_warnings(xEnv, bWarningsExpected);
end


%%
function sltu_assert_warnings(xEnv, bWarningsExpected)
astMessages = sltu_read_messages_from_env(xEnv);
if bWarningsExpected
    SLTU_ASSERT_TRUE(~isempty(astMessages), 'Expected warnings/errors not found.');
else
    SLTU_ASSERT_TRUE(isempty(astMessages), 'Found unexpected warnings/errors.');
end
end

function SLTU_ASSERT_EQUAL_STRUCT(stExpected, stTest)
% Assert that the test structure is equal to the expected structure.
%
% function SLTU_ASSERT_EQUAL_STRUCT(stExpected, stTest)
%
%   PARAMETER(S)    DESCRIPTION
%   - stExpected     The expected structure.
%   - stTest         The actual structure from the test.


%%
bIsEqual = isequal(stExpected, stTest);
SLTU_ASSERT_TRUE(bIsEqual, 'Instead of struct "%s" found "%s".', i_structToString(stExpected), i_structToString(stTest));
end


%%
function sString = i_structToString(stStruct)
if ~verLessThan('matlab', '9.1') % ML2016b and higher
    sString = jsonencode(stStruct);
else
    % TODO: implement something for lower ML versions if necessary
    sString = [inputname(1), ' (disp not supported)'];
end
end

function SLTU_ASSERT_EQUAL_FLAT_STRUCT(stExpected, stTest)
% Assert that the test structure is equal to the expected structure for each field.
%
% function SLTU_ASSERT_EQUAL_FLAT_STRUCT(stExpected, stTest)
%
%   PARAMETER(S)    DESCRIPTION
%   - stExpected     The expected structure.
%   - stTest         The actual structure from the test.


%%
casExpFields = fieldnames(stExpected);
casTestFields = fieldnames(stTest);

casUnexpected = setdiff(casTestFields, casExpFields);
for i = 1:numel(casUnexpected)
    SLTU_FAIL('Found unexpected field "%s".', casUnexpected{i});
end

for i = 1:numel(casExpFields)
    sField = casExpFields{i};
    
    if ~isfield(stTest, sField)
        SLTU_FAIL('Expected field "%s is missing".', sField);
        continue;
    end
    
    xExpVal = stExpected.(sField);
    xTestVal = stTest.(sField);
    
    bIsEqual = isequal(xExpVal, xTestVal);
    SLTU_ASSERT_TRUE(bIsEqual, 'For field "%s" expected "%s" but found "%s".', ...
        sField, i_toString(xExpVal), i_toString(xTestVal));
end
end


%%
function sString = i_toString(xSomething)
if ~verLessThan('matlab', '9.1') % ML2016b and higher
    sString = jsonencode(xSomething);
else
    % TODO: implement something for lower ML versions if necessary
    sString = [inputname, ' (disp not supported)'];
end
end

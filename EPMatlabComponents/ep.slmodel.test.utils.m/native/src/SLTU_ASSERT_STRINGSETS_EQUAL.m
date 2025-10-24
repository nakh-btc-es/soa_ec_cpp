function SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedSet, casFoundSet, sMessage)
% Asserting that the two provided cell arrays of *string* are equal.
%
%

%% main
casMissing = setdiff(casExpectedSet, casFoundSet);
casUnexpected = setdiff(casFoundSet, casExpectedSet);
if ((nargin > 2) && (~isempty(casMissing) || ~isempty(casUnexpected)))
    SLTU_FAIL(sMessage);
else
    if (isempty(casMissing) && isempty(casUnexpected))
        MU_PASS(); % just for statistics reported in MUNIT report
    else
        for i = 1:length(casMissing)
            SLTU_FAIL('Expected object "%s" not found.', casMissing{i});
        end
        for i = 1:length(casUnexpected)
            SLTU_FAIL('Unexpected object "%s" found.', casUnexpected{i});
        end
    end
end
end

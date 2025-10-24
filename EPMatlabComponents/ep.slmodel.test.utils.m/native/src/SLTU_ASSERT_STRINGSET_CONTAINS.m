function SLTU_ASSERT_STRINGSET_CONTAINS(casExpectedSet, casFoundSet, sMessage)
% Asserting that the set of expected strings is contained within the found set.
%
%

%% main
casMissing = setdiff(casExpectedSet, casFoundSet);
if ((nargin > 2) && ~isempty(casMissing))
    SLTU_FAIL(sMessage);
else
    if isempty(casMissing)
        MU_PASS(); % just for statistics reported in MUNIT report
    else
        for i = 1:length(casMissing)
            SLTU_FAIL('Expected object "%s" not found.', casMissing{i});
        end
    end
end
end

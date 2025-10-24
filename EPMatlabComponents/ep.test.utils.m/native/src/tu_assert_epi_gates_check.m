function tu_assert_epi_gates_check(sExpectedContext)
if ismember('sGateCheckerContext', evalin('base','who'))
    sExecutedContext = evalin('base', 'sGateCheckerContext');
    MU_ASSERT_EQUAL(sExecutedContext, sExpectedContext, sprintf('Gate check has not been performed in the correct context. Expected ''%s'' but was ''%s''.', sExpectedContext, sExecutedContext));
else
    MU_FAIL('Gate check has not been performed at all.');
end
clear GLOBAL sGateCheckerContext;
return;
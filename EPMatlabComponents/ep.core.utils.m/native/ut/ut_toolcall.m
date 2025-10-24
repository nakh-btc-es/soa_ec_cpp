% Tests, if the hook of ep_core_toolcall works.
%
%  function ut_toolcall()
%
%  It is hard to write a UT for this function because it uses a Java class
%  to search for an executable. This is hard to mock.
%
%  So the test only focusses on failing runs.
%
% $$$COPYRIGHT$$$-2023
function ut_toolcall()

    asEnv = ['VAR'; 'VAL'];
    
    [bSuccess, sError, sOutput] = ep_core_toolcall('unknown_tool', asEnv, 'param1');
    MU_ASSERT_FALSE(bSuccess);
    MU_ASSERT_FALSE(isempty(sError));
    MU_ASSERT_TRUE(isempty(sOutput));
    
end
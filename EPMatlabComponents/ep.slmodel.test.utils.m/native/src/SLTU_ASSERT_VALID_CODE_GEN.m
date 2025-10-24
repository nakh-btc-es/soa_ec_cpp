function SLTU_ASSERT_VALID_CODE_GEN(sCodegenFile, bAssertCompilable)
% Asserts that the code model XML exists and is valid.
%

%%
if (nargin < 2)
    bAssertCompilable = false;
end

%%
SLTU_ASSERT_TRUE(exist(sCodegenFile, 'file'), 'Codegen XML file is missing.');

%% DTD validation
% NOTE: currently no validation done!
% TODO ...

if bAssertCompilable
    bIsLegacyCodegenFile = true;
    [bIsCompilable, sError] = sltu_assert_compilable(sCodegenFile, bIsLegacyCodegenFile);
    SLTU_ASSERT_TRUE(bIsCompilable, 'Codegen XML is not valid: \n%s', sError);
end
end



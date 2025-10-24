function SLTU_ASSERT_EQUAL_EC_AA_COMPONENT(sExpectedAaComponentFile, sTestAaComponentFile)
% Asserts that the CodeModel XML file is equal to the expected XML file.
%

%%
if SLTU_update_testdata_mode()
    MU_MESSAGE('Updating expectation values in CodeModel XML. No equality checking performed!');
    sltu_copyfile(sTestAaComponentFile, sExpectedAaComponentFile);
    return;
end

%%
% Note: currently just a trivial compare based on string equality
% TODO: --> extend functionality (preferably on Java level)
sExpectedContentAsString = fileread(sExpectedAaComponentFile);
sTestContenctAsString = fileread(sTestAaComponentFile);
SLTU_ASSERT_TRUE(strcmp(sExpectedContentAsString, sTestContenctAsString), 'Unexpected difference in stubCodeAA.xml!')
end


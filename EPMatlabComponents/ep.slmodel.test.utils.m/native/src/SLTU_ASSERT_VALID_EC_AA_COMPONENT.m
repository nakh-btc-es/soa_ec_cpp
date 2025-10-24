function SLTU_ASSERT_VALID_EC_AA_COMPONENT(sAACompFile)
% Asserts that the EC AA stubbing XML exists and is valid.
%


%%
SLTU_ASSERT_TRUE(exist(sAACompFile, 'file'), 'AA component XML file is missing.');
sltu_validate_xml('EC_AA', sAACompFile);
end
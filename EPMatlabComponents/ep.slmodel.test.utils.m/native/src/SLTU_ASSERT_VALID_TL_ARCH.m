function SLTU_ASSERT_VALID_TL_ARCH(sTlArchFile)
% Asserts that the TL architecture XML exists and is valid.
%


%%
SLTU_ASSERT_TRUE(exist(sTlArchFile, 'file'), 'TL architecture XML file is missing.');
sltu_validate_xml('TL', sTlArchFile);
end


function SLTU_ASSERT_VALID_SL_ARCH(sSlArchFile)
% Asserts that the SL architecture XML exists and is valid.
%


%%
SLTU_ASSERT_TRUE(exist(sSlArchFile, 'file'), 'SL architecture XML file is missing.');
sltu_validate_xml('SL', sSlArchFile);
end


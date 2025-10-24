function SLTU_ASSERT_VALID_CONSTRAINTS(sArchConstraintsFile)
% Asserts that the TL architecture XML exists and is valid.
%


%%
SLTU_ASSERT_TRUE(exist(sArchConstraintsFile, 'file'), 'Architecture constraints XML file is missing.');
sltu_validate_xml('CONSTRAINTS', sArchConstraintsFile);
end


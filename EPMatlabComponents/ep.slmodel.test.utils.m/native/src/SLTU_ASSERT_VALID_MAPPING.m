function SLTU_ASSERT_VALID_MAPPING(sMappingFile)
% Asserts that the mapping XML exists and is valid.
%


%%
SLTU_ASSERT_TRUE(exist(sMappingFile, 'file'), 'Mapping file is missing.');
sltu_validate_xml('MAPPING', sMappingFile);
end


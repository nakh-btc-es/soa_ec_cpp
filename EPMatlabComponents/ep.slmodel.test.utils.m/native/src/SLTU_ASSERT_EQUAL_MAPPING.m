function SLTU_ASSERT_EQUAL_MAPPING(sExpectedMappingFile, sTestMappingFile)
% Asserts that the mapping XML file is equal to the expected XML file.
%

%%
sExpectedMappingFile = ep_core_canonical_path(sExpectedMappingFile);
sTestMappingFile = ep_core_canonical_path(sTestMappingFile);

if ~exist(sExpectedMappingFile, 'file')
    if SLTU_update_testdata_mode()
        MU_MESSAGE('Creating expected version of the Mapping XML. No equality checks performed!');
        sltu_copyfile(sTestMappingFile, sExpectedMappingFile);
    else
        SLTU_FAIL('No expected values found. Cannot perform any checking.');
    end
else
    jExpectedMappingFile = java.io.File(sExpectedMappingFile);
    jTestMappingFile = java.io.File(sTestMappingFile);


    jComparisonResult = ...
        ep.architecture.spec.test.utils.mapping.MappingComparison.compareFiles(jExpectedMappingFile, jTestMappingFile);

    jDiffList = jComparisonResult.getSummary();
    casDiffs = cell(jDiffList.toArray());
    
    bDiffsFound = ~isempty(casDiffs);
    if bDiffsFound
        if SLTU_update_testdata_mode()
            MU_MESSAGE('Updating expected values in the Mapping XML. No equality checks performed!');
            sltu_copyfile(sTestMappingFile, sExpectedMappingFile);
        else
            for i = 1:numel(casDiffs)
                SLTU_FAIL(casDiffs{i});
            end
        end
    else
        MU_PASS();
    end
end
end




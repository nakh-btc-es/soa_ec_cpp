function SLTU_ASSERT_VALID_CONSTANTS(sConstantsFile)
% Asserts that the TL architecture XML exists and is valid.
%


%%
SLTU_ASSERT_TRUE(exist(sConstantsFile, 'file'), 'Constants XML file is missing.');


astConstants = i_readConstants(sConstantsFile);
i_assertUniqueNames(astConstants);
i_assertNonEmptyNumericalValues(astConstants);
end


%%
function i_assertUniqueNames(astConstants)
if (numel(astConstants) > 1)
    casNames = {astConstants(:).name};
    nNames = numel(casNames);
    nUniqueNames = numel(unique(casNames));
    bNamesAreUnique = nUniqueNames == nNames;
    
    SLTU_ASSERT_TRUE(bNamesAreUnique, 'Unexpected: Found double entries in list of Constants.');
else
    MU_PASS('List with less than two entries --> unique by default.');
end
end


%%
function i_assertNonEmptyNumericalValues(astConstants)
if ~isempty(astConstants)
    casValues = {astConstants(:).value};    
    abIsValid = cellfun(@(v) isfinite(str2double(v)), casValues);
    
    astInvalidConstants = astConstants(~abIsValid);
    for i = 1:numel(astInvalidConstants)
        stInvC = astInvalidConstants(i);
        
        SLTU_FAIL('Invalid value "%s" found for constant "%s".', stInvC.value, stInvC.name);
    end
    
else
    MU_PASS('Empty list. Valid by default.');
end
end


%%
function astConstants = i_readConstants(sConstantsFile)
if ~exist(sConstantsFile, 'file')
    astConstants = [];
else
    hRoot = mxx_xmltree('load', sConstantsFile);
    oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
    
    astConstants = mxx_xmltree('get_attributes', hRoot, '/Constants/Constant', 'name', 'value');
end
end


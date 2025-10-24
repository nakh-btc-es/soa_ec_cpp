function SLTU_ASSERT_EQUAL_CONSTANTS_FILE(sExpectedConstantsFile, sTestConstantsFile)
% Asserts that the Constants XML file is equal to the expected XML file.
%

%%
if SLTU_update_testdata_mode()
    MU_MESSAGE('Updating expectation values in Constants XML. No equality checking performed!');
    sltu_copyfile(sTestConstantsFile, sExpectedConstantsFile);
    return;
end

mExpectedConstants = i_getConstantsMap(sExpectedConstantsFile);
mTestConstants = i_getConstantsMap(sTestConstantsFile);

i_compareConstantsMaps(mExpectedConstants, mTestConstants);
end


%%
function mConstants = i_getConstantsMap(sConstantsFile)
if ~exist(sConstantsFile, 'file')
    error('SLTU:READ_MESSAGES:ERROR', 'File "%s" not found.', sConstantsFile);
end

hRoot = mxx_xmltree('load', sConstantsFile);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));

mConstants = containers.Map;
astConstants = mxx_xmltree('get_attributes', hRoot, '/Constants/Constant', 'name', 'value');
for i = 1:numel(astConstants)
    stConstant = astConstants(i);
    
    mConstants(stConstant.name) = stConstant.value;
end
end


%%
function i_compareConstantsMaps(mExpConstants, mFoundConstants)
casExpectedConstants = mExpConstants.keys;
for i = 1:numel(casExpectedConstants)
    sExpectedConst = casExpectedConstants{i};
    
    if mFoundConstants.isKey(sExpectedConst)
        sExpValue = mExpConstants(sExpectedConst);
        sFoundValue = mFoundConstants(sExpectedConst);
        
        bIsEqual = strcmp(sExpValue, sFoundValue);
        SLTU_ASSERT_TRUE(bIsEqual, 'Expected value "%s" but found "%s" for constant "%s".', ...
            sExpValue, sFoundValue, sExpectedConst);
    else
        SLTU_FAIL('Expected constant "%s" is missing.', sExpectedConst);
    end
end

casFoundConstants = mFoundConstants.keys;
casUnexpectedConstants = setdiff(casFoundConstants, casExpectedConstants);
for i = 1:numel(casUnexpectedConstants)
    SLTU_FAIL('Found unexpected constant "%s".', casUnexpectedConstants{i});
end
end

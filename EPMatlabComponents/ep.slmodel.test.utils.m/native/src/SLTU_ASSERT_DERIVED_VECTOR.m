function SLTU_ASSERT_DERIVED_VECTOR(stTestData, sMatlabVersion)
% Compares derived vectors versus expected values
sSuffix = '';
if (nargin >= 2)
    sSuffix = ['_', sMatlabVersion];
end

for i = 1:length(stTestData.castLoggedSubsystems)
    stLogSub = stTestData.castLoggedSubsystems{i};
    
    sScopeID = stLogSub.sScopeUID;
    sExpectedValuesRoot = fullfile(stTestData.sFullTestDataPath, ['derive_', sScopeID, sSuffix]);
    
    sIExp = fullfile(sExpectedValuesRoot, ['di_', sScopeID, '_exp.csv']);
    sPExp = fullfile(sExpectedValuesRoot, ['dp_', sScopeID, '_exp.csv']);
    sOExp = fullfile(sExpectedValuesRoot, ['do_', sScopeID, '_exp.csv']);
    sLExp = fullfile(sExpectedValuesRoot, ['dl_', sScopeID, '_exp.csv']);
    
    i_assert_equals(sIExp, stLogSub.sInputsMDF,  sScopeID, 'Input');
    i_assert_equals(sPExp, stLogSub.sParamsMDF,  sScopeID, 'Parameter');
    i_assert_equals(sOExp, stLogSub.sOutputsMDF, sScopeID, 'Output');
    i_assert_equals(sLExp, stLogSub.sLocalsMDF,  sScopeID, 'Locals');
end
end


%%
function i_assert_equals(sExpCSV, sSimMDF, sScopeID, sKind)
if SLTU_update_testdata_mode()
    sExpDir = fileparts(sExpCSV);
    if ~exist(sExpDir, 'dir')
        mkdir(sExpDir);
    end
    sltu_mdf_to_simple_csv(sSimMDF, sExpCSV);
    
    MU_MESSAGE(sprintf('TEST NOT ACTIVE: No checks done! Instead testdata "%s" was updated.', sExpCSV));
    return;
end

sTmpCsv = [tempname(), '.csv'];
sltu_mdf_to_simple_csv(sSimMDF, sTmpCsv);
oOnCleanupRemoveTmpCsv = onCleanup(@() delete(sTmpCsv));

stExpData = sltu_simple_csv_to_struct(sExpCSV);
stSimData = sltu_simple_csv_to_struct(sTmpCsv);

MU_ASSERT_TRUE(isequal(stExpData.casTypes, stSimData.casTypes), ...
    sprintf('"%s" signal types of scope %s are not identical.', sKind, sScopeID));
MU_ASSERT_TRUE(isequal(stExpData.casIds, stSimData.casIds), ...
    sprintf('"%s" signal names of scope %s are not identical.', sKind, sScopeID));
MU_ASSERT_TRUE(isequal(stExpData.casValues, stSimData.casValues), ...
    sprintf('"%s" values of scope %s are not identical.', sKind, sScopeID));
end
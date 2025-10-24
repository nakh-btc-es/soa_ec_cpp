function SLTU_ASSERT_EQUAL_MDF(sExpMDF, sTestMDF, sContext)

if (nargin < 3)
    sContext = '';
else
    sContext = sprintf('[%s] ', sContext);
end

if ~exist(sExpMDF, 'file')
    error('USAGE:ERROR', '%sMDF file "%s" with expected values not found.', sContext, sExpMDF);
end
if ~exist(sTestMDF, 'file')
    SLTU_FAIL('%sMDF file "%s" to be checked is missing.', sContext, sTestMDF);
    return;
end

stExpData = i_mdfToStruct(sExpMDF);
stSimData = i_mdfToStruct(sTestMDF);

% Comparison of signal types deactivated, since the basic type of enums
% is derived differently in expected values and in the harness sfunction.
% The harness sfunction only has the bitsize but not the signedness of the
% basic type available. Hence it defines the basic type as unsigned as long
% as all ordinal values of the enum are positive.
% To be more correct here, we need to pass the basic type of the enum types
% in the harness.xml
% TODO Enhance harness-XML with basic type of enums and reactivate test.
% TODO See also EPDEV-68877
%SLTU_ASSERT_TRUE(isequal(stExpData.casTypes, stSimData.casTypes),   '%sSignal types are not identical.', sContext);

SLTU_ASSERT_TRUE(isequal(stExpData.casIds, stSimData.casIds),       '%sSignal names are not identical.', sContext);
SLTU_ASSERT_TRUE(isequal(stExpData.casValues, stSimData.casValues), '%sValues are not identical.', sContext);
end

%%
function stStruct = i_mdfToStruct(sFileMDF)
sTmpCsv = [tempname(), '.csv'];
sltu_mdf_to_simple_csv(sFileMDF, sTmpCsv);
oOnCleanupRemoveTmpCsv = onCleanup(@() delete(sTmpCsv));

stStruct = sltu_simple_csv_to_struct(sTmpCsv);
end

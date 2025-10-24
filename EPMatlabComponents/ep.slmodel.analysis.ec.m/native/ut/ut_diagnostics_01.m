function ut_diagnostics_01
% Testing the functionality: Diagnostics run for models.
%


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, ~, stTestData] = sltu_prepare_ats_env('datastore', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
[~, sModelName] = fileparts(sModelFile);
eca_run_diagnostics(sModelName, sInitScript);
i_assertReportFilesValid(sModelFile);
end


%%
function i_assertReportFilesValid(sModelFile)
[sOrigModelPath, sOrigModelName] = fileparts(sModelFile);

sExpectedReportName = ['analysis_results_', sOrigModelName];

% if sltu_excel_available()
    % sExpectedExcelCsvReportFile = fullfile(sOrigModelPath, [sExpectedReportName, '.xls']);
% else
    %check CSV fallback, performed by Matlab if Excel is not installed
    % sExpectedExcelCsvReportFile = fullfile(sOrigModelPath, [sExpectedReportName, '.csv']);
% end
% bFound = exist(sExpectedExcelCsvReportFile, 'file');
% SLTU_ASSERT_TRUE(bFound, 'Expected Excel (CSV) report "%s" not found.', sExpectedExcelCsvReportFile);

sExpectedTextReportFile = fullfile(sOrigModelPath, [sExpectedReportName, '.txt']);
SLTU_ASSERT_TRUE(exist(sExpectedTextReportFile, 'file'), 'Expected Text report "%s" not found.', sExpectedTextReportFile);
end

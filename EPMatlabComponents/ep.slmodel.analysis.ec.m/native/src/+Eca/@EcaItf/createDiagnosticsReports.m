function oEca = createDiagnosticsReports(oEca)
oEca.sCodeXmlFile = '';
oEca.sMappingXmlFile = '';
oEca.sModelInfoXmlFile = '';

%create analysis report
[oEca.sTextAnalysisReport, oEca.sExcelAnalysisReport] = ep_core_feval('eca_report_analysis_results', oEca);

oEca.sArchiveMatFile = fullfile(pwd, lower([oEca.sModelName '_oeca.mat']));
save(oEca.sArchiveMatFile, 'oEca');
end
function [textFilePath, xlsFilePath] = eca_report_analysis_results(oEca)

bWriteAsExcel   = true;
bWriteAsText    = true;
oRootScope      = oEca.oRootScope;

fprintf('\n## Process EC architecture analysis ...\n');

if isempty(oRootScope)
    fprintf('## No scope has been detected\n');
    return;
end

xlsFileName  = ['analysis_results_', oEca.sModelName,'.xls'];
textFileName = ['analysis_results_', oEca.sModelName,'.txt'];
xlsFilePath = fullfile(oEca.sModelPath, xlsFileName);
textFilePath = fullfile(oEca.sModelPath, textFileName);

% get all scopes and evaluate validity
[aoScopes, astEval] = oEca.getAllScopesWithEvaluatedValidity();


if isempty(aoScopes)
    fprintf('## No scope has been detected.\n');
else
    
    if bWriteAsExcel
        templateFile = which('analysis_results_template.xls');
        try
            copyfile(templateFile, xlsFilePath);
        end
    end
    
    %Content
    casTitles       = {'SignalName' 'BusSignalName' 'BlockName' 'Kind' 'Mappable' 'SimulinkDT'  'Min' 'Max' 'CcodeDT' 'DataClass' 'StorageClass' 'Codevariable' 'CodeStructName'  'CodeStructCompName' 'HFileMissing' 'CFileMissing' 'AnalysisNotes'};
    caExcelContent  = {};
    colLen = zeros(1,17);
    for iScope = 1:numel(aoScopes)
        oScope      = aoScopes(iScope);
        oaItfs       = [oScope.oaInputs, oScope.oaOutputs, oScope.oaParameters, oScope.oaLocals];
        itfExlTable    = {};
        for iItf = 1:numel(oaItfs)
            itfExlTable{iItf,1} = oaItfs(iItf).name;
            if not(isempty(oaItfs(iItf).metaBusSignal))
                itfExlTable{iItf,2} = oaItfs(iItf).metaBus.busSignalName;
            end
            itfExlTable{iItf,3} = regexprep(oaItfs(iItf).sourceBlockName,'[\n\r]+',' ');
            itfExlTable{iItf,4} = oaItfs(iItf).kind;
            itfExlTable{iItf,5} = oaItfs(iItf).bMappingValid;
            itfExlTable{iItf,6} = oaItfs(iItf).sldatatype;
            itfExlTable{iItf,7} = mat2str(oaItfs(iItf).min);
            itfExlTable{iItf,8} = mat2str(oaItfs(iItf).max);
            itfExlTable{iItf,9} = oaItfs(iItf).codedatatype;
            itfExlTable{iItf,10} = oaItfs(iItf).dataClass;
            itfExlTable{iItf,11} = oaItfs(iItf).storageClass;
            itfExlTable{iItf,12} = oaItfs(iItf).codeVariableName;
            itfExlTable{iItf,13} = oaItfs(iItf).codeStructName;
            itfExlTable{iItf,14} = oaItfs(iItf).codeStructComponentAccess;
            itfExlTable{iItf,15} = oaItfs(iItf).bHFileMissing;
            itfExlTable{iItf,16} = oaItfs(iItf).bCFileMissing;
            itfExlTable{iItf,17} = sprintf('%s\n', oaItfs(iItf).casAnalysisNotes{:});
            
            colLen(1) = max(colLen(1), max(cellfun(@numel, [casTitles(1), itfExlTable(:,1)'],'UniformOutput', true)));
            colLen(2) = max(colLen(2), max(cellfun(@numel, [casTitles(2), itfExlTable(:,2)'],'UniformOutput', true)));
            colLen(3) = max(colLen(3), max(cellfun(@numel ,[casTitles(3), itfExlTable(:,3)'],'UniformOutput', true)));
            colLen(4) = max(colLen(4), max(cellfun(@numel, [casTitles(4),itfExlTable(:,4)'],'UniformOutput', true)));
            colLen(5) = max(colLen(5), max(cellfun(@numel ,[casTitles(5),itfExlTable(:,5)'],'UniformOutput', true)));
            colLen(6) = max(colLen(6), max(cellfun(@numel ,[casTitles(6),itfExlTable(:,6)'],'UniformOutput', true)));
            colLen(7) = max(colLen(7), max(cellfun(@numel ,[casTitles(7),itfExlTable(:,7)'],'UniformOutput', true)));
            colLen(8) = max(colLen(8), max(cellfun(@numel ,[casTitles(8),itfExlTable(:,8)'],'UniformOutput', true)));
            colLen(9) = max(colLen(9), max(cellfun(@numel ,[casTitles(9),itfExlTable(:,9)'],'UniformOutput', true)));
            colLen(10) = max(colLen(10), max(cellfun(@numel ,[casTitles(10),itfExlTable(:,10)'],'UniformOutput', true)));
            colLen(11) = max(colLen(11), max(cellfun(@numel ,[casTitles(11),itfExlTable(:,11)'],'UniformOutput', true)));
            colLen(12) = max(colLen(12), max(cellfun(@numel ,[casTitles(12),itfExlTable(:,12)'],'UniformOutput', true)));
            colLen(13) = max(colLen(13), max(cellfun(@numel ,[casTitles(13),itfExlTable(:,13)'],'UniformOutput', true)));
            colLen(14) = max(colLen(14), max(cellfun(@numel ,[casTitles(14),itfExlTable(:,14)'],'UniformOutput', true)));
            colLen(15) = max(colLen(15), max(cellfun(@numel ,[casTitles(15),itfExlTable(:,15)'],'UniformOutput', true)));
            colLen(16) = max(colLen(16), max(cellfun(@numel ,[casTitles(16),itfExlTable(:,16)'],'UniformOutput', true)));
            colLen(17) = max(colLen(17), max(cellfun(@numel ,[casTitles(17),itfExlTable(:,17)'],'UniformOutput', true)));
        end
        
        if bWriteAsExcel
            caExcelContent{end+1,1} = sprintf('%s (%s)', oScope.sSubSystemFullName, sprintf('%s .', astEval(iScope).casNotes{:}));
            caExcelContent(end+1:end+size(itfExlTable,1),1:size(itfExlTable,2)) = itfExlTable;
        end
    end
    
    %Report in Excel sheet
    if bWriteAsExcel
        try
            caExcelContent = [casTitles; caExcelContent];
            xlswrite(xlsFilePath, caExcelContent, 'SUTs')
        end
    end
    
    %Report in Txt file
    if bWriteAsText
        txtFid = fopen(textFilePath,'w');
        i_writeTextReport();
        fclose(txtFid);
    end
    
    %Mappable interfaces summary
    fprintf('\n## Interfaces summary\n');
    i_writAnalysisSummary(1);
    
    fprintf('\n## Analysis results files\n');
    if exist(xlsFilePath,'file')
        fprintf('<a href="matlab:winopen(''%s'')">%s</a>\n', xlsFilePath, xlsFileName);
    end
    if exist(textFilePath,'file')
        fprintf('<a href="matlab:winopen(''%s'')">%s</a>\n', textFilePath, textFileName);
    end
    
end

%i_writeTestReport
    function i_writeTextReport()
        
        %Prepare column widths
        txtTitle = sprintf(' %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %s',...
            colLen(1), casTitles{1}, colLen(2), casTitles{2}, colLen(3), casTitles{3}, colLen(4), casTitles{4},...
            colLen(5), casTitles{5},colLen(6), casTitles{6},colLen(7), casTitles{7},colLen(8), casTitles{8},...
            colLen(9), casTitles{9},colLen(10), casTitles{10},colLen(11), casTitles{11},colLen(12), casTitles{12},...
            colLen(13), casTitles{13},colLen(14), casTitles{14}, colLen(15), casTitles{15}, colLen(16), casTitles{16}, casTitles{17});
        lineSepar = sprintf(' %-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s|%-*s',...
            colLen(1), char('_'*ones(1,1+colLen(1))), colLen(2), char('_'*ones(1,2+colLen(2))), colLen(3), char('_'*ones(1,2+colLen(3))), colLen(4), char('_'*ones(1,2+colLen(4))),...
            colLen(5), char('_'*ones(1,2+colLen(5))),colLen(6), char('_'*ones(1,2+colLen(6))),colLen(7), char('_'*ones(1,2+colLen(7))),colLen(8), char('_'*ones(1,2+colLen(8))),...
            colLen(9), char('_'*ones(1,2+colLen(9))),colLen(10), char('_'*ones(1,2+colLen(10))),colLen(11), char('_'*ones(1,2+colLen(11))),colLen(12), char('_'*ones(1,2+colLen(12))),...
            colLen(13), char('_'*ones(1,2+colLen(13))),colLen(14), char('_'*ones(1,2+colLen(14))), colLen(15), char('_'*ones(1,2+colLen(15))), colLen(16), char('_'*ones(1,2+colLen(16))),...
            colLen(17), char('_'*ones(1,2+colLen(17))));
        
        fprintf(txtFid, '---------------\n');
        fprintf(txtFid, 'General options\n');
        fprintf(txtFid, '---------------\n');
        fprintf(txtFid, '\n');
        fprintf(txtFid, '   All interfaces stub generation   = %s\n', ...
            mat2str(oEca.stConfig.General.AllowStubGeneration));
        fprintf(txtFid, '\n');
        fprintf(txtFid, '------------------------\n');
        fprintf(txtFid, 'Scope analysis options\n');
        fprintf(txtFid, '------------------------\n');
        fprintf(txtFid, '\n');
        fprintf(txtFid, '   Force root scope to use modelname_set() function = %s\n', ...
            mat2str(oEca.stConfig.ScopeCfg.RootScope.ForceUseOfModelStepFunc));
        fprintf(txtFid, '\n');
        fprintf(txtFid, '------------------\n');
        fprintf(txtFid, 'Analysis summary\n');
        fprintf(txtFid, '------------------\n');
        i_writAnalysisSummary(txtFid);
        
        %Scopes and Interfaces analysis results
        fprintf(txtFid, '\n');
        fprintf(txtFid, '----------------------------------------\n');
        fprintf(txtFid, 'Scopes and Interfaces analysis results\n');
        fprintf(txtFid, '----------------------------------------\n');
        
        for iScope = 1:numel(aoScopes)
            oScope = aoScopes(iScope);
            oaItfs = [oScope.oaInputs, oScope.oaOutputs, oScope.oaParameters, oScope.oaLocals];
            fprintf(txtFid, '\nScope: %s (%s)\n', oScope.sSubSystemFullName, sprintf('%s. ', astEval(iScope).casNotes{:}));
            fprintf(txtFid, '\nInterfaces\n');
            fprintf(txtFid, '\n%s\n', txtTitle);
            fprintf(txtFid, '%s\n', lineSepar);
            itfTextTable    = {};
            for iItf = 1:numel(oaItfs)
                itfTextTable{1} = oaItfs(iItf).name;
                if not(isempty(oaItfs(iItf).metaBusSignal))
                    itfTextTable{2} = oaItfs(iItf).metaBus.busSignalName;
                end
                itfTextTable{3} = regexprep(oaItfs(iItf).sourceBlockName,'[\n\r]+',' ');
                itfTextTable{4} = oaItfs(iItf).kind;
                itfTextTable{5} = num2str(oaItfs(iItf).bMappingValid);
                itfTextTable{6} = oaItfs(iItf).sldatatype;
                itfTextTable{7} = mat2str(oaItfs(iItf).min);
                itfTextTable{8} = mat2str(oaItfs(iItf).max);
                itfTextTable{9} = oaItfs(iItf).codedatatype;
                itfTextTable{10} = oaItfs(iItf).dataClass;
                itfTextTable{11} = oaItfs(iItf).storageClass;
                itfTextTable{12} = oaItfs(iItf).codeVariableName;
                itfTextTable{13} = oaItfs(iItf).codeStructName;
                itfTextTable{14} = oaItfs(iItf).codeStructComponentAccess;
                itfTextTable{15} = num2str(oaItfs(iItf).bHFileMissing);
                itfTextTable{16} = num2str(oaItfs(iItf).bCFileMissing);
                itfTextTable{17} = regexprep(sprintf('%s ', oaItfs(iItf).casAnalysisNotes{:}),'[\n\r]+','. ');
                
                fprintf(txtFid,' %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %s\n',...
                    colLen(1), itfTextTable{1}, colLen(2), itfTextTable{2}, colLen(3), itfTextTable{3}, colLen(4), itfTextTable{4},...
                    colLen(5), itfTextTable{5},colLen(6), itfTextTable{6},colLen(7), itfTextTable{7},colLen(8), itfTextTable{8},...
                    colLen(9), itfTextTable{9},colLen(10), itfTextTable{10},colLen(11), itfTextTable{11},colLen(12), itfTextTable{12},...
                    colLen(13), itfTextTable{13},colLen(14), itfTextTable{14}, colLen(15), itfTextTable{15}, colLen(16), itfTextTable{16}, itfTextTable{17});
            end
        end
    end

%i_writAnalysisSummary
    function i_writAnalysisSummary(fileId)
        for iScope =1:numel(aoScopes)
            oScope = aoScopes(iScope);
            fprintf(fileId,'   \nScope %s : %s\n', oScope.sSubSystemFullName, sprintf('%s. ', astEval(iScope).casNotes{:}));
            try fprintf(fileId,'   # mappable Inputs : %d/%d\n', numel(find([oScope.oaInputs.bMappingValid])), numel(oScope.oaInputs));end
            try fprintf(fileId,'   # mappable Outputs : %d/%d\n', numel(find([oScope.oaOutputs.bMappingValid])), numel(oScope.oaOutputs));end
            try fprintf(fileId,'   # mappable Locals : %d/%d\n', numel(find([oScope.oaLocals.bMappingValid])), numel(oScope.oaLocals));end
            try fprintf(fileId,'   # mappable Parameters : %d/%d\n', numel(find([oScope.oaParameters.bMappingValid])), numel(oScope.oaParameters));end
        end
    end
end

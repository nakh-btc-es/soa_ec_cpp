function sFile = createHeaderfile(oStubGen, sFile, sContent, casIncludeFileNames)
%

casIncludeFileNames = cellstr(casIncludeFileNames);
sContent = cellstr(sContent);

[~, sFileName] = fileparts(sFile);

%Create H file
fid = fopen(sFile,'w');
fprintf(fid, '#ifndef _%s_ET_H_\n', upper(sFileName));
fprintf(fid, '#define _%s_ET_H_\n', upper(sFileName));
fprintf(fid, '\n');
if ~isempty(char(casIncludeFileNames))
    fprintf(fid, '#include "%s"\n',  casIncludeFileNames{:});
end
fprintf(fid, '\n');
if ~isempty(char(sContent))
    fprintf(fid, '%s\n', sContent{:});
end
fprintf(fid, '\n');
fprintf(fid, '#endif //_%s_ET_H_\n', upper(sFileName));
fclose(fid);
end
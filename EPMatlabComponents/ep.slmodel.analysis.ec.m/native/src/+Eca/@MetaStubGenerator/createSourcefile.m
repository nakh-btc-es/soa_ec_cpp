function sFile = createSourcefile(oStubGen, sFile, sContent, casIncludeFileNames)

[~, sFileName] = fileparts(sFile);
casIncludeFileNames = cellstr(casIncludeFileNames);
sContent = cellstr(sContent);

%Create C file
fid = fopen(sFile,'w');
fprintf(fid, '#ifndef _%s_ET_C_\n', upper(sFileName));
fprintf(fid, '#define _%s_ET_C_\n', upper(sFileName));
fprintf(fid, '\n');
if ~isempty(char(casIncludeFileNames))
    fprintf(fid, '#include "%s"\n',  casIncludeFileNames{:});
end
fprintf(fid, '\n');
fprintf(fid, '%s\n', sContent{:});
fprintf(fid, '\n');
fprintf(fid, '#endif //_%s_ET_C_\n', upper(sFileName));
fclose(fid);
end
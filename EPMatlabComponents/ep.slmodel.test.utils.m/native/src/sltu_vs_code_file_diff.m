function sltu_vs_code_file_diff(sFile1, sFile2)
% Will open VS Code with a diff view on file1 and file2. ASSUMPTION: VS Code is installed on your machine!
%
% Usage: sltu_vs_code_file_diff(sFile1, sFile2)
%

eval(sprintf('!code --diff %s %s', sFile1, sFile2));
end

fid = fopen('epi_gates_check.m', 'w');
fprintf(fid, 'function epi_gates_check(oObject, sContext)\n');
fprintf(fid, 'clear GLOBAL sGateCheckerContext;\n');
fprintf(fid, 'evalin(''base'', sprintf(''sGateCheckerContext = ''''%%s'''';'', sContext));\n');
fprintf(fid, 'return;\n');
fclose(fid);
rehash;
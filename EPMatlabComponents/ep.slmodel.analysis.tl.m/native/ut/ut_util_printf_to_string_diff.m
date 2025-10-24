function bDiff = ut_util_printf_to_string_diff
% Note: newer ML versions behave more like the Java toString method
%       however, it seems that this behavior is also dependent on the Windows Patch version

dVal = 1.0733413696289062e-0;

sValML = regexprep(sprintf('%.16e', dVal), 'e.+$', '');
sValJava = char(java.lang.Double(dVal).toString());

bDiff = ~strcmp(sValML, sValJava);
end



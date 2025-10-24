function atgcv_m13_dsdd_error_handling(fid)
%
% function atgcv_m13_dsdd_error_handling(fid)
%
%   INPUTS               DESCRIPTION
%   fid                  (int)        file ID for output file             
%
%   OUTPUTS              DESCRIPTION
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2015
%
%   
%%

fprintf(fid, 'if ~isequal(nErrorCode,0)\n');
fprintf(fid, '\t[msgStruct] = dsdd(''GetMessage'',nErrorCode);\n');
fprintf(fid, '\tif ~isempty(msgStruct)\n');
fprintf(fid, '\t\tds_error_register(msgStruct);\n');
fprintf(fid, '\t\tds_error_display(''ShowDialog'',''off'');\n');
fprintf(fid, '\tend\n');
fprintf(fid, 'end\n');

function name = atgcv_tempname_get(dirname)
% Returns the path of a unique folder within the temp-folder
%
% function name = atgcv_tempname
%
%
%   INPUT               DESCRIPTION
%     dirname (opt.)    (string)   temp-dir name
%
%   OUTPUT              DESCRIPTION
%     name              (string)   unique temp-folder
%
%     
%   REMARKS
%     
%
%   <et_copyright>

%% internal 
%
%   REFERENCE(S):
%     EP5-Document
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Stefan Natelberg
% $$$COPYRIGHT$$$
%
%   $Revision: 62891 $
%   Last modified: $Date: 2010-01-27 18:13:05 +0100 (Mi, 27 Jan 2010) $ 
%   $Author: snatelberg $
%

    if nargin == 0
        dirname = atgcv_tempdir_get();
    end

    oUuid = java.util.UUID.randomUUID();
    sUuid = ['tp', strrep(char(oUuid.toString()), '-', '_')];
    name = fullfile(dirname, sUuid);
end
function utclean
% Remove all automatically created unit test files.
%
% function utclean
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$

%  remove files
files = { ...
        'MUnit-List.dtd', ...
        'MUnit-Run.xsl', ...
        'index.html', ... 
        'MUnit-List.xsl', ...
        'UnitTest-Listing.xml', ...
        'MUnit-Run.dtd', ...
        'UnitTest-Results.xml', ...
        'menu.html', ...
        'menu.xhtml', ...
    };

for i=1:length(files)
    if exist([cd, '\', files{i}], 'file')
        delete(files{i});
    end
end

%  remove coverage statistics
if isdir('mcovreport')
    [x,y] = dos(['rmdir /S /Q "mcovreport"']);
end

return;
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

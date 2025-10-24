function utclean
% Remove all automatically created unit test files.
%
%  function utclean
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%
files = { ...
        'MUnit-List.dtd', ...
        'MUnit-Run.xsl', ...
        'index.html', ... 
        'MUnit-List.xsl', ...
        'UnitTest-Listing.xml', ...
        'MUnit-Run.dtd', ...
        'UnitTest-Results.xml', ...
        'menu.xhtml', ...
        'utreport.xml', ...
        'menu.html', ...
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
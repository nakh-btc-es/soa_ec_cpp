function util_upgrade_all_dd()
% Upgrade all dSPACE DataDictionaries in the current dir for TL Version 2.1.6
%
% function util_upgrade_all_dd()
%
%   PARAMETER(S)    DESCRIPTION
%   - 
%
%   OUTPUT
%   - 
%
% AUTHOR(S):
%   marten.penning@osc-es.de
% $$$COPYRIGHT$$$-2003
%
% 

try
    if atgcv_m_version_is_greater_or_equal('TL2.1')
        %update all .dd files in current directory and subdirectories
        [x,sResults]=dos('dir *.dd /b /s');

        sDDArr=strread(sResults,'%s','delimiter','\n');

        for i = 1:length(sDDArr)
            s=sDDArr{i}; 
            dsdd('Close','Save','off');
            err=dsdd('Open','file',s,'Upgrade','on');
            %MU_ASSERT_FALSE(err);
            err=dsdd('Close','Save','on'); 
            %MU_ASSERT_FALSE(err);
        end
    end
catch
    disp('Can´t upgrade dSPACE DataDictionary.');
    MU_FAIL('Can´t upgrade dSPACE DataDictionary.');
end

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

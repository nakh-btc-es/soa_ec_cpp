function util_upgrade_dd()
% Upgrade the current loaded dSPACE DataDictionary for TL Version >= 2.1.
%
% function util_upgrade_dd()
%
%   PARAMETER(S)    DESCRIPTION
%   - 
%
%   OUTPUT
%   - 
%
% AUTHOR(S):
%   Hilger.Steenblock@osc-es.de
% $$$COPYRIGHT$$$-2003
%
% $Revision: 11398 $ Last modified: $Date: 2006-11-30 16:44:10 +0100 (Do, 30 Nov 2006) $ $Author: hsteenblock $ 

try
    if atgcv_m_version_is_greater_or_equal('TL2.1')
        disp('Upgrading DD');
        errorCode = dsdd('Upgrade');
        MU_ASSERT_FALSE(errorCode);
    end
catch
    disp('Can´t upgrade dSPACE DataDictionary.');
    MU_FAIL('Can´t upgrade dSPACE DataDictionary.');
end

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

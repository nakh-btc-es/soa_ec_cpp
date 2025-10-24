function util_close_all_dd
% Close all dSPACE DataDictionaries in the current dir for TL Version >= 2.x
%
% function util_close_all_dd()
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
    
if atgcv_m_version_is_greater_or_equal('TL2')
    dsdd('close','save','off');
end


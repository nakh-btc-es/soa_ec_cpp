function bIsEP2x = ut_m01_is_ep2_context()
% return true if UT is executed in EP2.x environment
%
% note: just a helper function for UnitTests   
%
%

% AUTHOR(S):
%   Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 86015 $ 
%   Last modified: $Date: 2011-04-26 10:06:58 +0200 (Di, 26 Apr 2011) $ 
%   $Author: ahornste $


sThisPath = fileparts(mfilename('fullpath'));
bIsEP2x = ~isempty(regexp(sThisPath, '[\\,/]native[\\,/]', 'once'));
end

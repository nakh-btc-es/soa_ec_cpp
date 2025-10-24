function sAssDtd = ut_m01_get_ass_dtd()
% return full path to official/current dev-version of InterfaceAssumption.dtd
%
% note: just a helper function for UnitTests   
%
%

% AUTHOR(S):
%   Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 218197 $ 
%   Last modified: $Date: 2017-02-08 13:46:35 +0100 (Mi, 08 Feb 2017) $ 
%   $Author: ahornste $

%%
sAssDtd = ut_m01_get_spec_dtd('InterfaceAssumption.dtd');
end


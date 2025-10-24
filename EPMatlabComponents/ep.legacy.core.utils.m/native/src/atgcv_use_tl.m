function bResult = atgcv_use_tl
% Checks if a TL installation is available
%
% function bResult = atgcv_use_tl
%
%   INPUT               DESCRIPTION
%     (none)
%   OUTPUT              DESCRIPTION
%     bResult               True if TL has to be used. 
%                           Otherwise false.
%   
%   REMARKS
%      !! internal function: no input checks !!
%      
%
%   <et_copyright>
%******************************************************************************

%% internal 
%
%   REFERENCE(S):
%
%   AUTHOR(S):
%     Steffen Kollmann
% $$$COPYRIGHT$$$
%
%   $Revision: 157174 $
%   Last modified: $Date: 2013-10-21 14:03:18 +0200 (Mo, 21 Okt 2013) $ 
%   $Author: steffenk $
%%                                                                          
bResult = false;
if exist('dsdd')
    bResult = true;
end
return;


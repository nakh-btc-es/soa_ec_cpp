function [sVersion, sPatchTrailer] = ep_core_version_get(sToolKey)
% Return currently used version of specified tool. 
%
% function [sVersion, sPatchTrailer] = [sVersion, sPatchTrailer] = ep_core_version_get(sToolKey)
%
%   INPUT               DESCRIPTION
%   - sToolKey             (string)  'ML' -- Matlab
%                                    'SL' -- Simulink
%                                    'TL' -- TargetLink
%
%   OUTPUT              DESCRIPTION
%   - sVersion            (string)   curently used version as string
%                                    "<major>.<minor>.<patch><patch_trailer>"
%                                    note: might be empty '' if not found
%
%   - sPatchTrailer        (string)  optional output: if requested, the 
%                                    version string is separted into 
%                                    <patch-main-number> and <patch-trailer> 
%                                    example: '3.3p6' --> '3.3' and 'p6'
%                               
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%
[sVersion, sPatchTrailer] = atgcv_current_version_get(sToolKey);
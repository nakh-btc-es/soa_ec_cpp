function [nComp, bTrailEqual] = ep_core_version_compare(varargin)
% Compare current Matlab/TargetLink version to reference version. 
%
% function [nComp, bTrailEqual] = ep_core_version_compare(varargin)
%
%   INPUT               DESCRIPTION
%   - sRefVersion            (string)  either MLxxx.xxx.xxx for Matlab 
%                                      or     TLxxx.xxx.xxx for TargetLink
%
%
%                                        
%   OUTPUT               DESCRIPTION
%   - nComp                 (integer) ( -1 | 0 | 1 )
%                               1: current version is greater than sRefVersion
%                               0: current version is equal to sRefVersion 
%                              -1: current version is smaller than sRefVersion
%                         <empty>: no valid current version found; 
%                                  tool is not installed
%                           
%   - bTrailEqual            (bool) optional output parameter
%                                  if asked for, the trailer after the version
%                                  number is also compared to the one of the
%                                  current version
%                                  (e.g. TL2.2.1patch3 --> "patch3")
%                            TRUE: trailers are equal
%                           FALSE: trailers differ
%                         <empty>: no valid current version found; 
%                                  tool is not installed
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%
[nComp, bTrailEqual] = atgcv_version_compare(varargin{:});
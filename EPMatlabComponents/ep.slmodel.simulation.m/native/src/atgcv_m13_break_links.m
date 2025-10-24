function nBreakCnt = atgcv_m13_break_links(hBlock, casPreserveLibLinks)
% Break library links of all block contained within provided block.
%
% function nBreakCnt = atgcv_m13_break_links(hBlock)
%
% INPUTS             DESCRIPTION
%   hBlock           (handle)     Simulink block.
%   casPreserveLibLinks
%                     (cell-array) Defines a list of library names for which the links must not be broken.
%                                  For some libraries it is possible that a link break leads to an invalid 
%                                  extraction model. E.g (SimScape). Hence no simulation is possible.
%                                  Only active if 'BreakLinks' is true
%
% OUTPUTS:
%   nBreakCount      (numeric)    number of links that were explcitly boroken
%

%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$
%
%%

if (nargin < 2)
    casPreserveLibLinks = {};
end
nBreakCnt = atgcv_m13_break_linkstatus(hBlock, casPreserveLibLinks);

aoSubsystems = ep_find_system(hBlock,...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'BlockType',      'SubSystem');

nLength = length(aoSubsystems);
for i = 1:nLength
    hSubsystem = aoSubsystems(i);
    nBreakSubCnt = atgcv_m13_break_linkstatus(hSubsystem, casPreserveLibLinks);
    nBreakCnt = nBreakCnt + nBreakSubCnt;
end
end

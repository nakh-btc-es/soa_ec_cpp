function [nBreakCnt, nNonBreakCnt] = atgcv_m13_break_linkstatus(xBlock, casPreserveLibLinks)
% Breakes any library link of the provided simulink block (and also its parents).
%
% function nBreakCnt = atgcv_m13_break_linkstatus(xBlock, casPreserveLibLinks)
%
% INPUTS             DESCRIPTION
%   xBlock           (string)     Simulink block.
%   casPreserveLibLinks
%                     (cell-array) Defines a list of library names for which the links must not be broken.
%                                  For some libraries it is possible that a link break leads to an invalid 
%                                  extraction model. E.g (SimScape). Hence no simulation is possible.
%                                  Only active if 'BreakLinks' is true
% OUTPUTS:
%   nBreakCount      (numeric)    number of links that were explcitly broken
%   nNonBreakCnt      (numeric)   number of links that were explcitly not broken
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

nBreakCnt = 0;
nNonBreakCnt = 0;
if isempty(xBlock)
    return;
end
if (nargin < 2)
    casPreserveLibLinks = {};
end
try
    sType = get_param(xBlock, 'Type');
    if ~strcmpi(sType, 'block')
        return;
    end
    sLinkStatus = get_param(xBlock, 'LinkStatus');
    if any(strcmp(sLinkStatus, {'inactive', 'implicit', 'resolved'}))
        % in order to break a link of a block, the link to the parent
        % needs to be broken also
        sParent = get_param(xBlock, 'Parent');
        [nBreakCnt, nNonBreakCnt] = atgcv_m13_break_linkstatus(sParent, casPreserveLibLinks);
        try
            if i_isLinkBreakAllowed(xBlock, casPreserveLibLinks, nNonBreakCnt > 0)
                set_param(xBlock, 'LinkStatus', 'none');
                nBreakCnt = nBreakCnt + 1;
            else
                nNonBreakCnt = nNonBreakCnt +1;
            end
        catch
        end
    end
catch
    % be robust; nothing to do
end
end

% decides if the linke break action is allowed. For some libraries is this forbidden. E.g. SimScape
function [bIsAllowed] = i_isLinkBreakAllowed(xBlock, casPreserveLibLinks, bIsParentLinkPreserved)
sReferenceBlock = get_param(xBlock, 'ReferenceBlock');
bIsAllowed = ~bIsParentLinkPreserved && (isempty(sReferenceBlock) || isempty(casPreserveLibLinks) || ...
    all(cellfun('isempty', regexpi(sReferenceBlock, casPreserveLibLinks))));
end
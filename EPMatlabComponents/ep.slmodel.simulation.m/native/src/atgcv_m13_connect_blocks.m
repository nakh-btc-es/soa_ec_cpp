function cahLines = atgcv_m13_connect_blocks( hSrcBlock, hDestBlock )
% Connects the source block with the destination block.
%
% Parameters:
%    hSrcBlock       (handle)    Handle of the source block.
%  	 hDestBlock      (handle)    Handle of the destination block.
%
% Output:
%    cahLines        (cell array)Cell array of handles of lines.
%
% Remarks:
%    The number of out ports of the source block and the number of
%    in ports of the destination block must be equal.
%    Both blocks are in the same subsystem of course.
% AUTHOR(S):
%   Remmer.Wilts@osc-es.de
% $$$COPYRIGHT$$$-2006
%
%%

sParent = get_param( hSrcBlock, 'Parent' );

anPorts = get_param(hSrcBlock,'Ports');
sSrcName = strrep(get_param( hSrcBlock, 'Name' ),'/','//');
sDestName = strrep(get_param( hDestBlock, 'Name' ),'/','//');
nLength = anPorts(2);
cahLines = cell(nLength, 0);
for i = 1 : nLength
    cahLines{i} = atgcv_m13_add_line( sParent, sSrcName, i, sDestName, i);
end


%**************************************************************************
% END OF FILE
%**************************************************************************

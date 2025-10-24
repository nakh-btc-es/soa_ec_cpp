function ep_ec_ui_arrange_blocks(aiStartPosition, ahBlockHandles, sFillMode, aiBlockSize, iPadding, aiGridDimensions)
% Arranges given blocks in a specified grid 
%
% *   Marked variable can be "inf"
%
%  INPUT                        DESCRIPTION
%
%   - aiStartPosition           [X, Y]
%   - ahBlockHandles            Array containing the blocks which are to be arranged
%   - sFillMode                 Fill the grid either from 'top_down' or 'bottom_up. Both are from left-to-right.
%   - aiBlockSize               [width, height]
%   - iPadding                  Space between the blocks and from the starting position.
%   - aiGridDimensions          [rows*, columns]
%
iBlockAMount = numel(ahBlockHandles);
iGridSize = aiGridDimensions(1) * aiGridDimensions(2);

for i = 1:iBlockAMount
    iLayerPadding = 5 * floor( (i - 1) / iGridSize);

    iColumnPosition = mod(i - 1, aiGridDimensions(2));
    iRowPosition = floor((mod(i - 1, iGridSize)) / aiGridDimensions(2));

    iLeftBorder = aiStartPosition(1) + iLayerPadding + iPadding + ...
        iColumnPosition * (iPadding + aiBlockSize(1));
    iRightBorder = iLeftBorder + aiBlockSize(1);

    switch sFillMode
        case "top_down"
            iTopBorder = aiStartPosition(2) + iLayerPadding + iPadding + ...
                iRowPosition * (iPadding + aiBlockSize(2));
            iBottomBorder = iTopBorder + aiBlockSize(2);
        case "bottom_up"
            iBottomBorder = aiStartPosition(2) - iLayerPadding - iPadding - ...
                iRowPosition * (iPadding + aiBlockSize(2));
            iTopBorder = iBottomBorder - aiBlockSize(2);
        otherwise
            throw(MException("EP:EC:UI:illegalArgument", ["Unknown block arrangement layout mode: " sFillMode]));
    end

    set_param(ahBlockHandles(i), 'Position', [iLeftBorder, iTopBorder, iRightBorder, iBottomBorder]);
end

end
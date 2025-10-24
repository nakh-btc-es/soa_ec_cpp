function [hTopArea, hBottomArea] = ep_ec_ui_create_bordered_area(aiBorders, aiBackgroundColor, sDestinationPath, iBorderWidth, sAreaLabel)
% Draw an bordered area annotation with specified parameters
%
%  INPUT                        DESCRIPTION
%
%   - aiBorders                 [leftBorder, topBorder, rightBorder, bottomBorder] - "," is apparently necessary.
%   - aiBackgroundColor         [red, green, blue] - Must be numbers from [0, 1] intervall.
%   - sDestinationPath          The path to the system where the area is to be added.
%   - iBorderWidth              The width of the area border.
%   - sAreaLabel                The label shown in the top left of the inner area. Can be '' (empty).
%
%
%  OUTPUT                       DESCRIPTION
%
%   - hTopArea                  The handle of the inner/top area.
%   - hBottomArea               The handle of the outer/bottom area.
%
hTopArea = add_block('built-in/Area', [sDestinationPath '/area'],'Position',[aiBorders(1:2)+iBorderWidth, ...
    aiBorders(3:4)-iBorderWidth], 'BackgroundColor', 'white', 'Text', sAreaLabel, 'DropShadow', 'off');
hBottomArea = add_block('built-in/Area', [sDestinationPath '/area'],'Position',aiBorders, 'BackgroundColor', ...
    ['[' num2str(aiBackgroundColor) ']'], 'Text', '', 'DropShadow', 'off');
end
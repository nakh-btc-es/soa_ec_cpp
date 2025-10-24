function oAreaLabel = ep_ec_ui_create_label(sDestinationPath, aiPosition, sText, sHexColor)
% Creates a bold, centered label at the given location
%
%  INPUT                        DESCRIPTION
%
%   - sDestinationPath          Path to the system where the label will be added
%   - aiPosition                [X, Y]
%   - sText                     The label text
%   - sHexColor                 Color of the text. Use hex with sharp symbol: '#102fda'
%
oAreaLabel = Simulink.Annotation(sDestinationPath, 'text');
oAreaLabel.Position = [aiPosition(1:2)];
oAreaLabel.Name = ['<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/REC-html40/strict.dtd">' ...
    '<html><head><meta name="qrichtext" content="1" /><style type="text/css">p, li { white-space: pre-wrap; } ' ...
    '</style></head><body align="left" style=" font-family:''Helvetica''; font-size:10px; font-weight:400; ' ...
    'font-style:normal;"><p align="left" style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:' ...
    '0px; -qt-block-indent:0; text-indent:0px;"><span style=" font-size:12px; font-weight:600; ' ...
    'color:' sHexColor ';">' sText '</span></p></body></html>'];
oAreaLabel.Interpreter = 'rich';
oAreaLabel.BackgroundColor = 'automatic';
end
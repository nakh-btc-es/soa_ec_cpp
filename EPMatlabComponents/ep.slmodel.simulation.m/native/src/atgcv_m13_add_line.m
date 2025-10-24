function hLine = atgcv_m13_add_line(sSrcname, sOutport, iOutPort, sInport, iInPort)
% wrapper for add_line to allow destination names including '/'
%
% function
%
%   INPUT               DESCRIPTION
%       sSrcname        (string) source block name
%       sOutport        (string) outport name
%       iOutPort        (int) index of outport 
%       sInport         (string) inport name
%       iInPort         (int) index of inport 
%
%   OUTPUT              DESCRIPTION
%       hLine           (handle) of the new inserted line
%   REMARKS
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

try
    hLine = add_line(sSrcname, [sOutport,'/',num2str(iOutPort)], ...
        [sInport,'/',num2str(iInPort)]);
catch 
    sOutport = regexprep(sOutport, '(?<=[^/])/(?=[^/])', '//');
    sInport = regexprep(sInport, '(?<=[^/])/(?=[^/])', '//');
    try
        hLine = add_line(sSrcname, [sOutport,'/',num2str(iOutPort)], ...
            [sInport,'/',num2str(iInPort)]);
    catch exception
        error('ATGCV:MIL_GEN:INTERNAL_ERROR', ...
            'Blocks can not be connected.');
    end
end
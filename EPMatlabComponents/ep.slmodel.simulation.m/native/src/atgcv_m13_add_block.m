function hBlock = atgcv_m13_add_block(sSrcName, sPath, sDestName, sBreakLink, casAddArgs)
% wrapper for add_block to allow destination names including '/'                                 
% 
% function hBlock = atgcv_m13_add_block(sSrcName, sPath, sDestName)
%
%   INPUT               DESCRIPTION
%       sSrcName        (string) source block name
%       sPath           (string) destination path
%       sDestName       (string) destination block name
%       sBreakLink      (string) OPTIONAL: 'BreakLink' == break library link
%
%   OUTPUT              DESCRIPTION
%       hBlock           (handle) of the new inserted block
%   REMARKS
%
%   REFERENCE(S):
%     Design Document: 
%        Section : M13
%        Download:
%        http://pcosc29/dp2004/Download.aspx?ID=1cd1982c-9a3f-4a8d-a155-ce05bc5d84a6
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Hilger Steenblock
% $$$COPYRIGHT$$$-2005
%
%%

if (nargin < 5)
    casAddArgs = {};
end

slash = strfind(sDestName, '/');
if length(slash) > 0
    sOriginalName = sDestName;
    sDestName = 'XYZ';
end

sFullDestPath = [sPath, '/', sDestName];
hBlock = [];
idx = 0;
sSuffix = '';
while idx<1000
    try
        if isempty(casAddArgs)
            hBlock = add_block( sSrcName, [sFullDestPath, sSuffix] );
        else
            hBlock = add_block( sSrcName, [sFullDestPath, sSuffix], casAddArgs{:} );
        end
        break;
    catch oEx
        if strcmp('Simulink:Commands:AddBlockCantAdd',oEx.identifier)
            sSuffix = num2str(idx);
            idx = idx + 1;
        else
            rethrow(oEx);
        end
    end
end

if isempty(hBlock)
    error('EP: hBlock was returned empty by add_block')
end

if length(slash) > 0
    set_param(hBlock, 'Name', sOriginalName);
end

if nargin>3
    if strcmpi(sBreakLink,'BreakLink')
        % break link if library link was copied
        atgcv_m13_break_linkstatus(hBlock);
    end
end

  
%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

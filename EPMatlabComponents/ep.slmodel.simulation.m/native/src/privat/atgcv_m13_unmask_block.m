function atgcv_m13_unmask_block( hBlock )
% Removes all copyfcn of the block and its subsystems. 
%
% function atgcv_m13_unmask_block( hBlock )
%
% INPUTS             DESCRIPTION
%   hBlock           (handle)     Simulink block.
%   
%
% OUTPUTS:
%

%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2008
%
%%

sTag = get(hBlock,'Tag');
if( ~isempty( sTag ) )
    try
        stRes = eval( sTag );
    catch
        stRes = [];
    end
    if( isfield( stRes, 'RefMdlName' ) )
        bMask = strcmp(get_param(hBlock,'Mask'), 'on' );
        if(bMask)
            set_param(hBlock,'MaskCallbackString','');
            set_param(hBlock,'MaskCallbacks',{});
            set_param(hBlock,'MaskDescription', '' );
            set_param(hBlock,'MaskDisplay','');
            set_param(hBlock,'MaskEnableString','');
            set_param(hBlock,'MaskEnables',{});
            set_param(hBlock,'MaskHelp','');
            set_param(hBlock,'MaskIconFrame','on');
            set_param(hBlock,'MaskIconOpaque','on');
            set_param(hBlock,'MaskIconRotate','off');
            set_param(hBlock,'MaskIconUnits','autoscale');
            set_param(hBlock,'MaskInitialization','');
            %set_param(hBlock,'MaskNames',{}); % read only
            set_param(hBlock,'MaskPrompts',{});
            set_param(hBlock,'MaskPromptString','');
            %set_param(hBlock,'MaskPropertyNameString',''); % read only
            set_param(hBlock,'MaskSelfModifiable','off');
            set_param(hBlock,'MaskStyles',{});
            set_param(hBlock,'MaskStyleString','');
            set_param(hBlock,'MaskToolTipsDisplay',{});
            set_param(hBlock,'MaskToolTipString','');
            set_param(hBlock,'MaskTunableValues',{});
            set_param(hBlock,'MaskType','');
            set_param(hBlock,'MaskValues',{});
            set_param(hBlock,'MaskValueString','');
            set_param(hBlock,'MaskVarAliases',{});
            set_param(hBlock,'MaskVariables','');
            set_param(hBlock,'MaskVisibilities',{});
            set_param(hBlock,'MaskVisibilityString','');
            set_param(hBlock,'Mask','off');
        end
    end
end


%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************

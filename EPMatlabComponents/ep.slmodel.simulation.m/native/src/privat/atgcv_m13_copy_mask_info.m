function atgcv_m13_copy_mask_info(stEnv, hDstBlock, hSrcBlock )
% Removes all copyfcn of the block and its subsystems. 
%
% function atgcv_m13_copy_mask_info(stEnv, hDstBlock, hSrcBlock )
%
% INPUTS             DESCRIPTION   
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

bMask = strcmp(get_param(hSrcBlock,'Mask'), 'on' );
if(bMask)
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'Mask');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskVariables');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskVisibilities');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskVisibilityString');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskType');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskValues');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskValueString');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskVarAliases');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskStyleString');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskToolTipsDisplay');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskToolTipString');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskTunableValues');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskCallbackString');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskCallbacks');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskDescription' );
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskDisplay');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskEnableString');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskEnables');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskHelp');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskIconFrame');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskIconOpaque');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskIconRotate');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskIconUnits');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskInitialization');
    %i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskNames'); % read only
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskPrompts');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskPromptString');
    %i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskPropertyNameString'); % read only
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskSelfModifiable');
    i_copy_property(stEnv, hSrcBlock, hDstBlock,'MaskStyles');
end


stRes = get_param(hSrcBlock, 'DialogParameters');
casFieldNames = fieldnames(stRes);

% Block is treated a template block if these conditions are met:
%   -Block has these properties:
%         #BlockChoise
%         #TemplateBlock
%         #MemberBlocks
%   -Block is of type 'SubSystem'
%   -Template property aims towards the current block (addresses itself)
%   -There are member blocks
bIsTemplate = isfield(stRes, 'BlockChoice') && ...
    isfield(stRes, 'TemplateBlock') && ...
    isfield(stRes, 'MemberBlocks') && ...
    strcmp(get_param(hSrcBlock, 'BlockType'), 'SubSystem');
    
if bIsTemplate
    % Check next conditions: property 'TemplateBlock' is not empty and
    % Member blocks are specified
    bIsTemplate = ~isempty(get_param(hSrcBlock, 'TemplateBlock')) && ...
        ~isempty(get_param( hSrcBlock, 'MemberBlocks' ));
end

% List of warnings that are to be ignored for template blocks
casIgnoreOnTemplate = { ...
    'Simulink:blocks:ConfigSubInvTemplate', ...
	'Simulink:SL_ConfigSubInvTemplate', ...
    'Simulink:blocks:ConfigSubInvMembers', ...
	'Simulink:SL_ConfigSubInvMembers', ...
    'Simulink:blocks:VariantInvalidSet'};

for i = 1:length(casFieldNames)
    sFieldName = casFieldNames{i};
    xValue = get_param( hSrcBlock, sFieldName );
    try
        set_param( hDstBlock, sFieldName, xValue );
    catch
        stError = lasterror;
        if any(strcmp(stError.identifier, ...
                {'Simulink:SL_SetParamReadOnly', ...
                'Simulink:Commands:SetParamReadOnly'}))
            continue;
        elseif bIsTemplate && ...
                any(strcmp(stError.identifier, casIgnoreOnTemplate))
            continue;
        else
            % Remove matlab links from error messages
            casExpr = {['<a href="matlab:[\s\w_]*', ...
                '\(''([A-Z]:)?[/\\\w\.]*''[\,\d]*\)">'], '</a>'};
            sMsg = regexprep(stError.message, casExpr, '');
            osc_messenger_add(stEnv, ...
                'ATGCV:MIL_GEN:MASK_PROPERTY_COPY', ...
                'key', sFieldName, ...
                'msg', sMsg);
        end
    end
end



%% i_copy_property
function i_copy_property(stEnv, hSrcBlock, hDstBlock, sProperty )
try
    set(hDstBlock,sProperty,get(hSrcBlock,sProperty));
catch
    stError = lasterror;
    osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:MASK_PROPERTY_COPY', ...
        'key', sProperty, ...
        'msg', stError.message);
end
%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************

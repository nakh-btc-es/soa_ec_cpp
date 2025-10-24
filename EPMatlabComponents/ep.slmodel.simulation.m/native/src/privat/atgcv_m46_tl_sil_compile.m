function atgcv_m46_tl_sil_compile(stEnv, sModel, sOrigPrj, bSilMode)
% Compile the model to tl_sil
%
% function atgcv_m46_tl_sil_compile(stEnv, sModel, sOrigPrj, bSilMode)
%
%   INPUT               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%     .sResultPath       (string)    Result directory for outputs
%   sModel               (string)    Model name of the model
%   sOrigPrj             (string)    DD path
%   bSilMode             (logical)   TRUE if TL model should be put in 
%                                    TL_SIL mode
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
%   REFERENCE(S):
%     Design Document:
%        Section : M46
%        Download:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%


if ~atgcv_debug_status()
    sWarn = warning;
    warning off all;
end

sBatchMode = ds_error_get('BatchMode');
ds_error_set('BatchMode', 'on');

stPreError = [];
stError = [];
atgcv_m46_checkLoadedDD(stEnv, sOrigPrj);
try 
    i_recompileCustomerBlocks(sModel);
    %avoid error because of unconnected ports for expectation values
    bRevert = false;
    
    if strcmp(get_param(sModel, 'UnconnectedOutputMsg'), 'error')
        bRevert = true;
        set_param(sModel, 'UnconnectedOutputMsg', 'none');
    end
    
    try
        evalin('base', [sModel, '([], [], [], ''compile'');']);
    catch %#ok
        evalin('base', [sModel, '([], [], [], ''compile'');']);
    end
    % Special handling for TL_OutPorts see BTS/12112
    atgcv_m46_evaluate_ports(sModel);
    evalin('base', [sModel, '([], [], [], ''term'');']);
catch %#ok
    stPreError = lasterror;%#ok
    try
        evalin('base', [sModel, '([], [], [], ''term'');']);
    catch %#ok
    end
end

if bRevert
	 set_param(sModel, 'UnconnectedOutputMsg', 'error');
end

if( isempty(stPreError) )
    atgcv_m46_checkLoadedDD(stEnv, sOrigPrj);
    try
        if bSilMode
            tl_build_host('Model', sModel, 'IncludeSubItems','on');
            atgcv_m46_checkLoadedDD(stEnv, sOrigPrj);
        end
        
    catch %#ok
        stError = lasterror;%#ok
        try
            evalin('base', [sModel, '([],[],[], ''term'');']);
        catch %#ok
        end
    end
end

ds_error_set('BatchMode', sBatchMode);

if( ~atgcv_debug_status )
    warning(sWarn);
end

% Report all kink of warnings and errors
stTLError = atgcv_m46_tl_msg_eval(stEnv);
if(~isempty(stTLError))
    stError = stTLError;
end

if( ~isempty( stPreError ) )
    sIdentifier = stPreError.identifier;
    sMessage = stPreError.message;
    if( strcmp( sIdentifier, 'MATLAB:MException:MultipleErrors') )
        osc_messenger_add( stEnv, ...
            'ATGCV:MDEBUG_ENV:INIT_FAILURE', ...
            'model', sModel );
    else
        osc_messenger_add( stEnv, ...
            'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
            'step', 'compiling', ...
            'descr', [sIdentifier sMessage] );
    end
end

if( ~isempty( stError ) )
    osc_messenger_add( stEnv, ...
        'ATGCV:MDEBUG_ENV:TL_SIL_MODE_FAILURE', ...
        'model', sModel );
end
end




%%
% re-compile CustomerBlock mex-Files just to be sure
function i_recompileCustomerBlocks(sModelName)
ahBlocks = i_findCustomBlocks(sModelName);
for i = 1:length(ahBlocks)
    i_recompileMexForCustomBlock(ahBlocks(i));
end
end


%%
function ahBlocks = i_findCustomBlocks(sModelName)
ahBlocks = ep_find_system(get_param(sModelName, 'handle'), ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on',  ...
    'MaskType',       'TL_CustomCode', ...
    'BlockType',      'S-Function');
end


%%
function i_recompileMexForCustomBlock(hCustomBlock)
try
    tl_build_customcode_sfcn('Block', hCustomBlock);
catch oEx
    warning('CUSTOM_BLOCK:SFUNC:COMPILE_FAILED', ...
        'Building CustomCode S-Function failed:\n%s', oEx.message);
end
end



function atgcv_mdebugenv_create(stEnv, sExportDir, sModelFileName, astNames, sStartScript, sInitialScript, casPaths, bIsTL, bSilMode, bSelfContainedModel, bHiddenStartMode, bShowExpectedValues, sDebugModel, bEnableTLHook, oProgress)
% Creation of the M-Debug Environment (start script,etc.)
%
% function atgcv_mdebugenv_create(stEnv, sExportDir, sModelFileName,
% sMatFileName, sStartScript, sInitialScript, casPaths, bIsTL, bSilMode,
% bSelfContainedModel, bHiddenStartMode, bShowExpectedValues, sDebugModel,
% bEnableTLHook, oProgress)
%
%   INPUT               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%     .sResultPath       (string)    Result directory for outputs
%   sExportDir           (string)    Export directory of the M-debug
%                                    environment.
%   sModelFileName       (string)    Name of the extraction model (without
%                                    path – assumed to be available in the
%                                    sExportDir)
%   astNames         (struct array)  (array of) struct containing names
%                                    (without path – assumed to be available in the
%                                    sExportDir)
%     .sMatFileName      (string)    Name of the .mat-file
%     .sDisplayName      (string)    Display name with special characters
%   sStartScript         (string)    File name of the start script file.
%                                    (without path – to be stored in
%                                     sExportDir.)
%   sInitialScript       (string)    File name of the initial script of the
%                                    model. Either TargetLink init
%                                    script or Simulink initialization
%                                    script. Init script can be empty ([]).
%   casPaths          (string cell)  Contains necessary string paths for
%                                    the execution of the extraction model.
%   bIsTL                (logical)   TRUE if model is supposed to be TL,
%                                    FALSE otherwise
%   bSilMode             (logical)   TRUE if TL model should be put in SIL mode
%   bSelfContainedModel  (logical)   TRUE if model is self contained
%   bHiddenStartMode     (logical)   FALSE, the script just loads the
%                                    model
%   bShowExpectedValues  (logical)   TRUE if expected values should be
%                                    shown
%   sDebugModel         (string)     Debug model which contains
%                                    information about the outputs.
%   bEnableTLHook        (logical)   Enable/Disable TL hook
%   oProgress            (object)    optional:
%                                    object that tracks the progress
%                                    of profile creation
%
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
% $$$COPYRIGHT$$$-2007

%% internal
%  Tasks:
%  (1) First task is to create a start script, where the model is open and
%      all variables of the MAT-File are loaded into the workspace.
%      Moreover the initial script of the original model is loaded and the
%      additional paths are added with add_path command.
%      (1.1) Add the paths to the environment of the extraction model
%      (optional)
%      (1.2) Load original initial script (optional)
%      (1.3) MAT-File is loaded into the workspace
%      (1.4) Open the extraction model
%  (2) Second task is to create an 'close' function, which is added to the
%      'CloseFcn' callback of the model. In this script all added paths are
%      removed (removepath). But only those paths are removed, which are
%      are added. (A workspace variable 'BTC_MIL_PATHS' are used for that
%      purpose).
%    $proplist$
%             $props$ START_SCRIPT_CREATED
%                   Start script for the debug environment must be created.
%                   $prop$ ADD_PATH_TO_ENVIRONMENT
%                   The environment paths are part of the start script and
%                   when the start script is executed they are added to the
%                   execution environment. But only those paths which do
%                   not exist before are added. And only those can be
%                   removed in the close script. They are stored in the
%                   BTC_MIL_PATHS 'base' workspace variable.
%                   $/prop$
%                   $prop$ BTC_MIL_PATHS_DEFINED
%                   Added environments paths are stored in the WS variable
%                   BTC_MIL_PATHS
%                   $/prop$
%                   $prop$ LOAD_MAT_FILE_IN_WS
%                   The stimuli vector MAT file must be load in the
%                   workspace 'base'.
%                   $/prop$
%                   $prop$ LOAD_ORIGINAL_INIT_SCRIPT
%                   The original init script file must be loaded. It might
%                   laod additional environments paths or parameter values.
%                   $/prop$
%                   $prop$ ENVIRONMENT_PATHS_ADDED
%                   After the start script is executed, additional
%                   environment paths are added.
%                   $/prop$
%             $/props$
%             $props$ CLOSE_SCRIPT_CREATED
%                   The close script is responsibe to remove the additional
%                   paths from matlab after the extraction model is closed.
%                   $prop$ REMOVE_PATH_FROM_ENVIRONMENT
%                   The additional environment variables for the extraction
%                   model must be removed from Matlab after closing the
%                   model.
%                   $/prop$
%                   $prop$ CLOSE_SCRIPT_CLOSE_FCN
%                   The created close function is set to the CloseFcn
%                   callback of the extraction model.
%                   $/prop$
%                   $prop$ CLOSE_FCN_CALLBACK_EXIST_ALREADY
%                   TODO : What happens when callback CloseFcn is already
%                   set. Solution just added it to the callback CloseFcn;
%                   $/prop$
%                   $prop$ BTC_MIL_PATHS_DELETED
%                   After the close script is executed (model is closed) the
%                   BTC_MIL_PATHS 'base' variable is cleared.
%                   $/prop$
%                   $prop$ ENVIRONMENT_PATHS_REMOVED
%                   After the close script is executed, all additional
%                   environment paths are removed.
%                   $/prop$
%             $/props$
%    $/proplist$
%
%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
%     BTC - Embedded Systems AG, GERMANY
%     Copyright 2007
%%


try   
    atgcv_progress_set(oProgress, ...
        'current', 0, ...
        'total',   8000, ...
        'msg',     'Enhance Debug Environment');
    
    %% BTS/14992
    sConfigDir = fullfile(sExportDir, 'config');
    if( exist(sConfigDir,'dir') == 7 )
        casPaths{end+1} = sConfigDir;
    end
    if bSelfContainedModel
        atgcv_m46_copy_files(sExportDir, casPaths, {'.h', '.c', '.m', '.p', '.mexw32', '.mexw64'});
    else
        atgcv_m46_copy_files(sExportDir, casPaths, {'.h', '.c'});
    end
    
    if bSelfContainedModel
        atgcv_m46_save_workspace_to_mat(stEnv, sExportDir, sModelFileName);
    end
    
    atgcv_progress_set(oProgress, 'current', 2000);
    
    if bSelfContainedModel
        atgcv_m46_init_script_create_selfcontained(stEnv, sExportDir, ...
            sModelFileName, sStartScript, bHiddenStartMode);
    else
        atgcv_m46_init_script_create(stEnv, sExportDir, ...
            sModelFileName, sStartScript, sInitialScript, casPaths, ...
            bHiddenStartMode);
    end
    
    
    atgcv_progress_set(oProgress, 'current', 3000);
    try
        % open model
        sPwdDir = pwd;
        [~, sModel] = fileparts( sModelFileName );
        
        cd( sExportDir );
        
        if isempty(casPaths)
            casPaths = {};
        end
        
        bActivateMil = false;
        bIgnoreInitFail = true;
        if(isempty(sInitialScript) )
            casInitScript = cell(0);
        else
            casInitScript = {sInitialScript};
        end
        stOpenRes = atgcv_m_model_open(stEnv, sModel, ...
            casInitScript, bIsTL, false, casPaths, bActivateMil, bIgnoreInitFail);
    catch exception
        osc_messenger_add( stEnv, ...
            'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
            'step', 'opening model', ...
            'descr', exception.message );
        
    end
    atgcv_m46_close_script_create(stEnv, sExportDir, sModel);
    
    
    atgcv_progress_set(oProgress, 'current', 4000);
    
    if( ~bHiddenStartMode )
        if ( bIsTL )
            try 
                ep_tl_debug_mode_settings(stEnv, sExportDir, ...
                    sModelFileName, bSilMode, ...
                    bEnableTLHook, bSelfContainedModel);
            catch exception
                osc_messenger_add( stEnv, ...
                    'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                    'step', 'TargetLink mode setting', ...
                    'descr', exception.message );
                
            end
        end
    end
    
    atgcv_progress_set(oProgress, 'current', 5000);
    
    % handle multiple vectors in debug environment
    if ~bHiddenStartMode
        atgcv_m46_add_multiple_vector_selection(stEnv, sModel, astNames, bShowExpectedValues);
    end
    
    atgcv_progress_set(oProgress, 'current', 6000);
    
    
    [hBlock, hSFct] = i_findBlock(sModel);
    if isempty(hSFct)
        if bShowExpectedValues
            atgcv_m46_add_expected_values(stEnv, sModel, sDebugModel);
        end
    else
        if bShowExpectedValues
            ep_sim_add_expected_values(stEnv, hBlock, hSFct);
        else
            addterms(hBlock);
        end
    end
    
    atgcv_progress_set(oProgress, 'current', 7000);
    
    try
        %% Delete calibration info file
        sCalibrationInfo = fullfile(sExportDir,'CalibrationInfo.xml');
        if( exist( sCalibrationInfo, 'file' ) )
            delete( sCalibrationInfo );
        end
        
        %% Delete interface info file
        sInterfaceInfo = fullfile(sExportDir,'interface.xml');
        if( exist( sInterfaceInfo, 'file' ) )
            delete( sInterfaceInfo );
        end
        
        %% Delete init file, because it is default empty
        if( ~bHiddenStartMode )
            if length(astNames) == 1
                sScriptName = sprintf('%s_pre_prodcode_sim_hook', sModel);
                sFcnScript = fullfile(sExportDir, [sScriptName, '.m']);
                if( exist( sFcnScript, 'file' ) )
                    delete(sFcnScript);
                end
                sScriptName = sprintf('%s_ddvar_get_hook', sModel);
                sFcnScript = fullfile(sExportDir, [sScriptName, '.m']);
                if( exist( sFcnScript, 'file' ) )
                    delete(sFcnScript);
                end
                sScriptName = sprintf('%s_tl_sim_interface_hook', sModel);
                sFcnScript = fullfile(sExportDir, [sScriptName, '.m']);
                if( exist( sFcnScript, 'file' ) )
                    delete(sFcnScript);
                end
            end
        end
        
    catch exception
        osc_messenger_add( stEnv, ...
            'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
            'step', 'debug environment configuration', ...
            'descr', exception.message );
        
    end
    
    % save the current extraction model
    try
        atgcv_m13_save_model(sModel, true, false);
    catch
        % save_system fails sometimes with "permission denied" -- see BTS/10408
        % workaround: wait for 2 secs then try again
        pause(2);
        atgcv_m13_save_model(sModel, true, false);
    end
    
    % close model
    atgcv_m_model_close(stEnv, stOpenRes);
    cd( sPwdDir );
    
    atgcv_progress_set(oProgress, 'current', 8000);
    
    
catch exception
    try
        % close model
        atgcv_m_model_close(stEnv, stOpenRes);
    catch
    end
    
    osc_messenger_add( stEnv, ...
        'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
        'step', 'debug environment configuration', ...
        'descr', exception.message );
end
end


%%
function [hBlock, hSFct] = i_findBlock(sModelName)
hSFct = [];
ahBlocks = ep_find_system(sModelName, 'Name', 'Ws2Vars');
if ~isempty(ahBlocks)
    hBlock = ahBlocks{1};
else
    ahBlocks = ep_find_system(sModelName, 'Name', 'BTCHarnessOut');
    hBlock = ahBlocks{1};
    ahBlocks = ep_find_system(sModelName, 'Name', 'BTCHarnessOUT');
    hSFct = ahBlocks{1};
end
end
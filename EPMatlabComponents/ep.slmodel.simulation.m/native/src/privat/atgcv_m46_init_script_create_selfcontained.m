function atgcv_m46_init_script_create_selfcontained(stEnv, sExportDir, sModelFileName, sStartScript, bHiddenStartMode)
% Creation of start a script.
%
% function atgcv_m46_init_script_create(stEnv, sExportDir, sModelFileName,
% sMatFileName, sStartScript, sInitialScript, casPaths)
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
%   sMatFileName         (string)    Mat file name (without path – assumed
%                                    to be available in the sExportDir)
%   sStartScript         (string)    File name of the start script file.
%                                    (without path – to be stored in
%                                     sExportDir.)
%   bHiddenStartMode     (logical)   If TRUE, model will be opened if the
%                                    startup script is executed
%
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
% $$$COPYRIGHT$$$-2007
%%


try
    sFile = fullfile( sExportDir, sStartScript );
    
    % open file
    [fid] = fopen(sFile,'wt');
    
    % create file header
    i_createHeader(fid, sStartScript);
    
    % create the environment
    i_createEnvironment(fid);
    
    % write the content
    [sMdlPath,sMdlName] = fileparts(sModelFileName);%#ok
    sWsMatFile = fullfile(sExportDir,[sMdlName,'_base.mat']);
    i_createContent(fid, sExportDir, sModelFileName, ...
        sWsMatFile, bHiddenStartMode );
    
    fclose(fid);
catch exception
    osc_messenger_add( stEnv, ...
        'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
        'step', 'init script generation', ...
        'descr', exception.message );
end
end

%**************************************************************************
%                    INTERNAL FUNCTION DEFINITION(S)                    ***
%**************************************************************************


%**************************************************************************
% Create file header                                                    ***
%                                                                       ***
% Parameters:                                                           ***
%   fid             (int)     file ID for output file                   ***
%                                                                       ***
% Outputs:                                                              ***
%   -                                                                   ***
%**************************************************************************
function i_createEnvironment( fid )


fprintf(fid,'\n\n%%%% Set the DEBUG directory\n');
fprintf(fid,'cd(fileparts(mfilename(''fullpath'')));\n\n');
fprintf(fid,'%%%% Add additional paths to the environment\n');
fprintf(fid,'addpath(fileparts(mfilename(''fullpath'')));\n');

fprintf(fid,'\n\n');
end

%**************************************************************************
% Create file header                                                    ***
%                                                                       ***
% Parameters:                                                           ***
%   fid             (int)     file ID for output file                   ***
%   sFileName       (string)  file name of the M-file                   ***
%                                                                       ***
% Outputs:                                                              ***
%   -                                                                   ***
%**************************************************************************
function i_createHeader(fid,sFileName)

[~,sName] = fileparts( sFileName );
fprintf(fid,['function ', sName,'()','\n']);
atgcv_m46_print_script_header(fid, sName, ...
    'This file contains functionality to initialize the extraction model.');

end




%%
function i_createContent(fid, sExportDir, sModelFileName, sWsMatFile, bHiddenStartMode)
if ~isempty(sWsMatFile) && exist(sWsMatFile, 'file')
    [~, sName, sExt] = fileparts(sWsMatFile);
    sWsMatFile = [sName,sExt];
    fprintf(fid, '%%%% Load the original WS mat file %s\n', sWsMatFile);
    fprintf(fid, 'evalin(''base'', ''load(''''%s'''')'');\n', sWsMatFile);
    fprintf(fid, '\n\n');
end

% evaluate the init script
[~, sMdlName] = fileparts(sModelFileName);
sModelScriptName =  [sMdlName, '_init'];
sModelInitScript = fullfile(sExportDir, [sModelScriptName, '.m']);
if exist(sModelInitScript, 'file')
    fprintf(fid, 'try evalin(''base'', ''%s''); catch end %#ok\n',sModelScriptName);
end

% open the model
sModelFile = fullfile(sExportDir, sModelFileName);
if exist(sModelFile, 'file')
    fprintf(fid, '%%%% Open the model %s\n', sMdlName);

    if atgcv_use_tl
        fprintf(fid, 'sBatchMode = ds_error_get(''BatchMode'');\n');
        fprintf(fid, 'ds_error_set(''BatchMode'', ''on'');\n\n');

        fprintf(fid,'%% Prevent DD question dialog\n');
        fprintf(fid,'dsdd(''Close'',''Save'',''off'');\n\n');        
    end
    
    if ~bHiddenStartMode    
        fprintf(fid, 'open_system(''%s'');\n\n', sMdlName);
    else
        fprintf(fid, 'load_system(''%s'');\n\n', sMdlName);
    end
    
    if atgcv_use_tl
        fprintf(fid, 'ds_error_set(''BatchMode'', sBatchMode);\n\n\n');
    end
    
    fprintf(fid, '%% Open all related models and trigger vector selection\n');
    fprintf(fid, 'try\n');
    fprintf(fid, '\tfind_mdlrefs(''%s'', ''KeepModelsLoaded'', 1, ''AllLevels'', 1);\n', sMdlName);
    fprintf(fid, ['\tset_param(''', sMdlName, '/BTCHarnessIN'', ''MaskValueString'', get_param(''', sMdlName, '/BTCHarnessIN'', ''MaskValueString''));\n']);
    fprintf(fid, 'catch\n');
    fprintf(fid, 'end\n');
end
end


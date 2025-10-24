function atgcv_m46_init_script_create(stEnv, sExportDir, sModelFileName, sStartScript, sInitialScript, casPaths, bHiddenStartMode)
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
%   sInitialScript       (string)    File name of the initial script of the
%                                    model. Either TargetLink init
%                                    script or Simulink initialization
%                                    script. Init script can be empty ([]).
%   casPaths          (string cell)  Contains necessary string paths for
%                                    the execution of the extraction model.
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
    sFile = fullfile(sExportDir, sStartScript);
    
    % open file
    [fid] = fopen(sFile,'wt');
    
    % create file header
    i_createHeader(fid, sStartScript);
    
    % create the environment (add paths)
    i_createEnvironment( fid, casPaths );
    
    % write the content
    i_createContent(fid, sExportDir, sModelFileName, sInitialScript, bHiddenStartMode);
    
    fclose(fid);
catch exception
    osc_messenger_add( stEnv, ...
        'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
        'step', 'init script generation', ...
        'descr', exception.message );
end
end


%%
function i_createEnvironment( fid, casAddPaths )
fprintf(fid,'\n\n%%%% Set the DEBUG directory\n');
fprintf(fid,'cd(fileparts(mfilename(''fullpath'')));\n\n');


fprintf(fid,'%%%% Add additional paths to the environment\n\n');

fprintf(fid,'addpath(fileparts(mfilename(''fullpath'')));\n');
for i = 1:length(casAddPaths)
    sPath = casAddPaths{i};
    fprintf(fid,'addpath(''%s'');\n', sPath);
end

fprintf(fid,'\n\n');
end


%%
function i_createHeader(fid,sFileName)
[~,sName] = fileparts( sFileName );
fprintf(fid,['function ', sName,'()','\n']);
atgcv_m46_print_script_header(fid, sName, 'This file contains functionality to initialize the extraction model.');
end


%%
function i_createContent(fid, sExportDir, sModelFileName, sInitialScript, bHiddenStartMode)
% load the original initial script
if( ~isempty( sInitialScript ) )
    if( exist(sInitialScript,'file') == 2 )
        fprintf(fid, ...
            '%%%% Load the original inital script %s .\n\n', ...
            sInitialScript );
        
        fprintf(fid,'sPwd = pwd;\n');
        fprintf(fid,'[sPath,sScript] = fileparts(''%s'');\n', ...
            sInitialScript);
        fprintf(fid,'cd(sPath);\n');
        fprintf(fid,'bLoadInitAgain = false;\n');
        fprintf(fid,'try\n');
        fprintf(fid,'\tevalin(''base'', sScript);\n');
        fprintf(fid,'catch\n');
        fprintf(fid,'\tbLoadInitAgain = true;\n');
        fprintf(fid,'end\n');
        fprintf(fid,'cd(sPwd);\n\n');
        fprintf(fid,'\n\n');
    end
end

% evaluate the init script
[~,sMdlName] = fileparts(sModelFileName);
sModelScriptName =  [sMdlName, '_init'];
sModelInitScript = fullfile( sExportDir, [sModelScriptName, '.m']);
if( exist( sModelInitScript, 'file' ) == 2)
    fprintf(fid, 'try evalin(''base'', ''%s'' ); catch end %#ok\n',sModelScriptName);
end

% open the model
sModelFile = fullfile( sExportDir, sModelFileName );
nResult = exist(sModelFile,'file');
if(  nResult == 4 || nResult == 2 )
    [~,sMdlName] = fileparts(sModelFile);
    fprintf(fid,['%%%% Open the model ', sMdlName,'.\n\n']);
    % SL-Only use case
    if atgcv_use_tl
        fprintf(fid, 'sBatchMode = ds_error_get(''BatchMode'');\n');
        fprintf(fid, 'ds_error_set(''BatchMode'', ''on'');\n\n');
    end
    
    if atgcv_use_tl
        fprintf(fid,'%%%% Prevent DD question dialog\n');
        fprintf(fid,'dsdd(''Close'',''Save'',''off'');\n\n');
        
    end
    
    if ~bHiddenStartMode
        fprintf(fid, 'open_system(''%s'');\n\n', sMdlName);
    else
        fprintf(fid, 'load_system(''%s'');\n\n', sMdlName);
    end
    
    % SL-Only use case
    if atgcv_use_tl
        fprintf(fid, 'ds_error_set(''BatchMode'', sBatchMode);\n\n\n');
    end
end

% Load init script again
if (~isempty(sInitialScript) && exist(sInitialScript,'file'))
    fprintf(fid, '%%%% Load the original inital script %s again, when it failed before.\n\n', sInitialScript );
    fprintf(fid,'if( bLoadInitAgain )\n');
    fprintf(fid,'cd(sPath);\n');
    fprintf(fid,'try\n');
    fprintf(fid,'\tevalin(''base'', sScript );\n');
    fprintf(fid,'catch exception\n');
    fprintf(fid,'\twarning(''DEBUG_ENV_WARNING:INIT_SCRIPT_FAILED'', ...\n');
    fprintf(fid,'\t\t%s\n', '''\n%s'', exception.message);');
    fprintf(fid,'end\n');
    fprintf(fid,'cd(sPwd);\n');
    fprintf(fid,'end\n\n');
end

fprintf(fid, '%% Open all related models and trigger vector selection\n');
fprintf(fid, 'try\n');
fprintf(fid, '\tfind_mdlrefs(''%s'', ''KeepModelsLoaded'', 1, ''AllLevels'', 1);\n', sMdlName);
fprintf(fid, ['\tset_param(''', sMdlName, '/BTCHarnessIN'', ''MaskValueString'', get_param(''', sMdlName, '/BTCHarnessIN'', ''MaskValueString''));\n']);
fprintf(fid, 'catch\n');
fprintf(fid, 'end\n');
end

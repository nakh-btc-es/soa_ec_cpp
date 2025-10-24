function atgcv_m46_close_script_create(stEnv, sExportDir, sModel)
% Creation of the exit script of a model.
%
% function atgcv_m46_exit_script_create(stEnv, sExportDir, sModelFileName, 
% sMatFileName, bIsTL, bSilMode, bHiddenStartMode)
%
%   INPUT               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%     .sResultPath       (string)    Result directory for outputs
%   sExportDir           (string)    Export directory of the M-debug 
%                                    environment. 
%   sModel               (string)    Name of the extraction model (without
%                                    path – assumed to be available in the
%                                    sExportDir)
%                                    
%   OUTPUT              DESCRIPTION
%     
%   REMARKS
%
% $$$COPYRIGHT$$$-2007
%%

try    
    % add exit function to model EXIT_FCN callback
    
    sExitScript = [sModel,'_closefcn'];
    sFile = fullfile(sExportDir, [sExitScript,'.m']);

    % open file
    [fid] = fopen(sFile,'wt');

    % create file header
    i_createHeader(fid, sExitScript);
    
    % create content
    i_createContent(fid);    

    % set the exit fcn callback 
    sContent = get_param(sModel,'CloseFcn');
    if (isempty(sContent))
        set_param(sModel, 'CloseFcn', sExitScript);
    elseif (isempty(strfind( sContent, sExitScript)))
        sNewContent = sprintf('%s;%s', sExitScript, sContent);
        set_param(sModel, 'CloseFcn', sNewContent);
    end
    
    fclose(fid);
catch exception
    try
        fclose(fid);
    catch
    end
    osc_messenger_add(stEnv, ...
        'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
        'step', 'close script generation', ...
        'descr', exception.message);
end
end

%**************************************************************************
%                    INTERNAL FUNCTION DEFINITION(S)                    ***
%**************************************************************************




%**************************************************************************
% Create file content                                                   ***
%                                                                       ***
% Parameters:                                                           ***
%   fid             (int)     file ID for output file                   ***
%                                                                       ***
% Outputs:                                                              ***
%   -                                                                   ***
%**************************************************************************
function i_createContent(fid)


fprintf(fid,'\n\n%%%% Remove Environment Paths\n\n'); 

fprintf(fid,'warning off all;\n'); 
fprintf(fid,'rmpath(fileparts(mfilename(''fullpath'')));\n');
fprintf(fid,'warning on all;\n'); 
fprintf(fid,'\n\n%%%% END OF FILE\n\n'); 
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
function i_createHeader(fid, sFileName)

fprintf(fid,['function ', sFileName,'()','\n']);
atgcv_m46_print_script_header(fid, sFileName, ...
    'Contains functionality to remove additional paths from the extraction model.');
end

%**************************************************************************
% END OF FILE
%**************************************************************************

function atgcv_m46_save_workspace_to_mat( stEnv, sExportDir, sModelFileName )
% Saves all workspace variables in a mat-file if saving is possible
%
% function atgcv_m46_save_workspace_to_mat(stEnv, sExportDir,
% sModelFileName) 
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
%                                    
%
%   OUTPUT              DESCRIPTION
%     
%   REMARKS
%
%   AUTHOR(S)
%   Frederik Berg
% $$$COPYRIGHT$$$-2015
%%
[~, sModelName] = fileparts(sModelFileName);

sMatFile = fullfile(sExportDir, [sModelName,'_base.mat']);

try
    
    % save the current WS as mat file
    evalin('base', sprintf('save(''%s'')',sMatFile));
    
catch 
    % possibly, non serializable java objects are in the workspace, so we
    % try to store the variables one by one
    i_storeWsVarsOneByOne(sMatFile);
    osc_messenger_add(stEnv, 'ATGCV:MDEBUG_ENV:MAT_INCOMPLETE', ...
        'fileName', sMatFile);
end

end

%% internal functions
function i_storeWsVarsOneByOne(sMatFile)
% only append vars that haven't been saved yet
castWsVars = evalin('base', 'who');
castSavedVars = evalin('base', sprintf('whos(''-file'', ''%s'')', ...
    sMatFile));
casSavedVarNames = {castSavedVars.name};
casVarsToSave = castWsVars(~ismember(castWsVars, casSavedVarNames));
for i=1:length(casVarsToSave)
    sVar = casVarsToSave{i};
    try
        evalin('base', sprintf('save(''%s'', ''%s'', ''-append'')',sMatFile, sVar));
    catch
        % nothing to do here, ignoring non serializable java objects
    end
end
end
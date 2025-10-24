function sInitScript = ep_sim_init_script_gen(sExportPath, sDestMdl, hContentCallback)
% Generates the init script
%
% function sInitScript = ep_sim_init_script_gen(sExportPath, sDestMdl, hContentCallback)
%
%   INPUT               DESCRIPTION
%     sExportPath         (string)    the path where the init script is placed
%     sDestMdl            (string)    the name of the corresponding model
%     hContentCallback    (function)  handle to the function that fills script with content
%                                     note: called as feval(hContentCallback, hFid) with 
%                                           * hFid --> the handle to the open init script file
%
%   OUTPUT              DESCRIPTION
%     sInitScript         (string)    full path to location of the exported init script
%


%%
if (nargin < 3)
    hContentCallback = [];
end

%%

sInitScript = fullfile(sExportPath, sprintf('%s_init.m', sDestMdl));
[~, sInitScriptName] = fileparts(sInitScript);

% open file
hFid = fopen(sInitScript, 'wt');
oOnCleanupCloseFileHandle = onCleanup(@() fclose(hFid));

% print header
ep_simenv_print_script_header(hFid, sInitScriptName, 'This file contains the initialization of the MIL simulation.');


% fill with content
if ~isempty(hContentCallback)
    feval(hContentCallback, hFid);
end
end

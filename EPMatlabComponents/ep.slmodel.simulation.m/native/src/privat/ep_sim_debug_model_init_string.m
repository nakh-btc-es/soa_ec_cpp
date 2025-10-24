function sCommand = ep_sim_debug_model_init_string(sModelName, nTabs)
% Creates a formatted string to use in internal mask callback or debug model start script
%
% function ep_sim_debug_model_init_string(sModelName)

%   INPUT               DESCRIPTION
%   sModelName (string) Name of the extraction model (without
%                       path – assumed to be available in the sExportDir)
%   nTabs      (integer)number of tabs to indent
%   OUTPUT              DESCRIPTION
%   sCommand   (string) Formatted string for correct debug vector selection in debug model simulation 
%   REMARKS
%
%   AUTHOR(S):
%     Kristof Woll
% $$$COPYRIGHT$$$-2022
%
%%
sPreSimScriptName = sprintf('%s_pre_sim', sModelName);
sPreSimScriptFile = fullfile(pwd, [sPreSimScriptName, '.m']);
sVarInit = sprintf([... 
    strcat(i_getIndentation(nTabs), 'sDisplayName = get_param(''', sModelName, '/BTCHarnessIN'', ''DebugVector'');\n'), ...
    strcat(i_getIndentation(nTabs), 'casVectorName = regexp(sDisplayName, ''.*\\[(.+)\\]$'', ''tokens'');\n'), ...
    strcat(i_getIndentation(nTabs), 'sVectorName = casVectorName{1}{1};\n'), ...
    strcat(i_getIndentation(nTabs), 'sVectorMatPath = sprintf(''%%s/%%s.mat'', sVectorName, sVectorName);\n')]);
sCommand = [sVarInit, sprintf([...
    strcat(i_getIndentation(nTabs), 'if strcmp(get_param(gcs, ''SimulationStatus''), ''stopped'')\n'), ...
    strcat(i_getIndentation(nTabs), '\tevalin(''base'', sprintf(''load(''''%%s'''')'', sVectorMatPath));\n'), ...
    strcat(i_getIndentation(nTabs), sprintf('\tif exist(''%s'', ''file'')', strrep(sPreSimScriptFile,'\','\\')), '\n'), ...
    strcat(i_getIndentation(nTabs), ['\t\tevalin(''base'', ' sprintf('''%s''', sPreSimScriptName) ');\n']), ...
    strcat(i_getIndentation(nTabs), '\tend\n'), ...
    strcat(i_getIndentation(nTabs), 'end')])];
end

%%
function sSequence = i_getIndentation(nTabs)
sSequence=[];
for i=1:nTabs
    sSequence = strcat(sSequence, '\t');
end
end


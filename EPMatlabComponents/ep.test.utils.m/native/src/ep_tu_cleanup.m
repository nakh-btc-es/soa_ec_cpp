function ep_tu_cleanup()
% Radically close all models and all DDs
%
% function ep_tu_cleanup()
%
%   Should be the first and the last call for every matlab unit_test using 
%   Simulink or TargetLink models.
%


%% main
try
    bdclose all;
catch oEx
    warning('TU:CLEANUP:WARNING', '%', oEx.message);
end

try
    i_allCompiledModelsClose();
catch oEx
    warning('TU:CLEANUP:WARNING', '%s', oEx.message);
end

try
    bdclose all;
    close all force; % closing all plotting figures of TL models
catch oEx
    warning('TU:CLEANUP:WARNING', '%s', oEx.message);
end

% TL related cleanup
if ~isempty(which('dsdd'))
    try
        dsdd('Close', 'Save', 'off');
        dsdd('Unlock');
        dsdd_free();
    catch oEx
        warning('TU:CLEANUP:WARNING', '%s', oEx.message);
    end
end
end



%%
function i_allCompiledModelsClose()
casBlackList = {...
    'tllib', ...
    'eml_lib', ...
    'tl_rtos_lib'};

nMaxCount    = 50;
nSafetyCount = 0;

casModels = find_system('Type', 'block_diagram');
casModels = setdiff(casModels, casBlackList);
while (~isempty(casModels) && (nSafetyCount < nMaxCount))
    nSafetyCount = nSafetyCount + 1;
    
    sCurrentModel = casModels{1};
    casMdlRefs = find_mdlrefs(sCurrentModel, true);
    
    nRefs = length(casMdlRefs);
    for i = 1:nRefs
        try
            feval(casMdlRefs{i}, [], [], [], 'term');
        catch oEx
            warning('TU:CLEANUP:WARNING', '%s', oEx.message);
        end
        try
            close_system(casMdlRefs{i});
        catch oEx
            warning('TU:CLEANUP:WARNING', '%s', oEx.message);
        end
    end
    try
        bdclose all;
    catch oEx
        warning('TU:CLEANUP:WARNING', '%s', oEx.message);
    end
    casModels = find_system('Type', 'block_diagram');
end
end

function sltu_cleanup(varargin)
% radically close all models and all DDs
%


%%
caxArgs = varargin;
stArgs = cell2struct(caxArgs(2:2:end), caxArgs(1:2:end), 2);

%% main
i_printInfoMsg(sprintf('starting cleanup from %s ...', i_getCallerFunc));
try
    bdclose all;
catch oEx
    warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
end

try
    i_allCompiledModelsClose();
catch oEx
    warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
end

try
    Simulink.data.dictionary.closeAll('-discard');
catch oEx
    warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
end

try
    bdclose all;
    close all force; % closing all plotting figures of TL models
catch oEx
    warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
end

try
    evalin('base', 'clear'); % clearing base workspace to avoid side-effects between UTs
catch oEx
    warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
end

if sltu_tl_available()
    try
        dsdd('Close', 'Save', 'off');
        dsdd('Unlock');
        dsdd_free();
    catch oEx
        warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
    end
end

if (isfield(stArgs, 'ClearClasses') && stArgs.ClearClasses)
    i_clearClasses();
end

i_printInfoMsg('... finished cleanup');
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
            warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
        end
        try
            close_system(casMdlRefs{i});
        catch oEx
            warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
        end
    end
    try
        bdclose all;
    catch oEx
        warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
    end
    casModels = find_system('Type', 'block_diagram');
end
end


%%
function i_clearClasses()
try
    i_clearClassesInternal();
catch oEx
    warning('SLTU:CLEANUP:WARNING', '%s', i_getCleanMsg(oEx));
end
end


%%
% note: e.g. important for Enum types defined in SL-DD
function i_clearClassesInternal()
stWarn = warning('off', 'MATLAB:ClassInstanceExists');
xOnCleanupRestore = onCleanup(@() warning(stWarn));
evalin('base', 'sltu_clear_classes;');
end


%%
function sMsg = i_getCleanMsg(oEx)
sMsg = oEx.getReport('extended', 'hyperlinks', 'off');
end


%%
function i_printInfoMsg(sMsg)
fprintf('[INFO:%s:SLTU_CLEANUP] %s\n', datestr(now, 'HH:MM:SS'), sMsg);
end


%%
function sCallerFunc = i_getCallerFunc()
astStack = dbstack();
if (numel(astStack) > 2)
    casStackFuncs = {astStack(3:end).name};
    sCallerFunc = casStackFuncs{1};
    for i = 2:numel(casStackFuncs)
        sFunc = casStackFuncs{i};
        if strcmp('i_call_user_function', sFunc)
            % stop with callstack info when entering MUNIT's own functions
            break;
        end
        sCallerFunc = [sCallerFunc, ':', sFunc]; %#ok<AGROW> 
    end
else
    sCallerFunc = '<unknown>';
end
end

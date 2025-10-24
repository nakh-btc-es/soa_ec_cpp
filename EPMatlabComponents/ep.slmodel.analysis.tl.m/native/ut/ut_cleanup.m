function ut_cleanup(varargin)
% radically close all models and all DDs
%
% function ut_cleanup()
%
%   Should be the first and the last call for every unit_test in M01.
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%     -
%
%   REMARKS
%     -
%
%   (c) 2007 by OSC Embedded Systems AG, Germany

%% internal
%
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 168136 $
%   Last modified: $Date: 2014-03-21 13:24:49 +0100 (Fr, 21 Mrz 2014) $
%   $Author: steffenk $
%


%%
caxArgs = varargin;
stArgs = cell2struct(caxArgs(2:2:end), caxArgs(1:2:end), 2);

%% main
try
    bdclose all;
catch oEx
    warning('UT:CLEANUP:WARNING', oEx.message);
end
try
    i_allCompiledModelsClose();
catch oEx
    warning('UT:CLEANUP:WARNING', oEx.message);
end
try
    bdclose all;
    close all force; % closing all plotting figures of TL models
catch oEx
    warning('UT:CLEANUP:WARNING', oEx.message);
end
try
    dsdd('Close', 'Save', 'off');
    dsdd('Unlock');
    dsdd_free();
catch oEx
    warning('UT:CLEANUP:WARNING', oEx.message);
end
if (isfield(stArgs, 'ClearClasses') && stArgs.ClearClasses)
    i_clearClasses();
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
            warning('UT:CLEANUP:WARNING', oEx.message);
        end
        try
            close_system(casMdlRefs{i});
        catch oEx
            warning('UT:CLEANUP:WARNING', oEx.message);
        end
    end
    try
        bdclose all;
    catch oEx
        warning('UT:CLEANUP:WARNING', oEx.message);
    end
    casModels = find_system('Type', 'block_diagram');
end
end


%%
function i_clearClasses()
try
    i_clearClassesInternal();
catch oEx
    warning('UT:CLEANUP:WARNING', oEx.message);
end
end


%%
% note: e.g. important for Enum types defined in SL-DD
function i_clearClassesInternal()
stWarn = warning('off', 'MATLAB:ClassInstanceExists');
xOnCleanupRestore = onCleanup(@() warning(stWarn));
evalin('base', 'clear classes;');
end


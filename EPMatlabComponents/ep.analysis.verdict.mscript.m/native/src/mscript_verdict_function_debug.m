function mscript_verdict_function_debug(sVerdictFunctionFile,stComparisonData)
%  Executes the verdict function in debug mode using the specified
%  comparison data
%  
% function mscript_verdict_function_debug(sVerdictFunctionFile, stComparisonData)
%
%   INPUTS                      DESCRIPTION
%   - sVerdictFunctionFile      (string) The verdict function file
%   - stComparisonData          (struct) The comparison data
%
%   OUTPUTS
%       -
%
% $$$COPYRIGHT$$$-2017
%

sCWD = pwd;
sVerdictFunctionFile = char(sVerdictFunctionFile);
[sFileFolder,sVerdictFunction]=fileparts(sVerdictFunctionFile);
cd(sFileFolder);
try
    eval(sprintf('dbstop in %s',sVerdictFunction));
    feval(sVerdictFunction,stComparisonData);   
    eval(sprintf('dbclear in %s',sVerdictFunction));
    delete(sVerdictFunctionFile);
     % cleanup
    cd(sCWD);
catch
    % clean-up in case of any error
    cd(sCWD);
    eval(sprintf('dbclear in %s',sVerdictFunction));
    delete(sVerdictFunctionFile);
    assignin('base','VerdictFunction_Debug',lasterror());
    msgbox('There was an exception while trying to debug the Verdict Function.See workspace variable "VerdictFunction_Debug" for complete stack-trace.','Debug error','error');
end
end
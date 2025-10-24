function [sResultState,sResultMessage] = mscript_verdict_function_evaluate(sFile,stParameter)
% Executes the verdict function in the specified parameter
%  
% function mscript_verdict_function_debug(sVerdictFunctionFile, stComparisonData)
%
%   INPUTS                      DESCRIPTION
%   - sVerdictFunctionFile      (string) The verdict function file
%   - stParameter               (struct) The comparison data
%
%   OUTPUTS
%   - sResultState              (string) state of the evaluation PASSED, FAILED, ERROR
%   - sResultMessage            (string) messge of the evaluation
%
% $$$COPYRIGHT$$$-2017
%

sCWD = pwd();
sFile = char(sFile);
    [sFilePath,sFileName]=fileparts(char(sFile));
try
    cd(sFilePath);
    rehash path;
    rehash pathreset;
    [sResultState,sResultMessage]=feval(sFileName,stParameter);
    cd(sCWD);
catch exception
    cd(sCWD);
     xEx = MException('MSCRIPT_VERDICT_FUNCTION:EVALUATE', ...
        'M-script evaluation failed.\n    %s ', exception.message);
    throw(xEx);
    
end
end
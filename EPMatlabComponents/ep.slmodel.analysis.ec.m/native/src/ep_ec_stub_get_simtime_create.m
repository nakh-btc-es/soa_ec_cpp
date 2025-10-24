function ep_ec_stub_get_simtime_create(sStepCounterFunc, sStubFile, dSampleTime, stFuncInfo)
% Creates the stub file for a function returning the simulation time.
%
% function ep_ec_stub_get_simtime_create(sStepCounterFunc, sStubFile, dSampleTime, stFuncInfo)
%
%   INPUT                                DESCRIPTION
%    sStepCounterFunc           (string)    name of the step counter function (can be used as pre-step function in EP)
%    sStubFile                  (string)    full file path for the stub to be created
%    dSampleTime                (double)    the sample time to be used to translate counter values into time units
%                                           (assumed to be seconds)
%    stFuncInfo                 (struct)    additional info for the stubbed function:
%       .funcname                 (string)*    name of the function to be stubbed (returns the sample time in units)
%       .includefile              (string)     optional: name of one include file (e.g. datatypes definition)
%       .returntype               (string)*    datatype of the return time variable
%       .usfactor                 (double)     factor for transfoming into the desired unit of time
%                                                     1         -> time in microsecond (us)
%                                                     10^-3     -> time in millisecond (ms)
%                                                     10^-6     -> time in second (s)
%
%  OUTPUT                                DESCRIPTION
%     -
%

%%
sStepCounterVar = 'btcStepCnt';

sContent = '';

%Include headerfile
if ~isempty(stFuncInfo.includefile)
    sContent =  [sContent, '#include "', stFuncInfo.includefile, '"\n\n'];
end

%static unsigned long btcStepCnt = 0;
sContent =  [sContent, 'static unsigned long ', sStepCounterVar, ' = 0;\n\n'];

% NOTE: should be made *static* when EP SIL harness is supporting static pre-step functions

%void btcStepCounter(void) {
%   ++btcStepCnt;
%}
sContent =  [sContent, 'void ', sStepCounterFunc, '(void){\n'];
sContent =  [sContent, '    ++', sStepCounterVar, ';\n'];
sContent =  [sContent, '}\n'];
sContent =  [sContent,'\n'];

%U32 getSimulationTime(void) {
%	return (<cast-type>)(<time-factor> * (btcStepCnt - 1)); } %
%}
nFactor     = dSampleTime * 10^6 * stFuncInfo.usfactor;
sContent    = [sContent, stFuncInfo.returntype , ' ', stFuncInfo.funcname, '(void){\n'];
sContent    = [sContent,'   /* ', num2str(nFactor), ' = Sampletime ', ...
    num2str(dSampleTime), ' (s) * 10^6 (conversion in us) * ', ...
    num2str(stFuncInfo.usfactor), ' (us factor) */\n '];
sContent = [sContent,'   return  (', stFuncInfo.returntype, ') (', num2str(nFactor), ' * (', sStepCounterVar, ' - 1));\n'];
sContent = [sContent,'}\n\n'];
sContent = sprintf(sContent);

i_createSourcefile(sStubFile, sContent, {});
end


%%
function i_createSourcefile(sFile, sContent, casIncludeFileNames)
[~, sFileName] = fileparts(sFile);
casIncludeFileNames = cellstr(casIncludeFileNames);
casContent = cellstr(sContent);

%Create C file
fid = fopen(sFile, 'w');
oOnCleanupClose = onCleanup(@() fclose(fid));

fprintf(fid, '#ifndef _%s_ET_C_\n',upper(sFileName));
fprintf(fid, '#define _%s_ET_C_\n',upper(sFileName));
fprintf(fid, '\n');
if ~isempty(char(casIncludeFileNames))
    fprintf(fid, '#include "%s"\n',  casIncludeFileNames{:});
end
fprintf(fid, '\n');
fprintf(fid, '%s\n', casContent{:});
fprintf(fid, '\n');
fprintf(fid, '#endif //_%s_ET_C_\n',upper(sFileName));
end

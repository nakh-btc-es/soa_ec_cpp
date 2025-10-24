function ut_ep_ccode_system_time_0
% Basic test to check general export of system time variable information
%
%  ut_ep_ccode_system_time_0
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_ccode_system_time_0');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'system_time');

sTlModel      = 'system_time';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, sTlModelFile);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',         sDdFile, ...
    'sTlModel',        sTlModel, ...
    'xEnv',            xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);

%% check test results

try 
    i_check_c_arch(stOpt.sCResultFile);
catch oEx
    MU_FAIL(i_printException('C Architecture', oEx)); 
end


end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_check_c_arch(sCResultFile)
hCResultFile = mxx_xmltree('load', sCResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hCResultFile));
% check if the pre-step function attribute is set
ahFunctions = mxx_xmltree('get_nodes', hCResultFile, '//Function');
asPreStepFuncNames = [];
for i=1:length(ahFunctions)
   hFunction = ahFunctions(i);
   sPreStepFuncName = mxx_xmltree('get_attribute', hFunction, 'preStepFunc');
   MU_ASSERT_TRUE(~isempty(sPreStepFuncName), 'Attribute "preStepFunc" is not set');
   MU_ASSERT_TRUE(strncmp('system_time_',sPreStepFuncName, 12), 'Attribute "preStepFunc" is not set');
   asPreStepFuncNames = [asPreStepFuncNames, [sPreStepFuncName,',']];
end
% check if the file exists and its content
sParentPath = fileparts(sCResultFile);
sFileName = fullfile(sParentPath, 'btc_system_time.c');
MU_ASSERT_TRUE(exist(sFileName, 'file'), 'File "btc_system_time.c" does not exist at the expected location');
hFile = fopen(sFileName, 'r');
sLine = fgets(hFile);
sFirstLine = sLine;
MU_ASSERT_TRUE(strncmp('#include ', sFirstLine, 9), 'The first line is expected to be an #include');
iIncrement = -1.0;
while ischar(sLine)
    sLine = fgets(hFile);
    if length(sLine)<5
        % skip this line
    elseif strncmp('void ',sLine, 5)
        % check if the method name equals the expected pattern 'void system_time_<increment>(Void) {'
        MU_ASSERT_FALSE_FATAL(isempty(strfind(sLine, 'system_time_')), 'Method not correct');
        iIdx = strfind(sLine,'(') - 1;
        MU_ASSERT_FALSE_FATAL(isempty(iIdx), 'Method not correct');
        iIncrement = str2double(sLine(length('void system_time_') + 1 : iIdx));
        MU_ASSERT_TRUE(iIncrement>0.0, ['Check the increment in function "', sLine(6:iIdx), '"']);
        sPreStepFuncName = sLine(6 : iIdx);
        % check if the pre-step funciton is one of the expected onces
        MU_ASSERT_FALSE(isempty(strfind(asPreStepFuncNames, [sPreStepFuncName,','])), ...
            ['Pre-step function "', sPreStepFuncName, '" not expected']);
        % remove the matched one from the list
        asPreStepFuncNames = strrep(asPreStepFuncNames, [sPreStepFuncName,','], '');
    elseif ~isempty(strfind(sLine, 'SystemTime += '))
        % check if the value corresponds to one of the used functions
        iIdx0 = strfind(sLine, '+=') + 2;
        iIdx1 = strfind(sLine, ';') - 1;
        MU_ASSERT_TRUE_FATAL(isnumeric(iIdx0) && isnumeric(iIdx1), ['Check the increment in line "', sLine, '"']);
        iInc = str2double(sLine(iIdx0:iIdx1));
        % check if the increment equals the increment in the method name
        MU_ASSERT_TRUE(isnumeric(iInc) && iInc==iIncrement, ['Check the increment in line "', sLine, '"']);
    else
        MU_ASSERT_TRUE(false, 'Generated file has faulty content');
    end
end
% check if all expected once are visited
MU_ASSERT_TRUE(isempty(asPreStepFuncNames), 'Not all pre-step functions are generated');
fclose(hFile);
% check if exactly one system_time.c file is in the files list of the
% CodeModel.xml
ahFiles = mxx_xmltree('get_nodes', hCResultFile, '//File[@name="btc_system_time.c"]');
MU_ASSERT_FALSE(length(ahFiles) < 1, 'File "btc_system_time.c" not added to the CodeModel.xml'); 
MU_ASSERT_FALSE(length(ahFiles) > 1, 'Several files "btc_system_time.c" are added to the CodeModel.xml'); 

end




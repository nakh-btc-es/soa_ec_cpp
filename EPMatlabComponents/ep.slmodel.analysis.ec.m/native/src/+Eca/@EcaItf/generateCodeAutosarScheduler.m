function stAutosarWrapCodeInfo = generateCodeAutosarScheduler(oEca, casUserIncludePaths)
% Generate stub code for the scheduler subsystem as caller of all runnables.
% The runnables are called
%
% stArWrapperCodeInfo
%    .sCFile
%    .sHFile
%    .casIncludePaths
%    .sStepFunName
%    .sInitFunName

stAutosarWrapCodeInfo = [];

%Get Function-Call outputs Names <=> Runnable Name
casOutBlk = ep_core_feval('ep_find_system', oEca.sAutosarWrapperSchedSubsystem, 'SearchDepth', 1,  'BlockType', 'Outport');
if isempty(casOutBlk)
    sMsg = sprintf(['## No Outport block has been found in %s. ',...
        'At least one Outport block driving a function-call signal is expected.'],...
        oEca.sAutosarWrapperSchedSubsystem);
    oEca.addMessageEPEnv('EP:SLC:ERROR', 'msg', sMsg);
    oEca.consoleErrorPrint(sMsg);
    return;
else
    %Get tiggrer block name of each runnable
    casRunTrigPortNames = cellstr(get_param(casOutBlk, 'Name'));
end

sInitFun = '';
astRunnablesInfo = [];
dModelSampleTime = oEca.dModelSampleTime;
for iRun = 1:numel(oEca.aoRunnables)
    if oEca.aoRunnables(iRun).bIsInitFunction
        sInitFun = oEca.aoRunnables(iRun).sSymbol;
    else
        idxFound = ismember(casRunTrigPortNames, oEca.aoRunnables(iRun).sRootInputTrigBlkName);
        if any(idxFound)
            stTmp.sFunName = oEca.aoRunnables(iRun).sSymbol;
            stTmp.dSampleTime = str2double(get_param([oEca.sAutosarModelName, '/',oEca.aoRunnables(iRun).sRootInputTrigBlkName], 'SampleTime'));
            stTmp.nPortNumber = str2double(get_param(casOutBlk(idxFound),'Port'));
            astRunnablesInfo = [astRunnablesInfo, stTmp];
        end
    end
end

% Generate a c-function which calls the Runnables functions (Use Symbol as function name)
% create stub directory
sStubDir = oEca.createStubDir();
% create stub function
casIncludeFilenames = {'Rte_Type.h', [oEca.sAutosarModelName '.h']};
stAutosarWrapCodeInfo = i_createDummyWrapperSources(oEca, sStubDir, casIncludeFilenames, astRunnablesInfo, sInitFun, ...
    dModelSampleTime, casUserIncludePaths);
end

function stWrapperInfo = i_createDummyWrapperSources(oEca, sStubDir, casIncludeFileNames, astRunnablesInfo, sInitFun, ...
    dModelSplTime, casUserIncludePaths)
% astRunnablesInfo
%   .sFuncName
%   .dSampleTime
%   .nPortNumber
%
% stWrapperInfo
%   .sHFile
%   .sCFile
%   .sStepFunName
%   .sInitFunName

stWrapperInfo = [];
sWrapperFunNameStep = 'swc_wrapper_scheduler_step';
sWrapperFunNameInit = 'swc_wrapper_scheduler_init';
sHFile = oEca.getStubHeaderFile('scheduler');
sCFile = oEca.getStubSourceFile('scheduler');
oStubGen = Eca.MetaStubGenerator;
%Build header file content
sHContent = '';
sHContent = [sHContent, 'extern void ', sWrapperFunNameInit, '(void);\n'];
sHContent = [sHContent, 'extern void ', sWrapperFunNameStep, '(void);\n'];
sHContent = sprintf(sHContent);
%Build c-file file content
sCContent = '';
sCContent = [sCContent, 'unsigned long stub_swc_cnt = 0;\n\n'];
sCContent = [sCContent, 'void ', sWrapperFunNameInit, '(void){\n'];
sCContent = [sCContent, '    ', sInitFun, '();\n'];
sCContent = [sCContent, '}\n'];
sCContent = [sCContent, '\n'];
sCContent = [sCContent, 'void ', sWrapperFunNameStep, '(void){\n'];

%Re-sort accoding to increasing port number to specify the order of function calls.
if ~isempty(astRunnablesInfo)
    [~, idxSorted] = sort([astRunnablesInfo(:).nPortNumber]);
    astRunnablesInfo = astRunnablesInfo(idxSorted);
    %create content
    for iFun = 1:numel(astRunnablesInfo)
        dRunST = astRunnablesInfo(iFun).dSampleTime;
        sFunName = astRunnablesInfo(iFun).sFunName;
        if isequal(dRunST, dModelSplTime)
            sCContent = [sCContent, '\n    ', sFunName, '();\n'];
        elseif isnumeric(dRunST) && ~isequal(dRunST,-1) && dRunST/dModelSplTime > 1
            if mod(dRunST, dModelSplTime) == 0
                nRate = dRunST/dModelSplTime;
                sCContent = [sCContent, '\n    if (stub_swc_cnt %% ', num2str(nRate), ' == 0) {\n'];
                sCContent = [sCContent, '        ', sFunName, '();\n'];
                sCContent = [sCContent, '    }\n'];
            else
                sCContent = [sCContent, '\n    // Sample time value of the function "', sFunName, '" is not multiple of the model sample time.'];
                sCContent = [sCContent, '    // The calling rate cannot be determined therefore function is called at each step\n'];
                sCContent = [sCContent, '    ', sFunName, '();\n'];
            end
        else
            %Sample time cannot be processed
            sCContent = [sCContent, '\n    // Sample time value of function "', sFunName, '" cannot be processed because it has not been explicitly set.'];
            sCContent = [sCContent, '    // Therefore the function is called at each step\n'];
            sCContent = [sCContent, '    ', sFunName, '();\n'];
        end
    end
end
sCContent = [sCContent, '\n    stub_swc_cnt++;\n'];
sCContent = [sCContent, '}\n'];
sCContent = sprintf(sCContent);
stWrapperInfo.sHFile = oStubGen.createHeaderfile(sHFile, sHContent, casIncludeFileNames);
stWrapperInfo.sCFile = oStubGen.createSourcefile(sCFile, sCContent, Eca.EcaItf.FileName(sHFile));
stWrapperInfo.sStepFunName = sWrapperFunNameStep;
stWrapperInfo.sInitFunName = sWrapperFunNameInit;
stWrapperInfo.casIncludePaths = casUserIncludePaths;
end
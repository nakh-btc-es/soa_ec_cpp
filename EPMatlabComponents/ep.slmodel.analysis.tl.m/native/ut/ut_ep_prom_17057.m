function ut_ep_prom_17057
% Check fix for Bug PROM-17057.
%
%  REMARKS
%       Bug:  TL-versions below TL4.0 are providing a wrong info about the width of the actual argument.
%             Although only _one_ element of an array is used as an input for a function call, the _whole_ array
%             width is referenced in DD.
%       Note: The newer TL-versions are correctly using ACTUAL_ARGIN_EXPRESSION instead of ACTUAL_ARGIN_REFERENCE.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'prom_17057');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'param_interface');

sTlModel     = 'param_interface';
sTlModelFile = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile      = fullfile(sTestRoot, [sTlModel, '.dd']);


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% check test results
try 
    i_check_code_model(stOpt.sCResultFile);
catch oEx
    MU_FAIL(i_printException('C-Code', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_check_code_model(sCodeModel)
if ~exist(sCodeModel, 'file')
    MU_FAIL('CodeModel XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sCodeModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

% expected arguments
xExpArgs = containers.Map();
xExpArgs('top_A') = ...
    {'a1:array:4', 'b1:array:7'};
xExpArgs('sub_B2') = ...
    {'Sa3_Const1:var:Sa3_Const1_a', 'Sa3_Sat1_lower:var:Sa3_Sat1_lower_a', 'Sa3_Sat1_upper:var:Sa3_Sat1_upper_a'};
xExpArgs('sub_B4') = ...
    {'Sa5_Const1:var:Sa5_Const1_a', 'Sa5_Sat1_lower:var:Sa5_Sat1_lower_a', 'Sa5_Sat1_upper:var:Sa5_Sat1_upper_a'};
xExpArgs('sub_C1') = ...
    {'c2:var:c2_a', 'a2:array:2', 'b2:array:2'};

casSubs = xExpArgs.keys();
for i = 1:length(casSubs)
    sSub = casSubs{i};
    
    sXPath = sprintf('/CodeModel/Functions/Function[contains(@name, "%s")]', sSub);
    hFunc = mxx_xmltree('get_nodes', hDoc, sXPath);
    if ~isempty(hFunc)
        casFound = i_readArguments(hFunc);
        casExpected = xExpArgs(sSub);
        
        casMissing = setdiff(casExpected, casFound);
        casUnexpected = setdiff(casFound, casExpected);
        for k = 1:length(casMissing)
            MU_FAIL(sprintf('Expected argument "%s" not found for subsystem "%s".', casMissing{k}, sSub));
        end
        for k = 1:length(casUnexpected)
            MU_FAIL(sprintf('Unexpected argument "%s" found for subsystem "%s".', casUnexpected{k}, sSub));
        end
    else
        MU_FAIL(sprintf('Function for subsystem "%s" not found.', sSub));
    end
end
end


%%
function casArgs = i_readArguments(hFunc)
ahArgs = mxx_xmltree('get_nodes', hFunc, './Args/Arg');
casArgs = arrayfun(@i_getArgInfo, ahArgs, 'UniformOutput', false);
end


%%
function sArgInfo = i_getArgInfo(hArg)
sArgInfo = mxx_xmltree('get_attribute', hArg, 'name');

stVar = mxx_xmltree('get_attributes', hArg, './Variable', 'name');
if ~isempty(stVar)
    sArgInfo = [sArgInfo, ':var:', stVar.name];
end

stArrayRef = mxx_xmltree('get_attributes', hArg, './ArrayRef', 'size');
if ~isempty(stArrayRef)
    sArgInfo = [sArgInfo, ':array:', stArrayRef.size];
end
end


function ut_ep_model_analysis_10
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_10
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
sTestRoot = fullfile(sPwd, 'model_ana_10');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'MatrixDisp');

sTlModel      = 'MatrixDisp';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open TL model
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
    i_check_tl_arch(stOpt.sTlResultFile);
    ut_tl_arch_consistency_check(stOpt.sTlResultFile);
catch oEx
    MU_FAIL(i_printException('TL Architecture', oEx)); 
end

try 
    i_check_c_arch(stOpt.sCResultFile);
catch oEx
    MU_FAIL(i_printException('C Architecture', oEx)); 
end

try 
    i_check_mapping(stOpt.sMappingResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_check_tl_arch(sTlResultFile)
hTlResultFile = mxx_xmltree('load', sTlResultFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hTlResultFile));

% Retrieve display variable.
hDisplay = mxx_xmltree('get_nodes', hTlResultFile, ['//subsystem[@subsysID="ss1"]/', ...
    'display[@path="Subsystem/Subsystem/Subsystem/Chart"]']);

% Check MilType and SilType
sList = {'miltype', 'siltype'};
for nl = 1:length(sList)
    hFirstLevelofArray = mxx_xmltree('get_nodes', hDisplay, ['./',sList{nl},'/nonUniformArray']);
    
    MU_ASSERT_EQUAL('10', mxx_xmltree('get_attribute', hFirstLevelofArray, 'size'), ...
        ['Wrong size1 information of matrix (',sList{nl},')']);
    ahSignalsLevelOne = mxx_xmltree('get_nodes', hFirstLevelofArray, './signal');
    ahSecondLevelOfArray = mxx_xmltree('get_nodes', hFirstLevelofArray, './signal/nonUniformArray');
    bIndex1IsCorrect = true;
    bIndex2IsCorrect = true;
    bSizeIsCorrect = length(ahSecondLevelOfArray) == 10;
    for nk = 1:length(ahSecondLevelOfArray)
        sIndex = mxx_xmltree('get_attribute', ahSignalsLevelOne(nk), 'index');
        sSize = mxx_xmltree('get_attribute', ahSecondLevelOfArray(nk), 'size');
        if isempty(sIndex) || str2double(sIndex) ~= nk
            bIndex1IsCorrect = false;
        end
        if isempty(sSize) || ~strcmp(sSize, '2')
            bSizeIsCorrect = false;
        end
        ahSignals = mxx_xmltree('get_nodes', ahSecondLevelOfArray(nk), './signal');
        bIndex2IsCorrect = length(ahSignals) == 2;
        for nm = 1:length(ahSignals)
            sIndex2 = mxx_xmltree('get_attribute', ahSignals(nm), 'index');
            if isempty(sIndex2) || str2double(sIndex2) ~= nm
                bIndex2IsCorrect = false;
            end
        end
        
    end
    MU_ASSERT_TRUE(bIndex1IsCorrect, ['Wrong index1 information of matrix (',sList{nl},')']);
    MU_ASSERT_TRUE(bIndex2IsCorrect, ['Wrong index2 information of matrix (',sList{nl},')']);
    MU_ASSERT_TRUE(bSizeIsCorrect, ['Wrong size2 information fo matrix (',sList{nl},')']);
end

MU_ASSERT_EQUAL('local', mxx_xmltree('get_attribute',hDisplay,'name'), 'Wrong name for Display has been set.');


% Check parameter
hDisplayNode = mxx_xmltree('get_nodes', hTlResultFile, ...
    '//display[@path="Subsystem/Subsystem/Subsystem/Chart" and @name="local"]');
MU_ASSERT_TRUE(~isempty(hDisplayNode), 'Display "local" not found');

% Check if stateflow variable has been set.
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hDisplayNode , 'stateflowVariable'), 'local', ...
    'Display "local" has wrong stateflow variable.');

% Check MIL-/SIL/Type Nodes
hDisplayMILTypeNode = mxx_xmltree('get_nodes', hDisplayNode,'./miltype');
MU_ASSERT_TRUE(~isempty(hDisplayMILTypeNode), 'MIL Type node missing');

hDisplaySILTypeNode = mxx_xmltree('get_nodes', hDisplayNode,'./siltype');
MU_ASSERT_TRUE(~isempty(hDisplaySILTypeNode), 'SIL Type node missing');

% Check MIL/SIL data types
hDisplayMILTypeArray = mxx_xmltree('get_nodes', hDisplayMILTypeNode,'./nonUniformArray');
MU_ASSERT_TRUE(~isempty(hDisplayMILTypeArray), 'MIL Type data type node missing');
MU_ASSERT_EQUAL('10',mxx_xmltree('get_attribute', hDisplayMILTypeArray, 'size'), 'MIL Type data type has wrong size attribute');

hDisplaySILTypeArray = mxx_xmltree('get_nodes', hDisplaySILTypeNode,'./nonUniformArray');
MU_ASSERT_TRUE(~isempty(hDisplaySILTypeArray), 'SIL Type data type node missing');
MU_ASSERT_EQUAL('10',mxx_xmltree('get_attribute', hDisplaySILTypeArray, 'size'), 'SIL Type data type has wrong size attribute');

% Check MIL/SIL element types
for i=1:10
    hDisplayMILTypeArrayElement = mxx_xmltree('get_nodes', hDisplayMILTypeArray,['./signal[@index="', num2str(i), '"]']);
    MU_ASSERT_TRUE(~isempty(hDisplayMILTypeArrayElement), ['MIL Element with index "', num2str(i), '" is missing']);
end

for i=1:10
    hDisplaySILTypeArrayElement = mxx_xmltree('get_nodes', hDisplaySILTypeArray,['./signal[@index="', num2str(i), '"]']);
    MU_ASSERT_TRUE(~isempty(hDisplaySILTypeArrayElement), ['SIL Element with index "', num2str(i), '" is missing']);
end
end



%%
function i_check_c_arch(sCResultFile)
hCResultFile = mxx_xmltree('load', sCResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hCResultFile));

% TODO
end


%%
function i_check_mapping(sMappingResultFile)
hMappingResultFile = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hMappingResultFile));

% TODO
end


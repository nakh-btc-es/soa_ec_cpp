function ut_ep_matrix_support_12
% Test the matrix support feature
%
%  ut_ep_matrix_support_12
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

%% Test only active for TL versions greater equal 4.0
if ep_core_version_compare('TL4.0') < 0
    MU_MESSAGE('TargetLink Matrix Support since TL4.0. Test omitted.');
    return;
end

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_matrix_support_12');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'matrix_sig_models', 'matrix_sig12', 'tl40');

sTlModel      = 'matrix_model_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.slx']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, sTlModelFile);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);

%% check test results
hTlRoot = mxx_xmltree('load', stOpt.sTlResultFile);
xCleanUpTL = onCleanup(@() mxx_xmltree('clear', hTlRoot));

i_check_tl(hTlRoot, 'sub_B1/Out1', 6, 1);
i_check_tl(hTlRoot, 'sub_B2/In1',  6, 1);
i_check_tl(hTlRoot, 'sub_B2/Out1', 6, 1);
i_check_tl(hTlRoot, 'sub_B3/In1',  1, 6);
i_check_tl(hTlRoot, 'sub_B3/Out1', 6, 1);
i_check_tl(hTlRoot, 'sub_B4/In1',  2, 3);
i_check_tl(hTlRoot, 'sub_B4/Out1', 6, 1);
i_check_tl(hTlRoot, 'sub_B5/In1',  3, 2);
i_check_tl(hTlRoot, 'sub_B5/Out1', 6, 1);
i_check_tl(hTlRoot, 'sub_M1/In1', 12, 1);
i_check_tl(hTlRoot, 'sub_M1/Out1', 5, 1);
i_check_tl(hTlRoot, 'sub_M2/In1',  3, 2);
i_check_tl(hTlRoot, 'sub_M2/Out1', 3, 4);
i_check_tl(hTlRoot, 'sub_M2/Out2', 2, 2);
i_check_tl(hTlRoot, 'sub_M3/In1',  3, 4);
i_check_tl(hTlRoot, 'sub_M3/Out1', 3, 4);
i_check_tl(hTlRoot, 'sub_M4/In1',  2, 2);
i_check_tl(hTlRoot, 'sub_M4/Out1', 2, 2);
end

%***********************************************************************************************************************
% Wrapper to replace the previous call
%***********************************************************************************************************************
function i_check_tl(hTlRoot, sPath, nIdx0, nIdx1)
if strcmp('In', sPath(end-2:end-1))
    i_check_interface_object(hTlRoot, 'inport', sPath, [], nIdx0, nIdx1, 'double', 'fixedPoint');
else
    i_check_interface_object(hTlRoot, 'outport', sPath, [], nIdx0, nIdx1, 'double', 'fixedPoint');
end
end
%***********************************************************************************************************************
% Check Interface Objects
%***********************************************************************************************************************
function i_check_interface_object(hTlRoot, sKind, sPath, sMember, nIdx0, nIdx1, sDataTypeMIL, sDataTypeSIL)
% TargetLink model
ahPorts = mxx_xmltree('get_nodes', hTlRoot, ...
    ['//', sKind, '[@path="top_A/Subsystem/top_A/', sPath, '"]']);
MU_ASSERT_TRUE(~isempty(ahPorts), ['"', sPath, '" is missing']);

for iPortIdx = 1:length(ahPorts)
    hPort = ahPorts(iPortIdx);
    if isempty(sMember)
        sHalfPath = './*/nonUniformArray';
    else
        sHalfPath = ['./*/bus/signal[@signalName="', sMember,'"]/nonUniformArray'];
    end
    ahArrayType1 = mxx_xmltree('get_nodes', hPort, sHalfPath);
    MU_ASSERT_TRUE(~isempty(ahArrayType1), ['Data type for "',sPath,'" is missing']);
    for idx=1:length(ahArrayType1)
        sSize = mxx_xmltree('get_attribute', ahArrayType1(idx), 'size');
        MU_ASSERT_EQUAL(num2str(nIdx0), sSize, ['Data type for "',sPath,'" has wrong dimensions']);
    end
    sFullPath = [sHalfPath,'/signal/nonUniformArray'];
    ahArrayType2 = mxx_xmltree('get_nodes', hPort, sFullPath);
    MU_ASSERT_TRUE(~isempty(ahArrayType2), ['Data type for "',sPath,'" is missing']);
    for idx=1:length(ahArrayType2)
        sSize = mxx_xmltree('get_attribute', ahArrayType2(idx), 'size');
        MU_ASSERT_EQUAL(num2str(nIdx1), sSize, ['Data type for "',sPath,'" has wrong dimensions']);
    end
    
    ahArrayElementMilType = mxx_xmltree('get_nodes', hPort, [sFullPath, '/signal/', sDataTypeMIL]);
    MU_ASSERT_TRUE(length(ahArrayElementMilType) == nIdx0 * nIdx1, ...
        ['Number of array element data types for "', sPath,'" is wrong']);
    
    ahArrayElementSilType = mxx_xmltree('get_nodes', hPort, [sFullPath, '/signal/', sDataTypeSIL]);
    MU_ASSERT_TRUE(length(ahArrayElementSilType) == nIdx0 * nIdx1, ...
        ['Array element data type for "', sPath,'" is missing']);
    
    for idx=1:length(ahArrayElementSilType)
        MU_ASSERT_EQUAL('Int16', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'baseType'), 'BaseType not correct');
        MU_ASSERT_EQUAL('1.0000000000000000e+00', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'lsb'), 'LSB not correct');
        MU_ASSERT_EQUAL('0.0000000000000000e+00', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'offset'), 'Offset not correct');
        MU_ASSERT_EQUAL('-3.2768000000000000e+04', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'min'), 'Min not correct');
        MU_ASSERT_EQUAL('3.2767000000000000e+04', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'max'), 'Max not correct');
    end
    % TL signals
    for i=1:nIdx0
        for j=1:nIdx1
            i_check_matrix_tl(hPort, sMember, num2str(i), num2str(j), sDataTypeMIL, sDataTypeSIL);
        end
    end
end
end
%***********************************************************************************************************************
% Check signals
%***********************************************************************************************************************
function i_check_matrix_tl(hPort, sMember, sX, sY, sDataTypeMIL, sDataTypeSIL)
% MIL
if isempty(sMember)
    sHalfPath = ['./miltype/nonUniformArray/signal[@index="', sX,'"]'];
else
    sHalfPath = ['./miltype/bus/signal[@signalName="', sMember,'"]/nonUniformArray/signal[@index="', sX,'"]'];
end
ahSignal = mxx_xmltree('get_nodes', hPort, sHalfPath);
MU_ASSERT_TRUE(~isempty(ahSignal), ['1st index of (', sX,',', sY,') Signal node is missing']);

sFullPath = [sHalfPath, '/nonUniformArray/signal[@index="', sY,'"]'];
ahSignal = mxx_xmltree('get_nodes', hPort, sFullPath);
MU_ASSERT_TRUE(~isempty(ahSignal), ['2nd index of (', sX,',', sY,') Signal node is missing']);

ahSignalDataType = mxx_xmltree('get_nodes', hPort, [sFullPath,'/', sDataTypeMIL]);
MU_ASSERT_TRUE(~isempty(ahSignalDataType), 'Signal data type node is missing');

% SIL
if isempty(sMember)
    sHalfPath = ['./siltype/nonUniformArray/signal[@index="', sX,'"]'];
else
    sHalfPath = ['./siltype/bus/signal[@signalName="', sMember,'"]/nonUniformArray/signal[@index="', sX,'"]'];
end
ahSignal = mxx_xmltree('get_nodes', hPort, sHalfPath);
MU_ASSERT_TRUE(~isempty(ahSignal), ['1st index of (', sX,',', sY,') Signal node is missing']);

sFullPath = [sHalfPath, '/nonUniformArray/signal[@index="', sY,'"]'];
ahSignal = mxx_xmltree('get_nodes', hPort, sFullPath);
MU_ASSERT_TRUE(~isempty(ahSignal), ['2nd index of (', sX,',', sY,') Signal node is missing']);

ahSignalDataType = mxx_xmltree('get_nodes', hPort, [sFullPath,'/', sDataTypeSIL]);
MU_ASSERT_TRUE(~isempty(ahSignalDataType), 'Signal data type node is missing');
end

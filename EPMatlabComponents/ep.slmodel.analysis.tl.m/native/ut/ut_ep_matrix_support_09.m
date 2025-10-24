function ut_ep_matrix_support_09
% Test the matrix support feature
%
%  ut_ep_matrix_support_09
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

%% Test only active for TL versions greater equal 4.0
if ep_core_version_compare('TL4.0') < 0
    MU_MESSAGE('TargetLink Matrix Support since TL4.0. Test omitted.');
    return;
end

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_matrix_support_09');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'matrix_sig_models', 'matrix_sig9', 'tl40');

sTlModel      = 'matrix_model_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.slx']);
sTlInitScript = [];
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

sSlModel      = 'matrix_model_sl';
sSlModelFile  = fullfile(sTestRoot, [sSlModel, '.slx']);
sSlInitScript = [];


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, {sSlModelFile, sSlInitScript, false}, {sTlModelFile, sTlInitScript});

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sSlModel',      sSlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'sSlInitScript', sSlInitScript, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);

%% check test results
hTlRoot = mxx_xmltree('load', stOpt.sTlResultFile);
hSlRoot = mxx_xmltree('load', stOpt.sSlResultFile);

xOnCleanupClosehTlRoot = onCleanup(@() mxx_xmltree('clear', hTlRoot));
xOnCleanupClosehSlRoot = onCleanup(@() mxx_xmltree('clear', hSlRoot));

%% test
% Check TargetLink model
i_check_interface_object(hTlRoot, 'display', 'sub_B1/Chart1', [], 1, 3, 'double', 'Float64', 0);
i_check_interface_object(hTlRoot, 'display', 'sub_B2/sub_C1/Chart2', [], 2, 1, 'double', 'Float64', 0);
i_check_interface_object(hTlRoot, 'display', 'sub_B2/sub_C1/Chart3', [], 2, 3, 'double', 'Float64', 0);

i_check_interface_object(hTlRoot, 'inport', 'sub_B2/sub_C1/In1', [], 1, 3, 'double', 'fixedPoint', 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_B2/sub_C1/Out1', [], 2, 1, 'double', 'fixedPoint', 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_B2/sub_C1/Out2', [], 2, 3, 'double', 'fixedPoint', 1);

% Check Simulink model
i_check_sl_interface_object(hSlRoot, 'inport', 'sub_B2/sub_C1/In1', [], 1, 3, 'double', 1);
i_check_sl_interface_object(hSlRoot, 'outport', 'sub_B2/sub_C1/Out1', [], 2, 1, 'double', 1);
i_check_sl_interface_object(hSlRoot, 'outport', 'sub_B2/sub_C1/Out2', [], 2, 3, 'double', 1);

i_check_sl_interface_object(hSlRoot, 'display', 'sub_B1/Chart1', [], 1, 3, 'double', 0);
i_check_sl_interface_object(hSlRoot, 'display', 'sub_B2/sub_C1/Chart2', [], 2, 1, 'double', 0);
i_check_sl_interface_object(hSlRoot, 'display', 'sub_B2/sub_C1/Chart3', [], 2, 3, 'double', 0);

% Check mapping
i_check_mapping_result_file(stOpt);

end
%***********************************************************************************************************************
% Check Interface Objects
%***********************************************************************************************************************
function i_check_interface_object(hTlRoot, sKind, sPath, sMember, nIdx0, nIdx1, sDataTypeMIL, sDataTypeSIL, n1stIdx)
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
    
    % TL signals (For charts the first index is '0' and not '1')
    for i = n1stIdx : nIdx0 + n1stIdx - 1
        for j = n1stIdx : nIdx1 + n1stIdx - 1
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

%% helper
function i_sub_B2_sub_C1_In1(hSlRoot)
sPath = 'sub_B2/sub_C1/In1';
% ------------------------------
% Simulink model
% ------------------------------

ahInports = mxx_xmltree('get_nodes', hSlRoot, ...
    ['//inport[@path="top_A/', sPath,'"]']);
MU_ASSERT_TRUE(~isempty(ahInports), ...
    ['"matrix_model_sl', sPath, '" is missing']);
MU_ASSERT_TRUE(length(ahInports) < 2, 'In1 is not unique');
hInport = ahInports(1);

% Signals
i_check_matrix_sl(hInport, '1', '1');
i_check_matrix_sl(hInport, '1', '2');
i_check_matrix_sl(hInport, '1', '3');

end
%***********************************************************************************************************************
% Check Interface Objects
%***********************************************************************************************************************
function i_check_sl_interface_object(hRoot, sKind, sPath, sMember, nIdx0, nIdx1, sDataTypeMIL, n1stIdx)
% TargetLink model
ahPorts = mxx_xmltree('get_nodes', hRoot, ...
    ['//', sKind, '[@path="top_A/', sPath, '"]']);
MU_ASSERT_TRUE(~isempty(ahPorts), ['"', sPath, '" is missing']);

for iPortIdx = 1:length(ahPorts)
    hPort = ahPorts(iPortIdx);
    if isempty(sMember)
        sHalfPath = './nonUniformArray';
    else
        sHalfPath = ['./bus/signal[@signalName="', sMember,'"]/nonUniformArray'];
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
    
    % TL signals (For charts the first index is '0' and not '1')
    for i = n1stIdx : nIdx0 + n1stIdx - 1
        for j = n1stIdx : nIdx1 + n1stIdx - 1
            i_check_matrix_sl(hPort, sMember, num2str(i), num2str(j), sDataTypeMIL);
        end
    end
end
end
%***********************************************************************************************************************
% Check Simulink signals
%***********************************************************************************************************************
function i_check_matrix_sl(hPort, sMember, sX, sY, sDataTypeMIL)
if isempty(sMember)
    sHalfPath = ['./nonUniformArray/signal[@index="', sX,'"]'];
else
    sHalfPath = ['./bus/signal[@signalName="', sMember,'"]/nonUniformArray/signal[@index="', sX,'"]'];
end
ahSignal = mxx_xmltree('get_nodes', hPort, sHalfPath);
MU_ASSERT_TRUE(~isempty(ahSignal), ['1st index of (', sX,',', sY,') Signal node is missing']);

sFullPath = [sHalfPath, '/nonUniformArray/signal[@index="', sY,'"]'];
ahSignal = mxx_xmltree('get_nodes', hPort, sFullPath);
MU_ASSERT_TRUE(~isempty(ahSignal), ['2nd index of (', sX,',', sY,') Signal node is missing']);

ahSignalDataType = mxx_xmltree('get_nodes', hPort, [sFullPath,'/', sDataTypeMIL]);
MU_ASSERT_TRUE(~isempty(ahSignalDataType), 'Signal data type node is missing');
end
%***********************************************************************************************************************
% Check mapping result
%***********************************************************************************************************************
function i_check_mapping_result_file(stOpt)
hMapRoot = mxx_xmltree('load', stOpt.sMappingResultFile);
xOnCleanupClosehMapRoot = onCleanup(@() mxx_xmltree('clear', hMapRoot));

ahIoMappingIn1 = mxx_xmltree('get_nodes', hMapRoot, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B1"]/../InterfaceObjectMapping[@kind="Output"]');
MU_ASSERT_TRUE(length(ahIoMappingIn1) == 3);
for i = 1:length(ahIoMappingIn1);
    hIoMappingIn1 = ahIoMappingIn1(i);
    [a,b] = ind2sub([1,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id0" and @path="Out1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id2" and @path="Out1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="Sa2_Out1"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id2" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id1" and @path="[',num2str(i-1),']"]'])));
end

ahIoMappingIn1 = mxx_xmltree('get_nodes', hMapRoot, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B1/Chart1"]/../InterfaceObjectMapping[@kind="Output"]');
MU_ASSERT_TRUE(length(ahIoMappingIn1) == 3);
for i = 1:length(ahIoMappingIn1);
    hIoMappingIn1 = ahIoMappingIn1(i);
    [a,b] = ind2sub([1,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id0" and @path="y"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id2" and @path="y"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="Ca1_y"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id2" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id1" and @path="[',num2str(i-1),']"]'])));
end

ahIoMappingIn1 = mxx_xmltree('get_nodes', hMapRoot, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B2"]/../InterfaceObjectMapping[@kind="Input"]');
MU_ASSERT_TRUE(length(ahIoMappingIn1) == 3);
for i = 1:length(ahIoMappingIn1);
    hIoMappingIn1 = ahIoMappingIn1(i);
    [a,b] = ind2sub([1,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id0" and @path="In1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id2" and @path="In1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="Sa3_In1"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id2" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id1" and @path="[',num2str(i-1),']"]'])));
end

ahIoMappingIn1 = mxx_xmltree('get_nodes', hMapRoot, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B2/sub_C1"]/../InterfaceObjectMapping[@kind="Input"]');
MU_ASSERT_TRUE(length(ahIoMappingIn1) == 3);
for i = 1:length(ahIoMappingIn1);
    hIoMappingIn1 = ahIoMappingIn1(i);
    [a,b] = ind2sub([1,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id0" and @path="In1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id2" and @path="In1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="Sa4_In1"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id2" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id1" and @path="[',num2str(i-1),']"]'])));
end

ahIoMappingIn1 = mxx_xmltree('get_nodes', hMapRoot, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B2/sub_C1"]/../InterfaceObjectMapping[@kind="Output"]');
ahIoMappingIn1 = ahIoMappingIn1(1:2);
MU_ASSERT_TRUE(length(ahIoMappingIn1) == 2);
for i = 1:length(ahIoMappingIn1);
    hIoMappingIn1 = ahIoMappingIn1(i);
    [a,b] = ind2sub([2,1],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id0" and @path="Out1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id2" and @path="Out1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="Sa4_Out1"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id2" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id1" and @path="[',num2str(i-1),']"]'])));
end

ahIoMappingIn1 = mxx_xmltree('get_nodes', hMapRoot, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B2/sub_C1"]/../InterfaceObjectMapping[@kind="Output"]');
ahIoMappingIn1 = ahIoMappingIn1(3:end);
MU_ASSERT_TRUE(length(ahIoMappingIn1) == 6);
for i = 1:length(ahIoMappingIn1);
    hIoMappingIn1 = ahIoMappingIn1(i);
    [a,b] = ind2sub([2,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id0" and @path="Out2"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id2" and @path="Out2"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="Sa4_Out2"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id2" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id1" and @path="[',num2str(a-1),'][',num2str(b-1),']"]'])));
end

ahIoMappingIn1 = mxx_xmltree('get_nodes', hMapRoot, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B2/Chart4"]/../InterfaceObjectMapping[@kind="Input"]');
ahIoMappingIn1 = ahIoMappingIn1(1:2);
MU_ASSERT_TRUE(length(ahIoMappingIn1) == 2);
for i = 1:length(ahIoMappingIn1);
    hIoMappingIn1 = ahIoMappingIn1(i);
    [a,b] = ind2sub([2,1],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id0" and @path="u1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id2" and @path="u1"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="Sa4_Out1"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id2" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id1" and @path="[',num2str(i-1),']"]'])));
end

ahIoMappingIn1 = mxx_xmltree('get_nodes', hMapRoot, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B2/Chart4"]/../InterfaceObjectMapping[@kind="Input"]');
ahIoMappingIn1 = ahIoMappingIn1(3:end);
MU_ASSERT_TRUE(length(ahIoMappingIn1) == 6);
for i = 1:length(ahIoMappingIn1);
    hIoMappingIn1 = ahIoMappingIn1(i);
    [a,b] = ind2sub([2,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id0" and @path="u2"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id2" and @path="u2"]')));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="Sa4_Out2"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id2" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ['./Path[@refId="id1" and @path="[',num2str(a-1),'][',num2str(b-1),']"]'])));
end
end
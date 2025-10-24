function ut_ep_matrix_support_18
% Test the matrix support feature
%
%  ut_ep_matrix_support_18
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
sTestRoot = fullfile(sPwd, 'ut_ep_matrix_support_18');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'matrix_sig_models', 'matrix_sig18', 'tl40');

sTlModel      = 'matrix_model_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.slx']);
sTlInitScript = [];
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

%% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, {sTlModelFile, sTlInitScript});
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);

%% test
i_check_tl_result_file(stOpt);
i_check_mapping_result_file(stOpt);
end

%***********************************************************************************************************************
% Check TargetLink model
%***********************************************************************************************************************
function i_check_tl_result_file(stOpt)

hTlRoot = mxx_xmltree('load', stOpt.sTlResultFile);
xOnCleanupClosehTlRoot = onCleanup(@() mxx_xmltree('clear', hTlRoot));

i_check_interface_object(hTlRoot, 'inport', 'sub_B3/In1', [], 2, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B3/Out1', [], 2, 3, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B4/In1', [], 2, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B4/Out1', [], 2, 3, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B1/Bus Inport', '<signal1>.a', 2, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B1/Bus Inport', '<signal1>.b', 2, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B1/Bus Outport', '<signal1>.a', 2, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B1/Bus Outport', '<signal1>.b', 2, 3, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'display', 'sub_B3/Gain', [], 2, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'display', 'sub_B4/Gain', [], 2, 3, 'double', 'fixedPoint');

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
%***********************************************************************************************************************
% Check mapping result
%***********************************************************************************************************************
function i_check_mapping_result_file(stOpt)
hMapRoot = mxx_xmltree('load', stOpt.sMappingResultFile);
xOnCleanupClosehMapRoot = onCleanup(@() mxx_xmltree('clear', hMapRoot));

% test 'Bus Inport' on
% 'top_A/Subsystem/top_A/sub_B1'
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B1"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="Bus Inport"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 12);
ahIoMapping = ahIoMapping(1:6);
for i = 1:length(ahIoMapping);
    hIoMappingTmp = ahIoMapping(i);
    [a,b] = ind2sub([2,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, ['./Path[@refId="id0" and', ...
        ' @path="Bus Inport"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, './Path[@refId="id1" and @path="Sa2_a"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingTmp, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path=".<signal1>.a(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id1" and @path="[',num2str(a-1),'][',num2str(b-1),']"]'])));
end

ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B1"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="Bus Inport"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 12);
ahIoMapping = ahIoMapping(7:end);
for i = 1:length(ahIoMapping);
    hIoMappingTmp = ahIoMapping(i);
    [a,b] = ind2sub([2,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, ['./Path[@refId="id0" and', ...
        ' @path="Bus Inport"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, './Path[@refId="id1" and @path="Sa2_b"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingTmp, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path=".<signal1>.b(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id1" and @path="[',num2str(a-1),'][',num2str(b-1),']"]'])));
end

% test 'Bus Outport' on
% 'top_A/Subsystem/top_A/sub_B1'
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B1"]/../InterfaceObjectMapping[@kind="Output"]', ...
    '/Path[@path="Bus Outport"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 12);
ahIoMapping = ahIoMapping(1:6);
for i = 1:length(ahIoMapping);
    hIoMappingTmp = ahIoMapping(i);
    [a,b] = ind2sub([2,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, ['./Path[@refId="id0" and', ...
        ' @path="Bus Outport"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, './Path[@refId="id1" and @path="Sa2_a_a"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingTmp, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path=".<signal1>.a(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id1" and @path="[',num2str(a-1),'][',num2str(b-1),']"]'])));
end

ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B1"]/../InterfaceObjectMapping[@kind="Output"]', ...
    '/Path[@path="Bus Outport"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 12);
ahIoMapping = ahIoMapping(7:end);
for i = 1:length(ahIoMapping);
    hIoMappingTmp = ahIoMapping(i);
    [a,b] = ind2sub([2,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, ['./Path[@refId="id0" and', ...
        ' @path="Bus Outport"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, './Path[@refId="id1" and @path="Sa2_b_a"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingTmp, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path=".<signal1>.b(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id1" and @path="[',num2str(a-1),'][',num2str(b-1),']"]'])));
end

% test 'Bus Outport' on 'top_A/Subsystem/top_A'
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A"]/../InterfaceObjectMapping[@kind="Local"]', ...
    '/Path[@path="top_A/Subsystem/top_A/sub_B1/Bus Outport(1)"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 2);
for i = 1:length(ahIoMapping);
    hIoMappingTmp = ahIoMapping(i);
    if (i==1)
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, ['./Path[@refId="id0" and', ...
            ' @path="top_A/Subsystem/top_A/sub_B1/Bus Outport(1)"]'])));
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, './Path[@refId="id1" and @path="Sa2_a_a"]')));
        hSignalMapping = mxx_xmltree('get_nodes', hIoMappingTmp, './SignalMapping');
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
            ['./Path[@refId="id0" and @path=".<signal1>.a"]'])));
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
            ['./Path[@refId="id1" and @path=""]'])));
    else
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, ['./Path[@refId="id0" and', ...
            ' @path="top_A/Subsystem/top_A/sub_B1/Bus Outport(1)"]'])));
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, './Path[@refId="id1" and @path="Sa2_b_a"]')));
        hSignalMapping = mxx_xmltree('get_nodes', hIoMappingTmp, './SignalMapping');
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping,'./Path[@refId="id0" and @path=".<signal1>.b"]')));
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping,'./Path[@refId="id1" and @path=""]')));
    end
end
end
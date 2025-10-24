function ut_ep_matrix_support_15
% Test the matrix support feature
%
%  ut_ep_matrix_support_15
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
sTestRoot = fullfile(sPwd, 'ut_ep_matrix_support_15');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'matrix_sig_models', 'matrix_sig15', 'tl40');

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


%%
%***********************************************************************************************************************
% Check TargetLink model
%***********************************************************************************************************************
function i_check_tl_result_file(stOpt)

hTlRoot = mxx_xmltree('load', stOpt.sTlResultFile);
xOnCleanupClosehTlRoot = onCleanup(@() mxx_xmltree('clear', hTlRoot));

i_check_interface_object(hTlRoot, 'inport', 'sub_B1/In1', [], 2, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B1/Out1', [], 2, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'display', 'sub_B1/Gain', [], 2, 3, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B2/In1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B2/Out1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'display', 'sub_B2/Gain', [], 3, 2, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B3/In1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B3/Out1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'display', 'sub_B3/Gain', [], 6, 1, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B4/In1', [], 1, 6, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B4/Out1', [], 1, 6, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'display', 'sub_B4/Gain', [], 1, 6, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B5/In1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B5/Out1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'display', 'sub_B5/Gain', [], 3, 2, 'double', 'fixedPoint');
end


%%
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


%%
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


%%
%***********************************************************************************************************************
% Check mapping result
%***********************************************************************************************************************
function i_check_mapping_result_file(stOpt)
hMapRoot = mxx_xmltree('load', stOpt.sMappingResultFile);
xOnCleanupClosehMapRoot = onCleanup(@() mxx_xmltree('clear', hMapRoot));

% test 'In1' on  'top_A/Subsystem/top_A/sub_B3'
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B3"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="In1"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 6);
aiCIndex = [0,0;1,0;0,1;1,1;0,2;1,2];
for i = 1:length(ahIoMapping);
    hIoMappingIn1 = ahIoMapping(i);
    [a,b] = ind2sub([6,1],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, ['./Path[@refId="id0" and', ...
        ' @path="In1"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="in2"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id1" and @path="[',num2str(aiCIndex(i,1)),'][',num2str(aiCIndex(i,2)),']"]'])));
end

% test 'In1' on  'top_A/Subsystem/top_A/sub_B4'
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B4"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="In1"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 6);
aiCIndex = [0,0;1,0;0,1;1,1;0,2;1,2];
for i = 1:length(ahIoMapping);
    hIoMappingIn1 = ahIoMapping(i);
    [a,b] = ind2sub([1,6],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, ['./Path[@refId="id0" and', ...
        ' @path="In1"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="in2"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id1" and @path="[',num2str(aiCIndex(i,1)),'][',num2str(aiCIndex(i,2)),']"]'])));
end

% test 'In1' on  'top_A/Subsystem/top_A/sub_B2'
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B2"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="In1"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 6);
aiTLIndex = [1,1;2,1;3,1;1,2;2,2;3,2];
for i = 1:length(ahIoMapping);
    hIoMappingIn1 = ahIoMapping(i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, ['./Path[@refId="id0" and', ...
        ' @path="In1"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="in1"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path="(',num2str(aiTLIndex(i,1)),')(',num2str(aiTLIndex(i,2)),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id1" and @path="[',num2str(i-1),']"]'])));
end

% test 'In1' on  'top_A/Subsystem/top_A/sub_B1'
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B1"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="In1"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 6);

for i = 1:length(ahIoMapping);
    hIoMappingIn1 = ahIoMapping(i);
    [a,b] = ind2sub([2,3],i);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, ['./Path[@refId="id0" and', ...
        ' @path="In1"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingIn1, './Path[@refId="id1" and @path="in1"]')));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingIn1, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path="(',num2str(a),')(',num2str(b),')"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id1" and @path="[',num2str(i-1),']"]'])));
end
end

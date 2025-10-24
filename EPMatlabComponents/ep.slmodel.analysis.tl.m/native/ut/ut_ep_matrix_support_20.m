function ut_ep_matrix_support_20
% Test the matrix support feature
%
%  ut_ep_matrix_support_20
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
sTestRoot = fullfile(sPwd, 'ut_ep_matrix_support_20');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'matrix_sig_models', 'matrix_sig20', 'tl40');

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

i_check_interface_object(hTlRoot, 'inport', 'sub_B6/In1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B6/Out1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B11/In1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B11/Out1', [],6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B16/In1', [], 4, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B16/Out1', [], 4, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B21/In1', [], 3, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B21/Out1', [], 3, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B26/In1', [], 2, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B26/Out1', [], 2, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B31/In1', [], 1, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B31/Out1', [], 1, 3, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B7/In1', [], 3, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B7/Out1', [], 3, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B12/In1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B12/Out1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B17/In1', [], 6, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B17/Out1', [], 6, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B22/In1', [], 3, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B22/Out1', [], 3, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B27/In1', [], 1, 4, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B27/Out1', [], 1, 4, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B32/In1', [], 2, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B32/Out1', [], 2, 1, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B3/In1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B3/Out1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B8/In1', [], 4, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B8/Out1', [], 4, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B13/In1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B13/Out1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B18/In1', [], 3, 4, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B18/Out1', [], 3, 4, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B23/In1', [], 4, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B23/Out1', [], 4, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B28/In1', [], 1, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B28/Out1', [], 1, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B33/In1', [], 1, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B33/Out1', [], 1, 2, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B4/In1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B4/Out1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B9/In1', [], 3, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B9/Out1', [], 3, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B14/In1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B14/Out1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B19/In1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B19/Out1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B24/In1', [], 1, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B24/Out1', [], 1, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B29/In1', [], 4, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B29/Out1', [], 4, 1, 'double', 'fixedPoint');

i_check_interface_object(hTlRoot, 'inport', 'sub_B5/In1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B5/Out1', [], 6, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B10/In1', [], 3, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B10/Out1', [], 3, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B15/In1', [], 3, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B15/Out1', [], 3, 3, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B20/In1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B20/Out1', [], 3, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B25/In1', [], 4, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B25/Out1', [], 4, 2, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'inport', 'sub_B30/In1', [], 4, 1, 'double', 'fixedPoint');
i_check_interface_object(hTlRoot, 'outport', 'sub_B30/Out1', [], 4, 1, 'double', 'fixedPoint');

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

% check sub_B17
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B17"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="In1"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 12);

for i = 1:3
    check(ahIoMapping(i), 'In1', i, 1, 'in9', i-1, 0);
end
for i = 4:6
    check(ahIoMapping(i), 'In1', i, 1, 'in10', i-4, 0);
end

% check sub_B23
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B23"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="In1"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 8);

for i = 1:3
    check(ahIoMapping(i), 'In1', i, 1, 'in9', i-1, 0);    
end
check(ahIoMapping(4), 'In1', 4, 1, 'in6', 0, []);
for i = 1:3
    check(ahIoMapping(4 + i), 'In1', i, 2, 'in9', i-1, 1);
end
check(ahIoMapping(8), 'In1', 4, 2, 'in6', 1, []);

% check sub_B25
ahIoMapping = mxx_xmltree('get_nodes', hMapRoot, ...
    ['//ScopeMapping/Path[@path="top_A/Subsystem/top_A/sub_B25"]/../InterfaceObjectMapping[@kind="Input"]', ...
    '/Path[@path="In1"]/..']);
MU_ASSERT_TRUE(length(ahIoMapping) == 8);

check(ahIoMapping(1), 'In1', 1, 1, 'in5', 0, []);
check(ahIoMapping(2), 'In1', 2, 1, 'in10', 0, 0);
check(ahIoMapping(3), 'In1', 3, 1, 'in10', 1, 0);
check(ahIoMapping(4), 'In1', 4, 1, 'in10', 2, 0);
check(ahIoMapping(5), 'In1', 1, 2, 'in5', 1, []);
check(ahIoMapping(6), 'In1', 2, 2, 'in10', 0, 1);
check(ahIoMapping(7), 'In1', 3, 2, 'in10', 1, 1);
check(ahIoMapping(8), 'In1', 4, 2, 'in10', 2, 1);

end

%***********************************************************************************************************************
% Helper to check the mapping
%***********************************************************************************************************************
function check(hIoMappingTmp, sSource, s_source_idx0, s_source_idx1, sTarget, s_target_idx0, s_target_idx1)
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, ['./Path[@refId="id0" and', ...
        ' @path="',sSource,'"]'])));
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMappingTmp, ['./Path[@refId="id1" and @path="',sTarget,'"]'])));
    hSignalMapping = mxx_xmltree('get_nodes', hIoMappingTmp, './SignalMapping');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
        ['./Path[@refId="id0" and @path="(',num2str(s_source_idx0),')(',num2str(s_source_idx1),')"]'])));
    if isempty(s_target_idx1)
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
            ['./Path[@refId="id1" and @path="[',num2str(s_target_idx0),']"]'])));
    else
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSignalMapping, ...
            ['./Path[@refId="id1" and @path="[',num2str(s_target_idx0),'][',num2str(s_target_idx1),']"]'])));
    end
end

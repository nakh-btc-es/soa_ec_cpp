function ut_ep_matrix_support_13
% Test the matrix support feature
%
%  ut_ep_matrix_support_13
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
sTestRoot = fullfile(sPwd, 'ut_ep_matrix_support_13');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'matrix_sig_models', 'matrix_sig13', 'tl40');

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

i_check_tl(hTlRoot, 'sub_Scal_Scal1/In1',      2, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Scal_Scal1/Out1', [], 2, 1, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Scal_Scal2/In1',      1, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Scal_Scal2/Out1', [], 1, 2, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Array_Scal/In1',      4, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Array_Scal/Out1', [], 4, 1, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Row_Scal/In1',        1, 3);
i_check_interface_object(hTlRoot, 'outport', 'sub_Row_Scal/Out1', [], 1, 3, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Col_Scal/In1',        4, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Col_Scal/Out1', [], 4, 1, 'boolean', 'Bool');

i_check_tl(hTlRoot, 'sub_Scal_Array/In1',      4, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Scal_Array/Out1', [], 4, 1, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Array_Array1/In1',    6, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Array_Array1/Out1', [], 6, 1, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Array_Array2/In1',    3, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Array_Array2/Out1', [], 3, 2, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Col_Array1/In1',      6, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Col_Array1/Out1', [], 6, 1, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Col_Array2/In1',      3, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Col_Array2/Out1', [], 3, 2, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Matrix_Array/In1',    3, 3);
i_check_interface_object(hTlRoot, 'outport', 'sub_Matrix_Array/Out1', [], 3, 3, 'boolean', 'Bool');

i_check_tl(hTlRoot, 'sub_Scal_Row/In1',        1, 3);
i_check_interface_object(hTlRoot, 'outport', 'sub_Scal_Row/Out1', [], 1, 3, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Row_Row1/In1',        2, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Row_Row1/Out1', [], 2, 2, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Row_Row2/In1',        1, 4);
i_check_interface_object(hTlRoot, 'outport', 'sub_Row_Row2/Out1', [], 1, 4, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Matrix_Row/In1',      4, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Matrix_Row/Out1', [], 4, 2, 'boolean', 'Bool');

i_check_tl(hTlRoot, 'sub_Scal_Col/In1',        4, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Scal_Col/Out1', [], 4, 1, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Array_Col1/In1',      6, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Array_Col1/Out1', [], 6, 1, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Array_Col2/In1',      3, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Array_Col2/Out1', [], 3, 2, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Col_Col1/In1',        6, 1);
i_check_interface_object(hTlRoot, 'outport', 'sub_Col_Col1/Out1', [], 6, 1, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Col_Col2/In1',        3, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Col_Col2/Out1', [], 3, 2, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Matrix_Col/In1',      3, 3);
i_check_interface_object(hTlRoot, 'outport', 'sub_Matrix_Col/Out1', [], 3, 3, 'boolean', 'Bool');

i_check_tl(hTlRoot, 'sub_Array_Matrix/In1',    3, 3);
i_check_interface_object(hTlRoot, 'outport', 'sub_Array_Matrix/Out1', [], 3, 3, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Row_Matrix/In1',      4, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Row_Matrix/Out1', [], 4, 2, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Col_Matrix/In1',      3, 3);
i_check_interface_object(hTlRoot, 'outport', 'sub_Col_Matrix/Out1', [], 3, 3, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Mat_Mat1/In1',        6, 2);
i_check_interface_object(hTlRoot, 'outport', 'sub_Mat_Mat1/Out1', [], 6, 2, 'boolean', 'Bool');
i_check_tl(hTlRoot, 'sub_Mat_Mat2/In1',       3, 4);
i_check_interface_object(hTlRoot, 'outport', 'sub_Mat_Mat2/Out1', [], 3, 4, 'boolean', 'Bool');
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
    if strcmp('fixedPoint', sDataTypeSIL)
        for idx=1:length(ahArrayElementSilType)
            MU_ASSERT_EQUAL('Int16', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'baseType'), 'BaseType not correct');
            MU_ASSERT_EQUAL('1.0000000000000000e+00', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'lsb'), 'LSB not correct');
            MU_ASSERT_EQUAL('0.0000000000000000e+00', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'offset'), 'Offset not correct');
            MU_ASSERT_EQUAL('-3.2768000000000000e+04', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'min'), 'Min not correct');
            MU_ASSERT_EQUAL('3.2767000000000000e+04', mxx_xmltree('get_attribute', ahArrayElementSilType(idx), 'max'), 'Max not correct');
        end
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

end
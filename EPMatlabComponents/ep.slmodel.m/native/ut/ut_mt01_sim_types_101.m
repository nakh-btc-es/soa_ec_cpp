function ut_mt01_sim_types_101
% checking functionality for BTS/32590 (info about Simulink.NumericType)
%
%
%   $Revision$ 
%   Last modified: $Date$ 
%   $Author$




%% test build-in types
try
    % float types
    stInfo = ep_sl_type_info_get('double');
    i_checkInfo(stInfo, 'double', 'double', true, 1.0, 0.0, ...
        i_toValue(-realmax('double')), i_toValue(realmax('double')));
    
    stInfo = ep_sl_type_info_get('single');
    i_checkInfo(stInfo, 'single', 'single', true, 1.0, 0.0, ...
        i_toValue(-realmax('single')), i_toValue(realmax('single')));
    
    % int types
    casInts = {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'};
    for i = 1:length(casInts)
        sIntType = casInts{i};
        stInfo = ep_sl_type_info_get(sIntType);
        i_checkInfo(stInfo, sIntType, sIntType, false, 1.0, 0.0, ...
            i_toValue(intmin(sIntType)), i_toValue(intmax(sIntType)));
    end
    
    % boolean/logical
    stInfo = ep_sl_type_info_get('boolean');
    i_checkInfo(stInfo, 'boolean', 'boolean', false, 1.0, 0.0, ...
        i_toValue(0.0), i_toValue(1.0));
    
    stInfo = ep_sl_type_info_get('logical');
    i_checkInfo(stInfo, 'logical', 'logical', false, 1.0, 0.0, ...
        i_toValue(0.0), i_toValue(1.0));
catch
    stErr = atgcv_lasterror();
    MU_FAIL(sprintf('Unexpected exception: "%s."', stErr.message));
end


%% FXP types without LSB/Offset
try
    % fixdt(0, 8, 0) == uint8
    stInfo = ep_sl_type_info_get('fixdt(0, 8, 0)');
    i_checkInfo(stInfo, 'fixdt(0, 8, 0)', 'uint8', false, 1.0, 0.0, ...
        i_toValue(intmin('uint8')), i_toValue(intmax('uint8')));
    
    % ufix8 == uint8
    stInfo = ep_sl_type_info_get('ufix8');
    i_checkInfo(stInfo, 'ufix8', 'uint8', false, 1.0, 0.0, ...
        i_toValue(intmin('uint8')), i_toValue(intmax('uint8')));
    
    % fltu8 == uint8
    stInfo = ep_sl_type_info_get('fltu8');
    i_checkInfo(stInfo, 'fltu8', 'uint8', false, 1.0, 0.0, ...
        i_toValue(intmin('uint8')), i_toValue(intmax('uint8')));
    
    % user-defined == uint8
    sMyType = 'MyTypeUInt8';
    evalin('base', sprintf('%s=%s;', sMyType, 'fixdt(0, 8, 0)'));
    stInfo = ep_sl_type_info_get(sMyType);
    i_checkInfo(stInfo, sMyType, 'uint8', false, 1.0, 0.0, ...
        i_toValue(intmin('uint8')), i_toValue(intmax('uint8')));
    
    
    % fixdt(1, 32, 0) == int32
    stInfo = ep_sl_type_info_get('fixdt(1, 32, 0)');
    i_checkInfo(stInfo, 'fixdt(1, 32, 0)', 'int32', false, 1.0, 0.0, ...
        i_toValue(intmin('int32')), i_toValue(intmax('int32')));
    
    % fixdt(1, 64, 0) == int64
    stInfo = ep_sl_type_info_get('fixdt(1, 64, 0)');
    i_checkInfo(stInfo, 'fixdt(1, 64, 0)', 'int64', false, 1.0, 0.0, ...
        i_toValue(intmin('int64')), i_toValue(intmax('int64')));
    
    % fixdt(0, 64, 0) == uint64
    stInfo = ep_sl_type_info_get('fixdt(0, 64, 0)');
    i_checkInfo(stInfo, 'fixdt(0, 64, 0)', 'uint64', false, 1.0, 0.0, ...
        i_toValue(intmin('uint64')), i_toValue(intmax('uint64')));
    
    % sfix32 == int32
    stInfo = ep_sl_type_info_get('sfix32');
    i_checkInfo(stInfo, 'sfix32', 'int32', false, 1.0, 0.0, ...
        i_toValue(intmin('int32')), i_toValue(intmax('int32')));
    
    % ufix64 == uint64
    stInfo = ep_sl_type_info_get('ufix64');
    i_checkInfo(stInfo, 'ufix64', 'uint64', false, 1.0, 0.0, ...
        i_toValue(intmin('uint64')), i_toValue(intmax('uint64')));
    
    % fltu32 == uint32
    stInfo = ep_sl_type_info_get('fltu32');
    i_checkInfo(stInfo, 'fltu32', 'uint32', false, 1.0, 0.0, ...
        i_toValue(intmin('uint32')), i_toValue(intmax('uint32')));
    
    % flts64 == int64
    stInfo = ep_sl_type_info_get('flts64');
    i_checkInfo(stInfo, 'flts64', 'int64', false, 1.0, 0.0, ...
        i_toValue(intmin('int64')), i_toValue(intmax('int64')));
    
    % user-defined == int32
    sMyType = 'MyTypeInt32';
    evalin('base', sprintf('%s=%s;', sMyType, 'fixdt(1, 32, 0)'));
    stInfo = ep_sl_type_info_get(sMyType);
    i_checkInfo(stInfo, sMyType, 'int32', false, 1.0, 0.0, ...
        i_toValue(intmin('int32')), i_toValue(intmax('int32')));
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(sprintf('Unexpected exception: "%s."', stErr.message));
end


%% FXP types with LSB/Offset
try
    sTestType = 'fixdt(0, 8, 2)';
    dLsb = 0.25;
    dOffset = 0.0;
    sBaseType = 'uint8';
    stInfo = ep_sl_type_info_get(sTestType);
    i_checkInfo(stInfo, 'fixdt(0, 8, 2)', sBaseType, false, dLsb, dOffset, ...
        i_toValue(double(intmin(sBaseType))*dLsb + dOffset), i_toValue(double(intmax(sBaseType))*dLsb + dOffset));
    
    sTestType = 'fixdt(1, 16, 3.5, -8.0)';
    dLsb = 3.5;
    dOffset = -8.0;
    sBaseType = 'int16';
    stInfo = ep_sl_type_info_get(sTestType);
    i_checkInfo(stInfo, sTestType, sBaseType, false, dLsb, dOffset, ...
        i_toValue(double(intmin(sBaseType))*dLsb + dOffset), i_toValue(double(intmax(sBaseType))*dLsb + dOffset));
    
    sTestType = 'sfix16_S3p5_Bn8';
    dLsb = 3.5;
    dOffset = -8.0;
    sBaseType = 'int16';
    stInfo = ep_sl_type_info_get(sTestType);
    i_checkInfo(stInfo, sTestType, sBaseType, false, dLsb, dOffset, ...
        i_toValue(double(intmin(sBaseType))*dLsb + dOffset), i_toValue(double(intmax(sBaseType))*dLsb + dOffset));
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(sprintf('Unexpected exception: "%s."', stErr.message));
end


%% FXP types with atypical WordLength
try
    stInfo = ep_sl_type_info_get('fixdt(0, 1, 0)');
    i_checkInfo(stInfo, 'fixdt(0, 1, 0)', ...
        'uint8', false, 1.0, 0.0, ...
        i_toValue(0.0), i_toValue(1.0));
    
    stInfo = ep_sl_type_info_get('fixdt(1, 1, 0)');
    i_checkInfo(stInfo, 'fixdt(1, 1, 0)', ...
        'int8', false, 1.0, 0.0, ...
        i_toValue(-1.0), i_toValue(0.0));
    
    dLsb = 3.5;
    dOffset = -8.0;
    stInfo = ep_sl_type_info_get('fixdt(0, 1, 3.5, -8.0)');
    i_checkInfo(stInfo, 'fixdt(0, 1, 3.5, -8.0)', ...
        'uint8', false, dLsb, dOffset, ...
        i_toValue(dOffset), i_toValue(dOffset+dLsb));
    
    dLsb = 3.5;
    dOffset = -8.0;
    stInfo = ep_sl_type_info_get('fixdt(1, 1, 3.5, -8.0)');
    i_checkInfo(stInfo, 'fixdt(1, 1, 3.5, -8.0)', ...
        'int8', false, dLsb, dOffset, ...
        i_toValue(dOffset-dLsb), i_toValue(dOffset));
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(sprintf('Unexpected exception: "%s."', stErr.message));
end



%% test robustness
% info function should _never_ throw exception
try
    % calls with invalid arguments
    % Note: also "auto", which you find sometimes for SL blocks, shall be considered an inavlid type
    casInvalid = {[], '', 'xxxNeverKnownxxx', 2, struct(), cell(1, 2), 'auto'};
    for i = 1:length(casInvalid)
        stInfo = ep_sl_type_info_get(casInvalid{i});
        MU_ASSERT_FALSE(stInfo.bIsValidType, 'Type should be invalid.');
    end
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(sprintf('Unexpected exception: "%s."', stErr.message));
end
end



%%
function i_checkInfo(stInfo, sType, sBaseType, bIsFloat, dLsb, dOffset, oMin, oMax)
MU_ASSERT_TRUE(stInfo.bIsValidType, ...
    sprintf('%s: Unexpected invalid type.', sType));

MU_ASSERT_TRUE(strcmp(stInfo.sBaseType, sBaseType), ...
    sprintf('%s: Expected BaseType "%s" instead of "%s".', ...
    sType, sBaseType, stInfo.sBaseType));

MU_ASSERT_TRUE(stInfo.bIsFloat == bIsFloat, ...
    sprintf('%s: Expected bIsFloat "%d" instead of "%d".', ...
    sType, bIsFloat, stInfo.bIsFloat));

MU_ASSERT_TRUE(isequal(stInfo.dLsb, dLsb), ...
    sprintf('%s: Expected LSB "%.16g" instead of "%.16g".', ...
    sType, dLsb, stInfo.dLsb));

MU_ASSERT_TRUE(isequal(stInfo.dOffset, dOffset), ...
    sprintf('%s: Expected Offset "%.16g" instead of "%.16g".', ...
    sType, dOffset, stInfo.dOffset));

MU_ASSERT_TRUE(compareTo(stInfo.oRepresentMin, oMin) == 0, ...
    sprintf('%s: Expected Min "%s" instead of "%s".', ...
    sType, oMin.toString, stInfo.oRepresentMin.toString));

MU_ASSERT_TRUE(compareTo(stInfo.oRepresentMax, oMax) == 0, ...
    sprintf('%s: Expected Max "%s" instead of "%s".', ...
    sType, oMax.toString, stInfo.oRepresentMax.toString));
end


%%
function oObj = i_toValue(xVal)
oObj = ep_sl.Value(xVal);
end

function ut_mt01_sim_types_102
% checking functionality for BTS/32590 (info about Simulink.NumericType)
%
%




%% test build-in types
% Note: clearing the type_info_get function is needed to avoid issues with the internal caching!!
try
    % float types
    sMyType = 'oType';
    i_createSimulinkNumericType(sMyType, 'Double');
    clear ep_sl_type_info_get;
    stInfo = ep_sl_type_info_get(sMyType);
    i_checkInfo(stInfo, 'double', 'double', true, 1.0, 0.0, ...
        i_toValue(-realmax('double')), i_toValue(realmax('double')));
    
    i_createSimulinkNumericType(sMyType, 'Single');
    clear ep_sl_type_info_get;
    stInfo = ep_sl_type_info_get(sMyType);
    i_checkInfo(stInfo, 'single', 'single', true, 1.0, 0.0, ...
        i_toValue(-realmax('single')), i_toValue(realmax('single')));
    
    % boolean/logical
    i_createSimulinkNumericType(sMyType, 'Boolean');
    clear ep_sl_type_info_get;
    stInfo = ep_sl_type_info_get(sMyType);
    i_checkInfo(stInfo, 'boolean', 'boolean', false, 1.0, 0.0, i_toValue(0.0), i_toValue(1.0));
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(sprintf('Unexpected exception: "%s."', stErr.message));
end
clear ep_sl_type_info_get;
end


%%
function i_createSimulinkNumericType(sTypeName, sBaseType)
evalin('base', sprintf('%s = Simulink.NumericType;', sTypeName));
evalin('base', sprintf('%s.DataTypeMode=''%s'';', sTypeName, sBaseType));
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




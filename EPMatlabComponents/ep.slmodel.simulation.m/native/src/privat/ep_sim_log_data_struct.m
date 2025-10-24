function stLogData = ep_sim_log_data_struct(sId, sType, adTimes, axValues, bIsStateflowData, sKind, dSampleTime)
% Transforms signal data into a predefined struct that can be handled by the mex-function "mxx_mdf".
%
% function stLogData = ep_sim_log_data_struct(sId, sType, adTimes, axValues, bIsStateflowData, sKind, dSampleTime)
%
%   INPUT               DESCRIPTION
%     sId                  (string)     ID of the logged signal
%     sType                (string)     signal type
%     adTimes              (double)     array with sampling times
%     axValues             (<numeric>)  array with sampling values of an arbitrary numerical value type
%     sKind                (string)     Input | Output | Param | Local
%     dSampleTime          (double)     the sampling time
%
%   OUTPUT              DESCRIPTION
%     stLogInfo            (struct)   struct summarizing the provided info
%

%%
% use always ZOH for higher ML versions or for logged data from SF-Charts
bIsZeroOrderHoldLogic = ~verLessThan('matlab', '9.6') || bIsStateflowData;

[sMdfType, axMdfValues] = i_translateToMDFTypeAndValue(sType, axValues);

stLogData = struct( ...
    'sId',     sId, ...
    'sType',   sMdfType, ...
    'anStep',  uint32(adTimes / dSampleTime), ...
    'adData',  axMdfValues, ...
    'bZoh',    bIsZeroOrderHoldLogic, ...
    'sKind',   sKind);
end


%%
function [sMdfType, axMdfValues] = i_translateToMDFTypeAndValue(sType, axValues)
stInfo = ep_sl_type_info_get(sType);
if stInfo.bIsFxp 
    sMdfType = sType;
    if isempty(axValues)
        axMdfValues = [];
    else
        try
            axMdfValues = int(axValues);

        catch oEx
            sMdfType = 'double';
            axMdfValues = double(axValues);
        end
    end
else
    sMdfType = stInfo.sBaseType;
    if (stInfo.bIsEnum && isenum(axValues))
        axMdfValues = cast(axValues, sMdfType);
    else
        axMdfValues = axValues;
    end
end
end

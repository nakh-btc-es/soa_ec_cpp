function sAdapterFunction = ep_ec_ar_multi_instance_adapter_function_get(sOrigFunction)
% Provided with the original step/init runnable function name returns the name of the adapted version.
%
% function sAdapterFunction = ep_ec_ar_multi_instance_adapter_function_get(sOrigFunction)
%
%  INPUT              DESCRIPTION
%      sOrigFunction             (string)          Name of the original runnable function
%
%  OUTPUT            DESCRIPTION
%      sAdapterFunction          (string)          Name of the adapted runnable function
%

%%
sAdapterFunction = [sOrigFunction, '_adapter'];
end



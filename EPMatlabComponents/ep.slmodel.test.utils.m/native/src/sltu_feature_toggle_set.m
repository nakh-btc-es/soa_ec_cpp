function onCleanupReset = sltu_feature_toggle_set(sFeatureName, xNewVal)
% For a test set the feature toggle to the provided values. Return cleanup object to automatically revert the change.
%

xCurrentVal = ep_sl_feature_toggle('get', sFeatureName);
ep_sl_feature_toggle('set', sFeatureName, xNewVal);

onCleanupReset = onCleanup(@() ep_sl_feature_toggle('set', sFeatureName, xCurrentVal));
end

function bSupportNeeded = ep_sl_preference_64bit_support()
% Return preference for 64bit integer type support in EP.
%

bInternalPref = true;
[sValue, bFoundKey] = ep_core_get_pref_value('PREVIEW_FEATURE_INT64_SUPPORT', bInternalPref);
bSupportNeeded = bFoundKey && strcmpi(sValue, 'true');
end



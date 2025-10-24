function sPrefLocationDir = ep_core_parse_preference_location()

sPrefLocationDir = getenv('EP_PREFERENCE_DIR');
if ~isempty(sPrefLocationDir)
    sPrefLocation = fullfile(sPrefLocationDir, 'EPPreferences.xml');
    ep_core_set_preference_location_env(sPrefLocation);
end

end
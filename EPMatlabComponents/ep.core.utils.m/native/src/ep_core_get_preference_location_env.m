function sPrefXML = ep_core_get_preference_location_env()
% Gets the environment variable for the preference file location.
%
%  function sPrefXML = ep_core_get_preference_location_env
%
%  OUTPUT              DESCRIPTION
%  - sPrefXML The preference file location.
%


%%
sPrefXML = getenv('EP_PREFERENCE_LOCATION');
end

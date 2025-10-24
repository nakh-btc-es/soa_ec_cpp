function sPreviousPrefXML = ep_core_set_preference_location_env(sPrefXML)
% Sets the environment variable for the preference file location.
%
%  function ep_core_set_preference_location_env(sPrefXML)
%
%  INPUT               DESCRIPTION
%  - sPrefXML           (string)    The preference file location of the current preference file.
%
%  OUTPUT              DESCRIPTION
%  - sPreviousPrefXML   (string)    The previous preference file location.
%
%


%%
sPreviousPrefXML = getenv('EP_PREFERENCE_LOCATION');

% set the environment variable
setenv('EP_PREFERENCE_LOCATION', sPrefXML);
end

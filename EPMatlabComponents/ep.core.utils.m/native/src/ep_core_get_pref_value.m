function [sValue, bFoundKey] = ep_core_get_pref_value(sPreferenceKey, bUseInternalPrefs)
% This fuction returns the value of a given preference name from EPPreferences.xml file
%
%   [sValue, bFoundKey] = ep_core_get_pref_value(sPreferenceKey)
%
%  INPUT              DESCRIPTION
%    - sPreferenceKey    (string)                 The preference key for which the value is needed.
%
%  OUTPUT            DESCRIPTION
%    - sValue            (string)                 The preference value attribute.
%    - bFoundKey         (bool)                   Flag if provided key was even found inside the preferences.


%%
sValue = '';
bFoundKey = false;

if (nargin < 2)
    bUseInternalPrefs = false;
end

sPreferencesXML = i_getPrefXML(bUseInternalPrefs);
if exist(sPreferencesXML, 'file')
    hDoc = mxx_xmltree('load', sPreferencesXML);
    xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hDoc));
    
    stRes = mxx_xmltree('get_attributes', hDoc, ...
        sprintf('/preferences/preference[@name="%s"]', sPreferenceKey), ...
        'value');
    if (numel(stRes) == 1) %#ok<ISCL>
        sValue = stRes.value;
        bFoundKey = true;
    end
end
end


%%
function sPrefXML = i_getPrefXML(bUseInternalPrefs)
sPrefXML = ep_core_get_preference_location_env();

% Fallback, if variable is not set
if isempty(sPrefXML)
    sPrefXML = i_getFallbackLocation();
end
if bUseInternalPrefs
    sPrefXML = i_replaceByInternalPrefFile(sPrefXML);
end
end


%%
function sInternalPrefXML = i_replaceByInternalPrefFile(sPublicPrefXML)
if isempty(sPublicPrefXML)
    sInternalPrefXML = '';
else
    [p, f, e] = fileparts(sPublicPrefXML);
    sInternalPrefXML = fullfile(p, 'internal', ['Internal_', f, e]);
end
end


%%
function sPrefXML = i_getFallbackLocation()
sPrefXML = fullfile(getenv('programdata'), 'BTC', 'ep', i_getVersionEP(), 'EPPreferences', 'EPPreferences.xml');
end


%%
function sEPVersion = i_getVersionEP()
sEPVersion = '';
try %#ok<TRYNC>
    astVersions = ver('ep'); % note: potentially many versions if EP has been registered multiple times (e.g. Dev mode)
    if ~isempty(astVersions)
        sRelease = lower(astVersions(1).Release);
        % e.g. '(R2.5p0)' -> 2.5p0
        sEPVersion = sRelease(3:end-1);
    end
end
end

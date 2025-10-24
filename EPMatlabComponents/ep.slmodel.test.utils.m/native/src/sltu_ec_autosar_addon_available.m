function bIsAvailable = sltu_ec_autosar_addon_available
% checks if the EmbeddedCoder AUTOSAR AddOn is installed
%


%%
bIsAvailable = false;
try
    sCreateCmd = which('autosar.api.create');
    bIsAvailable = ~isempty(sCreateCmd);
catch
end
end


function sInitScript = ep_simenv_init_script_gen(sExportPath, sModelName, sDestMdl, bTLSilMode, xSubsystem, bLoadSLDD)
% Generates the init script
%
% function sInitScript = ep_simenv_init_script_gen(sExportPath, sModelName, sDestMdl, bTLSilMode, xSubsystem, bLoadSLDD)
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%


%%
sInitScript = ep_sim_init_script_gen(sExportPath, sDestMdl, @(h) i_addInitCalCommands(h, xSubsystem));
end


%%
function i_addInitCalCommands(hFid, hSubsystem)
ahCalibrations = ep_em_entity_find(hSubsystem, 'child::Calibration');

%  for all inputs in the interface definition
for i = 1:length(ahCalibrations)
    hCalibration = ahCalibrations{i};
    
    ahIfNames = ep_em_entity_find(hCalibration, './/ifName');
    for j = 1:length(ahIfNames)
        hIfName = ahIfNames{j};
        
        sIfId = ep_em_entity_attribute_get(hIfName, 'ifid');
        
        sInput = ['i_', sIfId];
        dValue = 0.0;
        sDefaultValue = ep_em_entity_attribute_get(hIfName, 'initValue');
        if ~isempty(sDefaultValue)
            dValue = str2double(sDefaultValue);
        end
        
        sValue = sprintf('%s = [0, %.16g];', sInput, dValue);
        fprintf(hFid, 'try evalin(''base'', ''%s''); catch end %s\n', sValue, '%#ok');
    end
end
fprintf(hFid, '\n\n');
end

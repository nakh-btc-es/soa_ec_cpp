function createAdaptiveStubcodeXml(oEca)

if ~oEca.bIsAdaptiveAutosar
    error('EP:INTERNAL:ERROR', 'Adaptive Stubcode XML can only be created for AA models.');
end
ep_core_feval('ep_ec_aa_component_xml_create', oEca.sAutosarModelName, oEca.sAdaptiveStubcodeXmlFile);
end

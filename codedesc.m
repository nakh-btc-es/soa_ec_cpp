model = 'signal_dvPrivate_acMethod';
sCodegenFolder = "Y:\Documents\GitHub\soa_ec_cpp\models\signals\signal_dvPrivate_acMethod_ert_rtw";;

model = 'oClientServer_Model';
sCodegenFolder = "Y:\Documents\GitHub\soa_ec_cpp\models\example_cs_2\oClientServer_Model_ert_rtw";

% exportObjectToJSON_withMethods(desc,'description.json')
exportCodeDescriptorToJSON(sCodegenFolder, [model '.json']);

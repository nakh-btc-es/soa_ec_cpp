%i_analyzePropsAndCodeRepAutosar()
function oItf = i_analyzePropsAndCodeRepAutosar(oItf, cfgCodeFormatAutosar)
%Get properties (dataype, min, max, scaling, ... ) of the signal
oItf = oItf.getSignalProperties([]);
%Code representation of interface variables
oItf = oItf.getCodeVariableAutosar(cfgCodeFormatAutosar);
end
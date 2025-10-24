function sExpr = replaceMacrosAutosar(oItf, sExpr)

% <apiname> : name of rte api
% <c> : qname of component
% <re> : name of runnable
% <p> : name of port
% <o> : name of data element or operation or irv data
% <if> : name of the autosar interface
% <idt>: implementation datatype
% <name>: name of data (e.g. Parameter)
if any('<' == sExpr)
    sExpr = strrep(sExpr, '<apiname>', oItf.oAutosarComInfo.sRteApiName);
    sExpr = strrep(sExpr, '<c>',       oItf.oAutosarComInfo.sComponentName);
    sExpr = strrep(sExpr, '<re>',      oItf.oAutosarComInfo.sRunnableName);
    sExpr = strrep(sExpr, '<p>',       oItf.oAutosarComInfo.sPortName);
    sExpr = strrep(sExpr, '<if>',      oItf.oAutosarComInfo.sItfName);
    sExpr = strrep(sExpr, '<g>',       oItf.oAutosarComInfo.sModeGroup);
    if ismember(oItf.oAutosarComInfo.sInterfaceType, {'SenderReceiver', 'Calibration', 'NvData'})
        sExpr = strrep(sExpr, '<o>', oItf.oAutosarComInfo.sDataElementName);
    else
        sExpr = strrep(sExpr, '<o>', oItf.oAutosarComInfo.sDataName);
        sExpr = strrep(sExpr, '<name>', oItf.getAliasRootName);
    end
    sExpr = strrep(sExpr, '<idt>', oItf.oAutosarComInfo.sImplDatatype);
    if (oItf.isBusElement && oItf.metaBusSignal.iBusObjElement)
        sExpr = strrep(sExpr, '<codedt>', oItf.metaBus.busObjectName);
    else
        sExpr = strrep(sExpr, '<codedt>', oItf.codedatatype);
    end    
end
end
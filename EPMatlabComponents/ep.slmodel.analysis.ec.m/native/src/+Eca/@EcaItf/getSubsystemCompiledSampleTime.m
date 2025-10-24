function dSampleTime = getSubsystemCompiledSampleTime(oEca, nHandle)

try
    nCompiledSampleTime = get(nHandle, 'CompiledSampleTime');
    if size(nCompiledSampleTime,1) > 1
        nTmp = nCompiledSampleTime{1}(1)*100000;
        for iSpTm = 2:size(nCompiledSampleTime,1)
            if ~isequal(nCompiledSampleTime{iSpTm}(1),Inf)
                nTmp = gcd(nTmp, nCompiledSampleTime{iSpTm}(1)*100000);
            end
        end
        dSampleTime = nTmp/100000;
    else
        dSampleTime = nCompiledSampleTime(1);
    end
catch oEx
    dSampleTime = oEca.dModelSampleTime;
end
end



classdef TypeFXP
    % Class representing a type as used for Simulink models.
    properties (GetAccess = public, SetAccess = immutable)
        bIsSigned
        nBitWidth
        dLSB
        dOffset
    end

    methods
        function oObj = TypeFXP(bIsSigned, nBitWidth, dLSB, dOffset)
            if (nargin ~= 4)
                error('USAGE:ERROR', 'Following arguments required: bIsSigned, nBitWidth, dLSB, dOffset.');
            end
            [bIsSigned, nBitWidth, dLSB, dOffset] = i_assertArgs(bIsSigned, nBitWidth, dLSB, dOffset);
            oObj.bIsSigned = bIsSigned;
            oObj.nBitWidth = nBitWidth;
            oObj.dLSB      = dLSB;
            oObj.dOffset   = dOffset;
        end

        function [oMin, oMax] = getRepresentableMinMax(oObj)
            [oMin, oMax] = i_getRepresentableMinMax(oObj);
        end

        function [oMin, oMax] = getBaseIntegerMinMax(oObj)
            [oMin, oMax] = i_getBaseIntegerMinMax(oObj);
        end
    end

    methods (Static)
        function sNormalizedFxpTypeString = getNormalizedFxpString(sFxpTypeString)
            stTypeInfo = ep_core_feval('ep_sl_type_info_get', sFxpTypeString);            
            if (~stTypeInfo.bIsValidType || ~stTypeInfo.bIsFxp)
                error('EP:ERROR:INVALID_ARG', 'Provided string "%s" is not a valid FXP type.', sFxpTypeString);
            end
            sNormalizedFxpTypeString = sprintf('fixdt(%d,%d,%.17g,%.17g)', ...
                stTypeInfo.bIsSigned, ...
                stTypeInfo.iWordLength, ...
                stTypeInfo.dLsb, ...
                stTypeInfo.dOffset);
        end
    end
end


%%
function [bIsSigned, nBitWidth, dLSB, dOffset] = i_assertArgs(bIsSigned, nBitWidth, dLSB, dOffset)
bIsSigned = logical(bIsSigned);      % get rid of 0, 1

nBitWidth = int32(round(nBitWidth)); % get rid of floating point numbers
if (nBitWidth <= 0)
    error('ILLEGAL:ARGUMENT', 'Bit width needs to be a positive integer number.');    
end

dLSB = double(dLSB);
if (dLSB <= 0)
    error('ILLEGAL:ARGUMENT', 'LSB needs to be a positive floating number.');    
end

dOffset = double(dOffset);
end


%%
function [oMin, oMax] = i_getRepresentableMinMax(oObj)

[jMin, jMax] = i_getRepresentableMinMaxJava(oObj);

oMin = ep_sl.Value(i_translateBigDecimalToDoubleIfPossible(jMin));
oMax = ep_sl.Value(i_translateBigDecimalToDoubleIfPossible(jMax));
end


%%
function dVal = i_translateBigDecimalToDoubleIfPossible(jVal)
dCandidate = jVal.doubleValue();
if (jVal.compareTo(java.math.BigDecimal.valueOf(dCandidate)) == 0)
    dVal = dCandidate;
else
    dVal = jVal;
end
end


%%
function [jMin, jMax] = i_getRepresentableMinMaxJava(oObj)

[jBaseIntegerMin, jBaseIntegerMax] = i_getBaseIntegerMinMaxJava(oObj);

jLSB = java.math.BigDecimal.valueOf(oObj.dLSB);
jOffset = java.math.BigDecimal.valueOf(oObj.dOffset);

jMin = java.math.BigDecimal(jBaseIntegerMin).multiply(jLSB).add(jOffset);
jMax = java.math.BigDecimal(jBaseIntegerMax).multiply(jLSB).add(jOffset);
end


%%
function [oMin, oMax] = i_getBaseIntegerMinMax(oObj)
[jMin, jMax] = i_getBaseIntegerMinMaxJava(oObj);

jThreshold = java.math.BigInteger(sprintf('%d', int64(flintmax)));
if (jMax.compareTo(jThreshold) > 0)
    % min, max do not fit into int64 --> return them as BigInteger
    oMin = ep_sl.Value(jMin);
    oMax = ep_sl.Value(jMax);
else
    % min, max fit into int64 --> return them as int64
    oMin = ep_sl.Value(sscanf(jMin.toString(), '%ld'));
    oMax = ep_sl.Value(sscanf(jMax.toString(), '%ld'));
end
end


%%
function [jMin, jMax] = i_getBaseIntegerMinMaxJava(oObj)
jBaseTwo = java.math.BigInteger.valueOf(2);
if oObj.bIsSigned
    jMin = jBaseTwo.pow(oObj.nBitWidth - 1).negate();
    jMax = jMin.add(java.math.BigInteger.ONE).negate();
else
    jMin = java.math.BigInteger.ZERO;
    jMax = jBaseTwo.pow(oObj.nBitWidth).subtract(java.math.BigInteger.ONE);
end
end

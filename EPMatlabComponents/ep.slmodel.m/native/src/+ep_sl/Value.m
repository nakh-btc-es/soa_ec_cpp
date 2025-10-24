classdef Value
    % Class represents a value of arbitrary type boolean, int8, int16, ..., single, double, BigInteger, BigDecimal
    properties (Hidden, Access = private)
        xVal         % can be empty; always some kind of numerical value but with unknown type; never a string
        sValAsString % can be empty; always a string
    end
    
    methods
        function oObj = Value(xVal)
            if isjava(xVal)
                xVal = i_normalizeJavaVal(xVal);
            end
            if ischar(xVal)
                xVal = i_stringToNum(xVal);
            end
            oObj.xVal = xVal;
            oObj.sValAsString = i_toString(xVal);
        end

        function disp(oObj)
            if isempty(oObj)
                disp('<empty>');
            else
                disp(oObj.sValAsString);
            end
        end

        function bIsEmpty = isempty(oObj)
            bIsEmpty = isempty(oObj.xVal);
        end

        function xVal = get(oObj)
            xVal = oObj.xVal;
        end

        function sString = toString(oObj)
            sString = oObj.sValAsString;
        end

        % iRes = -1 --> this object is smaller than the other object
        % iRes = 1  --> this object is bigger than the other object
        % iRes = 0  --> both are equal
        function iRes = compareTo(oObj, oOtherObj)
            if ~isa(oOtherObj, 'ep_sl.Value')
                oOtherObj = ep_sl.Value(oOtherObj);
            end
            iRes = i_compareTo(oObj, oOtherObj);
        end

        function bIsFinite = isfinite(oObj)
            bIsFinite = ~oObj.isempty() && (~i_isFloat(oObj.xVal) || isfinite(oObj.xVal)); 
        end

        function bIsNan = isnan(oObj)
            bIsNan = oObj.isempty() || (i_isFloat(oObj.xVal) && isnan(oObj.xVal)); 
        end

        % DEPRECATED and should not be used; just for the current transition phase
        function dVal = doubleValue(oObj)
            dVal = i_doubleValue(oObj.xVal);
        end
    end
end


%%
function xVal = i_normalizeJavaVal(jVal)
if isa(jVal, 'java.math.BigDecimal')
    xVal = jVal; % keep BigDecimal as is
else
    xVal = i_stringToNum(char(jVal.toString()));
end
end


%%
function xVal = i_stringToNum(sVal)
if isempty(sVal)
    xVal = [];
else
    try
        xVal = java.math.BigDecimal(sVal);
    catch
        bSuccess = false;
        try %#ok<TRYNC>
            sVal = strrep(sVal, 'Infinity', 'Inf');
            xVal = eval(sVal);
            bSuccess = isnumeric(xVal) || islogical(xVal);
        end
        if ~bSuccess
            error('EP:ILLEGAL_ARG', 'String "%s" is not a numerical value.', sVal);
        end
    end
end
end


%%
function sString = i_toString(xValue)
sString = '';
if isempty(xValue)
    return;
end

if isa(xValue, 'embedded.fi')
    xValue = double(xValue); % TODO: normalize for now FXP object values <-- has to be changed for bitwidth 64
end

if i_isInteger(xValue)
    if isa(xValue, 'uint64')
        sString = sprintf('%u', xValue);
    else
        sString = sprintf('%d', xValue);
    end

elseif i_isFloat(xValue)
    sString = char(java.lang.Double(xValue).toString());

elseif i_isJava(xValue)
    sString = char(xValue.toString());

else
    error('ERROR:UNSUPPORTED_VALUE_TYPE', 'Value type "%s" is not supported.', class(xValue));
end
end


%%
function dVal = i_doubleValue(xVal)
dVal = [];
if isempty(xVal)
    return;
end

if (i_isInteger(xVal) || i_isFloat(xVal) || isa(xVal, 'embedded.fi'))
    dVal = double(xVal);

elseif i_isJava(xVal)
    dVal = xVal.doubleValue();

else
    error('ERROR:UNSUPPORTED_VALUE_TYPE', 'Value type "%s" is not supported.', class(xVal));
end
end


%%
% note: also booleans can be treated as integers
function bIsInt = i_isInteger(xVal)
bIsInt = islogical(xVal) || isinteger(xVal);
end


%%
function bIsFloat = i_isFloat(xVal)
bIsFloat = isfloat(xVal);
end


%%
function bIsJava = i_isJava(xVal)
bIsJava = isa(xVal, 'java.lang.Number');
end


%%
function iRes = i_compareTo(oThisValue, oOtherValue)
if oThisValue.isempty()
    oThisValue = ep_sl.Value(NaN);
end
if oOtherValue.isempty()
    oOtherValue = ep_sl.Value(NaN);
end

if oThisValue.isfinite()
    if oOtherValue.isfinite()
        jThisValue = i_translateToBigDecimal(oThisValue);
        jOtherValue = i_translateToBigDecimal(oOtherValue);
        iRes = jThisValue.compareTo(jOtherValue);
    else
        iRes = i_compareFiniteWithInfinite(oThisValue, oOtherValue);
    end
else
    if oOtherValue.isfinite()
        iRes = -i_compareFiniteWithInfinite(oOtherValue, oThisValue);
    else
        iRes = java.lang.Double(oThisValue.xVal).compareTo(java.lang.Double(oOtherValue.xVal));
    end
end
end


%%
function iRes = i_compareFiniteWithInfinite(oThisFiniteValue, oOtherInfiniteValue) %#ok<INUSD>
% Note: the concrete finite number does not need to be considered at all if compared to an infinite number
iRes = java.lang.Double(1).compareTo(oOtherInfiniteValue.xVal);
end


%%
function jValue = i_translateToBigDecimal(oValue)
if isa(oValue.xVal, 'java.math.BigDecimal')
    jValue = oValue.xVal;
else
    jValue = java.math.BigDecimal(oValue.toString());
end
end

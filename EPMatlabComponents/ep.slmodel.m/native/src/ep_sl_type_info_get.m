function stInfo = ep_sl_type_info_get(sSignalType, hResolverFunc)
% Get info about a specific Simulink signal type provided as string.
%
% function stInfo = ep_sl_type_info_get(sSignalType, hResolverFunc)
%
%   INPUT               DESCRIPTION
%     sSignalType       (string)          signal type
%     hResolverFunc     (handle)          optional function that can translate symbols used in model context
%                                         signature: <result-object> = feval(hResolverFunc, <symbol-string>)
%
%   OUTPUT              DESCRIPTION
%     stInfo             (struct)         info data:
%      .bIsValidType     (boolean)        true if type is known and was
%                                         correctly analyzed
%      .sType            (string)         the clean user type (i.e. prefixes like "Enum: " are removed)
%      .sEvalType        (string)         the evaluated (normalized) type
%                                         (the most basic type the user type can be uniquely reduced to)
%      .sBaseType        (string)         the base type of the signal type
%      .bIsFloat         (boolean)        true if a floating point type
%      .bIsFxp           (boolean)        true if a fixed point type
%      .bIsEnum          (boolean)        true if a enumeration type
%      .bIsBus           (boolean)        true if a bus type
%      .bIsSigned        (boolean)        flag for signed or unsigned integer types including FXP types
%      .iWordLength      (integer)        bit size of the base type for FXP types (empty for non-FXP types)
%      .dLsb             (double)         LSB as float for FXP types
%      .dOffset          (double)         Offset as float
%      .oBaseTypeMin     (object)         ep_sl.Value: min value of base type
%      .oBaseTypeMax     (object)         ep_sl.Value: max value of base type
%      .oRepresentMin    (object)         ep_sl.Value: min representable value
%      .oRepresentMax    (object)         ep_sl.Value: max representable value
%      .astEnum          (struct)         array of struct with Enum info
%         .Key           (string)         key of individual Enum
%         .Value         (sBaseType)      value of individual Enum
%      .casAliasChain    (strings)        ordered list of alias types, starting with the clean sType and ending
%                                         with the normalized sEvalType
%
%   REMARKS
%     Function never throws exception. If provided type is unknown, the
%     return struct will contain stInfo.bIsValidType==false.
%
%     Note: Types with the same sEvalType are effectively the same and are interchangeable in model context.
%
%   <et_copyright>


%%
persistent p_oTypeInfoMap;
if isempty(p_oTypeInfoMap)
    p_oTypeInfoMap = containers.Map;
end

%% special mode
if (nargin < 1)
    % return all cached types
    stInfo = cell2mat(p_oTypeInfoMap.values);
    return;
end

%% check for invalid inputs
if (isempty(sSignalType) || ~ischar(sSignalType))
    stInfo = i_getInfoDefault();
    return;
end
if (nargin < 2)
    hResolverFunc = atgcv_m01_generic_resolver_get(); % get the default generic resolver
end

%% main
sSignalType = i_normalizeType(sSignalType);
if p_oTypeInfoMap.isKey(sSignalType)
    stInfo = p_oTypeInfoMap(sSignalType);
    return;
end

stInfo = i_getSignalInfo(sSignalType, hResolverFunc);
stInfo.sType = sSignalType;

%% caching
% note: only cache valid types
if stInfo.bIsValidType
    p_oTypeInfoMap(sSignalType) = stInfo;
    
    % also cache for all alias types below
    for i = 2:length(stInfo.casAliasChain)
        sAliasType = stInfo.casAliasChain{i};
        if ~p_oTypeInfoMap.isKey(sAliasType)
            stAliasInfo = stInfo;
            stAliasInfo.sType = sAliasType;
            stAliasInfo.casAliasChain = stInfo.casAliasChain(i:end);
            p_oTypeInfoMap(sAliasType) = stAliasInfo;
        end
    end
elseif stInfo.bIsBus
    p_oTypeInfoMap(sSignalType) = stInfo;
end
end





%%
% main function
function stInfo = i_getSignalInfo(sSignalType, hResolverFunc)
switch sSignalType
    case {'double', 'single'}
        stInfo = i_getFloatInfo(sSignalType);
        
    case {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'}
        stInfo = i_getIntInfo(sSignalType);
        
    case {'boolean', 'logical'}
        stInfo = i_getBooleanInfo(sSignalType);
        
    otherwise
        stInfo = i_analyzeType(sSignalType, hResolverFunc);
end
end


%%
function stInfo = i_getInfoDefault()
stInfo = struct( ...
    'bIsValidType',  false, ...
    'sType',         '', ...
    'sEvalType',     '', ...
    'sBaseType',     '', ...
    'bIsFloat',      true, ...
    'bIsEnum',       false, ...
    'bIsBus',        false, ...
    'bIsFxp',        false, ...
    'bIsSigned',     [], ...
    'iWordLength',   [], ...
    'dLsb',          1.0, ...
    'dOffset',       0.0, ...
    'oRepresentMin', [], ...
    'oRepresentMax', [], ...
    'oBaseTypeMin',  [], ...
    'oBaseTypeMax',  [], ...
    'astEnum',       [], ...
    'casAliasChain', {{}});
end


%%
function stInfo = i_getFloatInfo(sFloatType)
stInfo = i_getInfoDefault();
stInfo.bIsValidType  = true;
stInfo.sEvalType     = sFloatType;
stInfo.sBaseType     = sFloatType;
stInfo.oRepresentMin = ep_sl.Value(-realmax(sFloatType));
stInfo.oRepresentMax = ep_sl.Value(realmax(sFloatType));
stInfo.oBaseTypeMin  = stInfo.oRepresentMin;
stInfo.oBaseTypeMax  = stInfo.oRepresentMax;
stInfo.casAliasChain = {sFloatType};
end


%%
function stInfo = i_getIntInfo(sIntType)
stInfo = i_getInfoDefault();
stInfo.bIsValidType  = true;
stInfo.sEvalType     = sIntType;
stInfo.sBaseType     = sIntType;
stInfo.bIsFloat      = false;
stInfo.bIsSigned     = intmin(sIntType) < 0;
stInfo.oRepresentMin = ep_sl.Value(intmin(sIntType));
stInfo.oRepresentMax = ep_sl.Value(intmax(sIntType));
stInfo.oBaseTypeMin  = stInfo.oRepresentMin;
stInfo.oBaseTypeMax  = stInfo.oRepresentMax;
stInfo.casAliasChain = {sIntType};
end


%%
function stInfo = i_getEmptyBaseIntFxpInfo()
stInfo = i_getInfoDefault();
stInfo.bIsValidType  = true;
stInfo.sEvalType     = '';
stInfo.sBaseType     = '';
stInfo.bIsFloat      = false;
stInfo.oRepresentMin = [];
stInfo.oRepresentMax = [];
stInfo.oBaseTypeMin  = [];
stInfo.oBaseTypeMax  = [];
stInfo.casAliasChain = {};
end


%%
function stInfo = i_getBooleanInfo(sBoolType)
stInfo = i_getInfoDefault();
stInfo.bIsValidType  = true;
stInfo.sEvalType     = sBoolType;
stInfo.sBaseType     = sBoolType;
stInfo.bIsFloat      = false;
stInfo.oRepresentMin = ep_sl.Value(false);
stInfo.oRepresentMax = ep_sl.Value(true);
stInfo.oBaseTypeMin  = stInfo.oRepresentMin;
stInfo.oBaseTypeMax  = stInfo.oRepresentMax;
stInfo.casAliasChain = {sBoolType};
end


%%
% try to analyze a type that is _not_ a builtin type
%
function stInfo = i_analyzeType(sSignalType, hResolverFunc)
% 1) check for BaseType
sBaseType = i_getBaseTypeFromAlias(sSignalType, hResolverFunc);
if ~isempty(sBaseType)
    stInfo = i_getSignalInfo(sBaseType, hResolverFunc);
    stInfo.casAliasChain = [{sSignalType}, stInfo.casAliasChain];
    return;
end

% 2) try fixdt (FixedPoint DataType)
stInfo = i_getFixdtInfo(sSignalType, hResolverFunc);
if stInfo.bIsValidType
    return;
end

% 3) try enumeration type
stInfo = i_getEnumInfo(sSignalType, hResolverFunc);
if stInfo.bIsValidType
    return;
end

% 4) try bus type and reset
stInfo = i_getBusInfo(sSignalType, hResolverFunc);
if stInfo.bIsBus
    return;
end

% 5) expression maybe?
[sEvalSignalType, bIsExpression] = i_evalAsExpression(sSignalType, hResolverFunc);
if bIsExpression
    stInfo = i_getSignalInfo(sEvalSignalType, hResolverFunc);
end
end


%%
function [sEvalSignalType, bIsExpression] = i_evalAsExpression(sSignalType, hResolverFunc)
sEvalSignalType = '';
bIsExpression = false;

try %#ok<TRYNC>
    xType = feval(hResolverFunc, sprintf('%s', sSignalType));
    if (ischar(xType) && ~strcmp(sSignalType, xType))

        bIsExpression = true;
        sEvalSignalType = xType;
    end
end
end


%%
function sBaseType = i_getBaseTypeFromAlias(sSignalType, hResolverFunc)
sBaseType = '';
try
    xType = feval(hResolverFunc, sprintf('%s', sSignalType));
    if isa(xType, 'Simulink.AliasType')
        sBaseType = i_normalizeType(xType.BaseType);
    end
catch
end
end


%%
function [xNumType, sAliasType] = i_checkForNumericType(sSignalType, hResolverFunc)
xNumType = [];
sAliasType = '';
if ~isempty(regexp(sSignalType, '^fixdt\(', 'once'))
    xNumType = feval(hResolverFunc, sprintf('%s', sSignalType));
else
    if (~isempty(regexp(sSignalType, '^[s,u]fix\d', 'once')) || ...
            ~isempty(regexp(sSignalType, '^flt[s,u]\d', 'once')))
        try
            xNumType = fixdt(sSignalType);
        catch
            % just ignore
        end
    else
        try
            xCheckType = feval(hResolverFunc, sprintf('%s', sSignalType));
            if isa(xCheckType, 'Simulink.NumericType')
                % is itself Simulink.NumericType
                xNumType = xCheckType;
                sAliasType = sSignalType;
            else
                % could be an "indirect" type (e.g. generated by sfix(16))
                xCheckType = eval(fixdt(xCheckType));
                if isa(xCheckType, 'Simulink.NumericType')
                    xNumType = xCheckType;
                end
            end
        catch
            % just ignore
        end
    end
end
end


%%
function stInfo = i_getFixdtInfo(sSignalType, hResolverFunc)
% initialize with default "invalid" TypeInfo
stInfo = i_getInfoDefault();

[xFixdtType, sAliasType] = i_checkForNumericType(sSignalType, hResolverFunc);
if isempty(xFixdtType)
    % type is not a FixedPoint type --> return default "invalid" TypeInfo
    return;
end

% check for mapping to builtin types (special cases of FixedPoint type)
sDataTypeMode = xFixdtType.DataTypeMode;
if any(strcmpi(sDataTypeMode, {'Double', 'Single'}))
    stInfo = i_getFloatInfo(lower(sDataTypeMode));
    if ~isempty(sAliasType)
        stInfo.casAliasChain = [{sAliasType}, stInfo.casAliasChain];
    end
    return;
end
if strcmpi(sDataTypeMode, 'Boolean')
    stInfo = i_getBooleanInfo(lower(sDataTypeMode));
    if ~isempty(sAliasType)
        stInfo.casAliasChain = [{sAliasType}, stInfo.casAliasChain];
    end
    return;
end

% now for the real FixedPoint types
aiPowTwo = [8, 16, 32, 64];
iOrigWordLength = xFixdtType.WordLength;
iStandardWordLength     = iOrigWordLength;
if ~any(iStandardWordLength == aiPowTwo)
    % if word length not power of two, get the next highest power
    iIdx = find(aiPowTwo > iStandardWordLength, 1, 'first');
    if ~isempty(iIdx)
        iStandardWordLength = aiPowTwo(iIdx);
    else
        iStandardWordLength = []; % wordlength > 64 --> there is no standard type wordlength for it in Simulink
    end
end

bIsSigned  = xFixdtType.Signed;
dLsb       = xFixdtType.Slope;
dOffset    = xFixdtType.Bias;
oTypeFXP   = ep_sl.TypeFXP(bIsSigned, iOrigWordLength, dLsb, dOffset);

if ~isempty(iStandardWordLength)
    if bIsSigned
        sBaseType = sprintf('int%d', iStandardWordLength);
    else
        sBaseType = sprintf('uint%d', iStandardWordLength);
    end
    stInfo = i_getIntInfo(sBaseType);
else
    % we have no base type to rely on
    stInfo = i_getEmptyBaseIntFxpInfo();
    [stInfo.oBaseTypeMin, stInfo.oBaseTypeMax] = oTypeFXP.getBaseIntegerMinMax();
end
stInfo.iWordLength = iOrigWordLength;
stInfo.bIsSigned   = bIsSigned;
stInfo.dLsb        = dLsb;
stInfo.dOffset     = dOffset;
[stInfo.oRepresentMin, stInfo.oRepresentMax] = oTypeFXP.getRepresentableMinMax();

stInfo.sEvalType = fixdt(xFixdtType);
stInfo.bIsFxp = true;
if isempty(sAliasType)
    stInfo.casAliasChain = {stInfo.sEvalType};
else
    stInfo.casAliasChain = {sAliasType, stInfo.sEvalType};
end
end


%%
function stInfo = i_getEnumInfo(sSignalType, hResolverFunc)
% initialize with default "invalid" TypeInfo
stInfo = i_getInfoDefault();

[aoEnum, casVals] = enumeration(sSignalType);
if isempty(aoEnum)
    % type is not an Enum type --> return default "invalid" TypeInfo
    return;
end

sBaseType = i_getBuiltinBaseType(sSignalType);
% limitation: an Enum that is not derived from some builtin numerical type
% (i.e. has no superclasses) cannot be evaluated --> return invalid TypeInfo
if isempty(sBaseType)
    return;
end

stInfo = i_getSignalInfo(sBaseType, hResolverFunc);
stInfo.sEvalType = sSignalType;

% adapt basic info to Enum specific details
stInfo.bIsEnum = true;
nEnumVals = length(aoEnum);
stEnum = struct( ...
    'Key',   '', ...
    'Value', []);
stInfo.astEnum = repmat(stEnum, 1, nEnumVals);
for i = 1:nEnumVals
    stInfo.astEnum(i).Key = casVals{i};
    stInfo.astEnum(i).Value = cast(aoEnum(i), sBaseType);
end
stInfo.oRepresentMin = ep_sl.Value(min([stInfo.astEnum(:).Value]));
stInfo.oRepresentMax = ep_sl.Value(max([stInfo.astEnum(:).Value]));
stInfo.casAliasChain = {stInfo.sEvalType};
end


%%
function stInfo = i_getBusInfo(sSignalType, hResolverFunc)
% initialize with default "invalid" TypeInfo
stInfo = i_getInfoDefault();

xType = feval(hResolverFunc, sprintf('%s', sSignalType));
stInfo.bIsBus = isa(xType, 'Simulink.Bus');
end


%%
function sBaseType = i_getBuiltinBaseType(sSignalType)
sBaseType = '';

casSuperClasses = superclasses(sSignalType);
for i = 1:length(casSuperClasses)
    sSuperClass = casSuperClasses{i};
    if i_isBuiltinSignalType(sSuperClass)
        sBaseType = sSuperClass;
        return;
    end
end
end


%%
function bIsBuiltIn = i_isBuiltinSignalType(sCheckType)
persistent casTypes;

if isempty(casTypes)
    casTypes = {  ...
        'double', ...
        'single', ...
        'int8',   ...
        'uint8',  ...
        'int16',  ...
        'uint16', ...
        'int32',  ...
        'uint32', ...
        'int64',  ...
        'uint64', ...
        'boolean', ...
        'logical'};
end
bIsBuiltIn = any(strcmpi(sCheckType, casTypes));
end


%%
% remove prefixes like "Enum: ", "Bus: ", "Inherited: ", ...
function sSignalType = i_normalizeType(sSignalType)
sSignalType = regexprep(sSignalType, '^.+:\s*', '');
end

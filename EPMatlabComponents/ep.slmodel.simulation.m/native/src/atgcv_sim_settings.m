function varargout = atgcv_sim_settings(varargin)
% read/write setting used in context Simulation
%
% function varargout = atgcv_sim_settings(varargin)
%
%  this function can be used in two modes:
%
%  --- set mode -----------------------------------------
%      oldValue = atgcv_sim_settings(<key>, <value>)
%
%   INPUT           DESCRIPTION
%     key              (string)      'PIL_MODE'
%     value            (string)      'TL' | 'BTC'
%
%     key              (string)      'PIL_TIMEOUT'
%     value            (string)      '120'
%
%     key              (string)      'MIL_RND_METH'
%     value            (string)      'Zero' | 'Floor' | 'Nearest' | ...
%                                    'Round' | 'Simplest' | 'Convergent' | ...
%                                    'Ceiling'
%
%     key              (string)      'REUSE_MODEL_CALLBACKS'
%     value            (string)      'none' | 'all'
%
%   OUTPUT          DESCRIPTION
%     oldValue         (xxx)          previously active "value" of set "key"
%
%
%  --- get mode -----------------------------------------
%      <value> = atgcv_sim_settings(<key>)
%
%   INPUT           DESCRIPTION
%      n.a.
%
%   OUTPUT          DESCRIPTION
%      <value>      (xxx)      the currently active "value" of "key"
%                              (see "set mode" for possible key-values)
%
%   <et_copyright>

%% internal
%
%  hidden input settings
%
%  Note the alias sim modes: "BASE" == "TL" and "CUSTOM" == "BTC"!
%
%   INPUT           DESCRIPTION
%     key              (string)      'PIL_MODE'
%     value            (string)      'BASE' | 'CUSTOM'
%
%     key              (string)      'SIL_MODE'
%     value            (string)      'BASE' | 'CUSTOM'
%
%     key              (string)      'MIL_MODE'
%     value            (string)      'NORMAL' | 'ACCEL'
%
%
%
% ------------------------------------------------
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 174775 $
%   Last modified: $Date: 2014-06-21 09:56:44 +0200 (Sa, 21 Jun 2014) $
%   $Author: jbohn $
%


[nIn, nOut] = i_evalArgNum(nargin, nargout);
sKey = i_evalKey(varargin{1});

if (nIn > 1)
    sPrivValue = i_setNewActiveValue(sKey, varargin{2});
else
    sPrivValue = i_getActiveValue(sKey);
end

% output is required if used in GET-Mode or if explicitly asked for
bIsOutputRequired = ((nIn < 2) || (nOut > 0));
if bIsOutputRequired
    varargout{1} = i_translatePrivateToPublic(sKey, sPrivValue);
    
    % check if private/internal naming is also required
    if (nOut > 1)
        varargout{2} = sPrivValue;
    end
end
end


%%
function [nIn, nOut] = i_evalArgNum(nIn, nOut)
if (nIn < 1)
    error('ATGCV:USAGE_ERROR', ...
        'Wrong usage: No arguments provided. Please see help.');
end
if (nOut > 2)
    error('ATGCV:USAGE_ERROR', ...
        'Wrong usage: Too many outputs expected. Please see help.');
end
end


%%
function sKey = i_evalKey(sKey)
if (~ischar(sKey) || isempty(sKey))
    error('ATGCV:USAGE_ERROR', ...
        'Wrong usage: Key has to be non-empty String. Please see help.');
end
sKey = upper(sKey);
end


%%
function sPubValue = i_translatePrivateToPublic(sKey, sPrivValue)
switch sKey
    case {'SIL_MODE', 'PIL_MODE'}
        sPubValue = i_translatePrivateSimMode(sPrivValue);
    
    otherwise
        sPubValue = sPrivValue;
end
end


%%
function sPrivValue = i_translatePublicToPrivate(sKey, sPubValue)
switch sKey
    case {'SIL_MODE', 'PIL_MODE'}
        sPrivValue = i_translatePublicSimMode(sPubValue);
        
    case 'MIL_MODE'
        sPrivValue = upper(sPubValue);
    case 'MIL_RND_METH'
        sPrivValue = lower(sPubValue);
        sPrivValue(1) = upper(sPrivValue(1));
        
    case 'REUSE_MODEL_CALLBACKS'
        sPrivValue = i_translatePublicModelCallbacks(sPubValue);
        
    otherwise
        sPrivValue = sPubValue;
end
end


%%
function sPubMode = i_translatePrivateSimMode(sPrivMode)
sPrivMode = upper(sPrivMode);
switch sPrivMode
    case 'BASE'
        sPubMode = 'TL';
        
    case 'CUSTOM'
        sPubMode = 'BTC';
        
    otherwise
        sPubMode = sPrivMode;
end
end


%%
function sPrivMode = i_translatePublicSimMode(sPubMode)
sPubMode = upper(sPubMode);
switch sPubMode
    case 'TL'
        sPrivMode = 'BASE';
        
    case 'BTC'
        sPrivMode = 'CUSTOM';
        
    otherwise
        sPrivMode = sPubMode;
end
end


%%
function sPrivValue = i_translatePublicModelCallbacks(sPubValue)
sPrivValue = '';

casPubValues = i_splitMultiValue(sPubValue);
if isempty(casPubValues)
    return;
end

% special case: none ---> do not select any callback
if any(strcmpi('none', casPubValues))
    return;
end

% special case: all --> do select all callbacks
casSupportedCallbacks = i_getModelCallbacks();
if any(strcmpi('all', casPubValues))
    sPrivValue = i_mergeToMultiValue(casSupportedCallbacks);
    return;
end

% common case: a list of callbacks to be selected --> check first for support
abIsSelected = cellfun(@(x) any(strcmpi(x, casPubValues)), casSupportedCallbacks);
sPrivValue = i_mergeToMultiValue(casSupportedCallbacks(abIsSelected));
end


%%
function [sValue, casSuppValues, sKind] = i_getActiveValue(sKey)
persistent stSupported;

if isempty(stSupported)
    stSupported = struct( ...
        'REUSE_MODEL_CALLBACKS', {[{'none', 'all'}, i_getModelCallbacks()]}, ...
        'PIL_MODE', {{'CUSTOM', 'BASE'}}, ...
        'SIL_MODE', {{'EXTERNAL', 'BASE', 'CUSTOM'}}, ...
        'MIL_MODE', {{'NORMAL', 'ACCEL'}}, ...
        'MIL_RND_METH', {{'Nearest', 'Zero', 'Round', 'Simplest', 'Convergent', 'Ceiling', 'Floor'}}, ...
        'PIL_TIMEOUT', {{'120'}});
end

if isfield(stSupported, sKey)
    casSuppValues = stSupported.(sKey);
    bExist = true;
    try
        [sValue] = atgcv_global_property_get(sKey);
    catch
        bExist = false;
    end
    if bExist
        % normalize (maybe set manually by user outside of this API function)
        sValue = i_translatePublicToPrivate(sKey, sValue);
    else
        % use the first supported Value as "default" but translate it to private
        sValue = i_translatePublicToPrivate(sKey, casSuppValues{1});
    end
    
    sKind = 'ENUM';
    if strcmp(sKey, 'PIL_TIMEOUT')
        sKind = 'POS_INT';
    end
else
    error('ATGCV:USAGE_ERROR', ...
        'Wrong usage: Key "%s" is not supported. Please see help.', sKey);
end
end


%%
function sOldValue = i_setNewActiveValue(sKey, sValue)
sValue = i_translatePublicToPrivate(sKey, sValue);

[sOldValue, casSuppValues, sKind] = i_getActiveValue(sKey);
if strcmpi(sValue, sOldValue)
    return;
end

if strcmp(sKind, 'ENUM')
    i_assertValueSupported(sKey, sValue, casSuppValues);
elseif strcmp(sKind, 'POS_INT')
    sValue = i_assertValuePositiveInteger(sKey, sValue);
end
atgcv_global_property_set(sKey, sValue);
end


%%
% * check that value is amoung the supported values (not case-sensitive)
% * for multi-values separated by ";" check that each value is supported
function i_assertValueSupported(sKey, sValue, casSupportedValues)
abIsSupported = ...
    cellfun(@(x) any(strcmpi(x, casSupportedValues)), ...
    i_splitMultiValue(sValue));
if ~all(abIsSupported)
    error('ATGCV:USAGE_ERROR', ...
        'Wrong usage: Value "%s" is not supported for key "%s". Please see help.', ...
        sValue, sKey);
end
end


%%
function sValue = i_assertValuePositiveInteger(sKey, sValue)
bIsSupported = false;
try
    dValue = str2double(sValue);
    bIsSupported = ~isempty(dValue) && isfinite(dValue) && (dValue > 0);
    sValue = num2str(round(dValue));
catch
end
if ~bIsSupported
    error('ATGCV:USAGE_ERROR', ...
        'Wrong usage: Value "%s" is not supported for key "%s". Please see help.', ...
        sValue, sKey);
end
end


%%
% * split multivalue at separator ';'
% * trim the resulting parts
% * remove all blanks (empty strings)
function casValues = i_splitMultiValue(sMultiValue)
casValues = strtrim(regexp(sMultiValue, ';', 'split'));
casValues(cellfun(@isempty, casValues)) = []; 
end


%%
% * split multivalue at separator ';'
% * trim the resulting parts
% * remove all blanks (empty strings)
function sMultiValue = i_mergeToMultiValue(casValues)
if isempty(casValues)
    sMultiValue = '';
else
    sMultiValue = sprintf('%s;', casValues{:});
    sMultiValue(end) = []; % remove last ";"
end
end


%%
function casCallbackFcns = i_getModelCallbacks()
casCallbackFcns = { ...
    'PreLoadFcn', ...
    'PostLoadFcn', ...
    'InitFcn', ...
    'StartFcn', ...
    'PauseFcn', ...
    'ContinueFcn', ...
    'StopFcn', ...
    'PreSaveFcn', ...
    'PostSaveFcn', ...
    'CloseFcn'};
end



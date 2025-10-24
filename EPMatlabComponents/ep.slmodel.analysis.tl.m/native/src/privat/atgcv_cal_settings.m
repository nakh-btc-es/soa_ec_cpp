function varargout = atgcv_cal_settings(varargin)
% read/write setting used in context Calibration
%
% function varargout = atgcv_cal_settings(varargin)
%
%  this function can be used in two modes:
%
%  --- set mode -----------------------------------------
%      atgcv_cal_settings(<key1>, <value1>, <key2>, <value2>, ...)
%
%   INPUT           DESCRIPTION
%     key              (string)      'ET_CAL_ignore_LUT_axis' |
%                                    'ET_CAL_ignore_LUT_1D_values' |
%                                    'ET_CAL_ignore_LUT_2D_values' |
%                                    'ET_CAL_ignore_Interpolation_values' |
%                                    'ET_CAL_ignore_arrays' | 
%     value            (string)      'no' | 'yes'
%       
%     key              (string)      'ET_CAL_ignore_variable_classes'
%     value            (string)      semicolon separated list of names of 
%                                    the ignored variable classes
%                                      
%
%   OUTPUT          DESCRIPTION
%      n.a.
%
%
%  --- get mode -----------------------------------------
%      stSettings = atgcv_cal_settings()
%
%   INPUT           DESCRIPTION
%      n.a.                                 
%
%   OUTPUT          DESCRIPTION
%      stSettings      (struct)      struct with info about current
%                                    settings
%         .<key>       (boolean)     false | true (with key as in set mode)
%
%
%   <et_copyright>

%% internal
%
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 211002 $
%   Last modified: $Date: 2016-04-27 08:42:25 +0200 (Mi, 27 Apr 2016) $
%   $Author: ahornste $
%

persistent stSettings;

if isempty(stSettings)
    stSettings = i_getGlobalSettings();
end

if (nargin > 0)
    stNewSettings = struct();
    
    if (mod(nargin, 2) == 0)
        casKeyValues = varargin;

        for i = 1:2:length(casKeyValues)
            sName  = casKeyValues{i};
            if strcmpi(sName, 'ET_CAL_ignore_variable_classes')
                sIgnoredClasses = i_readStringValue(casKeyValues{i+1});
                stNewSettings.ET_CAL_ignore_variable_classes = sIgnoredClasses;
            else
                bValue = i_readBoolValue(casKeyValues{i + 1});
                
                if (ischar(sName) && isvarname(sName))
                    stNewSettings.(sName) = bValue;
                else
                    error('ATGCV:MOD_ANA:USAGE_ERROR', ...
                        'Found invalid key. Cannot proceed.');
                end
            end
        end
    else
        error('ATGCV:MOD_ANA:USAGE_ERROR', ...
            'Changing the Calibration settings requires key-value pairs.');
    end
    
    stSettings = i_evalNewSettings(stSettings, stNewSettings);
end

if (nargout > 0)
    varargout{1} = stSettings;
end
end


%%
function bValue = i_readBoolValue(xArg)
bValue = [];
if islogical(xArg)
    bValue = xArg;
elseif isnumeric(xArg)
    bValue = logical(xArg);
elseif ischar(xArg)
    if any(strcmpi(xArg, {'on','yes','true','1'}))
        bValue = true;
    elseif any(strcmpi(xArg, {'off','no','false','0'}))
        bValue = false;
    end
end
if isempty(bValue)
    error('ATGCV:MOD_ANA:USAGE_ERROR', ...
        'Could not determine boolean value from argument.');        
end
end

%%
function sValue = i_readStringValue(xArg)
sValue = '';
casValidValues = cell(0);
if ~ischar(xArg)
    error('ATGCV:MOD_ANA:USAGE_ERROR', ...
        ['Invalid value for ET_CAL_ignore_variable_classes. ', ...
        'Argument must be semicolon-separated String of valid variable class names.']);
end

if ~isempty(xArg)
    casClasses = regexp(xArg, ';', 'split');
    for i=1:length(casClasses)
        sClass = casClasses{i};
        if ~isempty(sClass)
            sClass = strtrim(sClass);
            caMatches = regexpi(sClass, '^[_a-z][\w]*$');
            if length(caMatches) ~= 1
                error('ATGCV:MOD_ANA:USAGE_ERROR', ...
                    ['Invalid value for ET_CAL_ignore_variable_classes. ', ...
                    'Argument must be semicolon-separated String of valid variable class names.']);
            else
                casValidValues{end+1} = sClass; %#ok
            end
        end
    end
    if ~isempty(casValidValues)
        sValue = sprintf('%s;', casValidValues{:});
        sValue = sValue(1:end-1);
    end
end
end


%% i_getGlobalSettings
function stSettings = i_getGlobalSettings()
% first the default settings
% BTS/34093 igonre interpolation and index search block
stSettings = struct( ...
    'ET_CAL_ignore_LUT_axis',             false, ...
    'ET_CAL_ignore_LUT_1D_values',        false, ...
    'ET_CAL_ignore_LUT_2D_values',        false, ...
    'ET_CAL_ignore_Interpolation_values', false, ... % index search and interpolation
    'ET_CAL_ignore_arrays',               false, ...
    'ET_CAL_ignore_variable_classes',     '');

casSettings = fieldnames(stSettings);
for i = 1:length(casSettings)
    sName  = casSettings{i};
    sValue = '';
    
    try
        sValue = atgcv_global_property_get(sName);
    catch
    end
    
    if ~isempty(sValue)
        if ~strcmpi(sName, 'ET_CAL_ignore_variable_classes')
            try
                xValue = i_readBoolValue(sValue);
            catch
                warning('ATGCV:MOD_ANA:USAGE_ERROR', ...
                    'Unknown value for CAL setting %s. Reset to "no".', sName);
                atgcv_global_property_set(sName, 'no');
                
                xValue = false;
            end
        else
            try
                xValue = i_readStringValue(sValue);
            catch
                warning('ATGCV:MOD_ANA:USAGE_ERROR', ...
                    'Invalid value for CAL setting %s. Reset to "".', sName);
                atgcv_global_property_set(sName, '');
                
                xValue = '';
            end
        end
        stSettings.(sName) = xValue;
    end
end
end


%% i_evalSettings
function stSettings = i_evalNewSettings(stSettings, stNewSettings)
casAllowedSettings    = fieldnames(stSettings);
casNewSettings        = fieldnames(stNewSettings);
casNotAllowedSettings = setdiff(casNewSettings, casAllowedSettings);
if ~isempty(casNotAllowedSettings)
    sAllSettings = sprintf('%s;', casNotAllowedSettings{:});
    sAllSettings(end) = [];
    error('ATGCV:MOD_ANA:USAGE_ERROR', 'Unknown settings: %s.', sAllSettings);
end

for i = 1:length(casNewSettings)
    sName  = casNewSettings{i};
    xValue = stNewSettings.(sName);
    
    % need only to reset value if it differs from the old one
    if (ischar(xValue) && ~strcmpi(xValue, stSettings.(sName))) || ...
            (islogical(xValue) && (stSettings.(sName) ~= xValue))
        if ischar(xValue)
            sValue = xValue;
        elseif xValue
            sValue = 'yes';
        else
            sValue = 'no';
        end
        
        % memorize value persistently for User
        atgcv_global_property_set(sName, sValue);
        
        stSettings.(sName) = xValue;
    end
    
end
end




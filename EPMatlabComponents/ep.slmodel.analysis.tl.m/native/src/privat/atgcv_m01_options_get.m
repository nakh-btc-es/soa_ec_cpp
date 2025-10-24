function stOpt = atgcv_m01_options_get(varargin)
% get default options and combine them wit the provided ones
%
% function stOpt = atgcv_m01_options_get(varargin)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)  environment structure
%     stOpt               (struct)  structure with options for model analysis
%       .sDdPath          (string)  full path to DataDictionary to be used
%                                   for analysis
%       .sTlModel         (string)  name of TargetLink model to be used for
%                                   analysis (assumed to be open)
%       .sSlModel         (string)  name of Simulink model corresponding to the
%                                   TargetLink model (optional parameter)
%       .sTlSubsystem     (string)  name (without path) of TL toplevel Subsystem
%                                   (optional if there is just one Subsystem in
%                                   the model; obligatory if there are many)
%       .bCalSupport        (bool)  TRUE if CalibrationSupport shall be
%                                   activated, otherwise FALSE
%       .bDispSupport       (bool)  TRUE if DisplaySupport shall be
%                                   activated, otherwise FALSE
%       .bParamSupport      (bool)  TRUE if ParameterSupport shall be
%                                   activated, otherwise FALSE
%       .sDsmMode         (string)  DataStoreMode support
%                                   'all' | <'read'> | 'none'
%       .bExcludeTLSim      (bool)  TRUE if only the pure ProductionCode shall
%                                   be considered (i.e. all files from TLSim
%                                   directory are excluded)
%                                   default is FALSE
%       .sModelMode       (String)  <'TL'> | 'SL'
%       .sAddModelInfo    (String)  Path to the XML file including
%                                   additional model information.
%       .bAddEnvironment    (bool)  consider also the Parent-Subsystem of the
%                                   TL-TopLevel Subsystem
%                                   default is FALSE
%       .bIgnoreStaticCal   (bool)  if TRUE, ignore all STATIC_CAL Variables
%                                   default is FALSE
%       .bIgnoreBitfieldCal (bool)  if TRUE, ignore all CAL Variables with Type
%                                   Bitfield; default is FALSE
%
%   OUTPUT              DESCRIPTION
%     stModel             (struct) result structure
%        ... TODO ...
%

%%
% **************** (deprecated: but still supported for UnitTests) *************
%
% function stRes = atgcv_model_analysis(stEnv, sDDPath, sSLModel, sTLModel, ...
%       sTLSubsystem, sCodeSymbols, sCCodePath, bCalSupport, bDispSupport)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)  Environment structure.
%     sDDPath             (string) full path to the TargetLink Data Dictionary (OSC.dd).
%     sSLModel            (string) optinal: Name of the current Simulink model, or empty string.
%     sTLModel            (string) Name of the current TargetLink model.
%     sTLSubsystem        (string) Name of the current TargetLink subsystem.
%     sCodeSymbols        (string) full path to the CodeSymbols XML file with renamed function and variable
%                                  names (CodeSymbols.dtd).
%     sCCodePath          (string) full path to the generated C Code. Information is necessary to analyse
%                                  CodeSymbols.dtd.
%     bCalSupport         (boolean) If set to 'on' calibration variables are regarded as additional inputs to
%                                   system and are included in stimuli/test vectors
%     bDispSupport        (boolean) If set to 'true' Display (DISP) variables
%                                   are regarded as additional outputs in the
%                                   interfaces of subsystems and are included in
%                                   stimuli/test vectors
%     bParamSupport       (boolean) If set to 'true' CAL variables
%                                   are regarded as additional inputs
%                                   of subsystems and are included in
%                                   stimuli/test vectors


%% main
if (nargin < 1)
    stOpt = i_getDefaultArgs();
    stOpt = i_checkSetOptions(stOpt);
else
    stOpt = i_checkSetOptions(varargin{:});
end
end


%%
function stOpt = i_getDefaultArgs(sMode)
sDd = i_getCurrentDd();
bIsSL = isempty(sDd);
if ((nargin > 0) && strcmpi(sMode, 'SL'))
    bIsSL = true;
end
if bIsSL
    stOpt = struct( ...
        'sSlModel',   bdroot(gcs()), ...
        'sCalMode',   'explicit', ...
        'sDispMode',  'all', ...
        'sModelMode', 'SL');
else
    stOpt = struct( ...
        'sTlModel',   bdroot(gcs()), ...
        'sDdPath',    sDd, ...
        'sCalMode',   'explicit', ...
        'sDispMode',  'all');
    casSubsystems = get_tlsubsystems(stOpt.sTlModel);
    if (length(casSubsystems) > 1)
        casNames = cellfun( ...
            @(x)(get_param(x, 'Name')), ...
            casSubsystems, ...
            'UniformOutput', false);
        iIdx = find(strcmpi(get_param(gcbh, 'Name'), casNames));
        if isempty(iIdx)
            iIdx = 1;
        end
        stOpt.sTlSubsystem = get_param(casSubsystems{iIdx}, 'Name');
    end
end
end


%%
function sCurrDd = i_getCurrentDd()
if ~exist('dsdd', 'file')
    sCurrDd = '';
    return;
end

if (atgcv_version_compare('TL3.3') < 0)
    sCurrDd = dsdd('GetEnv', 'ProjectFile');
else
    sCurrDd = dsdd('GetDDAttribute', 0, 'fileName');
end
if strcmpi(sCurrDd, 'untitled.dd')
    sCurrDd = '';
end
end


%%
function stOpt = i_checkSetOptions(varargin)
nArgs = length(varargin);
if (nArgs > 1)
    % LegacySupport for deprecated Interface
    % trafo interface: old --> new
    % mandatory args (1-4)
    stOpt = struct( ...
        'sDdPath',      varargin{1}, ...
        'sSlModel',     varargin{2}, ...
        'sTlModel',     varargin{3}, ...
        'sTlSubsystem', varargin{4});
    % args (4-5) not needed anymore --> just ignore
    % optional args (7-9)
    if (nArgs > 6)
        stOpt.bCalSupport = varargin{7};
    end
    if (nArgs > 7)
        stOpt.bDispSupport = varargin{8};
    end
    if (nArgs > 8)
        stOpt.bParamSupport = varargin{9};
    end
    if (nArgs > 9)
        error('ATGCV:INTERNAL:ERROR', 'Wrong usage: unexpected number of inputs.');
    end
else
    stOpt = varargin{1};
    if isempty(fieldnames(stOpt))
        stOpt = i_getDefaultArgs();
    end
end

% set default options
if ~isfield(stOpt, 'sToplevel')
    stOpt.sToplevel = '';
end
if ~isfield(stOpt, 'sTlModel')
    stOpt.sTlModel = '';
end
if ~isfield(stOpt, 'sDdPath')
    stOpt.sDdPath = '';
end
if ~isfield(stOpt, 'sSlModel')
    stOpt.sSlModel = '';
end
if ~isfield(stOpt, 'sTlSubsystem')
    stOpt.sTlSubsystem = '';
end
if ~isfield(stOpt, 'sAddModelInfo')
    stOpt.sAddModelInfo = '';
end
bProvidedModelTL = ~isempty(stOpt.sTlModel);
bProvidedModelSL = ~isempty(stOpt.sSlModel);
if (~isfield(stOpt, 'sModelMode') || isempty(stOpt.sModelMode))
    if (bProvidedModelSL && ~bProvidedModelTL)
        % special case: SL provided but no TL --> indicates SL-only use case
        stOpt.sModelMode = 'SL';
    else
        if ~isempty(stOpt.sAddModelInfo)
            % additional model info was provided --> SL-only use case
            stOpt.sModelMode = 'SL';
        else
            stOpt.sModelMode = 'TL';
        end
    end
end

% CAL support
% Note: Mode-String is always overriding the boolean Flags!
if (~isfield(stOpt, 'sCalMode') || isempty(stOpt.sCalMode))
    if ~isfield(stOpt, 'bCalSupport')
        stOpt.bCalSupport = false;
    end
    if ~isfield(stOpt, 'bParamSupport')
        if stOpt.bCalSupport
            stOpt.bParamSupport = false;
        else
            stOpt.bParamSupport = true;
        end
    end
    if stOpt.bCalSupport
        stOpt.sCalMode = 'limited';
    elseif stOpt.bParamSupport
        stOpt.sCalMode = 'explicit';
    else
        stOpt.sCalMode = 'none';
    end
else
    switch lower(stOpt.sCalMode)
        case 'explicit'
            stOpt.bCalSupport   = false;
            stOpt.bParamSupport = true;
            
        case 'limited'
            stOpt.bCalSupport   = true;
            stOpt.bParamSupport = false;
            
        case 'none'
            stOpt.bCalSupport   = false;
            stOpt.bParamSupport = false;
            
        otherwise
            error('ATGCV:INTERNAL:ERROR', 'Unknown CAL mode.');
    end
end

% DISP support
if (~isfield(stOpt, 'sDispMode') || isempty(stOpt.sDispMode))
    if ~isfield(stOpt, 'bDispSupport')
        stOpt.bDispSupport = true;
    end
    if (stOpt.bDispSupport)
        stOpt.sDispMode = 'all';
    else
        stOpt.sDispMode = 'none';
    end
else
    switch lower(stOpt.sDispMode)
        case 'all'
            stOpt.bDispSupport = true;
            
        case 'none'
            stOpt.bDispSupport = false;
            
        otherwise
            error('ATGCV:INTERNAL:ERROR', 'Unknown DISP mode.');
    end
end

% DSM support
if (~isfield(stOpt, 'sDsmMode') || isempty(stOpt.sDsmMode))
    stOpt.sDsmMode = 'all';
end

% Environment support
if (~isfield(stOpt, 'bAdaptiveAutosar') || isempty(stOpt.bAdaptiveAutosar))
    stOpt.bAdaptiveAutosar = false;
end

if (~isfield(stOpt, 'bAddEnvironment') || isempty(stOpt.bAddEnvironment))
end

% STATIC_CAL handling
if (~isfield(stOpt, 'bIgnoreStaticCal') || isempty(stOpt.bIgnoreStaticCal))
    stOpt.bIgnoreStaticCal = false;
end

% handling of CALs with Type Bitfield
if (~isfield(stOpt, 'bIgnoreBitfieldCal') || isempty(stOpt.bIgnoreBitfieldCal))
    stOpt.bIgnoreBitfieldCal = false;
end

% TLSim handling
if ~isfield(stOpt, 'bExcludeTLSim')
    stOpt.bExcludeTLSim = false;
end
clear atgcv_m01_module_check; % re-set the persistent variables
if stOpt.bExcludeTLSim
    atgcv_m01_module_check('EXCLUDE_TLSIM');
end

% check mandatory parameters
if (strcmp(stOpt.sModelMode, 'TL'))
    if (isempty(stOpt.sDdPath) || isempty(stOpt.sTlModel))
        stDef = i_getDefaultArgs('TL');
        if isempty(stOpt.sDdPath)
            stOpt.sDdPath = stDef.sDdPath;
        end
        if isempty(stOpt.sTlModel) 
            stOpt.sTlModel = stDef.sTlModel;
        end
        if isempty(stOpt.sTlSubsystem)
            if (isfield(stDef, 'sTlSubsystem') && ~isempty(stDef.sTlSubsystem))
                stOpt.sTlSubsystem = stDef.sTlSubsystem;
            end
        end
    end
    if isempty(stOpt.sDdPath)
        error('ATGCV:INTERNAL:ERROR', 'Path to DD has to be provided.');
    end
    if isempty(stOpt.sTlModel)
        error('ATGCV:INTERNAL:ERROR', 'Name of TL model has to be provided.');
    end
else
    if isempty(stOpt.sSlModel)
        stDef = i_getDefaultArgs('SL');
        stOpt.sSlModel = stDef.sSlModel;
    end
    if isempty(stOpt.sSlModel)
        error('ATGCV:INTERNAL:ERROR', 'Path to SL has to be provided.');
    end
end
stOpt.sTlModel = i_normalizeModelName(stOpt.sTlModel);
stOpt.sSlModel = i_normalizeModelName(stOpt.sSlModel);
end


%%
function sModel = i_normalizeModelName(sModel)
if isempty(sModel)
    return;
end
% remove path and extension if there are any
[~, sModel] = fileparts(sModel);
try
    % try to get Model handle just to check if name is consistent
    get_param(sModel, 'handle');
    
    % avoid problems with wrong case letters and use the name as
    % returned from the get_param() function
    sModel = get_param(sModel, 'name');
catch oEx
    sAlternativeModel = i_getClosestMatchFromException(oEx);
    if ~isempty(sAlternativeModel)
        sModel = sAlternativeModel;
    else
        error('ATGCV:MOD_ANA:INVALID_MODEL', 'Could not find model "%s".', sModel);
    end
end
end


%%
function sModel = i_getClosestMatchFromException(oEx)
sModel = '';
if (isempty(oEx) || ~strcmp(oEx.identifier, 'Simulink:Commands:InvSimulinkObjectName'))
    return;
end
if ~isempty(oEx.cause)
    oCauseEx = oEx.cause{1};
    if strcmp(oCauseEx.identifier, 'Simulink:Commands:BlockDiagramNotLoaded')
        sMsg = oCauseEx.message;
        casFound = regexp(sMsg, 'The closest match is ['']([^'']+).*', 'tokens', 'once');
        if ~isempty(casFound)
            sAlternativeModel = casFound{1};
            try
                sModel = get_param(sAlternativeModel, 'name');
            catch
                sModel = '';
            end
        end
    end
end
end

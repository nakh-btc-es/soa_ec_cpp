function atgcv_m46_add_expected_values(stEnv, sModel, sDebugModel)
% Enhances the debug model for showing expected values.
%
% function atgcv_m46_add_expected_values(stEnv, sModel, sDebugModel)

%   INPUT               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%     .sResultPath       (string)    Result directory for outputs
%   sModel               (string)    Name of the extraction model (without
%                                    path – assumed to be available in the
%                                    sExportDir)
%   sDebugModel         (string)     Debug model which contains
%                                    information about the outputs.
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
%   AUTHOR(S):
%     Frederik Berg
% $$$COPYRIGHT$$$-2015
%
%%

try
    hDebugModel = mxx_xmltree('load', sDebugModel);
    xDebugModel = mxx_xmltree('get_root', hDebugModel);
    sSampleTime = ep_em_entity_attribute_get( xDebugModel, 'sampleTime');
    
    sVars2Ws = ep_find_system(sModel, 'SearchDepth', 1, 'Name', 'Vars2Ws');  
    if isempty(sVars2Ws)
        return;
    end
    casPaths = ep_find_system(sVars2Ws, 'LookUnderMasks', 'all', ...
        'Tag', 'BtcToWorkspace');    
    
    [casPaths, casIfIds] = i_sortAccordingToIDs(casPaths);
    
    casSignalNames = cell(1,length(casPaths));
    casScopeHandles = cell(1,length(casPaths));
    for i=1:length(casPaths)
        sHandle = casPaths{i};
        sIfId   = casIfIds{i};
        
        % delete 'o_' from ifid
        sIfIdModelAna = sIfId(3:end);
                
        % only one ToWorkspace block assumed
        sExpectedIfId = ['expected_', sIfId];
        casIfIds{i} = sExpectedIfId;
        
        eval(sprintf('%s = [0 0 0];', sExpectedIfId));
        
        
        % get ifid entry from ModelAna
        xVariable = ep_em_entity_find( xDebugModel, sprintf(['.', ...
            '/Outputs/Outport[@ifid=''%s'']'], sIfIdModelAna));
        
        sSignalName = ep_em_entity_attribute_get( ...
            xVariable{1}, 'displayName');
        casSignalNames{i} = sSignalName;
        
        % add blocks we need: 
        %     1. From workspace
        sFromWS = 'expected_in';
        hFromWS = add_block('built-in/FromWorkspace', [sHandle, '/', sFromWS]);
        set_param(hFromWS, 'VariableName', sExpectedIfId);
        set_param(hFromWS, 'Position', [20 219 75 231]);
        set_param(hFromWS, 'BackgroundColor', 'Yellow');
        set_param(hFromWS, 'ShowName', 'off');
        
        %     2. Demux 
        sDemux = 'demux';
        hDemux = add_block('built-in/Demux', [sHandle, '/', sDemux]);
        set_param(hDemux, 'Position', [145 193 150 257]);
        set_param(hDemux, 'Outputs', '2');
        set_param(hDemux, 'ShowName', 'off');
        
        %     3. Constant NaN
        sConst = 'const_nan';
        hConst = add_block('built-in/Constant', [sHandle, '/', sConst]);
        set_param(hConst, 'Position', [60 255 90 285]);
        set_param(hConst, 'Value', 'NaN');
        set_param(hConst, 'ShowName', 'off');
        
        %     4. Switch Block
        sSwitch = 'switch';
        hSwitch = add_block('built-in/Switch', [sHandle, '/', sSwitch]);
        set_param(hSwitch, 'Position', [260 197 315 283]);
        set_param(hSwitch, 'ShowName', 'off');
        set_param(hSwitch, 'Criteria', 'u2 ~= 0');
        
        if( ~isempty( sSampleTime ) )
            set_param( hFromWS, 'SampleTime', sSampleTime);
            set_param( hConst, 'SampleTime', sSampleTime);
        end
        %     5. Data Type Conversion
        sDTC = 'cast';
        hDTC = add_block('built-in/DataTypeConversion', [sHandle, '/', sDTC]);
        set_param(hDTC, 'Position', [125 133 200 167]);
        sSignalType = 'double';
        set_param(hDTC,'OutDataTypeStr', sSignalType);
        
        %     6. Mux 
        sMux = 'mux';
        hMux = add_block('built-in/Mux', [sHandle, '/', sMux]);
        set_param(hMux, 'Position', [400 158 405 222]);
        set_param(hMux, 'Inputs', '2');
        %     7. Scope
        hScope = add_block('built-in/Scope', [sHandle, '/', sSignalName]);
        set_param(hScope, 'Position', [465 165 515 215]);
        casScopeHandles{i} = getfullname(hScope);
        
        sSignalType = 'double';
        set_param(hDTC,'OutDataTypeStr', sSignalType);

        % connect blocks
        add_line(sHandle, [sFromWS '/1'], [sDemux '/1']);
        add_line(sHandle, [sDemux '/1'], [sSwitch '/1']);
        add_line(sHandle, [sDemux '/2'], [sSwitch '/2']);
        add_line(sHandle, [sConst '/1'], [sSwitch '/3']);
        hExpSig = add_line(sHandle, [sSwitch '/1'], [sMux '/2']);
        set_param(hExpSig, 'Name', 'expected');
        add_line(sHandle, ['btc_in' '/1'], [sDTC '/1']);
        hSimSig = add_line(sHandle, [sDTC '/1'], [sMux '/1']);
        set_param(hSimSig, 'Name', 'simulated');
        add_line(sHandle, [sMux '/1'], [sSignalName '/1']);
        
    end
    
    hVars2Ws = [sModel, '/Vars2Ws'];
    i_maskVars2WsSub(hVars2Ws, casSignalNames, casScopeHandles);
    
    % create dummy output mat file
    sMatFile = fullfile(pwd, 'expected_dummy.mat');
    save(sMatFile, casIfIds{:});
catch exception
    osc_messenger_add(stEnv, ...
        'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
        'step', 'expected value enhancement', ...
        'descr', exception.message );
end
end




%% internal functions


function [casPaths, casIfIds] = i_sortAccordingToIDs(casPaths)
casIfIds = cell(size(casPaths));
if isempty(casPaths)
    return;
end

aiID = zeros(size(casPaths));
for i = 1:length(casPaths)
    % every name should follow the following schema: o_ifXXX (with XXX = IntVal)
    [~, sName] = fileparts(casPaths{i});
    aiID(i) = sscanf(sName, 'o_if_%d');    
    casIfIds{i} = sName;
end

[~, aiSortIdx] = sort(aiID);
casPaths = casPaths(aiSortIdx);
casIfIds = casIfIds(aiSortIdx);
end


function i_maskVars2WsSub(hBlock, casSignalNames, casScopeHandles)
set_param(hBlock, 'Mask', 'on');

sPromptString = i_createVariablesString(casSignalNames);
set_param(hBlock, 'MaskPromptString', sPromptString);
sCheckbox = 'checkbox,';
sStyleString = repmat(sCheckbox, 1, length(casSignalNames));
if ~isempty(sStyleString)
    sStyleString = sStyleString(1:end-1);
end
sOff = 'off|';
sOffs = repmat(sOff, 1, length(casSignalNames));
if ~isempty(sOffs)
    sOffs = sOffs(1:end-1);
end
set_param(hBlock, 'MaskStyleString', sStyleString);
set_param(hBlock, 'MaskValueString', sOffs);
set_param(hBlock, 'MaskDisplay', 'disp(''Double-click to select\nsignals for comparison'')');
set_param(hBlock, 'MaskType', 'Signal Selection');
set_param(hBlock, 'MaskDescription', 'Select signals for comparison. For each selected signal a Scope plot is opened when a simulation is started');



sStartFcn = i_createFcnString(hBlock, casScopeHandles, 'on', 'open');
set_param(hBlock, 'StartFcn', sStartFcn);

sInitialization = i_createFcnString(hBlock, casScopeHandles, 'off', 'close');
set_param(hBlock, 'MaskInitialization', sInitialization);

% beautifying for ML versions greater or equal 2013b
if atgcv_version_compare('ML8.2') >= 0
    oMask = Simulink.Mask.get(hBlock);
    oCtrl = oMask.getDialogControl('ParameterGroupVar');
    if ~isempty(oCtrl)
        oCtrl.Prompt = '';
    end
end

end

function sFcn = i_createFcnString(hBlock, casScopeHandles, sValue, sCmd)
sFcn = '';
casMaskNames = get_param(hBlock, 'MaskNames');
for i=1:length(casScopeHandles)
    sScopeHandle = casScopeHandles{i};
    sScopePart = sprintf('if strcmp(get_param(''%s'', ''%s''), ''%s'') %s_system(''%s''); end;', ...
        hBlock, casMaskNames{i}, sValue, sCmd, sScopeHandle);
    sFcn = [sFcn, sScopePart]; %#ok<AGROW>
end

end


function sPromptString = i_createVariablesString(casSignalNames)
sPromptString = '';
for i=1:length(casSignalNames)
    sSignalName = casSignalNames{i};
    sPromptString = [sPromptString, sSignalName, '|']; %#ok<AGROW>
end
%delete last '|' from PromptString
if ~isempty(sPromptString)
    sPromptString = sPromptString(1:end-1);
end
end

function ep_core_highlight_sl_system(varargin)
% Highlights a specifiy block from a Simulink system
%
% ep_core_highlight_sl_system(varargin)
%
%   INPUT
%    - varargin           ([Key, Value]*)        Key-value pairs with the following
%                                                possibles values. Inputs marked with (*)
%                                                are mandatory.
%
%       Key(string):                             Meaning of the Value:
%           ModelFile*      (String)              Absolute file path to the model.
%           BlockPath*      (String or            Absolute SL Path(s) to the block which has to be highlighted.
%                           cell array of Strings)             
%   OUTPUT
%       -

%%
try
    sPwd = pwd;
    % Parser input parameters
    stArgs = i_evalArgs(varargin{:});
    
    [sPath, sModelName] = fileparts( stArgs.sModelFile );
    cd(sPath);
    i_assureModelIsLoaded(stArgs.sModelFile);
    if i_isModelLoaded(sModelName)
        % disable highlighting for previous blocks
        caBlocks = find_system(bdroot, 'LookUnderMasks', 'on', 'FollowLinks', 'on', 'HiliteAncestors', 'default');
        cellfun(@(block) set_param(block, 'HiliteAncestors', 'off'), caBlocks);

        paths = stArgs.sBlockPath;
        if iscell(paths) == 1
             hilite_system(stArgs.sBlockPath);
        else
             slprofile_hilite_system('encoded-path', paths);
        end
    end
    cd(sPwd);
catch exception
    cd(sPwd);
    rethrow(exception);
end
end


%%
function stArgs = i_evalArgs(varargin)
stArgs = struct( ...
    'sModelFile', '', ...
    'sBlockPath', '');

casValidKeys = {'ModelFile', 'BlockPath'};
stArgsTmp = ep_core_transform_args(varargin, casValidKeys);

% mainly a re-mapping to new fields
stKeyMap = struct('ModelFile', 'sModelFile', 'BlockPath', 'sBlockPath');

casKnownKeys = fieldnames(stKeyMap);
for i = 1:length(casKnownKeys)
    sKey = casKnownKeys{i};
    if isfield(stArgsTmp, sKey)
        stArgs.(stKeyMap.(sKey)) = stArgsTmp.(sKey);
    end
end
end


%%
function i_assureModelIsLoaded(sModelFile)

[sPath, sModelName, sExt] = fileparts(sModelFile);
bModelIsLoaded = i_isModelLoaded(sModelName);

if ~bModelIsLoaded && exist(sModelFile, 'file')
    % load main model
    load_system(sModelFile);
end

% Load model references
if i_isModelLoaded(sModelName)
    casModelRefs = ep_find_mdlrefs(sModelName);
    casModelRefs(end) = []; % delete last model ref (always the main model itself)
    
    for i = 1:length(casModelRefs)
        if i_isModelLoaded(casModelRefs{i})
            % Model is loaded, continue with next model
            continue;
        end
        
        sModelRefFile = which([casModelRefs{i}, sExt]);
        if ~isempty(sModelRefFile)
            % File was found in matlab path, try to open
            i_assureModelIsLoaded(sModelRefFile);
        else
            % Look at the location of the original model
            sModelRefFile = fullfile(sPath, [casModelRefs{i}, sExt]);
            if exist(sModelRefFile, 'file')
                i_assureModelIsLoaded(sModelRefFile);
            end
        end
    end
end
end


%%
function bModelIsLoaded = i_isModelLoaded(sModelName)
bModelIsLoaded = bdIsLoaded(sModelName);
end
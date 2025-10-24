function astSignals = atgcv_m01_block_output_signals_get(stEnv, hBlock, iPort, bWithVarInfo)
% Get info about all outputs of a provided DD "Block" handle.
%
% function astSignals = atgcv_m01_block_output_signals_get(stEnv, hBlock, iPort, bWithVarInfo)
%
%   INPUT               DESCRIPTION
%     stEnv              (struct)   error messenger environment
%     hBlock             (handle)   DD handle of model block
%     iPort              (integer)  port number of output port
%                                   (optional: if not given, _all_ output signals of all output ports are returned)
%     bWithVarInfo       (boolean)  return additional info about ref variable (optional: default = true)
%
%   OUTPUT              DESCRIPTION
%      astSignals        (array)    of structs with the following fields
%        .hBlockVar      (handle)     DD handle of output BlockVariable
%        .sSignalName    (string)     signal name of output BlockVariable
%        .hVariableRef   (handle)     reference to variable in C-code
%        .iWidth         (integer)    width of the Signal
%        .aiElements     (integer)    array of non-neg integer C-Indexes referring to the C-Variable
%                                     (usually used for "slices", i.e.  may be empty if the Variable is a 
%                                     Scalar or if all elements of the Variable are used)
%        .bIsDummyVar    (boolean)    if TRUE, the signal is a dummy variable
%        .bIsMacro       (boolean)    if TRUE, the signal is represented by a C-Macro
%        .bIsRDI         (boolean)    If true, the signal is a RDI interface
%        .stVarInfo      (struct)     info about ref variable (only non-empty if bWithVarInfo == true)
%        .astInstanceSigs (array)     of structs with the same fields as
%               ...                   the main "astSignals"
%                                     [used since TL4.0 for multiple instances of the same MIL Signal as
%                                     different C-Code Variables]
%


%% check inputs
hBlock = i_checkNormalizeBlockHandle(hBlock);
if (nargin < 3)
    iPort = [];
end
if (nargin < 4)
    bWithVarInfo = true;
end

ahBlockVars = i_getToplevelOutputBlockVars(stEnv, hBlock, iPort);
if ~isempty(ahBlockVars)
    hFunc = @(x) atgcv_m01_blockvar_signals_get(stEnv, x, bWithVarInfo);
    astSignals = cell2mat(arrayfun(hFunc, ahBlockVars, 'UniformOutput', false));
else
    astSignals = [];
end
end


%%
function ahOutBlockVars = i_getToplevelOutputBlockVars(stEnv, hBlock, iPort)
% get all blockvars and then filter out just the topelvel vars
ahOutBlockVars = atgcv_mxx_dsdd(stEnv, 'Find', hBlock, 'regExp', 'output');
ahOutBlockVars2 = atgcv_mxx_dsdd(stEnv, 'Find', hBlock, 'regExp', 'output[(].*'); % output(#XXX)
if ~isempty(ahOutBlockVars2)
    ahOutBlockVars = [reshape(ahOutBlockVars, 1, []), reshape(ahOutBlockVars2, 1, [])];
end

ahParents = arrayfun(@(x) dsdd('GetAttribute', x, 'hDDParent'), ahOutBlockVars);
abIsToplevel = ahParents == hBlock;
ahOutBlockVars = ahOutBlockVars(abIsToplevel);

% also if only one particular Port is asked for, filter that one out
if ((nargin > 2) && ~isempty(iPort))
    if (iPort < 2)
        sMatch = '^output$';
    else
        sPort = sprintf('output(#%i)', iPort);
        sMatch = ['^', regexptranslate('escape', sPort), '$'];
    end
    for i = 1:length(ahOutBlockVars)
        sName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', ahOutBlockVars(i), 'Name');
        if ~isempty(regexp(sName, sMatch, 'once'))
            ahOutBlockVars = ahOutBlockVars(i);
            return;
        end
    end
end
end


%% 
function hBlock = i_checkNormalizeBlockHandle(hBlock)
[bExist, hBlock] = dsdd('Exist', hBlock, 'objectKind', 'Block');
if ~bExist
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Argument is not a valid Block handle.');
end
end


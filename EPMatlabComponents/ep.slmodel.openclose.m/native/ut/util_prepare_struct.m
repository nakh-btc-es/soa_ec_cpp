%%
% function stArgs = util_prepare_struct(stEnv, sModelFile, caInitScripts, bIsTL, ...
%     bCheck, casAddPaths, bActivateMil, bIgnoreInitScriptFail, bIgnoreAssertModelKind)
%
function stArgs = util_prepare_struct(sModelFile, caInitScripts, casAddPaths, varargin)
stArgs = struct( ...
    'sModelFile',             sModelFile, ...
    'caInitScripts',          {{}}, ...
    'bCheck',                 false, ...
    'casAddPaths',            {casAddPaths}, ...
    'bActivateMil',           true, ...
    'bIgnoreInitScriptFail',  false, ...
    'bIgnoreAssertModelKind', false, ...
    'bEnableBusObjectLabelMismatch', false);

% to support legacy usage also handle the cases
%  caInitScripts == ''
%  caInitScripts == []
if isempty(caInitScripts)
    stArgs.caInitScripts = {};
elseif ~iscell(caInitScripts)
    stArgs.caInitScripts = {caInitScripts};
else
    % 1) get abs path for every script
    % 2) legacy stuff: remove things like {''}
    abSelect = true(size(caInitScripts));
    for i = 1:length(caInitScripts)
        if isempty(caInitScripts{i})
            abSelect(i) = false;
        else
            caInitScripts{i} = atgcv_canonical_path(caInitScripts{i});
        end
    end
    stArgs.caInitScripts = caInitScripts(abSelect);
end

% handle the optional arguments
caxOpt = varargin;
nOpt = length(caxOpt);
if (nOpt < 1)
    return;
end
stArgs.bCheck = caxOpt{1};

if (nOpt < 2)
    return;
end
stArgs.casAddPaths = caxOpt{2};

if (nOpt < 3)
    return;
end
stArgs.bActivateMil = caxOpt{3};

if (nOpt < 4)
    return;
end
stArgs.bIgnoreInitScriptFail = caxOpt{4};

if (nOpt < 5)
    return;
end
stArgs.bIgnoreAssertModelKind = caxOpt{5};

if (nOpt < 6)
    return;
end
stArgs.bEnableBusObjectLabelMismatch = caxOpt{6};
end

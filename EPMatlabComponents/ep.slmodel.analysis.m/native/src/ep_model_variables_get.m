function aoVars = ep_model_variables_get(xModelContext, sSearchMethod, bIncludeModelWs, casFilterKeyVals)
% Returns all variables from the base/model WS and SLDD that are used in the provided model context (e.g. model or some subsytem). 
%
% function aoVars = ep_model_variables_get(xModelContext, sSearchMethod, bIncludeModelWs, casFilterKeyVals)
%
%   INPUT               DESCRIPTION
%       sModelContext      (handle/string)  path/handle of model or subsystem block
%       sSearchMethod      (string)         optional: 'compiled' | 'cached' (default=cached)
%       bIncludeModelWs    (boolean)        optional: include MWP if set (default=false)
%       casFilterKeyVals   (cell)           optional: key-value pairs as accepted by Simulink.findVars ...
%                                           {<key1>, <val1>, <key2>, <val2>, ...}
%
%
%   OUTPUT              DESCRIPTION
%       aoVars             (array)          all found variables as objects of kind Simulink.VariableUsage
%
%   REMARKS
%       This is more or less a wrapper for Simulink.findVars().
%       The main advantage of using this function instead of "Simulink.findVars" directly is the handling
%       of the search method "cached". Here, a fallback mechanism is implemented that re-directs the search
%       to the method "compiled" when encountering problems.
%


%%
if (nargin < 1)
    xModelContext = bdroot(gcs);
end
if (nargin < 2)
    sSearchMethod = 'cached';
end
if (nargin < 3)
    bIncludeModelWs = false;
    casFilterKeyVals = {};
end
if (nargin < 4)
    casFilterKeyVals = {};
end

%%
if isempty(xModelContext)
    error('EP:USAGE_ERROR', 'A valid model name has to be provided.');
else
    try
        hModelContext = get_param(xModelContext, 'handle');
        sModelContext = getfullname(hModelContext);
    catch
        if ischar(xModelContext)
            error('EP:USAGE_ERROR', 'Provided model context "%s" is not valid.', xModelContext);
        else
            error('EP:USAGE_ERROR', 'Provided model context is not valid.');
        end
    end
end


%% check/set inputs
% Note: stEnv is not used since currently messages are not produced
if ~strcmp(sSearchMethod, 'compiled')
    hSearchFunc = @i_findVarsCached;
else
    hSearchFunc = @i_findVarsCompiled;
end
aoGlobalVars = [ ...
    feval(hSearchFunc, sModelContext, 'SourceType', 'base workspace', casFilterKeyVals{:}); ...
    feval(hSearchFunc, sModelContext, 'SourceType', 'data dictionary', casFilterKeyVals{:})];

if bIncludeModelWs
    aoLocalVars = feval(hSearchFunc, sModelContext, ...
        'SourceType',             'model workspace', ...
        'SearchReferencedModels', 'on', ...
        casFilterKeyVals{:});
    aoVars = vertcat(aoGlobalVars, aoLocalVars);
else
    aoVars = aoGlobalVars;
end
end


%%
function aoVars = i_findVarsCached(varargin)
try
    aoVars = Simulink.findVars(varargin{:}, 'SearchMethod', 'cached');
catch oEx %#ok<NASGU>
    aoVars = i_findVarsCompiled(varargin{:});
end
end


%%
function aoVars = i_findVarsCompiled(varargin)
aoVars = [];
try
    aoVars = Simulink.findVars(varargin{:});
catch oEx
    if (nargin > 0)
        sModel = bdroot(varargin{1});
        if atgcv_m01_compile_exceptions_handle(sModel, oEx)
            aoVars = Simulink.findVars(varargin{:});
        end
    end
end
end

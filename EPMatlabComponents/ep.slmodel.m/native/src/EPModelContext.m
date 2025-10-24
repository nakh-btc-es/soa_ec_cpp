classdef EPModelContext
    % Class handling the view on symbols (e.g. Signals, Types, ...) in a specfic model context.
    properties (Hidden = true, Access = private)
        hModelHandle_
        hContextHandle_
        sModelPath_
        oModelWorkspace_
    end
    
    methods (Static = true)
        function oObj = get(xModelContext)
            % Constructor for a model context.
            [hContextHandle, bIsValid] = i_getHandle(xModelContext);
            if ~bIsValid
                error('EP:ERROR:INVALID_MODEL_CONTEXT', 'Provided model context is not valid.');
            end
            oObj = EPModelContext(hContextHandle);
        end
    end
    
    methods
        %%
        function [xVar, nScope] = getVariable(oObj, sVarName)
            % Return the variable value if the variable is existing in model or global workspace (maks workspaces are not considered!).
            %
            % [xVar, nScope] = EPModelContext.getVariable(sVarName)
            %
            %  INPUT
            %     sVarName      (string)   the name of the variable
            %
            %  OUTPUT
            %     xVar          (xxx)      the value of the variable (type depends on the variable)
            %     nScope        (int)      0 --- variable does not exist
            %                              1 --- variable does exist and is global (base or DD workspace)
            %                              2 --- variable does exist and is local (model workspace).
            %
            [xVar, bExist] = ep_core_workspace_variable_get(oObj.oModelWorkspace_, sVarName);
            if bExist
                nScope = 2;
            else
                [xVar, bExist] = i_globalVariableGet(getfullname(oObj.hModelHandle_), sVarName);
                if bExist
                    nScope = 1;
                else
                    nScope = 0;
                end
            end
        end
        
        %%
        function xResult = resolve(oObj, sExpression)
            % Resolve an expression as "seen" from a model context (mask workspaces are considered!).
            %
            % xResult = EPModelContext.resolve(sExpression)
            %
            %  INPUT
            %     sExpression   (string)  some expression containing symbols (mostly just a variable name)
            %
            %  OUTPUT
            %     xResult       (xxx)     the result of the evaluation (type depends on the expression)
            %
            xResult = slResolve(sExpression, oObj.hContextHandle_);
        end
        
        %%
        function varargout = evalinLocal(oObj, sExpression)
            % Evaluate an expression inside the local model workspace (mask workspaces are not considered!).
            %
            % varargout = EPModelContext.evalinLocal(sExpression)
            %
            %  INPUT
            %     sExpression   (string)  some expression may contain symbols
            %
            %  OUTPUT
            %     varargout       (xxx)   the result of the evaluation (number and type(s) depend on the expression)
            %
            if isempty(oObj.oModelWorkspace_)
                error('EP:ERROR:NO_LOCAL_WORKSPACE', 'Model context has no local model workspace.');
            else
                [varargout{1:nargout}] = oObj.oModelWorkspace_.evalin(sExpression);
            end
        end
        
        %%
        function varargout = evalinGlobal(oObj, sExpression)
            % Evaluate an expression inside the global workspace (base or DD).
            %
            % varargout = EPModelContext.evalinGlobal(sExpression)
            %
            %  INPUT
            %     sExpression   (string)  some expression that may contain symbols
            %
            %  OUTPUT
            %     varargout      (xxx)    the result of the evaluation (number and type(s) depend on the expression)
            %
            [varargout{1:nargout}] = ep_core_evalin_global(getfullname(oObj.hModelHandle_), sExpression);
        end
        
        %%
        function bIsValid = isValid(oObj)
            % Check if model context is still valid (i.e. corresponding model is still in memory).
            %
            % bIsValid = EPModelContext.isValid()
            %
            [~, bIsValid] = i_getHandle(oObj.hContextHandle_);
        end
    end
    
    methods (Hidden = true)
        function disp(oObj)
            fprintf('ModelContext for "%s"\n', oObj.sModelPath_);
        end
    end
    
    methods (Access = private)
        function oObj = EPModelContext(hContextHandle)
            oObj.hModelHandle_ = bdroot(hContextHandle);
            oObj.hContextHandle_ = hContextHandle;
            oObj.sModelPath_ = getfullname(hContextHandle);
            oObj.oModelWorkspace_ = get_param(oObj.hModelHandle_, 'modelworkspace');
        end
    end
end



%%
function [hModelHandle, bIsValid] = i_getHandle(xModelContext)
try
    hModelHandle = get_param(xModelContext, 'handle');
    bIsValid = true;
catch
    hModelHandle = [];
    bIsValid = false;
end
end


%%
function [xVar, bExist] = i_globalVariableGet(sModelName, sVarName)
bExist = ep_core_evalin_global(sModelName, sprintf('exist(''%s'', ''var'')', sVarName));
if bExist
    xVar = ep_core_evalin_global(sModelName, sVarName);
else
    xVar = [];
end
end

function bSuccess = atgcv_m01_compile_exceptions_handle(sModelName, oEx)
% Try to handle exception that can occur when the model is brought into the compiled mode.
%
% function bSuccess = atgcv_m01_compile_exceptions_handle(sModelName, oEx)
%
%   INPUT               DESCRIPTION
%     sModelName         (string)      the name of the model that caused the exception
%     oEx                (object)      the MException that was caused
%
%   OUTPUT              DESCRIPTION
%     bSuccess           (boolean)     flag if the handling process was successful
%
%   <et_copyright>


%%
bSuccess = false;
if (isempty(oEx) || ~isa(oEx, 'MSLException'))
    return;
end

switch oEx.identifier
    case {'Simulink:slbuild:unsavedMdlRefs', 'Simulink:slbuild:unsavedMdlRefsWorkspc'}
        bSuccess = i_handleUnsavedMdlRefsException(sModelName, oEx);
end

for i = 1:length(oEx.cause)
    bSubSuccess = atgcv_m01_compile_exceptions_handle(sModelName, oEx.cause{i});
    bSuccess = bSuccess || bSubSuccess;
end
end


%%
function bSuccess = i_handleUnsavedMdlRefsException(sModelName, oEx) %#ok<INUSD>
casMdlRefs = i_getModelRefsFromModel(sModelName);
%casMdlRefs = i_getModelRefsFromMessage(oEx);

if ~isempty(casMdlRefs)
    % remove the original model from the list
    casMdlRefs(strcmpi(casMdlRefs, sModelName)) = [];
end

bSuccess = ~isempty(casMdlRefs);
for i = 1:length(casMdlRefs)
    sModelRef = casMdlRefs{i};
    if ~isempty(find_system('name', sModelRef))
        oModelRef = get_param(sModelRef, 'object');
        oModelRef.refreshModelBlocks;
        save_system(sModelRef);
    end
end
end


%%
function casMdlRefs = i_getModelRefsFromModel(sModelName)
casMdlRefs = ep_find_mdlrefs(sModelName);
end


%%
% maybe better alternative to getting all ModelRefs?
function casMdlRefs = i_getModelRefsFromMessage(oEx) %#ok<DEFNU>
% Exception message has the Pattern
%  "Can not update the model reference target of <NameOfModelRef> ..."
casFound = regexp(oEx.message, 'model reference target of (\w+)', 'tokens', 'once');
if ~isempty(casFound)
    casMdlRefs = casFound(1);
else
    casMdlRefs = {};
end
end



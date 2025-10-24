function [casCodeScopes, bFoundSharedFuncs] = ep_scope_code_paths_get(astSubsystems)
% Determine the code paths (call stacks) for the provided scopes.
%
% [casCodeScopes, bFoundSharedFuncs] = ep_scope_code_paths_get(astSubsystems)
%
%   INPUT               DESCRIPTION
%    - astSubsystems        (array)    structs with the following info
%        .sModuleName       (string)       name of the file where the step function is defined
%        .sStepFunc         (string)       name of the step function
%        .iParentIdx        (num)          index of the parent subsystem
%
%   OUTPUT              DESCRIPTION
%    - casCodeScope         (cell)     code paths for the provided subsystems (in the same order as the input array)
%    - bFoundSharedFunc     (boolean)  true if "shared function"s have been found among the subsystems
%
%
%   !! REMARK:
%          1) Algo is only valid if the order of the Subsystems is always "parent before child".
%             Otherwise a sorting needs to be implemented!
%
%          2) Also DUMMY scopes without any info about Functions can be provided; in this case the corresponding path
%             is returned as an empty string.
%
%
% $$$COPYRIGHT$$$
%

%%
bFoundSharedFuncs = false;

% count the names to find shared functions
oCountName = containers.Map();

% count the paths to see if the counter inside the name needs to be increased
oCountFirstPath = containers.Map();

nScopes = length(astSubsystems);
casCodeScopes = cell(1, nScopes);
for i = 1:nScopes
    stSub = astSubsystems(i);
    if (stSub.bIsDummy || ~stSub.bHasMilSupport) 
        casCodeScopes{i} = '';
    else
        sTryName = sprintf('%s:1:%s', stSub.sModuleName, stSub.sStepFunc);
        if oCountName.isKey(sTryName)
            bFoundSharedFuncs = true;
            nNewCount = oCountName(sTryName) + 1;
            oCountName(sTryName) = nNewCount;
        else
            oCountName(sTryName) = 1;
        end

        sParentPath = '';
        if ~isempty(stSub.iParentIdx)
            sParentPath = casCodeScopes{stSub.iParentIdx}; % assume: (stSub.iParentIdx < i)
        end
        
        % Note1: hidden subsystem do no contribute to the stack path; 
        %        instead they formally inherit the stack path of their parent
        % Note2: they also do no enter into the counting of shared subsystems
        if i_is_hidden(stSub)
            sPath = sParentPath;
        else
            sPath = i_path_name_concat(sParentPath, sTryName);
            if bFoundSharedFuncs
                if oCountFirstPath.isKey(sPath)
                    nNewCount = oCountFirstPath(sPath) + 1;
                    oCountFirstPath(sPath) = nNewCount;
                    
                    % NOTE: this is the case where we need to rename the function
                    % due to multiple calls from the same parent function
                    sRealName = sprintf('%s:%d:%s', stSub.sModuleName, nNewCount, stSub.sStepFunc);
                    sPath = i_path_name_concat(sParentPath, sRealName);
                else
                    oCountFirstPath(sPath) = 1;
                end
            else
                oCountFirstPath(sPath) = 1;
            end
        end
        casCodeScopes{i} = sPath;
    end
end
end


%%
function sFullPath = i_path_name_concat(sPath, sName)
if isempty(sPath)
    sFullPath = sName;
else
    sFullPath = [sPath, '/', sName];
end
end


%%
function bIsHidden = i_is_hidden(stObject)
bIsHidden = i_get_field(stObject, 'bIsHidden', false);
end


%%
function xValue = i_get_field(stStruct, sField, xDefaultValue)
if isfield(stStruct, sField)
    xValue = stStruct.(sField);
else
    if (nargin > 2)
        xValue = xDefaultValue;
    else
        xValue = [];
    end
end
end




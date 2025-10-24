function astConsts = ep_tldd_constants_get(stEnv)
% get all constants and macros from the Pool within a data dictionary
%
% function astConsts = ep_tldd_constants_get(stEnv)
%
%   INPUT           DESCRIPTION
%     stEnv             (struct)       environment structure
%
%   OUTPUT          DESCRIPTION
%       astConsts       (arr. of st.)  Constants in struct array representation
%           .sName      (string)       Name of the constant
%           .xValue     (numeric)      Value of the constant
%


%% main
if (nargin < 1)
    stEnv = 0;
end

astConsts = [];
% check for the existence of the /Pool section
[bExist, hPool] = dsdd('Exist', '/Pool');
if bExist
    astConsts = i_getAllConsts(stEnv, hPool);
end
end


%%
function astConsts = i_getAllConsts(stEnv, hPool)
ahConsts = [];
ahConstVarClasses = atgcv_mxx_dsdd(stEnv, 'Find', hPool, ...
    'ObjectKind', 'VariableClass', ...
    'Property',   {'name', 'Const', 'value', 'true'});
ahReadOnlyVarClasses = atgcv_mxx_dsdd(stEnv, 'Find', hPool, ...
    'ObjectKind', 'VariableClass', ...
    'Property',   {'name', 'Info', 'value', 'readonly'});
ahNoInfoVarClasses = atgcv_mxx_dsdd(stEnv, 'Find', hPool, ...
    'ObjectKind', 'VariableClass', ...
    'Property',   {'name', 'Info', 'value', 'none'});
ahConstNoInfoClasses = intersect(ahConstVarClasses, ahNoInfoVarClasses);
ahConstReadOnlyClasses = intersect(ahConstVarClasses, ahReadOnlyVarClasses);
ahConstVarClasses = union(ahConstNoInfoClasses, ahConstReadOnlyClasses);

for i = 1:length(ahConstVarClasses)
    sClassName = dsdd('GetAttribute', ahConstVarClasses(i), 'Name');
    ahFound = atgcv_mxx_dsdd(stEnv, ...
        'find',         hPool, ...
        'ObjectKind',   'Variable', ...
        'Property',     {'name', 'Class', 'value', sClassName});
    ahConsts = [ahConsts, ahFound]; %#ok<AGROW>
end

%pre-initialize astConsts as an empty struct array
astConsts = struct( ...
    'sName',    {}, ...
    'xValue',   {});
oNameSet = java.util.HashSet;
for j = 1:length(ahConsts)
    nWidth = prod(dsdd('GetWidth', ahConsts(j)));
    if(nWidth <= 1)
        sPathInDd = dsdd('GetAttribute', ahConsts(j), 'Path');
        xValue = ddv(sPathInDd);
        if isnumeric(xValue) && ~isempty(xValue)
            sName = dsdd('GetAttribute', ahConsts(j), 'Name');
            if(~oNameSet.contains(sName) && ~isempty(sName))
                oNameSet.add(sName);
                astConsts(end+1) = struct('sName', sName, 'xValue', xValue); %#ok<AGROW>
            end
        end
    end
end
end


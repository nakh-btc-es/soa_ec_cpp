function aoItfs = getInterfaces(oScope, casKinds, bIncludeDescendants)
% returns interfaces of the provided scope (and optionally of the scope descendants)
%

%%
if (nargin < 2)
    casKinds = {'in', 'out', 'param', 'local'};
else
    casKinds = cellstr(casKinds);
end
if (nargin < 3)
    bIncludeDescendants = false;
end

aoItfs = i_getInterfaces(oScope, casKinds);
if bIncludeDescendants
    aoDescScopes = oScope.getDescendants();
    if ~isempty(aoDescScopes)
        for i = 1:numel(aoDescScopes)
            aoItfs = [aoItfs, i_getInterfaces(aoDescScopes(i), casKinds)]; %#ok<AGROW>
        end
    end
end
end


%%
function aoItfs = i_getInterfaces(oScope, casKinds)
aoItfs = [];
for i = 1:numel(casKinds)
    switch casKinds{i}
        case 'in'
            aoItfs = [aoItfs, oScope.oaInputs]; %#ok<AGROW>
            
        case 'out'
            aoItfs = [aoItfs, oScope.oaOutputs]; %#ok<AGROW>
            
        case 'param'
            aoItfs = [aoItfs, oScope.oaParameters]; %#ok<AGROW>
            
        case 'local'
            aoItfs = [aoItfs, oScope.oaLocals]; %#ok<AGROW>            
    end
end
end

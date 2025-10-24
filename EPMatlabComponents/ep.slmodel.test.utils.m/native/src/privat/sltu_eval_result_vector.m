function [stVector, sSimStatus] = sltu_eval_result_vector(sResultVector, casIfidsWhitelist)
% Utility function to gather all relevant infos from the extraction XML.
%

%%
if (nargin < 2)
    bReturnAllSignals = true;
else
    bReturnAllSignals = false;
end

%%
stVector = struct();
sSimStatus = '';

%%
if ~exist(sResultVector, 'file')
    MU_FAIL(sprintf('Result vector "%s" not found.', sResultVector));
    return;
end

%%
hDoc = mxx_xmltree('load', sResultVector);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

hSimStatus = mxx_xmltree('get_nodes', hDoc, '/TestVector/SimStatus');
if ~isempty(hSimStatus)
    sSimStatus = mxx_xmltree('get_attribute', hSimStatus, 'status');
end

ahObjects = mxx_xmltree('get_nodes', hDoc, '/TestVector/Outputs/Object[@matFile]');
for i = 1:length(ahObjects)
    hObj = ahObjects(i);
    
    sIfid = mxx_xmltree('get_attribute', hObj, 'ifid');
    if (bReturnAllSignals || any(strcmpi(sIfid, casIfidsWhitelist)))
        sMatFile = mxx_xmltree('get_attribute', hObj, 'matFile');
        stVector.(sIfid) = i_getSamples(sMatFile, sIfid);
    end    
end
end


%%
function adData = i_getSamples(sMatFile, sIfid)
adData = [];
if ~isempty(sMatFile)
    if exist(sMatFile, 'file')
        stData = load(sMatFile);
        if isfield(stData, sIfid)
            adData = stData.(sIfid);
            [nRows, ~] = size(adData);
            MU_ASSERT_TRUE(nRows == 2, 'Data shall have two rows: one for time and one for values.');
        else
            MU_FAIL('Variable %s was not found in file "%s".', sIfid, sMatFile);
        end
        
    else
        MU_FAIL(sprintf('Referenced mat-File "%s" was not found.', sMatFile));
    end
end
end

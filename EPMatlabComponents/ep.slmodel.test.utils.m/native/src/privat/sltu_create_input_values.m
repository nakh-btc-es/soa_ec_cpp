function stValues = sltu_create_input_values(stModel, nSteps, dInitValue, dValueDiffPerStep, dValueDiffPerSignal)
% Utility function to create initial input values for a simulation.
%

%%
if (nargin < 3)
    dInitValue = 0.0;
end
if (nargin < 4)
    dValueDiffPerStep = 0.0;
end
if (nargin < 5)
    dValueDiffPerSignal = 0.0;
end


%%
adTimeValues = (0:(nSteps)-1);
adValues = repmat(dInitValue, 1, nSteps) + (0:(nSteps-1))*dValueDiffPerStep;

stInputs = struct();
for i = 1:length(stModel.astInports)
    sIfid = stModel.astInports(i).ifid;
    stInputs.(sIfid) = adValues + (i-1)*dValueDiffPerSignal;
end
for i = 1:length(stModel.astDSReads)
    sIfid = stModel.astDSReads(i).ifid;
    stInputs.(sIfid) = adValues + (i-1)*dValueDiffPerSignal;
end

stValues = struct( ...
    'adTimeValues', adTimeValues, ...
    'stInputs',     stInputs, ...
    'astCals',      stModel.astCals);
end
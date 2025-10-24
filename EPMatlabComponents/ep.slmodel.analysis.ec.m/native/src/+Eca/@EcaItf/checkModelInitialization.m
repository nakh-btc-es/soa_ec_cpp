function [bReady, oEca] = checkModelInitialization(oEca, sModelFile, sSlInitScript, bLoadModel)
if (nargin < 4)
    bLoadModel = true;
end

%Get model information
%Check model compilation
%Get SLDD informations
%Set Model informations
oEca.sModelFile = sModelFile;
[oEca.sModelPath, oEca.sModelName, oEca.sModelExt] = fileparts(sModelFile);
if not(isempty(sSlInitScript))
    oEca.sMscriptFile = sSlInitScript;
    [oEca.sMscriptPath, oEca.sMscriptName, ~] = fileparts(sSlInitScript);
    if bLoadModel
        evalin('base', ['run(''', oEca.sMscriptFile, ''');']);
    end
end

%Move to model folder
oEca.sCurrMatlabFolder = pwd;
cd(oEca.sModelPath);
%Load model and get referenced models info
if bLoadModel
    oEca.hModel = load_system(oEca.sModelName);
else
    oEca.hModel = get_param(oEca.sModelName, 'handle');
end
if isempty(oEca.sModelExt)
    oEca.sModelFile = get_param(oEca.hModel, 'FileName');
    if ~isempty(oEca.sModelFile)
        [oEca.sModelPath, oEca.sModelName, oEca.sModelExt] = fileparts(oEca.sModelFile);
    end    
end

oEca.casModelRefs = setxor(oEca.sModelName, ep_core_feval('ep_find_mdlrefs', oEca.sModelName));

if bLoadModel
    try
        oEca.startModelCompilation();
        oEca.stopModelCompilation();
        bReady = true;
    catch e
        casMsgs = {e.message};
        c = e.cause;
        while ~isempty(c)
            casMsgs{end + 1} = sprintf('  %s', c{1}.message);
            c = c{1}.cause;
        end
        sStr = sprintf('Model initialization failed\n %s\n', casMsgs{:});
        oEca.addMessageEPEnv('EP:SLC:ERROR', 'msg', sStr);
        bReady = false;
        if oEca.bDiagMode
            rethrow(e)
        end
        return;
    end
else
    bReady = true; % assume that we already have check model initialization
end
oEca.mCombineOutputUpdate = i_readCombineOutputUpdateMap(oEca.sModelName, oEca.casModelRefs);

%Simulink Data Dictionary
if i_isSLDDUsed(oEca.hModel)
    oEca.bIsSLDDUsed = true;
    oEca.sSLDDName = get(oEca.hModel, 'DataDictionary');
    oEca.sSLDDFile = which(oEca.sSLDDName);
    oEca.sSLDDPath = fileparts(oEca.sSLDDFile);    
else
    oEca.bIsSLDDUsed = false;
end

if bReady
    % model fundamental sampletime
    oEca.dModelSampleTime = str2double(get(oEca.hModel, 'FixedStep'));
    oEca.sSystemTargetFileName = get(oEca.hModel, 'RTWSystemTargetFile');
end
end


%%
function bSldd = i_isSLDDUsed(hModel)
bSldd = ~isempty(get(hModel, 'DataDictionary'));
end


%%
function mCombineOutputUpdate = i_readCombineOutputUpdateMap(sModelName, casModelRefs)

cahModels = get_param([{sModelName} casModelRefs'], 'handle');
ahModels = [cahModels{:}];
caoBlockDiagrams = get_param(ahModels, 'object');
if ~iscell(caoBlockDiagrams) % caoBlockDiagrams is only one single object and not a cell
    caoBlockDiagrams = {caoBlockDiagrams};
end

casSettings = cell(1, length(caoBlockDiagrams));

for i = 1:length(caoBlockDiagrams)
    oConfigSet = caoBlockDiagrams{i}.getActiveConfigSet;
    casSettings{i} = oConfigSet.get_param('CombineOutputUpdateFcns');
end

mCombineOutputUpdate = containers.Map(cahModels, casSettings);
end
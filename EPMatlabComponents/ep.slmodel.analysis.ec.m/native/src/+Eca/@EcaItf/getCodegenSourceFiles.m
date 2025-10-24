function astCodegenSourcesFiles = getCodegenSourceFiles(oEca, casFileNameBlacklist)
% astCodegenSourcesFiles: Array of structure
% 	.path  		: String
% 	.codecov  	: Boolean

astCodegenSourcesFiles = [];

oBuildInfo = oEca.getStoredBuildInfo();
casSourceFilesTmp = getFullFileList(oBuildInfo, 'source');
iFile = 0;
for k = 1:numel(casSourceFilesTmp)
    sFullFile = casSourceFilesTmp{k};
    [~, sFileName, sFileExt] = fileparts(sFullFile);

    sFile = [sFileName, sFileExt];
    if ismember(sFile, casFileNameBlacklist)
        sMsg = sprintf('Source file %s has been ignored in c-code architecture as specified in hook functions.', sFile);
        if oEca.bDiagMode
            fprintf('%s\n', sMsg);
        end
        if ~isempty(oEca.EPEnv)
            oEca.addMessageEPEnv('EP:SLC:INFO', 'msg', sMsg);
        end
        continue;
    end

    % for AUTOSAR Adaptive we have useless *.cxx file in the stub/aragen folder --> filter them out
    if (oEca.bIsAdaptiveAutosar && verLessThan('matlab', '9.13'))
        if ~isempty(regexp(sFullFile, '\Wstub\Waragen\W\w+\.cxx', 'once'))
            continue;
        end        
    end

    iFile = iFile + 1;
    astCodegenSourcesFiles(iFile).path = casSourceFilesTmp{k};
    astCodegenSourcesFiles(iFile).codecov = true;
    if oEca.bIsAutosarArchitecture && ...
            strcmp(strrep(fileparts(casSourceFilesTmp{k}), '/', '\'),...
            strrep(fullfile(oEca.sAutosarCodegenPath, 'stub'), '/', '\'))
        astCodegenSourcesFiles(iFile).hide = true;
    else
        astCodegenSourcesFiles(iFile).hide = false;
    end

end
end

% Get an absolute resource location.
%
% sAbsoluteResourcePath = ep_core_internal_resource_get(sRelativeResourcePath)
%
%   INPUT
%    - sRelativeResourcePath    (string)   relative resource path (like in the containing plugin).  
%
%   OUTPUT
%    - sAbsoluteResourcePath    (string)   absolute file path or [] if not found
%
% $$$COPYRIGHT$$$-2017
function sAbsoluteResourcePath = ep_core_internal_resource_get(sRelativeResourcePath)
   
    try
        oBtcEpInstallationPath = i_get_installation_path;
        if ~isempty(oBtcEpInstallationPath)
            sBtcEpMatlabPath = fullfile(char(oBtcEpInstallationPath), 'matlab');
            sAbsoluteResourcePath = fullfile(sBtcEpMatlabPath, sRelativeResourcePath);
            if (exist(sBtcEpMatlabPath, 'dir') || ~isempty(oBtcEpInstallationPath))
                return;
            end
        end
    catch btcInstallationException
        warning(['ep_core_resource_get->btcInstallationException :', btcInstallationException.message]);
    end
    try
        % developer mode. Extract file from the resource service cache
        oResourceService = ct.nativeaccess.ResourceServiceFactory.getInstance();
        sAbsoluteResourcePath = char(oResourceService.getResourceAsFile([], sRelativeResourcePath).getAbsolutePath());
        return;
    catch exception
        warning(['ep_core_resource_get->resource service cache exception: ', exception.message]);
    end
    try
        % developer mode. Extract file from btc_ep.jar
        oFile=i_get_btc_ep_jar_file();
        oBtcEpJarAbsolutePath = char(oFile.getAbsolutePath());
        if ~isempty(oBtcEpJarAbsolutePath)
            sAbsoluteResourcePath = fullfile(oBtcEpJarAbsolutePath, sRelativeResourcePath);
            if exist(sAbsoluteResourcePath, 'file')
                return;
            end
        end
    catch btcEpJarException
        warning(['ep_core_resource_get->btcEpJarException: ', btcEpJarException.message]);
    end
end

%%
%  This function determines the path to the EmbeddedPlatform Installation.
%
% function i_get_installation_path
%
%  INPUT               DESCRIPTION
%  -
%  OUTPUT              DESCRIPTION
%  sInstallPath         Path to the EmbeddedPlatform Installation or empty string if not installed
%%
function sInstallPath = i_get_installation_path
    sInstallPath = '';
    try
        oBtcEpJarFile = i_get_btc_ep_jar_file;
        if strcmp(oBtcEpJarFile.getParentFile().getParentFile().getName(), 'matlab')
            sInstallPath = oBtcEpJarFile.getParentFile().getParentFile().getParentFile();
        end
    catch eException %#ok
        sInstallPath = '';
    end
end

function oBtcEPJarFile = i_get_btc_ep_jar_file
    oResService = ct.nativeaccess.ResourceServiceFactory.getInstance();
    oBtcEPJarFile = oResService.getLocationOfClass(oResService.getClass);
end
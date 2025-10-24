function [nLength, sName] = ep_simenv_vec2mat(xEnv, sVectorFile, sLocation)
% Transform a vector file into a MAT file.
%
% function [nLength, sName] = ep_simenv_vec2mat(xEnv, sVectorFile, sLocation)
%
%   INPUT               DESCRIPTION
%   xEnv                 (object)    Environment settings.
%   sVectorFile          (string)    Full path to vector file (see
%
%   OUTPUT              DESCRIPTION
%   nLength              (integer)   Length of vector
%   sName                (string)    Name of vector
%

%%
try
    hDoc = mxx_xmltree('load', sVectorFile);
    xOnCleanupClose = onCleanup(@()  mxx_xmltree('clear', hDoc));
    
    xStimVec = mxx_xmltree('get_root', hDoc);    
    sName    = mxx_xmltree('get_attribute', xStimVec, 'name');
    sLength  = mxx_xmltree('get_attribute', xStimVec, 'length');
    nLength  = str2double(sLength);
    

    % get input variables
    xNodeList = mxx_xmltree('get_nodes', xStimVec, 'Inputs/Object');
    nInputs   = length(xNodeList);
    
    for iInput = 1:nInputs
        xInput = xNodeList(iInput);
        % TODO: dead code?
        sFile = mxx_xmltree('get_attribute', xInput, 'matFile');
        if ~isempty(sFile)
            sExportDir = fullfile(sLocation, 'vecs');
            if ~exist(sExportDir, 'dir')
                mkdir(sExportDir);
            end
            [sPath, sName, sExt] = fileparts(sFile); %#ok
            sDestFile = fullfile(sExportDir, [sName, sExt]);
            if ~strcmp(sDestFile, sFile)
                copyfile(sFile, sDestFile,'f');
            end
        end
    end
    
catch exception
    xEnv.rethrowException(exception);
end
end

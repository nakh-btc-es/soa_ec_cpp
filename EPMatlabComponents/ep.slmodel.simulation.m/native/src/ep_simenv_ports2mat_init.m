function ep_simenv_ports2mat_init(xEnv, sVectorFile, sLocation)
% Transform a vector file into MAT files.
%
% function ep_simenv_ports2mat_init(xEnv, sVectorFile, sLocation)
%
%   INPUT               DESCRIPTION
%   xEnv                 (object)    Environment settings.
%   sVectorFile          (string)    Full path to vector file (see
%   sLocation            (string)    Location where the MAT files should be
%                                    stored.
%   OUTPUT              DESCRIPTION
%
% $$$COPYRIGHT$$$-2015

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


try   
    
    xDocInit = mxx_xmltree('load', sVectorFile );
    xStimVec = mxx_xmltree('get_root',xDocInit);
    
    
    xNodeList = mxx_xmltree('get_nodes',xStimVec,'//Inport');
    nInputs   = length(xNodeList);
    
    %  for all inputs
    for iInput=1:nInputs
        xInput = xNodeList(iInput);
        sFile = mxx_xmltree('get_attribute', xInput, 'matFile');
        if( ~isempty(sFile ) )
            sExportDir = fullfile(sLocation,'vecs');
            if( exist(sExportDir, 'dir') ~= 7)
                mkdir(sExportDir);
            end
            [sPath,sName,sExt] = fileparts(sFile); %#ok
            sDestFile = fullfile(sExportDir,[sName,sExt]);
            if( ~strcmp(sDestFile,sFile) )
                copyfile(sFile, sDestFile,'f');
            end
        end
    end
    mxx_xmltree('clear', xDocInit);
    
catch exception
    try mxx_xmltree('clear',xDocInit); catch end %#ok
    xEnv.rethrowException(exception);
end

%**************************************************************************
% END OF FILE
%**************************************************************************

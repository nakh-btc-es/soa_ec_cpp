function stNames = ep_simenv_debug_vector(xEnv, sVectorFile, sExportDir)
% Transform relevant info from the vector file into a single MAT file.
%
% function sMatFile = ep_simenv_debug_vector(xEnv, sVectorFile, sExportDir, sName)
%
%   INPUT               DESCRIPTION
%   xEnv                 (object)    Environment settings.
%   sVectorFile          (string)    Full path to vector file (see
%   sExportDir           (string)    Location where the MAT files should be
%                                    stored.
%   sName                (string)    Name of the model
%   OUTPUT              DESCRIPTION
%   stNames              (struct)    Struct containing vector names
%       .sMatFileName    (string)    Internal vector name 
%       .sDisplayName    (string)    Name for display purposes 

%%
    stNames= struct(...
            'sMatFileName','',...
            'sDisplayName','');
try  
    xDocInit = mxx_xmltree('load', sVectorFile );
    xOnCleanUp = onCleanup(@() mxx_xmltree('clear', xDocInit));
    
    xStimVec = mxx_xmltree('get_root', xDocInit);  
    
    sLength = mxx_xmltree('get_attribute', xStimVec, 'length');
    
    stNames.sDisplayName = mxx_xmltree('get_attribute', xStimVec, 'name');
        
    % new harness approach
    sExportVecDir = mxx_xmltree('get_attribute', xStimVec, 'exportDir');
    if isempty(sExportVecDir)
        sExportVecDir = fileparts(sVectorFile);
    end
    [~, sFolderName] = fileparts(sExportVecDir);
    sMatExportDir = fullfile(sExportDir, sFolderName);
    mxx_xmltree('set_attribute', xStimVec, 'exportDir', sMatExportDir);
    mxx_xmltree('save', xDocInit, sVectorFile);
    
    movefile(sExportVecDir, sExportDir);
    
    sMatFile = fullfile(sMatExportDir, [sFolderName, '.mat']);
    [~, stNames.sMatFileName] = fileparts(sMatFile);
    
    nLength = str2double(sLength);
   
    btc_vector_length = nLength; %#ok
    save(sMatFile, 'btc_vector_length');
    
    % TODO: remove this crap ASAP! ----
    % In the new harness, the vector MDF files are stored in the exportDir 
    sMDFExportDir = sMatExportDir; %#ok<NASGU>
    save(sMatFile, 'sMDFExportDir', '-append');
    % END TODO --------
    
    xNodeList = mxx_xmltree('get_nodes', xStimVec, './Inputs/Calibration');
    nInputs   = length(xNodeList);
    
    %  for all Calibration
    for iInput=1:nInputs
        xInput = xNodeList(iInput);
        sIfid  = mxx_xmltree('get_attribute', xInput, 'ifid');
        sValue = mxx_xmltree('get_attribute', xInput, 'initValue');
        
        if ~isempty(sValue)
            dValue = str2double(sValue);
            anVec(1,1) = 0;
            anVec(1,2) = dValue;
            sInputId = ['i_', sIfid];
            % create input variable in base workspace
            assignin('base', sInputId, anVec );

            sCmd = sprintf('save( ''%s'', ''%s'', ''-append'');', sMatFile, sInputId);
            evalin('base', sCmd);
            evalin('base', sprintf('clear %s;', sInputId));
        end
    end
    
    xNodeList = mxx_xmltree('get_nodes', xStimVec, './Outputs/Outport');
    nOutputs   = length(xNodeList);
    
    %  for all Outports
    for iOutput = 1:nOutputs
        xInput = xNodeList(iOutput);
        sIfid  = mxx_xmltree('get_attribute', xInput, 'ifid');
        sFile = mxx_xmltree('get_attribute', xInput, 'matFile');
        if( ~isempty(sFile ) )
            stContent = load(sFile,'-mat',sIfid);
            anVec = getfield(stContent,sIfid); %#ok
            anCVec = ctranspose(anVec);
            sInputId = ['expected_o_', sIfid];
            assignin('base', sInputId, anCVec );

            sCmd = sprintf('save( ''%s'', ''%s'', ''-append'');', ...
                sMatFile,sInputId);
            evalin('base', sCmd);
            evalin('base', sprintf('clear %s;',sInputId));
        end
    end
    
    xNodeList = mxx_xmltree('get_nodes', xStimVec, './Inputs/Inport');
    nInputs   = length(xNodeList);
    
    %  for all Inports
    for iInput=1:nInputs
        xInput = xNodeList(iInput);
        sIfid  = mxx_xmltree('get_attribute', xInput, 'ifid');
        sFile = mxx_xmltree('get_attribute', xInput, 'matFile');
        if( ~isempty(sFile ) && exist(sFile,'file') )
            stContent = load(sFile,'-mat',sIfid);
            anVec = getfield(stContent,sIfid); %#ok
            anCVec = ctranspose(anVec);
            sInputId = ['i_', sIfid];
            assignin('base', sInputId, anCVec );

            sCmd = sprintf('save( ''%s'', ''%s'', ''-append'');', ...
                sMatFile,sInputId);
            evalin('base', sCmd);
            evalin('base', sprintf('clear %s;',sInputId));
        end
    end
catch exception
    xEnv.rethrowException(exception);
end

%**************************************************************************
% END OF FILE
%**************************************************************************

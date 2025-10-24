function ut_m_model_open
% Test of atgcv_m_model_open
%
% function ut_m_model_open
%
% #Further Descriptions#
%
%   PARAMETER(S)    DESCRIPTION
%   -
%
%   OUTPUT
%   -
%
% AUTHOR(S):
%  Remmer Wilts
% $$$COPYRIGHT$$$
%%

sDataPath =  fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tst', 'testdata', 'model_open_test');
sNewDataPath = fullfile(pwd, 'm_model_open');
if exist(sNewDataPath, 'dir')
    rmdir(sNewDataPath, 's');
end
copyfile(sDataPath, sNewDataPath);
sDataPath = sNewDataPath;
sPwd = pwd;
cd(sDataPath);
bdclose all; dsdd('Close', 'Save', 'off');

sName = 'Simplemodel';
sModelFile = fullfile(sDataPath,[sName,'.mdl']);
tu_test_model_adapt(sModelFile);

stEnv.sTmpPath    = pwd;
stEnv.sResultPath = pwd;
stEnv.hMessenger  = EPEnvironment;

% init model with SIL mode
stRes = atgcv_m_model_open( ...
            stEnv, ...
            sModelFile, ...
            [], ...
            true, ...
            true, ...
            {},...
            true);
if ~verLessThan('tl','5.2')
    tl_build_host('Model', sName);
    dsdd('Save');
else
    tl_set_sim_mode('Model', sName, ...
                'SimMode', 'TL_CODE_HOST');
end

save_system(sName);            
atgcv_m_model_close(stEnv,stRes);


%  check 1) model is closed _AND_ bActivateMil is true
%  --> no exception
stRes1 = atgcv_m_model_open( ...
            stEnv, ...
            sModelFile, ...
            [], ...
            true, ...
            true, ...
            {},...
            true);
        
bd = find_system('Name', sName, 'Type', 'block_diagram');
if(isempty(bd))
    MU_FAIL('Unexpected: Model should be open.');
else
    MU_PASS('Model is open.');
end
atgcv_m_model_close(stEnv,stRes1);
bd = find_system('Name', sName, 'Type', 'block_diagram');
if(~isempty(bd))
    MU_FAIL('Unexpected: Model should be closed.');
else
    MU_PASS('Model is closed.');
end


%  check 2) model is closed _AND_ bActivateMil is false
%  --> no exception
stRes2 = atgcv_m_model_open( ...
            stEnv, ...
            sModelFile, ...
            [], ...
            true, ...
            true, ...
            {},...
            false);
        
bd = find_system('Name', sName, 'Type', 'block_diagram');
if(isempty(bd))
    MU_FAIL('Unexpected: Model should be open.');
else
    MU_PASS('Model is open.');
end
% reset SIL mode
tl_set_sim_mode('Model', sName, ...
                'SimMode', 'TL_CODE_HOST');

    
%  check 3) model is open _AND_ bActivateMil is true
%  --> no exception
stRes3 = atgcv_m_model_open( ...
            stEnv, ...
            sModelFile, ...
            [], ...
            true, ...
            true, ...
            {},...
            true);
        
bd = find_system('Name', sName, 'Type', 'block_diagram');
if(isempty(bd))
    MU_FAIL('Unexpected: Model should be open.');
else
    MU_PASS('Model is open.');
end
tl_set_sim_mode('Model', sName, ...
                'SimMode', 'TL_CODE_HOST');


%  check 4) model is open _AND_ bActivateMil is false
%  --> yes exception
try
    stRes4 = atgcv_m_model_open( ...
            stEnv, ...
            sModelFile, ...
            [], ...
            true, ...
            true, ...
            {},...
            false);
    MU_FAIL('Exception expected');
catch
    z = lasterror;
    MU_ASSERT_TRUE(strcmp(z.identifier,'ATGCV:MOD_ANA:MIL_MODE_NOT_ENABLED'), ...
        'Unexpected exception ID.');
end


% cleanup
atgcv_m_model_close(stEnv, stRes2);
bdclose all; dsdd('Close', 'Save', 'off');

% check open close for SL.
i_checkSlOnlyModelOpenClose(stEnv)

%%
cd(sPwd);
i_cleanup(sDataPath);

end

%%  i_checkSlOnlyModelOpenClose(stEnv)
% Check model open/close 
function i_checkSlOnlyModelOpenClose(stEnv)
    movefile('atgcv_use_tl_onlyForSL.m', 'atgcv_use_tl.m')
    sName = 'StandardModel_sl';
    sScript = 'standard_start';
    sModelFile = fullfile(pwd,[sName,'.mdl']);
    sScriptFile = fullfile(pwd,[sScript,'.m']);
    
    try
        stOpenRes = atgcv_m_model_open(stEnv, sModelFile,{sScriptFile}, false, true, {}, false, false);
        bd = find_system('Name', sName, 'Type', 'block_diagram');
        if(isempty(bd))
            MU_FAIL('Unexpected: Model should be open.');
        else
            MU_PASS('Model is open.');
        end
        
        atgcv_m_model_close(stEnv, stOpenRes);
        
        bd = find_system('Name', sName, 'Type', 'block_diagram');
        if(isempty(bd))
            MU_PASS('Model is closed.');            
        else
            MU_FAIL('Unexpected: Model should be closed.');
        end
    catch
        z = lasterror;
        osc_throw(z);
    end
    
     try
        stOpenRes = atgcv_m_model_open(stEnv, sModelFile,{sScript}, false, true, {}, false, false, true);
        bd = find_system('Name', sName, 'Type', 'block_diagram');
        if(isempty(bd))
            MU_FAIL('Unexpected: Model should be open.');
        else
            MU_PASS('Model is open.');
        end
        
        atgcv_m_model_close(stEnv, stOpenRes);
        
        bd = find_system('Name', sName, 'Type', 'block_diagram');
        if(isempty(bd))
            MU_PASS('Model is closed.');            
        else
            MU_FAIL('Unexpected: Model should be closed.');
        end
    catch
        z = lasterror;
        osc_throw(z);
    end
    
    movefile('atgcv_use_tl.m', 'atgcv_use_tl_onlyForSL.m')
end

%%
function i_cleanup(sTestDir)
bdclose all;
dsdd_free();
clear mex;
if exist(sTestDir, 'dir')
    rmdir(sTestDir, 's');
end
end
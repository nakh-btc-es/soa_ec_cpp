function ep_simenv_init_vect_file_to_sfunc_attach( xEnv, hSimModel, sInputsVectorFile, sOutputsVectorFile)
try
    q=char(39);
    sVectorName = 'MyVectorName'; % TODO Implement here correct way
    hSFuncIn = ep_find_system(hSimModel, 'BlockType', 'S-Function', 'Tag', 'BTC_SIM_MODEL_INPUTS');
    if ~isempty(hSFuncIn)
        casCurrentParams = strsplit(get_param(hSFuncIn, 'Parameters'), ',');
        sCurrentParams = casCurrentParams{1};       
        set_param(hSFuncIn, 'Parameters', [sCurrentParams, ',', ...
            [q, sInputsVectorFile, q], ',', [q, sVectorName, q]]);
    end
    hSFuncOut = ep_find_system(hSimModel, 'BlockType', 'S-Function', 'Tag', 'BTC_SIM_MODEL_OUTPUTS');
    if ~isempty(hSFuncOut)
        casCurrentParams = strsplit(get_param(hSFuncOut, 'Parameters'), ',');
        sCurrentParams = casCurrentParams{1};
        set_param(hSFuncOut, 'Parameters', [sCurrentParams, ',', ...
            [q, sOutputsVectorFile, q], ',', [q, sVectorName, q]]);
    end
catch oEx
    xEnv.rethrowException(oEx);
end
end
function ep_sl_top_enable_calibration(xEnv, stSrcModelInfo, stExtrModelInfo, ~)
stEnv = ep_core_legacy_env_get(xEnv, true);
i_generatePreSimScript(stEnv, stSrcModelInfo, stExtrModelInfo);
end


%%
function i_generatePreSimScript(stEnv, stSrcModelInfo, stExtrModelInfo)
ep_sim_sl_top_pre_sim_script_gen(stEnv, ...
    stExtrModelInfo.sName, ...
    stSrcModelInfo.xSubsys, ...
    []);
end
%%
function sFunctionInterfaceSettings = ep_ec_func_interface_settings_create(stParse)
if isempty(stParse.sReturn)
    sReturnFuncName = [stParse.sFuncName,'('];
else
    sReturnFuncName = [stParse.sReturn '=' stParse.sFuncName,'('];
end
astArgs = stParse.astArgs; %
sArgsInOut = '';

for i = 1:numel(astArgs)
    if (astArgs(i).bIsPointer)
        sArgsInOut = [sArgsInOut '* '];  %#ok<AGROW>
    end
    sArgsInOut = [sArgsInOut,astArgs(i).sName ' ' astArgs(i).sMacro ', ']; %#ok<AGROW>
end
sFunctionInterfaceSettings = [sReturnFuncName  sArgsInOut(1:end-2) ')'];
end
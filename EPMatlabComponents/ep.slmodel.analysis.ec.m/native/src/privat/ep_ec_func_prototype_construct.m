function stConstruct = ep_ec_func_prototype_construct(stPrototypeParts)
% Parses the prototype (signatature) of a SL Function into simpler parts: return-value, function-name, arguments.
%
% function stConstruct = ep_ec_func_prototype_construct(stPrototypeParts)
%
%  INPUT              DESCRIPTION
%    stPrototypeParts           (struct)         Parsed prototype parts
%      .sFuncName               (string)            name of the function
%      .sReturn                 (string)            name of the return variable (or empty '' if nothing is returned)
%      .astArgs                 (structs)           infos about each individual input argument
%        .sName                   (string)            name of the argument
%        .sMacro                  (string)            template transforming the argument name into a C-name (e.g. rt$I$N$M)
%        .bIsPointer              (boolean)           flag if the argument is a pointer or not
%
%  OUTPUT            DESCRIPTION
%    stConstruct                (struct)         Constructed prototype
%      .sPrototype              (string)            full prototype of the SL function 
%                                                   (e.g. y= func1(* u1 rt$I$N$M, u2 rt$I$N$M, * u3 rt$I$N$M) )
%      .sFuncName               (string)            name of the function
%                                                   (e.g. func1)
%      .sArguments              (string)            arguments of the prototype
%                                                   (e.g. y= (* u1 rt$I$N$M, u2 rt$I$N$M, * u3 rt$I$N$M))
%


%%
if isempty(stPrototypeParts.sReturn)
    sArguments = '(';
    sPrototype = [stPrototypeParts.sFuncName, '('];
else
    sArguments = [stPrototypeParts.sReturn, '= ('];
    sPrototype = [stPrototypeParts.sReturn, '= ', stPrototypeParts.sFuncName, '('];
end

sAllArgs = '';
for i = 1:numel(stPrototypeParts.astArgs)
    if (stPrototypeParts.astArgs(i).bIsPointer)
        sArg = sprintf('* %s %s', stPrototypeParts.astArgs(i).sName, stPrototypeParts.astArgs(i).sMacro);
    else
        sArg = sprintf('%s %s', stPrototypeParts.astArgs(i).sName, stPrototypeParts.astArgs(i).sMacro);
    end
    sAllArgs = [sAllArgs, sArg, ', ']; %#ok<AGROW>
end

sArguments = [sArguments,  sAllArgs(1:end-2), ')'];
sPrototype = [sPrototype,  sAllArgs(1:end-2), ')'];

stConstruct = struct( ...
    'sPrototype', sPrototype, ...
    'sFuncName',  stPrototypeParts.sFuncName, ...
    'sArguments', sArguments);
end
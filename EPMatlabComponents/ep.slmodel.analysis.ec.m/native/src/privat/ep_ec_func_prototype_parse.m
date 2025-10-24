function stParts = ep_ec_func_prototype_parse(sPrototype)
% Parses the prototype (signatature) of a SL Function into simpler parts: return-value, function-name, arguments.
%
% function stParts = ep_ec_func_prototype_parse(sPrototype)
%
%  INPUT              DESCRIPTION
%    sPrototype                (string)*         the prototype string
%                                                Examples: 
%                                                     y= func1(*u1 rt$I$N$M, u2 rt$I$N$M, *u3 rt$I$N$M) 
%                                                     func2()
%                                                     func3(a rt$I$N$M)
%
%  OUTPUT            DESCRIPTION
%    stParts                    (struct)         Parsed prototype parts
%      .sFuncName               (string)            name of the function
%      .sReturn                 (string)            name of the return variable (or empty '' if nothing is returned)
%      .astArgs                 (structs)           infos about each individual input argument
%        .sName                   (string)            name of the argument
%        .sMacro                  (string)            template transforming the argument name into a C-name (e.g. rt$I$N$M)
%        .bIsPointer              (boolean)           flag if the argument is a pointer or not
%



%%
stParts.sFuncName = '';
stParts.sReturn   = '';
stParts.astArgs   = [];

% handle the case of two fields: {(returnValue=)* sFuncName} {InOutArgs}
casCodePrototype = split(sPrototype, '(');
sReturnFuncName = casCodePrototype{1};
sInOutArgs = casCodePrototype{2};

%check if Return value exist
casReturnFuncName = split(sReturnFuncName, '=');
if (numel(casReturnFuncName) < 2)
    stParts.sReturn   = '';
    stParts.sFuncName = strtrim(casReturnFuncName{1}); % rm whitespace at begin and end
else
    stParts.sReturn   = strtrim(casReturnFuncName{1});
    stParts.sFuncName = strtrim(casReturnFuncName{2});
end

% Identify in/out args and add to stParse.astArgs (by default empty) only if there are any
if numel(sInOutArgs) > 1
    casInOutArgs = split(sInOutArgs, ',');
    nArgs = numel(casInOutArgs);
    astArgs = repmat(struct( ...
        'sName',      '', ...
        'sMacro',     '', ...
        'bIsPointer', false), 1, nArgs);
    for i = 1:nArgs
        casInOutArgs(i) = regexprep(casInOutArgs(i), '^ +', '');
        
        %if last expression -> rm closing bracket
        if (i == nArgs)
            casInOutArgs(i) = regexprep(casInOutArgs(i), ')', '');
        end
        
        %check if pointer
        astArgs(i).bIsPointer= startsWith(casInOutArgs(i), '*');
        if (astArgs(i).bIsPointer)
            %rm the pointer symbol
            casInOutArgs(i) = regexprep(casInOutArgs(i), '*', '');
        end
        
        %rm whitespace at begin since it will be delimiter later
        casInOutArgs(i) = regexprep(casInOutArgs(i), '^ +', '');
        %split every expression into simulink function argument and c/c++ id name if existent
        casArgsTable = split(casInOutArgs(i), ' ');
        astArgs(i).sName = casArgsTable{1};
        if (numel(casArgsTable) > 1)
            astArgs(i).sMacro = casArgsTable{2};  %pointer
        end
    end
    stParts.astArgs = astArgs;
end
end

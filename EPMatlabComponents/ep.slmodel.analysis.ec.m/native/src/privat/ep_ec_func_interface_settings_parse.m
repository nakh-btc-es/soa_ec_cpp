function stParse = ep_ec_func_interface_settings_parse(sCodePrototype)
stParse.sFuncName = '';
stParse.sReturn   = '';
stParse.astArgs = [];

%early return in case of empty prototype definition
if isempty(sCodePrototype) || i_isAllWhitespace(sCodePrototype)
    return;
end

% handle the case of two fields: {(returnValue=)* sFuncName} {InOutArgs}
casCodePrototype = split(sCodePrototype, '(');
sReturnFuncName = casCodePrototype{1};
sInOutArgs = casCodePrototype{2};

%check if Return value exist
casReturnFuncName = split(sReturnFuncName, '=');
if (numel(casReturnFuncName) < 2)
    stParse.sReturn   = '';
    stParse.sFuncName = strtrim(casReturnFuncName{1}); % rm whitespace at begin and end
else
    stParse.sReturn   = strtrim(casReturnFuncName{1});
    stParse.sFuncName = strtrim(casReturnFuncName{2});
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
    stParse.astArgs = astArgs;
end
end

function bReturn = i_isAllWhitespace(sPrototype)
bReturn = isempty(regexp(sPrototype,'\S', 'once'));
end

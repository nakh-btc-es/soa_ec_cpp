function [ret, bHasDataObject] = replaceMacros(oItf, ret, sDataObject)

% <DATANAME>                : name of the data object
% <DATAOBJ>                 : data object variable
% <PARSCOPEDEFFILE>         : name of parent subssystem's c-file
% <MODELCFILE>              : model.c
% <MODELHFILE>              : model.h
% <MODELPRIVHFILE>          : model_private.h
% <PARSCOPEFUNCNAME>        : name of parent c-function
% <PARSCOPEFULLNAME>        : name of parent subsystem
% <CCODDATATYPE>            : datatype used in c-code
% <MODELNAME>               : name of the model

if (nargin < 3)
    sDataObject = '';
end

bHasDataObject = false;

if ischar(ret)
    sExp = '<(\w+)>';
    ccasMatchStr = regexp(ret, sExp, 'tokens');
    for i=1:numel(ccasMatchStr)
        switch ccasMatchStr{i}{1}
            case 'DATAOBJ'
                ret = strrep(ret, '<DATAOBJ>',           sDataObject);
                bHasDataObject = true;
            case 'DATANAME'
                ret = strrep(ret, '<DATANAME>',          oItf.getAliasRootName());
            case 'PARSCOPEDEFFILE'
                ret = strrep(ret, '<PARSCOPEDEFFILE>',   oItf.sParentScopeDefFile);
            case 'MODELCFILE'
                ret = strrep(ret, '<MODELCFILE>',        i_getModelCfile(oItf));
            case 'MODELHFILE'
                ret = strrep(ret, '<MODELHFILE>',        i_getModelHfile(oItf));
            case 'MODELPRIVHFILE'
                ret = strrep(ret, '<MODELPRIVHFILE>',    i_getModelPrivateHfile(oItf));
            case 'PARSCOPEFUNCNAME'
                ret = strrep(ret, '<PARSCOPEFUNCNAME>',  oItf.sParentScopeFuncName);
            case 'PARSCOPEFULLNAME'
                ret = strrep(ret, '<PARSCOPEFULLNAME>',  fileparts(oItf.sourceBlockFullName));
            case 'CCODDATATYPE'
                ret = strrep(ret, '<CCODDATATYPE>',      oItf.codedatatype);
            case 'MODELNAME'
                ret = strrep(ret, '<MODELNAME>',         oItf.getBdroot());
        end
    end
    ret = strrep(ret, '$N', oItf.name); %used in GetSet attributes
end
end


%%
function str = i_getModelCfile(oItf)
str = [oItf.getBdroot(), '.c'];
end


%%
function str = i_getModelHfile(oItf)
str = [oItf.getBdroot(), '.h'];
end


%%
function str = i_getModelPrivateHfile(oItf)
str = [oItf.getBdroot(),'_private.h'];
end

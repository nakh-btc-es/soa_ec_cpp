function atgcv_m01_tlcheck(stEnv, sModelAna)
% check info in ModelAnalysis.xml
%
%  atgcv_m01_tlcheck(stEnv, sModelAna)
%
%   INPUT              DESCRIPTION
%     stEnv              (struct)      environment structure
%     sModelAna          (string)      fullpath to ModelAnalysis.xml
%
%   OUTPUT             DESCRIPTION
%

if i_doAcceptMismatch()
    return;
end

stErr = []; 
hDoc = mxx_xmltree('load', sModelAna);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

ahSubs = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem[not(@isDummy="yes")]');
sXPathBoolean = './ma:Interface/ma:Input/ma:Port/ma:Variable[not(@isDummy="yes")]/ma:ifName[@signalType="boolean"]';
sXPathEnums = i_getXPathForEnums();

for i = 1:length(ahSubs)
    hSub = ahSubs(i);
    
    % currently only the Input-Ports and the "boolean" SignalType is
    % interesting for us
    ahIfBoolean = mxx_xmltree('get_nodes', hSub, sXPathBoolean);

    ahIfEnums = [];
    if ~isempty(sXPathEnums)
        ahIfEnums = mxx_xmltree('get_nodes', hSub, sXPathEnums);
    end

    for j = 1:length(ahIfBoolean)
        hIf = ahIfBoolean(j);
        stScaling = mxx_xmltree('get_attributes', hIf, './ma:DataType/ma:Scaling', 'lsb', 'offset', 'upper', 'lower');
        if ~i_isScalingBooleanConsistent(stScaling)
            sSub       = mxx_xmltree('get_attribute', hSub, 'tlPath');
            sIfname    = i_getIfDisplayName(hIf);
            sModelType = 'boolean';
            sCodeType  = i_getCodeType(stScaling);
            stErr = i_addMessage(stEnv, sSub, sIfname, sModelType, sCodeType);
        end
    end
    for j = 1:length(ahIfEnums)
        hIf = ahIfEnums(j); 
        sTlTypeName = mxx_xmltree('get_attribute', mxx_xmltree('get_nodes', hIf, './ma:DataType'), 'tlTypeName');
        if ~strcmpi('Enum', sTlTypeName)
            sSub       = mxx_xmltree('get_attribute', hSub, 'tlPath');
            sIfname    = i_getIfDisplayName(hIf);
            sModelType = mxx_xmltree('get_attribute', hIf, 'signalType');
            sCodeType  = sTlTypeName;
            stErr = i_addMessage(stEnv, sSub, sIfname, sModelType, sCodeType);

        end        
    end
end

if ~isempty(stErr)
    stErr.stEnv = stEnv;
    osc_throw(stErr);
end
end


%%
function stErr = i_addMessage(stEnv, sSub, sIfname, sModelType, sCodeType)
stErr = osc_messenger_add(stEnv, ...
    'ATGCV:MOD_ANA:INPORT_TYPE_INCONSISTENT', ...
    'subsys',  sSub, ...
    'portsig', sIfname, ...
    'mtype',   sModelType, ...
    'ctype',   sCodeType);
end


%%
function bDoAccept = i_doAcceptMismatch()
bDoAccept = false;
try
    sFlag = atgcv_global_property_get('accept_inport_type_inconsistent');
    if any(strcmpi(sFlag, {'1', 'on', 'true', 'yes'}))
        bDoAccept = true;
    end
catch %#ok
end
end


%%
function bIsConsistent = i_isScalingBooleanConsistent(stScaling)
bIsConsistent =  ...
    (str2double(stScaling.lsb)   == 1) && ...
    (str2double(stScaling.lower) == 0) && ...
    (str2double(stScaling.upper) == 1);
end


%%
function sName = i_getIfDisplayName(hIf)
astInfo = mxx_xmltree('get_attributes', hIf, './ma:DisplayInfo/ma:ModelInfo', 'relPath', 'name', 'specifier');
sName = [astInfo(1).relPath, astInfo(1).name, astInfo(1).specifier];
end


%%
function sType = i_getCodeType(stScaling)
sType = sprintf('LSB=%s, Range=[%s, %s]', stScaling.lsb, stScaling.lower, stScaling.upper);
end


%%
function sXPathEnums = i_getXPathForEnums()
sXPathEnums = [];
astTypeInfo = ep_sl_type_info_get();
if ~isempty(astTypeInfo)
    astTypeInfo = astTypeInfo(cell2mat({astTypeInfo(:).bIsEnum}));
    if ~isempty(astTypeInfo)
        sXPathEnums = './ma:Interface/ma:Input/ma:Port/ma:Variable[not(@isDummy="yes")]/ma:ifName[';
        for i=1:length(astTypeInfo)
            if (i == 1)
                sXPathEnums = [sXPathEnums, '@signalType="',astTypeInfo(i).sType,'"']; %#ok
            else
                sXPathEnums = [sXPathEnums, ' or @signalType="',astTypeInfo(i).sType,'"']; %#ok
            end
        end
        sXPathEnums = [sXPathEnums, ']'];
    end
end
end
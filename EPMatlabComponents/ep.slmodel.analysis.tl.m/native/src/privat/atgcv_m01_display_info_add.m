function atgcv_m01_display_info_add(sMa, sModifiedMa)
% add display info for every interface object
%
%  atgcv_m01_display_info_add(sOldMa, sNewMa)
%   INPUT           DESCRIPTION
%     sMa             (string)       full path to original ModelAnalysis.xml
%     sModifiedMa     (string)       full path to modified ModelAnalysis.xml
%                                    (may be identical to sMa)
%
%   OUTPUT          DESCRIPTION
%      ---             ---

%% internal
%
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 214788 $
%   Last modified: $Date: 2016-09-21 14:47:43 +0200 (Mi, 21 Sep 2016) $
%   $Author: ahornste $
%


%%
hDoc = mxx_xmltree('load', sMa);
xOnCleanupClear = onCleanup(@() mxx_xmltree('clear', hDoc));

ahSubs = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem');
for i = 1:length(ahSubs)
    hSub = ahSubs(i);
    sSubPath = mxx_xmltree('get_attribute', hSub, 'tlPath');

    ahPorts = mxx_xmltree('get_nodes', hSub, './/ma:Port');
    i_addDisplayInfoPorts(ahPorts, sSubPath);

    ahCals = mxx_xmltree('get_nodes', hSub, './/ma:Calibration');
    i_addDisplayInfoCals(ahCals, sSubPath);

    ahDisps = mxx_xmltree('get_nodes', hSub, './/ma:Display');
    i_addDisplayInfoDisps(ahDisps, sSubPath);
end
mxx_xmltree('save', hDoc, sModifiedMa);
end




%%
function i_addDisplayInfoPorts(ahPorts, sSubPath)
for i = 1:length(ahPorts)
    hPort = ahPorts(i);
    
    sKind  = mxx_xmltree('get_attribute', hPort, 'compositeSig');
    bIsBus = strcmpi(sKind, 'bus');
    
    sPortNumber = mxx_xmltree('get_attribute', hPort, 'portNumber');
    
    bIsDSM = strcmp(sPortNumber, '0'); % check for DataStoreMemory Port
    if bIsDSM
        % for DataStoreMemory blocks use
        % - "DSM" as fixed Prefix
        % - name of the global Simulink.Signal as Name
        sPrefix = 'DSM';
        sBlockName = mxx_xmltree('get_attribute', hPort, 'signal');
    else
        sPrefix = ['#', sPortNumber];
        sPort = mxx_xmltree('get_attribute', hPort, 'tlPath');
        sBlockName = strrep(sPort, [sSubPath, '/'], '');
    end
    
    % relative path is empty because Ports are directly on toplevel of Subsystem
    % and DSMs are referred to by their global Workspace Simulink.Signal
    sRelPath = '';
        
    ahIf = mxx_xmltree('get_nodes', hPort, './/ma:ifName');
    for j = 1:length(ahIf)
        hIf    = ahIf(j);
        sIndex = i_getIndexNamePart(hIf);
        if bIsBus
            sSigName = mxx_xmltree('get_attribute', hIf, 'signalName');
            if isempty(sSigName)
                sSigName = 'ERROR-CASE<missing signal name>';
            end
            sSigName = regexprep(sSigName, '^<signal1>', 'signal1');
            sSpec = ['[', sPrefix, '{', sSigName, '}', sIndex, ']'];
        else
            sSpec = ['[', sPrefix, sIndex, ']'];
        end
        hDispInfo = i_setDisplayInfo(hIf);
        i_addModelInfo(hDispInfo, sRelPath, sBlockName, sSpec);
    end
end
end


%%
function hDispInfo = i_setDisplayInfo(hIf)
hDispInfo = mxx_xmltree('get_nodes', hIf, './ma:DisplayInfo');
if ~isempty(hDispInfo)
    mxx_xmltree('delete_node', hDispInfo);
end        
hDispInfo = mxx_xmltree('add_node', hIf, 'DisplayInfo');
end


%%
function hModelInfo = i_addModelInfo(hDispInfo, sRelPath, sBlockName, sSpec)
hModelInfo = mxx_xmltree('add_node', hDispInfo, 'ModelInfo');

mxx_xmltree('set_attribute', hModelInfo, 'relPath',   sRelPath);
mxx_xmltree('set_attribute', hModelInfo, 'name',      sBlockName);
mxx_xmltree('set_attribute', hModelInfo, 'specifier', sSpec);
end


%%
function i_addDisplayInfoCals(ahCals, sSubPath)
for i = 1:length(ahCals)
    hCal = ahCals(i);
    sVarName = mxx_xmltree('get_attribute', hCal, 'name');
    bIsExplicitParam = false;
    
    ahModelContexts = mxx_xmltree('get_nodes', hCal, './ma:ModelContext');
    casPrefix    = cell(1, length(ahModelContexts));
    casRelPath   = cell(1, length(ahModelContexts));
    casBlockName = cell(1, length(ahModelContexts));
    for k = 1:length(casPrefix)
        hModelContext = ahModelContexts(k);
        
        % start empty
        sPrefix = '';
        
        % SF name has top priority for prefix of specifier
        sSfVar = mxx_xmltree('get_attribute', hModelContext, 'sfVariable');
        if ~isempty(sSfVar)
            sPrefix = sSfVar;
        end
        
        % usage for "limited blockset" and var_name for "explicit param"
        if isempty(sPrefix)
            sUsage = mxx_xmltree('get_attribute', hModelContext, 'usage');
            if strcmpi(sUsage, 'explicit_param')
                sPrefix = sVarName;
                bIsExplicitParam = true;                
            else
                sPrefix = sUsage;
            end
        end
        
        sTlPath = mxx_xmltree('get_attribute', hModelContext, 'tlPath');        
        if (length(sTlPath) > length(sSubPath))
            sTlPath = strrep(sTlPath, [sSubPath, '/'], '');
            [sRelPath, sBlockName] = i_separatePathName(sTlPath);
        else
            sRelPath = '';
            [p, sBlockName] = i_separatePathName(sTlPath); %#ok p not used
        end
        
        casPrefix{k}    = sPrefix;
        casRelPath{k}   = sRelPath;
        casBlockName{k} = sBlockName;
    end
    
    ahIf = mxx_xmltree('get_nodes', hCal, './/ma:ifName');
    for j = 1:length(ahIf)
        hIf    = ahIf(j);
        sIndex = i_getIndexNamePart(hIf);
        
        sSigName = '';
        if bIsExplicitParam
            sSigName = mxx_xmltree('get_attribute', hIf, 'signalName');
        end
        
        hDispInfo = i_setDisplayInfo(hIf);
        for k = 1:length(casPrefix)
            sRelPath = casRelPath{k};
            sBlockName = casBlockName{k};
            if ~isempty(sSigName)
                sSpec = ['[', sSigName, sIndex, ']'];
            else
                sSpec = ['[', casPrefix{k}, sIndex, ']'];
            end
            i_addModelInfo(hDispInfo, sRelPath, sBlockName, sSpec);
        end       
    end
end
end


%%
function i_addDisplayInfoDisps(ahDisps, sSubPath)
for i = 1:length(ahDisps)
    hDisp = ahDisps(i);
    sKind  = mxx_xmltree('get_attribute', hDisp, 'compositeSig');
    bIsBus = strcmpi(sKind, 'bus');
    
    sSfVar = mxx_xmltree('get_attribute', hDisp, 'sfVariable');
    if ~isempty(sSfVar)
        sPrefix = sSfVar;
    else
        sPortNumber = mxx_xmltree('get_attribute', hDisp, 'portNumber');
        if strcmp(sPortNumber, '1')
            sPrefix = '';
        else
            sPrefix = ['#', sPortNumber];
        end
    end
    
    sPath = mxx_xmltree('get_attribute', hDisp, 'tlBlockPath');
    if (length(sPath) > length(sSubPath))
        sPath = strrep(sPath, [sSubPath, '/'], '');
        [sRelPath, sBlockName] = i_separatePathName(sPath);
    else
        sRelPath = '';
        [p, sBlockName] = i_separatePathName(sPath); %#ok p not used
    end

    ahIf = mxx_xmltree('get_nodes', hDisp, './/ma:ifName');
    for j = 1:length(ahIf)
        hIf    = ahIf(j);
        sIndex = i_getIndexNamePart(hIf);
        
        if bIsBus        
            sSigName = mxx_xmltree('get_attribute', hIf, 'signalName');
            if ~isempty(sSigName)
                sSigName = regexprep(sSigName, '^<signal1>', 'signal1');
            end
        else
            sSigName = '';
        end
        if (isempty(sPrefix) && isempty(sSigName))
            sSpec = sIndex;
        else
            if isempty(sPrefix)
                sPart = '[';
            else
                sPart = ['[', sPrefix];
            end
            if isempty(sSigName)
                sSpec = [sPart, sIndex, ']'];
            else
                sSpec = [sPart, '{', sSigName, '}', sIndex, ']'];
            end
        end
        hDispInfo = i_setDisplayInfo(hIf);
        i_addModelInfo(hDispInfo, sRelPath, sBlockName, sSpec);
    end
end
end


%%
function sIndex = i_getIndexNamePart(hIf)
sIndex  = '';
sIndex1 = mxx_xmltree('get_attribute', hIf, 'index1');
if isempty(sIndex1)
    return;
end

sIndex2 = mxx_xmltree('get_attribute', hIf, 'index2');
if isempty(sIndex2)
    sIndex = ['(', sIndex1, ')'];
else
    sIndex = ['(', sIndex1, ',', sIndex2, ')'];
end
end


%%
function [sPath, sName] = i_separatePathName(sFullPath)
% get rid of the double-symbols '//' which indicate a non-name-separator
sModPath  = regexprep(sFullPath, '//', 'xx');
aiNameSep = regexp(sModPath, '/');
if isempty(aiNameSep)
    sPath = '';
    sName = sFullPath;
else
    iLast = aiNameSep(end);
    sPath = sFullPath(1:(iLast - 1));
    if (iLast < length(sFullPath))
        sName = sFullPath((iLast+1):end);
    else
        sName = '';
    end
end
end

function atgcv_m01_assumptions_calmode_add(~, sAssumpFile, sModelAnaFile, sCalMode)
% Add Assumptions from ModelAnalysis and CAL usage to already existing AssumptionsFile.
%
%  atgcv_m01_assumptions_calmode_add(stEnv, sAssumpFile, sModelAnaFile, ...
%       sCalMode)
%   INPUT           DESCRIPTION
%     sEnv            (struct)       environment struct
%     sAssumpFile     (string)       path to InterfaceAssumptions.xml
%     sModelAnaFile   (string)       path to ModelAnalysis.xml
%     sCalMode        (string)       optional: 'init' | 'each_step'
%                                    (default is 'init')
%
%   OUTPUT          DESCRIPTION
%
%   REMARKS
%     Function modifies the original InterfaceAssumptions.xml!
%
%   <et_copyright>

%% internal
%
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 211853 $
%   Last modified: $Date: 2016-06-01 14:03:30 +0200 (Mi, 01 Jun 2016) $
%   $Author: ahornste $
%

if ((nargin < 4) || strcmpi(sCalMode, 'init'))
    bInitMode = true;
else
    bInitMode = false;
end

hAssDoc = mxx_xmltree('load', sAssumpFile);
oOnCleanupCloseAss = onCleanup(@() mxx_xmltree('clear', hAssDoc));

hMaDoc = mxx_xmltree('load', sModelAnaFile);
oOnCleanupCloseMa = onCleanup(@() mxx_xmltree('clear', hMaDoc));

ahMaSubs = mxx_xmltree('get_nodes', hMaDoc, '/ma:ModelAnalysis/ma:Subsystem');
for i = 1:length(ahMaSubs)
    hMaSub = ahMaSubs(i);
    sSubId = mxx_xmltree('get_attribute', hMaSub, 'id');
    
    hAssSub = mxx_xmltree('get_nodes', hAssDoc, ...
        sprintf('/InterfaceAssumption/Subsystem[@id="%s"]', sSubId));
    if isempty(hAssSub)
        hAssRoot = mxx_xmltree('get_root', hAssDoc);
        hAssSub  = mxx_xmltree('add_node', hAssRoot, 'Subsystem');
        mxx_xmltree('set_attribute', hAssSub, 'id', sSubId);
    end
    
    % time_const assumptions for all "anyButFixed" CALs
    if bInitMode
        sXpath = [ ...
            './ma:Interface/ma:Input/', ...
            'ma:Calibration/ma:Variable/ma:ifName'];
    else
        sXpath = ['./ma:Interface/maInput/', ...
            'ma:Calibration[@usage="explicit_param"]/ma:Variable/ma:ifName'];
    end
    astRes = mxx_xmltree('get_attributes', hMaSub, sXpath, 'ifid');
    if ~isempty(astRes)
        casIfid = {astRes(:).ifid};
        i_addTimeConstAssumption(hAssSub, casIfid);
    end
    
    % const_equal assumptions for restricted CALs
    sXpath = [ ...
        './ma:Interface/maInput/', ...
        'ma:Calibration[@restricted="yes"]/ma:Variable/ma:ifName'];
    ahCalIf = mxx_xmltree('get_nodes', hMaSub, sXpath);
    if ~isempty(ahCalIf)
        i_addConstEqualAssumption(hAssSub, ahCalIf);
    end
end
mxx_xmltree('save',  hAssDoc, sAssumpFile);
end




%%
function i_addTimeConstAssumption(hParent, casIfid)
hAss = mxx_xmltree('add_node', hParent, 'Assumption');
mxx_xmltree('set_attribute', hAss, 'origin', 'cal:init');

for i = 1:length(casIfid)
    hRel = mxx_xmltree('add_node', hAss, 'TimeRelation');
    mxx_xmltree('set_attribute', hRel, 'kind', 'CONST');
    mxx_xmltree('set_attribute', hRel, 'ifid', casIfid{i});
end
end


%%
function i_addConstEqualAssumption(hParent, ahIf)
hAss = mxx_xmltree('add_node', hParent, 'Assumption');
mxx_xmltree('set_attribute', hAss, 'origin', 'cal:restricted');

for i = 1:length(ahIf)
    sIfid    = mxx_xmltree('get_attribute', ahIf(i), 'ifid');
    sInitVal = mxx_xmltree('get_attribute', ahIf(i), 'initValue');
    
    hRel = mxx_xmltree('add_node', hAss, 'ConstRelation');
    mxx_xmltree('set_attribute', hRel, 'kind',      'EQU');
    mxx_xmltree('set_attribute', hRel, 'leftIfid',   sIfid);
    mxx_xmltree('set_attribute', hRel, 'rightConst', sInitVal);
end
end





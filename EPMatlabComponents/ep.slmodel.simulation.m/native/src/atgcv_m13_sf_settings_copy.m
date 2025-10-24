function atgcv_m13_sf_settings_copy(stEnv, sSrcMdl,sDestMdl,sUserMdlPath,sResultPath,sSampleTime)
% Copy the SF machine settings
% 
% Output:
%
% AUTHOR(S):
%   Remmer Wilts
% $$$COPYRIGHT$$$-2006
%
%%


% find rtw data of all open models
root      = sfroot;
saRtwData = root.find('-isa', 'Stateflow.Target', '-and', 'Name', 'sfun');
nRtwData  = length(saRtwData);

% search for the source and the destination chart
SrcID = 0;
DstID = 0;
for idx=1:nRtwData
    if ~isempty(saRtwData(idx).Machine)
        sName = saRtwData(idx).Machine(1).Name;
        if strcmp(sSrcMdl,sName)
            SrcID = idx;
        end
        if strcmp(sDestMdl,sName)
            DstID = idx;
        end
    end
end
if ((SrcID > 0) && (DstID > 0))
    hDest = saRtwData(DstID);
    hSrc = saRtwData(SrcID);
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'CustomCode' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'CustomInitializer' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'CustomInitializer' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'CustomTerminator' );
    % Default directoy assumed
    % atgcv_m13_property_copy( stEnv, hSrc, hDest, 'CodegenDirectory' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'ReservedNames' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'Document' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'Tag' );
    
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'UserSources' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'UserIncludeDirs' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'UserLibraries' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'ApplyToAllLibs' );
    atgcv_m13_property_copy( stEnv, hSrc, hDest, 'UseLocalCustomCodeSettings' );
    
    % CodeFlagsInfo is a RO option
    hDest.setCodeFlag('debug',hSrc.getCodeFlag('debug'));
    hDest.setCodeFlag('overflow',hSrc.getCodeFlag('overflow'));
    hDest.setCodeFlag('echo',hSrc.getCodeFlag('echo'));
    %set(hDest,'CodeFlagsInfo', hSrc.CodeFlagsInfo);
    
    
    % HS hack: if user sources are defined it's possible that the
    % Stateflow builder can't find the sources (source files defined
    % without full or relative path ...). As a workaround the *.c and
    % *.h files in the user directory are copied into the profile.
    if ~isempty( hSrc.UserSources )
        astRes = dir(fullfile(sUserMdlPath,'*.c*'));
        if ~isempty(astRes)
            copyfile( fullfile(sUserMdlPath,'*.c*'), sResultPath, 'f');
        end
        astRes = dir(fullfile(sUserMdlPath,'*.h'));
        if ~isempty(astRes)
            copyfile( fullfile(sUserMdlPath,'*.h'),  sResultPath, 'f');
        end
    end
end

% getting Stateflow root
root       = sfroot;

% getting machine of source model
srcMachine = root.find( '-isa', 'Stateflow.Machine', '-and', 'Name', sSrcMdl);
% return successfully if no Stateflow chart is in the source model
if isempty(srcMachine)
    return;
end

% getting machine of destination model
dstMachine = root.find( '-isa', 'Stateflow.Machine', '-and', 'Name', sDestMdl);
% return successfully if no Stateflow chart is in the destination model
% bugfix 4873 - Matlab crashes during model extraction
if isempty(dstMachine)
    return;
end


% Copy some settings (Properties might not be available in all SL
% versions
sEnableBitOps = get(srcMachine,'EnableBitOps');
set(dstMachine,'EnableBitOps', sEnableBitOps);

hSrcDebug = get(srcMachine,'Debug');
hDstDebug = get(dstMachine,'Debug');
hSrcBreakOn = get(hSrcDebug,'BreakOn');
hDstBreakOn = get(hDstDebug,'BreakOn');
hSrcRunTimeCheck = get(hSrcDebug,'RunTimeCheck');
hDstRunTimeCheck = get(hDstDebug,'RunTimeCheck');
hSrcAnimation = get(hSrcDebug,'Animation');
hDstAnimation = get(hDstDebug,'Animation');

dDisableAllBreakpoints = get(hSrcDebug, 'DisableAllBreakpoints');
set( hDstDebug, 'DisableAllBreakpoints', dDisableAllBreakpoints);

dChartEntry = get(hSrcBreakOn, 'ChartEntry');
set(hDstBreakOn, 'ChartEntry', dChartEntry);

dEventBroadcast = get(hSrcBreakOn, 'EventBroadcast');
set(hDstBreakOn, 'EventBroadcast', dEventBroadcast);

dStateEntry = get(hSrcBreakOn, 'StateEntry');
set(hDstBreakOn, 'StateEntry', dStateEntry);

dStateInconsistencies = get(hSrcRunTimeCheck, 'StateInconsistencies');
set( hDstRunTimeCheck, 'StateInconsistencies', dStateInconsistencies );

% from Matlab 2015b 'TransitionConflicts' is no longer an accessible property
if atgcv_version_p_compare('ML8.5') < 0
    dTransitionConflicts = get(hSrcRunTimeCheck, 'TransitionConflicts');
    set( hDstRunTimeCheck,'TransitionConflicts', dTransitionConflicts );
end

dDataRangeChecks = get(hSrcRunTimeCheck, 'DataRangeChecks');
set( hDstRunTimeCheck,'DataRangeChecks',dDataRangeChecks);

dCycleDetection = get(hSrcRunTimeCheck, 'CycleDetection');
set( hDstRunTimeCheck,'CycleDetection',dCycleDetection);

dEnabled = get(hSrcAnimation, 'Enabled');
set( hDstAnimation,'Enabled',dEnabled);

dDelay = get(hSrcAnimation, 'Delay');
set( hDstAnimation,'Delay',dDelay);

ahChartDst = dstMachine.find( '-isa', 'Stateflow.Chart');
%% Set the sample time, TODO check why necessary
set(ahChartDst,'SampleTime',sSampleTime);
%% Remove TL description, when available BTS/22197
set(ahChartDst,'Description', ''); 
%% Remove TL description from each sfObject

% for i = 1:length(ahChartDst)
%     hChartDst = ahChartDst(i);
%     sfStateHandle = hChartDst.Id;
%     dataItems = sf('DataOf', sfStateHandle);
%     for j=1:length(dataItems)
%         hSfObject = dataItems(j);
%         dataName = sf('get', hSfObject, '.name');
%         sDescription = sf('get', hSfObject, '.description');
%         sf( 'set', hSfObject,'.description','');
%     end
% end

%**************************************************************************
% END OF FILE
%**************************************************************************
classdef MetaAutosarRunnable
    
   properties
       sName = '';
       sSymbol = '',
       sSubsysPath = '';
       
       bIsInitFunction = false;
       bIsStepFunction = false;
       bIsSlFunction = false;
       bIsExportFunction = false;
       
       bIsModeled = false;
       
       dSampleTime = [];
       sRootInputTrigBlkName = '';
       bIsRootScope = false;
   end
end
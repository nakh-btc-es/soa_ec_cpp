% Init script for AUTOSAR wrapper model: Wrapper_SOA_demo_codegen
if ~isempty(which('init'))
  init;
else
  if exist('init.m', 'file')
    run('init.m');
  else
    warning('EP:CRITICAL', 'Original model init script could not be called. The wrapper model might be in an invalid state.');
  end
end


c_6A442= Simulink.Signal;
c_6A442.StorageClass = 'ExportedGlobal';
c_6A442.DataType = 'double';
c_6A442.Dimensions = [1 1];
c_6A442.Complexity = 'real';
c_6A442.InitialValue = '';
c_6A442.CoderInfo.Identifier = 'a_f_u_In';


c_6BB89= Simulink.Signal;
c_6BB89.StorageClass = 'ExportedGlobal';
c_6BB89.DataType = 'double';
c_6BB89.Dimensions = [1 1];
c_6BB89.Complexity = 'real';
c_6BB89.InitialValue = '';
c_6BB89.CoderInfo.Identifier = 'a_f_y_Out';
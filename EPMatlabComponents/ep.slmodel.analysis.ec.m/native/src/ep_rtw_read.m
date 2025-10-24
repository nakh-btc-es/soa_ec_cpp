function stContent = ep_rtw_read(sFileRTW)
sBaseVar = 'my_compiledModel';
sTlcFile = which('ep_rtw_read.tlc');
tlc('-v', '-r', sFileRTW, sTlcFile); 

stContent = evalin('base', sBaseVar);
evalin('base', ['clear ', sBaseVar]);
end

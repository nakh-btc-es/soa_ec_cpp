function sPath = ep_dspaceroot()
if exist('tl_env', 'file')
    sPath = tl_env('GetProductRoot');
else
    sPath = '';
end
end

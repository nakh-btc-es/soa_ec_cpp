function epecamsgbox(str, title, kind)

h = msgbox(str, title, kind);
%Set BTC icon
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
jframe=get(h,'javaframe');
iconfile = which('product-icon.png');
if  ~isempty(iconfile)
    jIcon=javax.swing.ImageIcon(iconfile);
    jframe.setFigureIcon(jIcon);
end

end
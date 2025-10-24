model = 'signal_dvPrivate_acMethod';
slbuild(model);

desc = coder.getCodeDescriptor(model);

% Show entry-point functions
fns = getFunctionInterfaces(desc);
{fns.Name}

% Show input ports
in = getDataInterfaces(desc, 'Inports');
{in.Name}

% Show generated source files
bi = getBuildInfo(desc);
bi.getSourceFiles()
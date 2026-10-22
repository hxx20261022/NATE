function root = setup_nate()
root=fileparts(mfilename('fullpath'));addpath(root);
assert(exist('fmincon','file')==2&&exist('lsqnonlin','file')==2, ...
 'nate:MissingToolbox','Install/enable MATLAB Optimization Toolbox.');
fprintf('NATE 1.0.0 ready: %s\n',root);
end

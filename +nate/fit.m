function model = fit(data,cfg)
if nargin<2,cfg=nate.default_config();end
assert(exist('fmincon','file')==2&&exist('lsqnonlin','file')==2, ...
    'nate:MissingToolbox','Optimization Toolbox is required.');
nate.internal.validate_fit_inputs(data,cfg);
warm=nate.internal.fit_core(data,cfg.thetaNominal,cfg.known,'FTF',[],[],cfg);
model=nate.internal.fit_core(data,cfg.thetaNominal,cfg.known,'NATE',warm,[],cfg);
model.config=cfg;model.warm_start=warm;model.version=cfg.version;
model.parameter_names={'L_H','C_F','RC_ohm'};
model.noise_names={'sigma_i_A','sigma_v_V'};
if warm.exitflag<=0||model.exitflag<=0
    warning('nate:Convergence','Inspect model.exitflag and model.warm_start.exitflag; at least one solve did not report successful termination.');
end
end

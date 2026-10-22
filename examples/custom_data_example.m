root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
cfg=nate.default_config();rng(7,'twister');
loads=[3.1 10.2 6.1];segments=cell(3,1);
for l=1:3
    n=239;s=repmat([1;0],120,1);s=s(1:n);dt=25e-6*ones(n,1);
    generator.theta=cfg.thetaNominal;generator.config=cfg;
    clean=nate.predict(generator,[24/loads(l),24],s,dt,loads(l));
    segments{l}=struct('y',clean+randn(size(clean)).*[0.01 0.02], ...
      'switch_state',s,'dt',dt,'Rload',loads(l));
end
data=nate.make_data(segments,180,181);
model=nate.fit(data,cfg);
evaluation=nate.evaluate(data,model);
disp(model.theta);disp(evaluation.summary);

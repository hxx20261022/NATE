function run_tests(runFit)
if nargin<1,runFit=true;end
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
cfg=nate.default_config();
x=[4 23];a=nate.step(x,1,8e-6,6.1,cfg.thetaNominal,cfg.known);
b=nate.step(a,1,12e-6,6.1,cfg.thetaNominal,cfg.known);
c=nate.step(x,1,20e-6,6.1,cfg.thetaNominal,cfg.known);
assert(norm(b-c,inf)<1e-10,'Matrix-exponential semigroup check failed.');
assert(norm(nate.step(x,0,0,6.1,cfg.thetaNominal,cfg.known)-x,inf)<1e-12);
data=nate.load_public();assert(data.n_loads==3);
res=[];
for l=1:3
 s=data.segments{l};assert(size(s.y,1)==240&&numel(s.dt)==239);
 assert(isequal(s.test_transition_idx,(181:239)'));
 for k=1:239
  res=[res;nate.step(s.y(k,:),s.switch_state(k),s.dt(k),s.Rload,cfg.thetaNominal,cfg.known)-s.y(k+1,:)];
 end
end
rmse=sqrt(mean(res.^2,1));assert(rmse(1)<1e-5&&rmse(2)<5e-5,'Public data/model alignment check failed.');
bad=data.segments;bad{1}.dt(1)=-1;failed=false;
try,nate.make_data(bad,180);catch,failed=true;end
assert(failed,'Negative time interval was accepted.');
short=nate.load_public([],60);assert(numel(short.segments{1}.train_state_idx)==61);
assert(isequal(short.segments{1}.test_transition_idx,data.segments{1}.test_transition_idx));
if runFit
 [model,evaluation]=run_example(0);
 assert(model.exitflag>0&&model.warm_start.exitflag>0,'Fit did not converge.');
 assert(max(abs(model.theta-cfg.thetaNominal)./cfg.thetaNominal)<0.002,'Clean identification regression failed.');
 assert(size(evaluation.prediction,1)==177);
 s=data.segments{1};idx=s.test_transition_idx;
 pred=nate.predict(model,s.y(181,:),s.switch_state(idx),s.dt(idx),s.Rload);
 assert(max(abs(pred(2:end,:)-evaluation.prediction(1:59,:)),[],'all')<1e-10);
 assert(evaluation.summary.voltage_rmse_V<1e-4,'Free-run regression failed.');
end
fprintf('All NATE package checks passed. Full fit: %d\n',runFit);
end

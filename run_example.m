function [model,evaluation] = run_example(caseId)
if nargin<1,caseId=0;end
validateattributes(caseId,{'numeric'},{'scalar','integer','>=',0,'<=',6});
root=setup_nate();
data=nate.load_public(fullfile(root,'data',sprintf('buckSimulation_%d.mat',caseId)));
cfg=nate.default_config();
fprintf('Fitting case %d: FTF warm start + NATE...\n',caseId);timer=tic;
model=nate.fit(data,cfg);elapsed=toc(timer);
evaluation=nate.evaluate(data,model);
reference=cfg.thetaNominal;
ARE=100*abs(model.theta-reference)./reference;
result=table(caseId,model.theta(1)*1e6,model.theta(2)*1e6,model.theta(3), ...
 mean(ARE),1000*evaluation.summary.voltage_rmse_V,1000*evaluation.summary.voltage_mae_V, ...
 model.noise_scales(1),model.noise_scales(2),model.exitflag,elapsed, ...
 'VariableNames',{'case_id','L_uH','C_uF','RC_ohm','mean_ARE_percent', ...
 'voltage_RMSE_mV','voltage_MAE_mV','sigma_i_A','sigma_v_V','exitflag','seconds'});
disp(result);
folder=fullfile(root,'output');if ~isfolder(folder),mkdir(folder);end
save(fullfile(folder,sprintf('case%d_model.mat',caseId)),'model','evaluation','result','cfg');
writetable(result,fullfile(folder,sprintf('case%d_summary.csv',caseId)));
writetable(evaluation.per_load,fullfile(folder,sprintf('case%d_per_load.csv',caseId)));
fprintf('Saved numeric results to %s\n',folder);
end

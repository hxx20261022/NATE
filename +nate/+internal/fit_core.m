function fit = fit_core(data, thetaNominal, known, method, warmStart, knownNoise, cfg)

if nargin < 5, warmStart = []; end
if nargin < 6, knownNoise = []; end
method = upper(string(method));
assert(any(method == ["FTF","NATE","ORACLE"]), 'method must be FTF, NATE, or ORACLE');

observed = [];
zObserved = zeros(data.n_loads,2);
for l = 1:data.n_loads
    seg = data.segments{l};
    observed = [observed; seg.y(seg.train_state_idx,:)];
    zObserved(l,:) = seg.y(seg.train_state_idx(1),:);
end
channelScale = std(observed,0,1);
stateScale = cfg.stateScale;

if isempty(warmStart)
    thetaStart = thetaNominal .* cfg.startFactors;
    zStart = zObserved;
else
    thetaStart = warmStart.theta;
    zStart = warmStart.initial_states;
end

xBase = [log(thetaStart ./ thetaNominal), reshape((zStart ./ stateScale)',1,[])]';
lbBase = [log(cfg.parameterLowerFactors), repmat((cfg.initialLower./stateScale)',data.n_loads,1)']';
ubBase = [log(cfg.parameterUpperFactors), repmat((cfg.initialUpper./stateScale)',data.n_loads,1)']';

if method == "FTF" || method == "ORACLE"
    if method == "FTF"
        residualScale = channelScale;
        sigma = [nan nan];
    else
        assert(numel(knownNoise)==2 && all(knownNoise>0), ...
            'ORACLE requires two positive known noise scales.');
        residualScale = knownNoise;
        sigma = knownNoise;
    end
    residualFun = @(x) trajectory_residuals(x,data,thetaNominal,known,stateScale,residualScale);
    options = optimoptions('lsqnonlin','Display','off', ...
        'MaxIterations',120,'MaxFunctionEvaluations',2400, ...
        'FunctionTolerance',1e-10,'StepTolerance',1e-10, ...
        'OptimalityTolerance',1e-8,'FiniteDifferenceType','forward');
    [x,fval,residual,exitflag,output] = lsqnonlin(residualFun,xBase,lbBase,ubBase,options);
else
    if ~isempty(warmStart) && all(isfinite(warmStart.noise_scales))
        sigmaStart = warmStart.noise_scales;
    else
        raw = trajectory_residuals(xBase,data,thetaNominal,known,stateScale,[1 1]);
        raw = reshape(raw,2,[])';
        sigmaStart = max(sqrt(mean(raw.^2,1)),[1e-4 1e-4]);
    end
    sigmaStart = min(max(sigmaStart,cfg.noiseLower),cfg.noiseUpper);
    x0 = [xBase; log(sigmaStart(:) ./ channelScale(:))];
    lb = [lbBase; log(cfg.noiseLower(:) ./ channelScale(:))];
    ub = [ubBase; log(cfg.noiseUpper(:) ./ channelScale(:))];
    objective = @(x) nate_objective(x,data,thetaNominal,known,stateScale,channelScale);
    options = optimoptions('fmincon','Algorithm','sqp','Display','off', ...
        'MaxIterations',180,'MaxFunctionEvaluations',5000, ...
        'FunctionTolerance',1e-9,'StepTolerance',1e-10, ...
        'OptimalityTolerance',1e-7,'FiniteDifferenceType','forward');
    [x,fval,exitflag,output] = fmincon(objective,x0,[],[],[],[],lb,ub,[],options);
    residual = trajectory_residuals(x(1:end-2),data,thetaNominal,known,stateScale,[1 1]);
    sigma = channelScale .* exp(x(end-1:end))';
    x = x(1:end-2);
end

[theta,z] = decode_base(x,thetaNominal,stateScale,data.n_loads);
fit.method = char(method);
fit.theta = theta;
fit.initial_states = z;
fit.noise_scales = sigma;
fit.objective = fval;
fit.residual = residual;
fit.exitflag = exitflag;
fit.output = output;
fit.channel_scale = channelScale;
end

function residual = trajectory_residuals(x,data,thetaNominal,known,stateScale,residualScale)
[theta,z] = decode_base(x,thetaNominal,stateScale,data.n_loads);
nStates = data.n_loads * (data.n_train_transitions + 1);
residualMatrix = zeros(nStates,2);
cursor = 1;
for l = 1:data.n_loads
    seg = data.segments{l};
    predicted = zeros(data.n_train_transitions+1,2);
    predicted(1,:) = z(l,:);
    for j = 1:data.n_train_transitions
        k = seg.train_transition_idx(j);
        predicted(j+1,:) = nate.step(predicted(j,:),seg.switch_state(k), ...
            seg.dt(k),seg.Rload,theta,known);
    end
    n = size(predicted,1);
    residualMatrix(cursor:cursor+n-1,:) = ...
        (predicted - seg.y(seg.train_state_idx,:)) ./ residualScale;
    cursor = cursor + n;
end
residual = reshape(residualMatrix',[],1);
end

function value = nate_objective(x,data,thetaNominal,known,stateScale,channelScale)
base = x(1:end-2);
sigma = channelScale .* exp(x(end-1:end))';
raw = trajectory_residuals(base,data,thetaNominal,known,stateScale,[1 1]);
raw = reshape(raw,2,[])';
n = size(raw,1);
value = sum(raw(:,1).^2)/(sigma(1)^2) + n*log(sigma(1)^2) + ...
        sum(raw(:,2).^2)/(sigma(2)^2) + n*log(sigma(2)^2);
end

function [theta,z] = decode_base(x,thetaNominal,stateScale,nLoads)
theta = thetaNominal .* exp(x(1:3))';
zScaled = reshape(x(4:end),2,nLoads)';
z = zScaled .* stateScale;
end

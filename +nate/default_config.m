function cfg = default_config()
cfg.version = '1.0.0';
cfg.thetaNominal = [725e-6 164.5e-6 0.201];
cfg.known = struct('RL',0.314,'Ron',0.221,'Vin',48,'Vf',1);
cfg.stateScale = [10 30];
cfg.startFactors = [0.90 1.10 1.15];
cfg.parameterLowerFactors = [0.40 0.40 0.30];
cfg.parameterUpperFactors = [1.60 1.60 2.00];
cfg.initialLower = [0 13.5];
cfg.initialUpper = [12 33];
cfg.noiseLower = [1e-5 1e-5];
cfg.noiseUpper = [2 5];
end

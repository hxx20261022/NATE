function validate_fit_inputs(data,cfg)
required={'thetaNominal','known','stateScale','startFactors','parameterLowerFactors', ...
 'parameterUpperFactors','initialLower','initialUpper','noiseLower','noiseUpper','version'};
assert(all(isfield(cfg,required)),'nate:InvalidConfig','Start from nate.default_config().');
for field={'thetaNominal','startFactors','parameterLowerFactors','parameterUpperFactors'}
    validateattributes(cfg.(field{1}),{'double'},{'row','numel',3,'finite','real','positive'});
end
for field={'stateScale','noiseLower','noiseUpper'}
    validateattributes(cfg.(field{1}),{'double'},{'row','numel',2,'finite','real','positive'});
end
for field={'initialLower','initialUpper'}
    validateattributes(cfg.(field{1}),{'double'},{'row','numel',2,'finite','real'});
end
assert(all(cfg.parameterLowerFactors<cfg.parameterUpperFactors)&& ...
 all(cfg.startFactors>=cfg.parameterLowerFactors)&all(cfg.startFactors<=cfg.parameterUpperFactors), ...
 'nate:InvalidConfig','Invalid parameter bounds or starting factors.');
assert(all(cfg.initialLower<cfg.initialUpper)&&all(cfg.noiseLower<cfg.noiseUpper), ...
 'nate:InvalidConfig','Lower bounds must be below upper bounds.');
assert(all(isfield(cfg.known,{'RL','Ron','Vin','Vf'})),'nate:InvalidConfig','Missing known circuit quantities.');
for field={'RL','Ron','Vin','Vf'}
    validateattributes(cfg.known.(field{1}),{'double'},{'scalar','finite','real','nonnegative'});
end
assert(data.n_loads==numel(data.segments),'nate:InvalidData','Segment count mismatch.');
observed=[];
for l=1:data.n_loads
    s=data.segments{l};n=data.n_train_transitions;
    assert(isequal(s.train_transition_idx(:),(1:n)')&&isequal(s.train_state_idx(:),(1:n+1)'), ...
      'nate:InvalidData','Use nate.make_data to construct consecutive training windows.');
    validateattributes(s.y,{'double'},{'2d','ncols',2,'finite','real'});
    validateattributes(s.dt,{'double'},{'vector','positive','finite','real'});
    validateattributes(s.Rload,{'double'},{'scalar','positive','finite','real'});
    assert(size(s.y,1)==numel(s.dt)+1&&numel(s.switch_state)==numel(s.dt)&& ...
      all(ismember(s.switch_state,[0 1])),'nate:InvalidData','Misaligned state and transition arrays.');
    assert(all(s.y(1,:)>=cfg.initialLower)&all(s.y(1,:)<=cfg.initialUpper), ...
      'nate:InvalidData','Initial observation outside configured bounds; adjust cfg.initialLower/Upper.');
    observed=[observed;s.y(1:n+1,:)];
end
assert(all(std(observed,0,1)>0),'nate:InvalidData','Both training channels need nonzero variance.');
end

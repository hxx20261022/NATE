function data = load_public_core(matFile,nTrain)

if nargin < 2, nTrain = 180; end
assert(nTrain>=1 && nTrain<=180 && nTrain==round(nTrain), ...
    'nTrain must be an integer from 1 to 180.');
raw = load(matFile);
loads = unique(raw.Rload, 'stable');
segments = cell(numel(loads), 1);

for l = 1:numel(loads)
    idx = find(raw.Rload == loads(l));
    assert(numel(idx) == 480, 'Expected 480 stored rows per load segment.');
    groups = reshape(idx, 4, [])';

    stateIdx = [groups(1,1); reshape(groups(:,[2 4])', [], 1)];
    switchAll = reshape(raw.Dswitch(groups(:,[1 3]))', [], 1);
    dtAll = reshape(raw.dt(groups(:,[1 3]))', [], 1);

    seg.y = [raw.Current(stateIdx(1:240)), raw.Voltage(stateIdx(1:240))];
    seg.switch_state = switchAll(1:239);
    seg.dt = dtAll(1:239);
    seg.Rload = loads(l);
    seg.train_transition_idx = (1:nTrain)';
    seg.test_transition_idx = (181:239)';
    seg.train_state_idx = (1:nTrain+1)';
    seg.test_state_idx = (181:240)';
    segments{l} = seg;
end

data.source_file = matFile;
data.segments = segments;
data.loads = loads;
data.n_loads = numel(loads);
data.n_transitions_per_load = 239;
data.n_train_transitions = nTrain;
data.n_test_transitions = 59;
end

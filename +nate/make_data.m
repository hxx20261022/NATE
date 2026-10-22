function data = make_data(segments,nTrain,testStart)
if nargin<3,testStart=nTrain+1;end
validateattributes(nTrain,{'numeric'},{'scalar','integer','positive'});
validateattributes(testStart,{'numeric'},{'scalar','integer','>',nTrain});
assert(iscell(segments)&&~isempty(segments),'nate:InvalidData','segments must be a nonempty cell array.');
for l=1:numel(segments)
    seg=segments{l};
    assert(all(isfield(seg,{'y','switch_state','dt','Rload'})),'nate:InvalidData','Missing segment fields.');
    validateattributes(seg.y,{'double'},{'2d','ncols',2,'real','finite'});
    n=size(seg.y,1)-1;
    validateattributes(seg.switch_state,{'numeric','logical'},{'vector','numel',n,'real','finite'});
    assert(all(ismember(seg.switch_state,[0 1])),'nate:InvalidData','Switch states must be 0 or 1.');
    validateattributes(seg.dt,{'double'},{'vector','numel',n,'real','finite','positive'});
    validateattributes(seg.Rload,{'double'},{'scalar','real','finite','positive'});
    assert(testStart<=n,'nate:InvalidData','Each segment must contain at least one test transition.');
    seg.switch_state=double(seg.switch_state(:));seg.dt=seg.dt(:);
    seg.train_transition_idx=(1:nTrain)';seg.train_state_idx=(1:nTrain+1)';
    seg.test_transition_idx=(testStart:n)';seg.test_state_idx=(testStart:n+1)';
    segments{l}=seg;
end
data.segments=segments;data.n_loads=numel(segments);data.n_train_transitions=nTrain;
data.loads=cellfun(@(s)s.Rload,segments);
data.n_test_transitions=cellfun(@(s)numel(s.test_transition_idx),segments);
data.source_file='custom';
end

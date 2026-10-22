function data = load_public(matFile,nTrain)
if nargin<1||isempty(matFile)
    root=fileparts(fileparts(mfilename('fullpath')));
    matFile=fullfile(root,'data','buckSimulation_0.mat');
end
if nargin<2,nTrain=180;end
raw=nate.internal.load_public_core(matFile,nTrain);
data=nate.make_data(raw.segments,nTrain,181);
data.source_file=char(matFile);data.n_transitions_per_load=239;
end

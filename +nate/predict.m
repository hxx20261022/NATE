function states = predict(model,x0,switchState,dt,Rload)
validateattributes(x0,{'double'},{'vector','numel',2,'finite','real'});
validateattributes(dt,{'double'},{'vector','positive','finite','real'});
n=numel(dt);
validateattributes(switchState,{'numeric','logical'},{'vector','numel',n,'finite','real'});
assert(all(ismember(switchState,[0 1])),'nate:InvalidSwitch','Switch states must be 0 or 1.');
validateattributes(Rload,{'double'},{'scalar','positive','finite','real'});
validateattributes(model.theta,{'double'},{'vector','numel',3,'positive','finite','real'});
states=zeros(n+1,2);states(1,:)=x0(:)';
for k=1:n
    states(k+1,:)=nate.step(states(k,:),switchState(k),dt(k),Rload,model.theta,model.config.known);
end
end

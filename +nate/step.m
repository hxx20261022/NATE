function xNext = step(x, switchState, dt, Rload, theta, known)

L = theta(1);
C = theta(2);
RC = theta(3);
s = switchState;

Rseries = known.RL + s * known.Ron;
b1 = (s * known.Vin - (1-s) * known.Vf) / L;
a11 = -Rseries / L;
a12 = -1 / L;

alpha = RC * Rload / (RC + Rload);
a21 = alpha * a11 + Rload / (C * (RC + Rload));
a22 = alpha * a12 - 1 / (C * (RC + Rload));
b2 = alpha * b1;

augmented = [a11 a12 b1; a21 a22 b2; 0 0 0];
transition = expm(augmented * dt);
nextAugmented = transition * [x(:); 1];
xNext = nextAugmented(1:2)';
end

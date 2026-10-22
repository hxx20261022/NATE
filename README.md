# NATE

**Noise-Adaptive Trajectory Estimation** for buck-converter parameter estimation and free-running prediction.

MATLAB + Optimization Toolbox · Tested on R2024a

## Install

```bash
git clone https://github.com/hxx20261022/NATE.git
cd NATE
```

Open MATLAB in the repository folder:

```matlab
setup_nate;
```

## Run an example

```matlab
[model, evaluation] = run_example(0);

model.theta
model.noise_scales
evaluation.summary
evaluation.per_load
```

Cases `0–6` are included. Outputs are saved in `output/`.

```matlab
[model, evaluation] = run_example(6);
```

| Output | Values |
|---|---|
| `model.theta` | `[L, C, RC]` in H, F, ohm |
| `model.noise_scales` | `[sigma_i, sigma_v]` in A, V |
| `model.initial_states` | Initial current and voltage for each segment |
| `evaluation.summary` | Pooled prediction-error metrics |

## Estimate and evaluate

```matlab
cfg = nate.default_config();
data = nate.load_public(fullfile('data', 'buckSimulation_0.mat'), 180);

model = nate.fit(data, cfg);
evaluation = nate.evaluate(data, model);

model.exitflag
model.warm_start.exitflag
```

For a shorter training window with the same test window:

```matlab
data = nate.load_public([], 60);
model = nate.fit(data, cfg);
evaluation = nate.evaluate(data, model);
```

## Predict

```matlab
seg = data.segments{1};
idx = seg.test_transition_idx;
x0 = seg.y(seg.test_state_idx(1), :);

states = nate.predict(model, x0, ...
    seg.switch_state(idx), seg.dt(idx), seg.Rload);

current = states(2:end, 1);
voltage = states(2:end, 2);
```

The first row of `states` is the initial state; subsequent rows are free-running predictions.

## Use your data

Supply measured column vectors in SI units; each segment has a constant load.

```matlab
segments = cell(1, 1);
segments{1}.y = [current_A, voltage_V];
segments{1}.switch_state = switch_states;
segments{1}.dt = interval_seconds;
segments{1}.Rload = 6.1;

data = nate.make_data(segments, 180, 181);
cfg = nate.default_config();

cfg.thetaNominal = [725e-6, 164.5e-6, 0.201];
cfg.known = struct('RL', 0.314, 'Ron', 0.221, 'Vin', 48, 'Vf', 1);
cfg.parameterLowerFactors = [0.4, 0.4, 0.3];
cfg.parameterUpperFactors = [1.6, 1.6, 2.0];
cfg.initialLower = [0, 13.5];
cfg.initialUpper = [12, 33];
cfg.noiseLower = [1e-5, 1e-5];
cfg.noiseUpper = [2, 5];

model = nate.fit(data, cfg);
evaluation = nate.evaluate(data, model);
```

Replace the example circuit values and bounds with those of your converter.

| Field | Shape | Content |
|---|---|---|
| `y` | `(N+1) × 2` | Current (A), voltage (V) at unique interval boundaries |
| `switch_state` | `N × 1` | Binary switch states |
| `dt` | `N × 1` | Positive interval durations (s) |
| `Rload` | Scalar | Load resistance (ohm) |

A complete synthetic-data example is also available:

```matlab
run(fullfile('examples', 'custom_data_example.m'));
```

## Save and load

```matlab
save('nate_model.mat', 'model');
saved = load('nate_model.mat', 'model');
model = saved.model;
```

## Test

```matlab
addpath('tests');
run_tests;
```

Quick checks without refitting:

```matlab
run_tests(false);
```

[Default settings](+nate/default_config.m) · [Custom-data example](examples/custom_data_example.m) · [Data license](data/LICENSE)

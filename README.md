# NATE MATLAB Package

**Noise-Adaptive Trajectory Estimation (NATE), version 1.0.0.**

NATE estimates the inductance, capacitance, and capacitor equivalent series resistance of an asynchronous DC–DC buck converter. Inputs include inductor current, output voltage, binary switch states, interval durations, and load resistance. The estimator also fits segment-specific initial states and two measurement-noise scales. Free-running prediction and test-error evaluation are included.

## Requirements

- Tested with MATLAB R2024a.
- Optimization Toolbox (`lsqnonlin` and `fmincon`).
- Examples run serially without Python, TensorFlow, or Parallel Computing Toolbox.

## Quick Start

Clone or download this repository, open its root folder in MATLAB, and run:

```matlab
setup_nate;
[model, evaluation] = run_example(0);
model.theta
model.noise_scales
evaluation.summary
```

Case 0 is the clean benchmark; `run_example(6)` runs the combined high-noise case. All seven public cases, numbered 0–6, are included.

Each run performs fixed-weight trajectory fitting (FTF) for initialization, followed by NATE optimization. Results are saved in `output/` as a model MAT file, a summary CSV, and a per-load CSV. Repeating a case updates its output files.

## Core API

```matlab
cfg = nate.default_config();
data = nate.load_public();
model = nate.fit(data, cfg);
evaluation = nate.evaluate(data, model);

seg = data.segments{1};
idx = seg.test_transition_idx;
states = nate.predict(model, seg.y(181,:), ...
    seg.switch_state(idx), seg.dt(idx), seg.Rload);
voltage = states(:,2);
```

The default loader uses case 0 and 180 training transitions. `nate.fit` automatically computes the FTF warm start. The first row of `states` is the initial state; the remaining 59 rows are predictions.

`model.theta` contains `[L, C, RC]` in H, F, and ohm. `model.noise_scales` contains `[sigma_i, sigma_v]` in A and V. Additional fields include `initial_states`, `exitflag`, `output`, `objective`, `channel_scale`, `config`, and `warm_start`. Check both `model.exitflag` and `model.warm_start.exitflag` for solver termination status.

## Custom Data

Represent each constant-load segment as a structure using SI units:

```matlab
segments{1}.y = [current_A, voltage_V];
segments{1}.switch_state = s;
segments{1}.dt = interval_seconds;
segments{1}.Rload = 6.1;

data = nate.make_data(segments, 180, 181);
cfg = nate.default_config();
model = nate.fit(data, cfg);
```

| Field | Shape | Description |
|---|---|---|
| `y` | `(N+1) × 2` | Chronologically ordered, unique boundary states: current in A and voltage in V |
| `switch_state` | `N × 1` | Binary switch state for each interval |
| `dt` | `N × 1` | Positive interval duration in seconds |
| `Rload` | Scalar | Constant load resistance in ohm |

Add further segments to the cell array as needed. All segments share the circuit parameters. Set `cfg.thetaNominal`, `cfg.known`, and the bounds for your converter before fitting.

In `make_data(segments,nTrain,testStart)`, `testStart` is a MATLAB one-based transition index and defaults to `nTrain+1`. Every segment must contain at least one test transition. Segments share the same training length but may have different total lengths.

Run the standalone synthetic-data example with:

```matlab
run(fullfile('examples','custom_data_example.m'));
```

The public-data loader reconstructs the benchmark's four-row PWM format. For custom data, supply boundary sequences with duplicate boundaries already removed.

## Default Configuration

Nominal parameters are `[725e-6, 164.5e-6, 0.201]`. Known quantities are `RL=0.314`, `Ron=0.221`, `Vin=48`, and `Vf=1`, in SI units. Default optimization settings match the study's numerical implementation.

| Configuration field | Default | Description |
|---|---|---|
| `thetaNominal` | `[725e-6 164.5e-6 0.201]` | Nominal L, C, and RC in H, F, and ohm |
| `parameterLowerFactors` | `[0.4 0.4 0.3]` | Lower-bound multipliers of nominal parameters |
| `parameterUpperFactors` | `[1.6 1.6 2.0]` | Upper-bound multipliers of nominal parameters |
| `startFactors` | `[0.9 1.1 1.15]` | FTF starting-value multipliers |
| `stateScale` | `[10 30]` | Numerical scaling of initial states |
| `initialLower` | `[0 13.5]` | Initial-state lower bounds in A and V |
| `initialUpper` | `[12 33]` | Initial-state upper bounds in A and V |
| `noiseLower` | `[1e-5 1e-5]` | Noise-scale lower bounds in A and V |
| `noiseUpper` | `[2 5]` | Noise-scale upper bounds in A and V |

Initial observations must lie within the configured initial-state bounds. Both training channels must have nonzero sample variance. Vector configuration fields must be row vectors. The benchmark defaults use the published parameter values as nominal scales; adjust them and their bounds for other converters.

## Model and Evaluation

- The state is `[i_L, v_o]`. A 3 × 3 augmented matrix exponential computes the exact affine transition within each constant-switch interval.
- FTF uses fixed training-channel sample standard deviations. NATE jointly estimates circuit parameters, segment-specific initial states, and two shared noise scales.
- The NATE objective is `RSS_i/sigma_i^2 + n*log(sigma_i^2) + RSS_v/sigma_v^2 + n*log(sigma_v^2)`, where `n` includes the initial observation of each segment.
- Each public-data segment contains 240 reconstructed states and 239 retained transitions. The default split uses 180 training transitions and test transitions 181–239. `nate.load_public([],60)` and `nate.load_public([],120)` retain the same test window.
- `predict` uses the initial state, switch states, interval durations, and load resistance without subsequent observation updates.
- `evaluate(data,model)` initializes from the supplied test-boundary observation and evaluates against the supplied observations, excluding the initialization point. Pass clean data explicitly when using the clean-reference protocol for synthetic-noise experiments.
- The model uses two-state affine dynamics with constant load within each segment. Zero-current clamping events are not modeled.

## Tests

```matlab
addpath('tests');
run_tests;
```

Use `run_tests(false)` to skip the full fitting check. Tests cover matrix-exponential consistency, clean-data one-step errors, fixed test indices, invalid interval rejection, parameter recovery, and agreement between the prediction and evaluation APIs. Results are displayed in the MATLAB command window.

## Repository Structure

```text
NATE/
  +nate/               Public API and internal solvers
  data/                Seven public simulation cases and their license
  examples/            Custom-data example
  tests/               Numerical and integration checks
  setup_nate.m         Session path setup
  run_example.m        Parameter estimation and evaluation
  README.md
```

Add only the repository root to the MATLAB path. MATLAB manages the `+nate` namespace directories automatically.

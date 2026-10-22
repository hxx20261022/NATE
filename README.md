# NATE

**Noise-Adaptive Trajectory Estimation**

A MATLAB package for buck-converter parameter estimation and free-running prediction.

## Quick start

Requires MATLAB with Optimization Toolbox. Tested on R2024a.

Open the repository folder in MATLAB and run:

```matlab
setup_nate;
[model, evaluation] = run_example(0);
```

Cases `0–6` are included. Results are saved to `output/`.

## API

```matlab
cfg = nate.default_config();
data = nate.load_public();
model = nate.fit(data, cfg);
evaluation = nate.evaluate(data, model);
```

| Output | Values |
|---|---|
| `model.theta` | Inductance (H), capacitance (F), capacitor ESR (ohm) |
| `model.noise_scales` | Current noise (A), voltage noise (V) |
| `evaluation.summary` | Prediction error metrics |

## Your data

Provide one structure per constant-load segment. All quantities use SI units.

| Field | Shape | Content |
|---|---|---|
| `y` | `(N+1) × 2` | Current and voltage at unique interval boundaries |
| `switch_state` | `N × 1` | Binary switch states |
| `dt` | `N × 1` | Positive interval durations |
| `Rload` | Scalar | Load resistance |

```matlab
data = nate.make_data(segments, 180, 181);
cfg = nate.default_config();
model = nate.fit(data, cfg);
```

Set `cfg.thetaNominal`, `cfg.known`, and the bounds for your converter before fitting.

[Custom-data example](examples/custom_data_example.m) · [Default settings](+nate/default_config.m) · [Tests](tests/run_tests.m) · [Data license](data/LICENSE)

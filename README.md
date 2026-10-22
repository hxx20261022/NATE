# NATE MATLAB 模型包

**Noise-Adaptive Trajectory Estimation (NATE)，版本 1.0.0。**

用于非同步DC–DC Buck变换器的参数估计。输入电感电流、输出电压、二值开关状态、区间持续时间及负载电阻，输出电感L、电容C、电容ESR R_C、各负载段初始状态及两个通道的噪声标准差。支持自由递推预测与测试误差评价。

## 环境

- MATLAB R2024a为本包验证版本。
- 需要Optimization Toolbox（`lsqnonlin`、`fmincon`）。
- 示例串行运行，不依赖Python、TensorFlow、并行工具箱或原项目路径。

## 快速运行

解压后进入`NATE_MATLAB`文件夹，在MATLAB命令窗口执行：

```matlab
setup_nate;
[model, evaluation] = run_example(0); % 0=清洁公开场景
model.theta                         % [L(H), C(F), RC(ohm)]
model.noise_scales                  % [sigma_i(A), sigma_v(V)]
evaluation.summary
```

`run_example(6)`运行复合高噪声场景。七个公开场景0–6均随包提供。
第一次运行包括FTF暖启动和NATE优化，运行时间取决于设备。结果写入包内`output/`：模型MAT、汇总CSV和逐负载CSV。同一场景再次运行会更新该场景结果文件。

## 核心接口

```matlab
cfg = nate.default_config();
data = nate.load_public();             % 默认场景0，训练180转移
model = nate.fit(data, cfg);           % 自动FTF暖启动后求解NATE
evaluation = nate.evaluate(data, model);

seg = data.segments{1};
idx = seg.test_transition_idx;
states = nate.predict(model, seg.y(181,:), ...
    seg.switch_state(idx), seg.dt(idx), seg.Rload);
voltage = states(:,2);                 % 第1行是初始化，后59行是预测
```

`model`还包含`initial_states`、`exitflag`、`output`、`objective`、`channel_scale`、`config`及`warm_start`。`exitflag`和`warm_start.exitflag`应分别检查。

## 自有数据

每个负载段是一个结构体，负载在段内保持常数。所有量使用SI单位：

```matlab
segments{1}.y = [current_A, voltage_V]; % (N+1)×2，时间排序的唯一边界状态
segments{1}.switch_state = s;         % N×1，每区间为0或1
segments{1}.dt = interval_seconds;    % N×1，每区间持续时间>0
segments{1}.Rload = 6.1;              % 标量，ohm
% 可加入更多负载段，参数L/C/RC由所有段共享。
data = nate.make_data(segments, 180, 181);
cfg = nate.default_config();
% 按实际设备设置cfg.thetaNominal、cfg.known及边界。
model = nate.fit(data, cfg);
```

`make_data(segments,nTrain,testStart)`的`testStart`采用MATLAB一起点转移索引，默认`nTrain+1`。每段需至少有一个测试转移；各段训练长度相同，完整记录长度可以不同。使用自己的数据时需提供`segments`中所有必要字段。

独立可运行的合成数据示例：

```matlab
run(fullfile('examples','custom_data_example.m'));
```

公开数据专用加载器负责四行PWM格式重建。自有数据通过`make_data`输入已经去除重复边界的序列。

## 默认模型与约束

标称参数为`[725e-6,164.5e-6,0.201]`；已知量为`RL=0.314`、`Ron=0.221`、`Vin=48`、`Vf=1`。默认优化设置与论文计算代码保持一致。

| 配置字段 | 默认值 | 说明 |
|---|---|---|
| `thetaNominal` | `[725e-6 164.5e-6 0.201]` | H、F、ohm |
| `parameterLowerFactors` | `[0.4 0.4 0.3]` | 相对标称参数下界 |
| `parameterUpperFactors` | `[1.6 1.6 2.0]` | 相对标称参数上界 |
| `startFactors` | `[0.9 1.1 1.15]` | FTF参数初值倍率 |
| `stateScale` | `[10 30]` | 初始状态数值缩放 |
| `initialLower` | `[0 13.5]` | 初始电流A、初始电压V下界 |
| `initialUpper` | `[12 33]` | 初始电流A、初始电压V上界 |
| `noiseLower` | `[1e-5 1e-5]` | 电流A、电压V噪声尺度下界 |
| `noiseUpper` | `[2 5]` | 电流A、电压V噪声尺度上界 |

初始观测必须位于配置的初始状态边界内。两个训练通道都需有非零样本方差。所有向量配置采用行向量。默认基准的标称尺度取自公开参数；使用不同电路时应设置相应标称量和边界。

## 计算与评价协议

- 状态为`[i_L,v_o]`，每个常开关区间用3×3增广矩阵指数计算精确仿射转移。
- FTF采用固定的训练通道样本标准差；NATE联合优化参数、各段初始状态和共享的两个噪声尺度。
- NATE目标：`RSS_i/sigma_i^2 + n*log(sigma_i^2) + RSS_v/sigma_v^2 + n*log(sigma_v^2)`；`n`包括每段初始观测。
- 公开数据每段重建240个状态和239次转移；默认前180次训练，转移181–239测试。`nate.load_public([],60)`或120仍保留相同测试窗口。
- `predict`只接收初始状态及开关、时间和负载信息；后续没有观测更新。
- `evaluate(data,model)`以传入`data`的测试观测初始化并作为评价参照，排除初始化点。公开示例按含噪观测评价；合成实验需要传入清洁`data`才能得到论文中的清洁参照协议。
- 模型采用每段恒定负载的二状态仿射动态，没有零电流钳位事件处理。

## 验证

```matlab
addpath('tests');
run_tests;          % 包含完整清洁数据拟合及预测检查
run_tests(false);   % 只运行快速动态、索引及输入校验
```

测试包括矩阵指数半群一致性、清洁公开数据一步误差、固定测试索引、非法持续时间拒绝、参数恢复、预测API与评价API一致性。验证结果在MATLAB命令窗口显示。

## 文件结构

```text
NATE_MATLAB/
  +nate/               公共API和内部求解代码
  data/                七个公开仿真场景
  examples/            自有数据接入示例
  tests/               数值与集成检查
  setup_nate.m         当前会话安装路径
  run_example.m        一键估计与评价
  README.md
```

这是独立源代码包；将根目录加入当前会话路径即可使用。`+nate`内部目录由MATLAB命名空间管理。

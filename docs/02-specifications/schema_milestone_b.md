# AIWA Milestone B 输出规范文档（vB1.1）

---

## 1️⃣ neutral_keypoints.json Schema（vB1.1）

### 顶层结构
| 字段 | 类型 | 说明 |
|------|------|------|
| version | string | 固定 `"vB1.1"` |
| video | object | 视频信息 |
| engine | object | 推理引擎信息 |
| sampling | object | 采样参数 |
| frames | array<Frame> | 帧序列数据 |

### video
| 字段 | 类型 | 说明 |
|------|------|------|
| fpsIntended | number | 处理前帧率，默认 30 |
| width / height | int | 输入分辨率（720p） |
| durationMs | int | 视频时长 |

### engine
| 字段 | 类型 | 说明 |
|------|------|------|
| name | string | `"mlkit"` |
| model | string | `"blazepose-full"` |
| sdkVersion | string | ML Kit SDK 版本号 |

### sampling
| 字段 | 类型 | 说明 |
|------|------|------|
| stride | int | 抽样步长，默认 2 |
| effectiveFps | number | 有效帧率 = fpsIntended / stride |

### Frame
| 字段 | 类型 | 说明 |
|------|------|------|
| frameIndex | int | 帧序号 |
| timestampMs | int | 相对首帧 0 ms |
| lowConfidence | bool | 帧是否低置信 |
| mirrorApplied | bool | 是否在适配层执行了左右翻转（前置摄像头为 true） |
| keypoints | array<Keypoint> | 当前帧关键点 |

### Keypoint
| 字段 | 类型 | 说明 |
|------|------|------|
| name | string | 中立语义名称 (nose / leftHip …) |
| x / y | float (0–1) | 坐标归一化 |
| z | float (可选) | 深度坐标 |
| score | float (0–1) | 置信度 |

### 质量约束
- 单点阈值：score < 0.3 → 剔除。  
- 可用帧阈值：≥ 70 % 关键点 score ≥ 0.5 → 可用。  
- 否则 Frame.lowConfidence = true。  
- 时间戳单调递增，间隔 ≈ 66.67 ms (30 fps 抽 2 帧)。  
- 前置摄像头输入需镜像翻转：`x' = 1 - x`，并在 `mirrorApplied` 标记为 true。

---

## 2️⃣ result.json 增量字段

| 字段 | 类型 | 说明 |
|------|------|------|
| engine | string | `"mlkit"` |
| engineVersion | string | 版本号 |
| inputResolution | string | `"720p"` |
| samplingStride | int | 默认 2 |

---

## 3️⃣ 输出目录规范
```
build/offline_out/
└── <video_basename>/
    ├── neutral_keypoints.json     # 新增输出
    ├── angles.csv                 # 角度结果
    ├── result.json                # 汇总结果
    ├── overlay.mp4                # 骨架叠加回放（可选）
    └── logs/
        ├── run.log
        └── perf.json
```

说明：  
- `<video_basename>` 为输入视频文件名（无扩展名）。  
- 日志目录保存运行参数与性能统计。  
- 若启用多批次，可追加 `_vB1.1` 后缀区分。  
- `overlay.mp4` 为可选验证产物，用于可视化关键点与滤波结果；  
  推荐 15 fps 导出以减少体积；  
  主要用于人工核查动作计数、翻转是否正确，不计入性能指标；  
  若存在则校验脚本可记录 `hasOverlay = true`。

---

## 4️⃣ 校验清单

| 检查项 | 期望值 / 规则 | 结果 (PASS/FAIL) |
|--------|---------------|------------------|
| 文件存在 | 三件套 ( neutral_keypoints.json / angles.csv / result.json ) 齐全 | |
| JSON 结构 | 符合 Schema 字段 & 类型 | |
| 帧时间戳 | 单调递增 且 首帧 = 0 ms | |
| 帧数量 | ≈ duration / (1000 / effectiveFps) ± 1 帧 | |
| 可用帧比例 | ≥ 70 % PASS | |
| 低置信帧比例 | ≤ 10 % PASS | |
| 单帧推理耗时 | ≤ 35 ms | |
| 性能报告存在 | logs/perf.json 存在且 字段完整 | |
| 目录结构 | 符合规范 | |
| 错误日志 | logs/run.log 无 FATAL 级别 错误 | |
| mirrorApplied 字段 | 前置摄像头帧 = true，后置 = false | |
| overlay 视频 | overlay.mp4 存在 且 时长≈duration ± 1 s （可选） | |

---

## 5️⃣ 备注
- 目录规范、Schema 和 校验清单是 Milestone B 阶段的验收基准。  
- 适配层负责坐标归一化与镜像修正。  
- 骨架回放视频可作为可视化验证结果的附加输出。  
- 校验脚本可用 Python 或 Dart 解析 JSON 后按清单逐项核对。  
- 若与 Python baseline 比对，应确保时间戳与帧索引一致。


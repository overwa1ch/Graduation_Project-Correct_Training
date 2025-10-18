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

---

## 6️⃣ C-augment 补充（Hybrid & Evidence）

### 6.1 result.json 中的 C-augment 字段
```json
{
  "version": "vB1.1",
  "hybrid": {
    "triggered": true,
    "reason": "low_coverage",
    "uploadPolicy": "keypoints_only",
    "cloudEnhanced": true,
    "mergeStrategy": "prefer-cloud-count-then-reconcile",
    "reconcileNote": "cloud-count=12, device-count=11, diff=1",
    "metrics": {
      "coverage": 0.72,
      "lowConfPct": 0.18,
      "fps": 28.5,
      "jitterPx": 6.2
    },
    "delta": {
      "countLocal": 11,
      "countCloud": 12,
      "countFinal": 12
    }
  },
  "evidence": [
    {
      "type": "segment",
      "timestampMs": 4233,
      "frameIndex": 64,
      "repIndex": 2,
      "phase": "bottom",
      "cues": ["knee_inward", "depth_insufficient"],
      "angles": {"leftKnee": 142.3, "hipFlexion": 78.5},
      "thresholds": {
        "leftKnee_maxValgus": 160,
        "depth_minHipAngle": 70
      },
      "snapshotRef": "overlay.mp4#t=4.23"
    }
  ]
}
```
> 若旧产物缺少 `hybrid`/`evidence` 节点仍视为向后兼容；校验脚本需容忍字段缺省。

### 6.2 hybrid_policy.json（C-augment 结构）
```json
{
  "version": "C-augment",
  "engine": "mlkit|movenet|any",
  "uploadPolicy": "keypoints_only|keypoints_plus_video",
  "rules": [
    { "name": "low_coverage", "metric": "coverage", "op": "<", "threshold": 0.85, "weight": 1.0 },
    { "name": "low_conf_pct", "metric": "lowConfPct", "op": ">", "threshold": 0.15, "weight": 1.0 },
    { "name": "fps_instability", "metric": "jitter", "op": ">", "threshold": 5.0, "weight": 0.5 }
  ],
  "trigger": {
    "mode": "any|all|weighted_sum",
    "weighted_sum_threshold": 1.0
  }
}
```

### 6.3 cloud_result.json（本地云端模拟）
```json
{
  "source": "mock",
  "counts": 12,
  "segments": [
    { "startMs": 300, "endMs": 1200 },
    { "startMs": 1250, "endMs": 2200 }
  ],
  "quality": { "tempo": 0.92, "depth": 0.88 },
  "notes": "simulated cloud enhancement vC"
}
```
> 示例文件：`aiwa_cli/mocks/cloud_result.json` 可直接作为 `--cloud-mock` 参数使用。

### 6.4 校验规则（C-augment）
| 规则 ID | 严重级别 | 判据 / 提示 |
| --- | --- | --- |
| `hybrid.reason` | ERROR | `hybrid.triggered=true` 时必须包含 `reason`、`uploadPolicy`。|
| `hybrid.coverage_range` | ERROR | `metrics.coverage`、`lowConfPct` 必须在 `[0,1]`。|
| `hybrid.missing_reconcile_note` | WARN | `cloudEnhanced=true` 且 `|cloud-count - local-count| > 2` 时缺少 `reconcileNote`。|
| `overlay.duration_mismatch` | ERROR | overlay.mp4 时长与 result 区间差异 > 1s。|
| `overlay.snapshot_out_of_range` | ERROR | `snapshotRef` 时间戳不在 overlay 区间内。|
| `evidence.timestamp` | ERROR | `evidence[].timestampMs` 缺失或非数值。|
| `evidence.angle_nan` | ERROR | `angles` 内出现 NaN/Inf。|
| `evidence.file_missing` | WARN | 启用证据化但缺少 `evidence.json`。|
| `evidence.perf_missing` | WARN | 缺少 `logs/perf.json` 性能统计。|


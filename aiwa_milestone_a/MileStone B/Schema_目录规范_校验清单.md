# AIWA Milestone B 输出规范文档（vB1）
---

## 1️⃣ neutral_keypoints.json Schema（vB1）

### 顶层结构
| 字段 | 类型 | 说明 |
|------|------|------|
| version | string | 固定 `"vB1"` |
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


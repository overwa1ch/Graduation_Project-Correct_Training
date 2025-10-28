# stdout_events.md
**Version:** v2.0  
**Purpose:** 定义 aiwa_cli.dart → 前端 UI 的事件协议（JSON Lines 格式）。

---

## 通用约定
- 每行一个 JSON 对象（UTF-8 编码，\n 结尾）
- 字段：`ts`, `sessionId`, `event`
- 输出到 `stdout`，错误日志输出到 `stderr`
- 同步写入 `logs/run.log`

## 事件枚举

### 1️⃣ START
视频信息与运行参数。
```json
{"event":"START","sessionId":"20251028_101320_7f2c",
 "input":{"path":"/videos/input.mp4","durationMs":42500,"fps":30,"resolution":"1280x720"},
 "params":{"stride":2,"engine":"MoveNet","strictness":"strict"}}
```

### 2️⃣ PHASE
阶段切换。
```json
{"event":"PHASE","phase":"infer"}
```

### 3️⃣ PROGRESS
处理进度。
```json
{"event":"PROGRESS","processed":450,"total":1275,"p95MsPerFrame":33,"etaSec":28}
```

### 4️⃣ METRIC
中间指标。
```json
{"event":"METRIC","lowConfidenceRatio":0.18,"usableFrameRatio":0.76}
```

### 5️⃣ EVIDENCE
命中证据。
```json
{"event":"EVIDENCE","frame":812,"t":"00:00:27.07","files":["evidence/frame_812.jpg"]}
```

### 6️⃣ DONE
产物生成完毕。
```json
{"event":"DONE","artifacts":{"root":"build/offline_out/20251028_101320_7f2c/",
 "files":["result.json","neutral_keypoints.json","angles.csv"]}}
```

### 7️⃣ ERROR
错误事件。
```json
{"event":"ERROR","code":"422_SCHEMA_MISMATCH","message":"result.json missing field posture"}
```
